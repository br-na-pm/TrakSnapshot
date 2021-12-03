
ACTION Process_2: 

	TrgPointEnable[3].ProcessPoint  := ADR(PP_Process_2);
	TrgPointEnable[3].Enable        := TRUE;
	TrgPointGetInfo[3].ProcessPoint := ADR(PP_Process_2);
	
	CASE StnState[3] OF
		STN_WAIT_FOR_SHUTTLE:
			IF (TrgPointEnable[3].EventCount > 0) THEN
				TrgPointGetInfo[3].Execute := TRUE;
				StnState[3]                := STN_GET_INFO;
			END_IF
			
		STN_GET_INFO:
			IF TrgPointGetInfo[3].Done THEN
				ShCopyUserData[3].Axis        := ADR(TrgPointGetInfo[3].TrgPointInfo.Axis);
				ShCopyUserData[3].DataAddress := ADR(StationData[3]);
				ShCopyUserData[3].DataSize    := SIZEOF(StationData[3]);
				ShCopyUserData[3].Mode        := mcACPTRAK_USERDATA_GET;
				ShCopyUserData[3].Execute     := TRUE;
				StnState[3]                   := STN_GET_USERDATA;
			END_IF
		
		STN_GET_USERDATA:
			IF ShCopyUserData[3].Done THEN
				ShCopyUserData[3].Execute := FALSE;
				IF (StationData[3].Color = BLUE) THEN
					StnState[3] := STN_HANDLE_SHUTTLE;
				ELSE
					TrgPointGetInfo[3].Execute := FALSE;
					StnState[3]                := STN_WAIT_FOR_SHUTTLE;
				END_IF
			END_IF
			
		STN_HANDLE_SHUTTLE:
			IF (StationData[3].Color = BLUE) THEN
				IF (RejectIndex[3] = RejectRate) THEN
					StationData[3].Color                                      := RED;
					StnRoutedMoveAbs[3].Axis                                  := ADR(TrgPointGetInfo[3].TrgPointInfo.Axis);
					StnRoutedMoveAbs[3].Sector                                := Stn[6];
					StnRoutedMoveAbs[3].Position                              := 0.405;
					StnRoutedMoveAbs[3].Acceleration                          := 10;
					StnRoutedMoveAbs[3].Deceleration                          := 10;
					StnRoutedMoveAbs[3].Velocity                              := 1;
					StnRoutedMoveAbs[3].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					StnRoutedMoveAbs[3].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
					StnRoutedMoveAbs[3].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					RejectIndex[3]                                            := 0;
				ELSE
					StationData[3].Color                                      := ORANGE;
					StnRoutedMoveAbs[3].Axis                                  := ADR(TrgPointGetInfo[3].TrgPointInfo.Axis);
					StnRoutedMoveAbs[3].Sector                                := Stn[4];
					StnRoutedMoveAbs[3].Position                              := 0.005;
					StnRoutedMoveAbs[3].Acceleration                          := 15;
					StnRoutedMoveAbs[3].Deceleration                          := 15;
					StnRoutedMoveAbs[3].Velocity                              := 2;
					StnRoutedMoveAbs[5].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					StnRoutedMoveAbs[3].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
					StnRoutedMoveAbs[3].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					RejectIndex[3]                                            := RejectIndex[3] + 1;
				END_IF
			END_IF
			ShCopyUserData[3].Mode    := mcACPTRAK_USERDATA_SET;
			ShCopyUserData[3].Execute := TRUE;
			StnState[3]               := STN_SET_USERDATA;
				
		STN_SET_USERDATA:
			IF ShCopyUserData[3].Done THEN
				ShCopyUserData[3].Execute   := FALSE;
				StnRoutedMoveAbs[3].Execute := TRUE;
				StnState[3]                 := STN_SEND_SHUTTLE;
			END_IF
			
		STN_SEND_SHUTTLE:
			IF StnRoutedMoveAbs[3].Active THEN
				TrgPointGetInfo[3].Execute  := FALSE;
				StnRoutedMoveAbs[3].Execute := FALSE;
				StnState[3]                 := STN_WAIT_FOR_SHUTTLE;
			END_IF
			
	END_CASE
	
	TrgPointEnable[3]();
	TrgPointGetInfo[3]();
	ShCopyUserData[3]();
	StnRoutedMoveAbs[3]();
	
END_ACTION
