(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    nealj 
 * Created:   October 27, 2021/1:47 PM 
 * The SnapshotSpawner FUB will gather the list of shuttles and monitor their
 * postions when enabled. When execute is TRUE, the FUB will gather the user data
 * and shuttle info of each shuttle.
 *********************************************************************************)

FUNCTION_BLOCK TrakSnapSpawn
	
	Internal.FB.ShCopyUserData.Mode  := mcACPTRAK_USERDATA_SET;
	
	Internal.FB.RecipeXML.Enable     := Enable;
	Internal.FB.RecipeXML.MpLink     := ADR(RecipeLink);
	Internal.FB.RecipeXML.DeviceName := ADR('SnapshotDevice');
	Internal.FB.RecipeXML.FileName   := ADR(SnapshotToLoad);
	
	Internal.FB.RecipeRegPar.Enable := Internal.FB.RecipeXML.Active;
	Internal.FB.RecipeRegPar.MpLink := ADR(RecipeLink);
	Internal.FB.RecipeRegPar.PVName := ADR(TrakSnapStructureName);
	
	CASE Internal.State OF
		//************************************************************************************************************
		SNAPSPAWN_IDLE:
			IF (Internal.FB.RecipeXML.Error OR Internal.FB.RecipeRegPar.Error) THEN
				//RECIPE INIT FAILED
				Error          := TRUE;
				ErrorID        := SPAWN_RECIPE_INIT_FAILED;
				Internal.State := SNAPSPAWN_ERROR;
			ELSIF (Enable AND Internal.FB.RecipeXML.Active AND Internal.FB.RecipeRegPar.Active) THEN
				Active         := TRUE;
				Ready          := TRUE;
				Internal.State := SNAPSPAWN_READY;
			END_IF
			
			//************************************************************************************************************
		SNAPSPAWN_READY:
			//TO DO: ADD LOGIC TO PREVENT SPAWNING SHUTTLES WITH SHUTTLES ON THE TRAK VIA ASMGETSHUTTLE FUB <~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<<<
			IF NOT Enable THEN
				Internal.State := SNAPSPAWN_RESET;
			ELSIF Spawn THEN
				IF (0 = brsstrcmp(ADR(SnapshotToLoad),ADR(''))) THEN
					//SNAPSHOT TO LOAD EMPTY
					Error          := TRUE;
					ErrorID        := SPAWN_SNAPSHOT_TO_LOAD_EMPTY;
					Internal.State := SNAPSPAWN_ERROR;
				ELSE	
					Done                       := FALSE;
					Ready                      := FALSE;
					Busy                       := TRUE;
					Internal.FB.RecipeXML.Load := TRUE;
					Internal.State             := SNAPSPAWN_LOAD_RECIPE;
				END_IF
			END_IF				
			
			//************************************************************************************************************
		SNAPSPAWN_LOAD_RECIPE:
			IF NOT Enable THEN
				Internal.State := SNAPSPAWN_RESET;
			ELSIF Internal.FB.RecipeXML.Error THEN
				//LOAD RECIPE FAILED
				Error          := TRUE;
				ErrorID        := SPAWN_LOAD_RECIPE_FAILED;
				Internal.State := SNAPSPAWN_ERROR;
			ELSIF Internal.FB.RecipeXML.CommandDone THEN
				Internal.FB.RecipeXML.Load         := FALSE;
				Internal.NumShuttles               := TrakSnapStructure.NumShuttlesFound;
				Internal.Index                     := 0;
				IF (0 <> brsstrcmp(ADR(TrakSnapStructure.ShuttleInfo[Internal.Index].CurrentSector),ADR(''))) THEN
					//If the shuttle was on a user defined sector (the sector name is not empty), spawn it on that sector
					Internal.PV_XGETADR_ERROR_ID := PV_xgetadr(ADR(TrakSnapStructure.ShuttleInfo[Internal.Index].CurrentSector),ADR(Internal.SectorReference),ADR(Internal.SectorReferenceSize));
					Internal.FB.SecAddShuttle.Sector   := Internal.SectorReference;
					Internal.FB.SecAddShuttle.Position := TrakSnapStructure.ShuttleInfo[Internal.Index].CurrentPosition;
					Internal.FB.SecAddShuttle.Execute  := TRUE;
					Internal.State                     := SNAPSPAWN_SPAWN_SHUTTLE;
				ELSIF ((0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[0]),ADR('')))  OR
					   (0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[1]),ADR('')))  OR
					   (0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[2]),ADR('')))  OR
					   (0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[3]),ADR('')))) THEN
					//The shuttle was not on a user defined sector, and at least one of the segment references wasn't empty
					Internal.State := SNAPSPAWN_PICK_SEGSEC;
				ELSE
					//NO POSITION FOR SHUTTLE SPAWN
					Error          := TRUE;
					ErrorID        := SPAWN_NO_POS_FOR_SHUTTLE_SPAWN + Internal.Index;
				END_IF
			END_IF
		
			//************************************************************************************************************
		SNAPSPAWN_PICK_SEGSEC:
			//Check to see which options are valid (name is not empty and position is positive)
			Internal.SegmentSector.Valid[0] := ((0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[0]),ADR(''))) AND (TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[0] >= 0));
			Internal.SegmentSector.Valid[1] := ((0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[1]),ADR(''))) AND (TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[1] >= 0));
			Internal.SegmentSector.Valid[2] := ((0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[2]),ADR(''))) AND (TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[2] >= 0));
			Internal.SegmentSector.Valid[3] := ((0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[3]),ADR(''))) AND (TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[3] >= 0));
			
			//Read in the positions to improve programming readability
			Internal.SegmentSector.Position[0] := TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[0];
			Internal.SegmentSector.Position[1] := TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[1];
			Internal.SegmentSector.Position[2] := TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[2];
			Internal.SegmentSector.Position[3] := TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[3];
			
			//Use the for loop to determine the lowest valid segment sector position
			//This check is necessary since shuttles hanging off the end of a segment will have positions larger than the length of the segment
			FOR Internal.SegmentSector.Index:=0 TO 3 DO
				//Confirm that the best option is a valid reference
				IF Internal.SegmentSector.Valid[Internal.SegmentSector.BestOption] THEN
					//Confirm that the current index is a valid reference
					IF Internal.SegmentSector.Valid[Internal.SegmentSector.Index] THEN
						//Check if the current index is lower than the best option
						IF (Internal.SegmentSector.Position[Internal.SegmentSector.Index] < Internal.SegmentSector.Position[Internal.SegmentSector.BestOption]) THEN
							//The current index is lower than the best option, so make it the new best option
							Internal.SegmentSector.BestOption := Internal.SegmentSector.Index;
						ELSE
							//The best option is lower than the current index, so keep the best option
						END_IF
					ELSE
						//The current index is not a valid reference, so keep the best option
					END_IF
				ELSE
					//The best option is not a valid index, so make the current index the new best option
					Internal.SegmentSector.BestOption := Internal.SegmentSector.Index;
				END_IF
			END_FOR
			
			Internal.SectorReferenceSize       := SIZEOF(Internal.SectorReference);
			Internal.SegmentSector.Name        := '';
			brsstrcat(ADR(Internal.SegmentSector.Name),ADR(Internal.SegmentSector.Prefix));
			brsstrcat(ADR(Internal.SegmentSector.Name),ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[Internal.SegmentSector.BestOption]));
			Internal.PV_XGETADR_ERROR_ID       := PV_xgetadr(ADR(Internal.SegmentSector.Name),ADR(Internal.SectorReference),ADR(Internal.SectorReferenceSize));
			Internal.FB.SecAddShuttle.Sector   := Internal.SectorReference;
			Internal.FB.SecAddShuttle.Position := TrakSnapStructure.SegmentInfo[Internal.Index].CurrentPosition[Internal.SegmentSector.BestOption];
			Internal.FB.SecAddShuttle.Execute  := TRUE;
			Internal.State                     := SNAPSPAWN_SPAWN_SHUTTLE;
		
			//************************************************************************************************************
		SNAPSPAWN_SPAWN_SHUTTLE:
			IF NOT Enable THEN
				Internal.State := SNAPSPAWN_RESET;
			ELSIF Internal.FB.SecAddShuttle.Error THEN
				//ADD SHUTTLE FAILED
				Error          := TRUE;
				ErrorID        := SPAWN_ADD_SHUTTLE_FAILED + Internal.Index;
				Internal.State := SNAPSPAWN_ERROR;
			ELSIF Internal.FB.SecAddShuttle.Done THEN
				Internal.Shuttles[Internal.Index]      := Internal.FB.SecAddShuttle.Axis;
				Internal.FB.ShCopyUserData.Axis        := ADR(Internal.Shuttles[Internal.Index]);
				Internal.FB.SecAddShuttle.Execute      := FALSE;
				Internal.FB.ShCopyUserData.DataAddress := ADR(TrakSnapStructure.UserData[Internal.Index]);
				Internal.FB.ShCopyUserData.DataSize    := SIZEOF(TrakSnapStructure.UserData[Internal.Index]);
				Internal.FB.ShCopyUserData.Execute     := TRUE;
				Internal.State                         := SNAPSPAWN_SET_USERDATA;
			END_IF
			
			//************************************************************************************************************
		SNAPSPAWN_SET_USERDATA:
			IF NOT Enable THEN
				Internal.State := SNAPSPAWN_RESET;
			ELSIF Internal.FB.ShCopyUserData.Error THEN
				//SET USERDATA FAILED
				Error          := TRUE;
				ErrorID        := SPAWN_SET_USERDATA_FAILED + Internal.Index;
				Internal.State := SNAPSPAWN_ERROR;
			ELSIF Internal.FB.ShCopyUserData.Done THEN
				Internal.FB.ShCopyUserData.Execute := FALSE;
				//Check if there are more shuttles to spawn and move on
				IF (Internal.Index = (Internal.NumShuttles - 1)) THEN
					Done           := TRUE;
					Internal.State := SNAPSPAWN_DONE;
				ELSE
					Internal.Index                     := Internal.Index + 1;
					Internal.SectorReferenceSize       := SIZEOF(Internal.SectorReference);
					IF (0 <> brsstrcmp(ADR(TrakSnapStructure.ShuttleInfo[Internal.Index].CurrentSector),ADR(''))) THEN
						//If the shuttle was on a user defined sector (the sector name is not empty), spawn it on that sector
						Internal.PV_XGETADR_ERROR_ID := PV_xgetadr(ADR(TrakSnapStructure.ShuttleInfo[Internal.Index].CurrentSector),ADR(Internal.SectorReference),ADR(Internal.SectorReferenceSize));
						Internal.FB.SecAddShuttle.Sector   := Internal.SectorReference;
						Internal.FB.SecAddShuttle.Position := TrakSnapStructure.ShuttleInfo[Internal.Index].CurrentPosition;
						Internal.FB.SecAddShuttle.Execute  := TRUE;
						Internal.State                     := SNAPSPAWN_SPAWN_SHUTTLE;
					ELSIF ((0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[0]),ADR('')))  OR
						   (0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[1]),ADR('')))  OR
						   (0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[2]),ADR('')))  OR
						   (0 <> brsstrcmp(ADR(TrakSnapStructure.SegmentInfo[Internal.Index].CurrentSegment[3]),ADR('')))) THEN
						//The shuttle was not on a user defined sector, and at least one of the segment references wasn't empty
						Internal.State := SNAPSPAWN_PICK_SEGSEC;
					ELSE
						//NO POSITION FOR SHUTTLE SPAWN
						Error          := TRUE;
						ErrorID        := SPAWN_NO_POS_FOR_SHUTTLE_SPAWN + Internal.Index;
					END_IF
				END_IF
			END_IF
			
			//************************************************************************************************************
		SNAPSPAWN_DONE:
			IF NOT Enable THEN
				Internal.State := SNAPSPAWN_RESET;
			ELSIF NOT Spawn THEN
				Done           := FALSE;
				Ready          := TRUE;
				Internal.State := SNAPSPAWN_READY;
			END_IF			
			
			//************************************************************************************************************
		SNAPSPAWN_RESET:
			Active                             := FALSE;
			Ready                              := FALSE;
			Spawn                              := FALSE;
			Busy                               := FALSE;
			Done                               := FALSE;
			Internal.FB.RecipeRegPar.Enable    := FALSE;
			Internal.FB.RecipeXML.Enable       := FALSE;
			Internal.FB.SecAddShuttle.Execute  := FALSE;
			Internal.FB.ShCopyUserData.Execute := FALSE;
			Internal.State := SNAPSPAWN_IDLE;
			
			//************************************************************************************************************
		SNAPSPAWN_ERROR:
			IF NOT Enable THEN
				Internal.State := SNAPSPAWN_RESET;
			END_IF		
		
	END_CASE
	
	Internal.FB.RecipeRegPar();
	Internal.FB.RecipeXML();
	Internal.FB.SecAddShuttle();
	Internal.FB.ShCopyUserData();
	
END_FUNCTION_BLOCK
