
ACTION Reject: 

	TrgPointEnable[5].ProcessPoint  := ADR(PP_Reject);
	TrgPointEnable[5].Enable        := TRUE;
	TrgPointGetInfo[5].ProcessPoint := ADR(PP_Reject);
	
	CASE StnState[5] OF
		STN_WAIT_FOR_SHUTTLE:
			IF (TrgPointEnable[5].EventCount > 0) THEN
				TrgPointGetInfo[5].Execute := TRUE;
				StnState[5]                := STN_GET_INFO;
			END_IF
			
		STN_GET_INFO:
			IF TrgPointGetInfo[5].Done THEN
				ShReadInfo[5].Axis            := ADR(TrgPointGetInfo[5].TrgPointInfo.Axis);
				ShReadInfo[5].Enable          := TRUE;
				ShCopyUserData[5].Axis        := ADR(TrgPointGetInfo[5].TrgPointInfo.Axis);
				ShCopyUserData[5].DataAddress := ADR(StationData[5]);
				ShCopyUserData[5].DataSize    := SIZEOF(StationData[5]);
				ShCopyUserData[5].Mode        := mcACPTRAK_USERDATA_GET;
				ShCopyUserData[5].Execute     := TRUE;
				StnState[5]                   := STN_GET_USERDATA;
			END_IF
		
		STN_GET_USERDATA:
			IF ShCopyUserData[5].Done AND (ShReadInfo[5].ShuttleInfo.AdditionalInfo.PLCopenState = mcAXIS_STANDSTILL) THEN
				ShCopyUserData[5].Execute := FALSE;
				IF (StationData[5].Color = RED) THEN
					ShSwitchSector[5].Axis    := ADR(TrgPointGetInfo[5].TrgPointInfo.Axis);
					ShSwitchSector[5].Sector  := Stn[7];
					ShSwitchSector[5].Execute := TRUE;
					StnState[5]               := STN_HANDLE_SHUTTLE;
				ELSE
					TrgPointGetInfo[5].Execute := FALSE;
					ShReadInfo[5].Enable       := FALSE;
					StnState[5]                := STN_WAIT_FOR_SHUTTLE;
				END_IF
			END_IF
			
		STN_HANDLE_SHUTTLE:
			IF (ShSwitchSector[5].Done) AND (ShReadInfo[5].ShuttleInfo.CurrentValues.SectorName = 'Reject_RightDown') THEN
				ShSwitchSector[5].Execute                                 := FALSE;
				StationData[5].Color                                      := GRAY;
				StnRoutedMoveAbs[5].Axis                                  := ADR(TrgPointGetInfo[5].TrgPointInfo.Axis);
				StnRoutedMoveAbs[5].Sector                                := Stn[9];
				StnRoutedMoveAbs[5].Position                              := 0.405;
				StnRoutedMoveAbs[5].Acceleration                          := 20;
				StnRoutedMoveAbs[5].Deceleration                          := 20;
				StnRoutedMoveAbs[5].Velocity                              := 4;
				StnRoutedMoveAbs[5].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
				StnRoutedMoveAbs[5].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
				StnRoutedMoveAbs[5].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
				ShCopyUserData[5].Mode                                    := mcACPTRAK_USERDATA_SET;
				ShCopyUserData[5].Execute                                 := TRUE;
				StnState[5]                                               := STN_SET_USERDATA;
			END_IF
				
		STN_SET_USERDATA:
			IF ShCopyUserData[5].Done THEN
				ShCopyUserData[5].Execute   := FALSE;
				StnRoutedMoveAbs[5].Execute := TRUE;
				StnState[5]                 := STN_SEND_SHUTTLE;
			END_IF
			
		STN_SEND_SHUTTLE:
			IF StnRoutedMoveAbs[5].Active THEN
				TrgPointGetInfo[5].Execute  := FALSE;
				ShReadInfo[5].Enable        := FALSE;
				StnRoutedMoveAbs[5].Execute := FALSE;
				StnState[5]                 := STN_WAIT_FOR_SHUTTLE;
			END_IF
			
	END_CASE
	
	TrgPointEnable[5]();
	TrgPointGetInfo[5]();
	ShCopyUserData[5]();
	ShReadInfo[5]();
	ShSwitchSector[5]();
	StnRoutedMoveAbs[5]();
	
END_ACTION
