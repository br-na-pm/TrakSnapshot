
ACTION Process_3: 

	TrgPointEnable[4].ProcessPoint  := ADR(PP_Process_3);
	TrgPointEnable[4].Enable        := TRUE;
	TrgPointGetInfo[4].ProcessPoint := ADR(PP_Process_3);
	
	CASE StnState[4] OF
		STN_WAIT_FOR_SHUTTLE:
			IF (TrgPointEnable[4].EventCount > 0) THEN
				TrgPointGetInfo[4].Execute := TRUE;
				StnState[4]                := STN_GET_INFO;
			END_IF
			
		STN_GET_INFO:
			IF TrgPointGetInfo[4].Done THEN
				ShCopyUserData[4].Axis        := ADR(TrgPointGetInfo[4].TrgPointInfo.Axis);
				ShCopyUserData[4].DataAddress := ADR(StationData[4]);
				ShCopyUserData[4].DataSize    := SIZEOF(StationData[4]);
				ShCopyUserData[4].Mode        := mcACPTRAK_USERDATA_GET;
				ShCopyUserData[4].Execute     := TRUE;
				StnState[4]                   := STN_GET_USERDATA;
			END_IF
		
		STN_GET_USERDATA:
			IF ShCopyUserData[4].Done THEN
				ShCopyUserData[4].Execute := FALSE;
				IF (StationData[4].Color = ORANGE) THEN
					StnState[4] := STN_HANDLE_SHUTTLE;
				ELSE
					TrgPointGetInfo[4].Execute := FALSE;
					StnState[4]                := STN_WAIT_FOR_SHUTTLE;
				END_IF
			END_IF
			
		STN_HANDLE_SHUTTLE:
			IF (StationData[4].Color = ORANGE) THEN
				IF (RejectIndex[4] = RejectRate) THEN
					StationData[4].Color                                      := RED;
					StnRoutedMoveAbs[4].Axis                                  := ADR(TrgPointGetInfo[4].TrgPointInfo.Axis);
					StnRoutedMoveAbs[4].Sector                                := Stn[6];
					StnRoutedMoveAbs[4].Position                              := 0.405;
					StnRoutedMoveAbs[4].Acceleration                          := 15;
					StnRoutedMoveAbs[4].Deceleration                          := 15;
					StnRoutedMoveAbs[4].Velocity                              := 2;
					StnRoutedMoveAbs[4].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					StnRoutedMoveAbs[4].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
					StnRoutedMoveAbs[4].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					RejectIndex[4]                                            := 0;
				ELSE
					StationData[4].Color                                      := GREEN;
					StnRoutedMoveAbs[4].Axis                                  := ADR(TrgPointGetInfo[4].TrgPointInfo.Axis);
					StnRoutedMoveAbs[4].Sector                                := Stn[1];
					StnRoutedMoveAbs[4].Position                              := 0.005;
					StnRoutedMoveAbs[4].Acceleration                          := 20;
					StnRoutedMoveAbs[4].Deceleration                          := 20;
					StnRoutedMoveAbs[4].Velocity                              := 2.5;
					StnRoutedMoveAbs[5].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					StnRoutedMoveAbs[4].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
					StnRoutedMoveAbs[4].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					RejectIndex[4]                                            := RejectIndex[4] + 1;
				END_IF
			END_IF
			ShCopyUserData[4].Mode    := mcACPTRAK_USERDATA_SET;
			ShCopyUserData[4].Execute := TRUE;
			StnState[4]               := STN_SET_USERDATA;
				
		STN_SET_USERDATA:
			IF ShCopyUserData[4].Done THEN
				ShCopyUserData[4].Execute   := FALSE;
				StnRoutedMoveAbs[4].Execute := TRUE;
				StnState[4]                 := STN_SEND_SHUTTLE;
			END_IF
			
		STN_SEND_SHUTTLE:
			IF StnRoutedMoveAbs[4].Active THEN
				TrgPointGetInfo[4].Execute  := FALSE;
				StnRoutedMoveAbs[4].Execute := FALSE;
				StnState[4]                 := STN_WAIT_FOR_SHUTTLE;
			END_IF
			
	END_CASE
	
	TrgPointEnable[4]();
	TrgPointGetInfo[4]();
	ShCopyUserData[4]();
	StnRoutedMoveAbs[4]();
	
END_ACTION
