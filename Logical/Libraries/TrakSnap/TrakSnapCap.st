(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    nealj 
 * Created:   October 18, 2021/11:10 AM 
 * The SnapshotTaker FUB will gather the list of shuttles and monitor their
 * postions when enabled. When execute is TRUE, the FUB will gather the user data
 * and shuttle info of each shuttle.
 *
 * NOTE: The FUB works on the assumption that a global trak sector has been
 * created. This is a sector that encompasses the entire assembly in one
 * continuous path. Overlap is allowed.
 *********************************************************************************)

FUNCTION_BLOCK TrakSnapCap
	
	Internal.FB.GetTime.enable           := Enable;
	Internal.CurrentDateTime             := Internal.FB.GetTime.DT1;
	Internal.FB.DTRecipeConverter.Input  := DT_TO_UDINT(Internal.CurrentDateTime);
	Internal.FB.DTRecipeConverter.Offset := EPOCH_OFFSET;
	IF (Enable AND NOT Internal.FB.DTRecipeConverter.Execute) THEN
		Internal.FB.DTRecipeConverter.Execute := TRUE;
	END_IF
	Internal.CurrentDateTime_Str         := Internal.FB.DTRecipeConverter.DTString_For_Recipe;
	
	Internal.FB.RecipeXML.Enable     := Enable;
	Internal.FB.RecipeXML.MpLink     := ADR(RecipeLink);
	Internal.FB.RecipeXML.DeviceName := ADR('SnapshotDevice');
	Internal.FB.RecipeXML.FileName   := ADR(Internal.CurrentDateTime_Str);
	
	Internal.FB.RecipeRegPar.Enable := Internal.FB.RecipeXML.Active;
	Internal.FB.RecipeRegPar.MpLink := ADR(RecipeLink);
	Internal.FB.RecipeRegPar.PVName := ADR(TrakSnapStructureName);
	
	CASE Internal.State OF
		//************************************************************************************************************
		SNAPCAP_IDLE:
			IF (Internal.FB.RecipeXML.Error OR Internal.FB.RecipeRegPar.Error) THEN
				//RECIPE INIT FAILED
				Error          := TRUE;
				ErrorID        := CAP_RECIPE_INIT_FAILED;
				Internal.State := SNAPCAP_ERROR;
			ELSIF (Enable AND Internal.FB.RecipeXML.Active AND Internal.FB.RecipeRegPar.Active) THEN
				//Set the active flag, clear the user structure and shuttle list, and start the AsmGetShuttle FUB
				Active                             := TRUE;
				brsmemset(ADR(TrakSnapStructure),0,SIZEOF(TrakSnapStructure));
				brsmemset(ADR(Internal.Shuttles),0,SIZEOF(Internal.Shuttles));
				Internal.FB.AsmGetShuttle.Assembly := ADR(Assembly);
				Internal.FB.AsmGetShuttle.Enable   := TRUE;
				Internal.Index                     := 0;
				Internal.State                     := SNAPCAP_GET_SHUTTLES;
			END_IF
		
		//************************************************************************************************************
		SNAPCAP_GET_SHUTTLES:
			IF NOT Enable THEN
				Internal.State := SNAPCAP_RESET;
			ELSIF Internal.FB.AsmGetShuttle.Error THEN
				//GET SHUTTLES FAILED
				Error          := TRUE;
				ErrorID        := CAP_GET_SHUTTLES_FAILED;
				Internal.State := SNAPCAP_ERROR;
			ELSIF (Internal.FB.AsmGetShuttle.Valid AND (Internal.Shuttles[Internal.Index].controlif = 0)) THEN
				IF (Internal.FB.AsmGetShuttle.TotalCount > TRAKSNAP_NUM_SHUTTLES) THEN
					//TOO MANY SHUTTLES
					Error          := TRUE;
					ErrorID        := CAP_TOO_MANY_SHUTTLES;
					Internal.State := SNAPCAP_ERROR;
				ELSE
					//Update the list of shuttles
					Internal.FB.AsmGetShuttle.Next    := FALSE;
					Internal.Shuttles[Internal.Index] := Internal.FB.AsmGetShuttle.Axis;
					Internal.Index                    := Internal.Index + 1;
					Internal.State                    := SNAPCAP_CHECK_REMAINING_COUNT;
				END_IF
			END_IF
			
		//************************************************************************************************************
		SNAPCAP_CHECK_REMAINING_COUNT:
			IF NOT Enable THEN
				Internal.State := SNAPCAP_RESET;
			ELSIF Internal.FB.AsmGetShuttle.RemainingCount > 0 THEN
				Internal.FB.AsmGetShuttle.Next := TRUE;
				Internal.State                 := SNAPCAP_GET_SHUTTLES;
			ELSE
				//Update the count for the FUB and the recipe, and configure the ShReadSegmentInfo & ShReadInfo FUBs
				NumShuttlesFound                   := Internal.FB.AsmGetShuttle.TotalCount;
				TrakSnapStructure.NumShuttlesFound := Internal.FB.AsmGetShuttle.TotalCount;
				FOR Internal.Index:=0 TO (NumShuttlesFound-1) DO
					Internal.FB.ShReadSegmentInfo[Internal.Index].Axis   := ADR(Internal.Shuttles[Internal.Index]);
					Internal.FB.ShReadSegmentInfo[Internal.Index].Enable := TRUE;
					Internal.FB.ShReadInfo[Internal.Index].Axis          := ADR(Internal.Shuttles[Internal.Index]);
					Internal.FB.ShReadInfo[Internal.Index].Enable        := TRUE;
				END_FOR
				Ready          := TRUE;
				Internal.State := SNAPCAP_READY;
			END_IF
			
		//************************************************************************************************************	
		SNAPCAP_READY:			
			//ADD CONDITION TO DISABLE WHEN ENABLE IS RESET
			IF NOT Enable THEN
				Internal.State := SNAPCAP_RESET;
			ELSIF Internal.FB.AsmGetShuttle.TotalCount <> NumShuttlesFound THEN
				//If the shuttle count of the AsmGetShuttle FUB changes, clear the user structure and shuttle list and update the shuttle list
				FOR Internal.Index:=0 TO (TRAKSNAP_NUM_SHUTTLES) DO
					Internal.FB.ShReadSegmentInfo[Internal.Index].Enable := FALSE;
					Internal.FB.ShReadInfo[Internal.Index].Enable        := FALSE;
				END_FOR
				brsmemset(ADR(TrakSnapStructure),0,SIZEOF(TrakSnapStructure));
				brsmemset(ADR(Internal.Shuttles),0,SIZEOF(Internal.Shuttles)); //Is this the proper way to clear the array? -JRN 10/18/21
				Internal.Index                     := 0;
				Internal.State                     := SNAPCAP_GET_SHUTTLES;
			ELSIF Capture THEN
				//When the capture command is set, leave the state to capture the data and info
				Ready                                  := FALSE;
				Busy                                   := TRUE;
				Internal.Index                         := 0;
				FOR Internal.Index:=0 TO (NumShuttlesFound-1) DO
					Internal.FB.ShCopyUserData[Internal.Index].Axis        := ADR(Internal.Shuttles[Internal.Index]);
					Internal.FB.ShCopyUserData[Internal.Index].DataAddress := ADR(TrakSnapStructure.UserData[Internal.Index]);
					Internal.FB.ShCopyUserData[Internal.Index].DataSize    := SIZEOF(TrakSnapStructure.UserData[Internal.Index]);
					Internal.FB.ShCopyUserData[Internal.Index].Execute     := TRUE;
				END_FOR
				Internal.State                         := SNAPCAP_CAPTURE;
			ELSE
				//Check the ShReadSegmentInfo and ShReadInfo FUBs for errors
				FOR Internal.Index:=0 TO (NumShuttlesFound-1) DO
					IF Internal.FB.ShReadSegmentInfo[Internal.Index].Error THEN
						//READ GLOBAL POS FAILED
						Error          := TRUE;
						ErrorID        := CAP_READ_SEGMENT_INFO_FAILED + Internal.Index;
						Internal.State := SNAPCAP_ERROR;
					ELSIF Internal.FB.ShReadInfo[Internal.Index].Error THEN
						//READ SHUTTLE INFO FAILED
						Error          := TRUE;
						ErrorID        := CAP_READ_SHUTTLE_INFO_FAILED + Internal.Index;
						Internal.State := SNAPCAP_ERROR;
					END_IF
				END_FOR
			END_IF
			
			//************************************************************************************************************
		SNAPCAP_CAPTURE:
			FOR Internal.Index:=0 TO (NumShuttlesFound-1) DO
				IF Internal.FB.ShCopyUserData[Internal.Index].Error THEN
					//GET USERDATA FAILED
					Error          := TRUE;
					ErrorID        := CAP_GET_USERDATA_FAILED + Internal.Index;
					Internal.State := SNAPCAP_ERROR;
				ELSIF Internal.FB.ShCopyUserData[Internal.Index].Done THEN
					Internal.FB.ShCopyUserData[Internal.Index].Execute                  := FALSE;
					//Read in segment information. A shuttle can be on up to 4 segments at once, so all possibilities are gathered
					TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[0]    := Internal.FB.ShReadSegmentInfo[Internal.Index].SegmentInfo.SegmentCurrentValues[0].Position;
					TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[0]     := Internal.FB.ShReadSegmentInfo[Internal.Index].SegmentInfo.SegmentCurrentValues[0].SegmentName;
					TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[1]    := Internal.FB.ShReadSegmentInfo[Internal.Index].SegmentInfo.SegmentCurrentValues[1].Position;
					TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[1]     := Internal.FB.ShReadSegmentInfo[Internal.Index].SegmentInfo.SegmentCurrentValues[1].SegmentName;
					TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[2]    := Internal.FB.ShReadSegmentInfo[Internal.Index].SegmentInfo.SegmentCurrentValues[2].Position;
					TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[2]     := Internal.FB.ShReadSegmentInfo[Internal.Index].SegmentInfo.SegmentCurrentValues[2].SegmentName;
					TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[3]    := Internal.FB.ShReadSegmentInfo[Internal.Index].SegmentInfo.SegmentCurrentValues[3].Position;
					TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[3]     := Internal.FB.ShReadSegmentInfo[Internal.Index].SegmentInfo.SegmentCurrentValues[3].SegmentName;
					//Read in shuttle information
					TrakSnapStructure.ShuttleInfo[Internal.Index].CurrentPosition       := Internal.FB.ShReadInfo[Internal.Index].ShuttleInfo.CurrentValues.ActualModuloPosition;
					TrakSnapStructure.ShuttleInfo[Internal.Index].CurrentSector         := Internal.FB.ShReadInfo[Internal.Index].ShuttleInfo.CurrentValues.SectorName;
					TrakSnapStructure.ShuttleInfo[Internal.Index].CurrentVelocity       := Internal.FB.ShReadInfo[Internal.Index].ShuttleInfo.CurrentValues.Velocity;
					TrakSnapStructure.ShuttleInfo[Internal.Index].TargetPosition        := Internal.FB.ShReadInfo[Internal.Index].ShuttleInfo.RouteDestinationInfo.Position;
					TrakSnapStructure.ShuttleInfo[Internal.Index].TargetSector          := Internal.FB.ShReadInfo[Internal.Index].ShuttleInfo.RouteDestinationInfo.SectorName;
					TrakSnapStructure.ShuttleInfo[Internal.Index].VelocityAtDestination := Internal.FB.ShReadInfo[Internal.Index].ShuttleInfo.RouteDestinationInfo.VelocityAtDestination;
				END_IF
			END_FOR
			IF NOT Enable THEN
				Internal.State := SNAPCAP_RESET;
			ELSIF NOT Error THEN
				Internal.FB.RecipeXML.Save := TRUE;
				Internal.State             := SNAPCAP_DONE;
			END_IF
			
			//************************************************************************************************************
		SNAPCAP_DONE:
			IF (Internal.FB.RecipeXML.Error OR Internal.FB.RecipeRegPar.Error) THEN
				//SAVE RECIPE FAILED
				Error          := TRUE;
				ErrorID        := CAP_SAVE_RECIPE_FAILED;
				Internal.State := SNAPCAP_ERROR;
			ELSIF (Internal.FB.RecipeXML.CommandDone AND NOT Done) THEN
				Busy := FALSE;
				Done := TRUE;
			ELSIF NOT Capture THEN
				Done           := FALSE;
				Ready          := TRUE;
				Internal.State := SNAPCAP_READY;
			ELSIF NOT Enable THEN
				Internal.State := SNAPCAP_RESET;
			END_IF
			
		//************************************************************************************************************
		SNAPCAP_RESET:
			Active  := FALSE;
			Ready   := FALSE;
			Capture := FALSE;
			Busy    := FALSE;
			Done    := FALSE;
			Active  := FALSE;
			Error   := FALSE;
			ErrorID := 0;
			
            Internal.FB.AsmGetShuttle.Enable                     := FALSE;
			FOR Internal.Index:=0 TO TRAKSNAP_NUM_SHUTTLES DO
			Internal.FB.ShReadSegmentInfo[Internal.Index].Enable := FALSE;
			Internal.FB.ShCopyUserData[Internal.Index].Execute   := FALSE;
			Internal.FB.ShReadInfo[Internal.Index].Enable        := FALSE;
			END_FOR
				
			Internal.Index := 0;
			Internal.State := SNAPCAP_IDLE;
			
		//************************************************************************************************************
		SNAPCAP_ERROR:
			IF NOT Enable THEN
				Internal.State := SNAPCAP_RESET;
			END_IF
		
				
	END_CASE
	
	Internal.FB.AsmGetShuttle();
	IF NumShuttlesFound <> 0 THEN
		FOR Internal.Index:=0 TO (NumShuttlesFound-1) DO
			Internal.FB.ShReadSegmentInfo[Internal.Index]();
			Internal.FB.ShReadInfo[Internal.Index]();
			Internal.FB.ShCopyUserData[Internal.Index]();
		END_FOR
	END_IF
	Internal.FB.GetTime();
	Internal.FB.RecipeXML();
	Internal.FB.RecipeRegPar();
	Internal.FB.DTRecipeConverter();
	
END_FUNCTION_BLOCK
