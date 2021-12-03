
ACTION Process_1: 

	TrgPointEnable[2].ProcessPoint  := ADR(PP_Process_1);
	TrgPointEnable[2].Enable        := TRUE;
	TrgPointGetInfo[2].ProcessPoint := ADR(PP_Process_1);
	
	CASE StnState[2] OF
		STN_WAIT_FOR_SHUTTLE:
			IF (TrgPointEnable[2].EventCount > 0) THEN
				TrgPointGetInfo[2].Execute := TRUE;
				StnState[2]                := STN_GET_INFO;
			END_IF
			
		STN_GET_INFO:
			IF TrgPointGetInfo[2].Done THEN
				ShCopyUserData[2].Axis        := ADR(TrgPointGetInfo[2].TrgPointInfo.Axis);
				ShCopyUserData[2].DataAddress := ADR(StationData[2]);
				ShCopyUserData[2].DataSize    := SIZEOF(StationData[2]);
				ShCopyUserData[2].Mode        := mcACPTRAK_USERDATA_GET;
				ShCopyUserData[2].Execute     := TRUE;
				StnState[2]                   := STN_GET_USERDATA;
			END_IF
		
		STN_GET_USERDATA:
			IF ShCopyUserData[2].Done THEN
				ShCopyUserData[2].Execute := FALSE;
				IF (StationData[2].Color = YELLOW) THEN
					StnState[2] := STN_HANDLE_SHUTTLE;
				ELSE
					TrgPointGetInfo[2].Execute := FALSE;
					StnState[2]                := STN_WAIT_FOR_SHUTTLE;
				END_IF
			END_IF
			
		STN_HANDLE_SHUTTLE:
			IF (StationData[2].Color = YELLOW) THEN
				IF (RejectIndex[2] = RejectRate) THEN
					StationData[2].Color                                      := RED;
					StnRoutedMoveAbs[2].Axis                                  := ADR(TrgPointGetInfo[2].TrgPointInfo.Axis);
					StnRoutedMoveAbs[2].Sector                                := Stn[6];
					StnRoutedMoveAbs[2].Position                              := 0.405;
					StnRoutedMoveAbs[2].Acceleration                          := 5;
					StnRoutedMoveAbs[2].Deceleration                          := 5;
					StnRoutedMoveAbs[2].Velocity                              := 0.5;
					StnRoutedMoveAbs[5].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					StnRoutedMoveAbs[2].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
					StnRoutedMoveAbs[2].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					RejectIndex[2]                                            := 0;
				ELSE
					StationData[2].Color                                      := BLUE;
					StnRoutedMoveAbs[2].Axis                                  := ADR(TrgPointGetInfo[2].TrgPointInfo.Axis);
					StnRoutedMoveAbs[2].Sector                                := Stn[3];
					StnRoutedMoveAbs[2].Position                              := 0.005;
					StnRoutedMoveAbs[2].Acceleration                          := 10;
					StnRoutedMoveAbs[2].Deceleration                          := 10;
					StnRoutedMoveAbs[2].Velocity                              := 1;
					StnRoutedMoveAbs[5].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					StnRoutedMoveAbs[2].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
					StnRoutedMoveAbs[2].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					RejectIndex[2]                                            := RejectIndex[2] + 1;
				END_IF
			END_IF
			ShCopyUserData[2].Mode    := mcACPTRAK_USERDATA_SET;
			ShCopyUserData[2].Execute := TRUE;
			StnState[2]               := STN_SET_USERDATA;
				
		STN_SET_USERDATA:
			IF ShCopyUserData[2].Done THEN
				ShCopyUserData[2].Execute   := FALSE;
				StnRoutedMoveAbs[2].Execute := TRUE;
				StnState[2]                 := STN_SEND_SHUTTLE;
			END_IF
			
		STN_SEND_SHUTTLE:
			IF StnRoutedMoveAbs[2].Active THEN
				TrgPointGetInfo[2].Execute  := FALSE;
				StnRoutedMoveAbs[2].Execute := FALSE;
				StnState[2]                 := STN_WAIT_FOR_SHUTTLE;
			END_IF
			
	END_CASE
	
	TrgPointEnable[2]();
	TrgPointGetInfo[2]();
	ShCopyUserData[2]();
	StnRoutedMoveAbs[2]();
	
END_ACTION
