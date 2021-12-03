
ACTION Flipper: 

	TrgPointEnable[6].ProcessPoint  := ADR(PP_Flipper);
	TrgPointEnable[6].Enable        := TRUE;
	TrgPointGetInfo[6].ProcessPoint := ADR(PP_Flipper);
	
	CASE StnState[6] OF
		STN_WAIT_FOR_SHUTTLE:
			IF (TrgPointEnable[6].EventCount > 0) THEN
				TrgPointGetInfo[6].Execute := TRUE;
				StnState[6]                := STN_GET_INFO;
			END_IF
			
		STN_GET_INFO:
			IF TrgPointGetInfo[6].Done THEN
				ShReadInfo[6].Axis            := ADR(TrgPointGetInfo[6].TrgPointInfo.Axis);
				ShReadInfo[6].Enable          := TRUE;
				ShCopyUserData[6].Axis        := ADR(TrgPointGetInfo[6].TrgPointInfo.Axis);
				ShCopyUserData[6].DataAddress := ADR(StationData[6]);
				ShCopyUserData[6].DataSize    := SIZEOF(StationData[6]);
				ShCopyUserData[6].Mode        := mcACPTRAK_USERDATA_GET;
				ShCopyUserData[6].Execute     := TRUE;
				StnState[6]                   := STN_GET_USERDATA;
			END_IF
		
		STN_GET_USERDATA:
			IF ShCopyUserData[6].Done AND (ShReadInfo[6].ShuttleInfo.AdditionalInfo.PLCopenState = mcAXIS_STANDSTILL) THEN
				ShCopyUserData[6].Execute := FALSE;
				IF (StationData[6].Color = GRAY) THEN
					ShSwitchSector[6].Axis    := ADR(TrgPointGetInfo[6].TrgPointInfo.Axis);
					ShSwitchSector[6].Sector  := Stn[10];
					ShSwitchSector[6].Execute := TRUE;
					StnState[6]               := STN_HANDLE_SHUTTLE;
				ELSE
					TrgPointGetInfo[6].Execute := FALSE;
					ShReadInfo[6].Enable       := FALSE;
					StnState[6]                := STN_WAIT_FOR_SHUTTLE;
				END_IF
			END_IF
			
		STN_HANDLE_SHUTTLE:
			IF (ShSwitchSector[6].Done) AND (ShReadInfo[6].ShuttleInfo.CurrentValues.SectorName = 'Flipper_RightDown') THEN
				ShSwitchSector[6].Execute                                 := FALSE;
				StationData[6].Color                                      := GRAY;
				StnRoutedMoveAbs[6].Axis                                  := ADR(TrgPointGetInfo[6].TrgPointInfo.Axis);
				StnRoutedMoveAbs[6].Sector                                := Stn[1];
				StnRoutedMoveAbs[6].Position                              := 0.005;
				StnRoutedMoveAbs[6].Acceleration                          := 20;
				StnRoutedMoveAbs[6].Deceleration                          := 20;
				StnRoutedMoveAbs[6].Velocity                              := 4;
				StnRoutedMoveAbs[6].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
				StnRoutedMoveAbs[6].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
				StnRoutedMoveAbs[6].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
				ShCopyUserData[6].Mode                                    := mcACPTRAK_USERDATA_SET;
				ShCopyUserData[6].Execute                                 := TRUE;
				StnState[6]                                               := STN_SET_USERDATA;
			END_IF
				
		STN_SET_USERDATA:
			IF ShCopyUserData[6].Done THEN
				ShCopyUserData[6].Execute   := FALSE;
				StnRoutedMoveAbs[6].Execute := TRUE;
				StnState[6]                 := STN_SEND_SHUTTLE;
			END_IF
			
		STN_SEND_SHUTTLE:
			IF StnRoutedMoveAbs[6].Active THEN
				TrgPointGetInfo[6].Execute  := FALSE;
				ShReadInfo[6].Enable        := FALSE;
				StnRoutedMoveAbs[6].Execute := FALSE;
				StnState[6]                 := STN_WAIT_FOR_SHUTTLE;
			END_IF
			
	END_CASE
	
	TrgPointEnable[6]();
	TrgPointGetInfo[6]();
	ShCopyUserData[6]();
	ShReadInfo[6]();
	ShSwitchSector[6]();
	StnRoutedMoveAbs[6]();
	
END_ACTION
