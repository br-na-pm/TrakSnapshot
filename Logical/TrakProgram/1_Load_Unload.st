
ACTION Load_Unload: 
	
	TrgPointEnable[1].ProcessPoint  := ADR(PP_Load_Unload);
	TrgPointEnable[1].Enable        := TRUE;
	TrgPointGetInfo[1].ProcessPoint := ADR(PP_Load_Unload);
	
	CASE StnState[1] OF
		STN_WAIT_FOR_SHUTTLE:
			IF (TrgPointEnable[1].EventCount > 0) THEN
				TrgPointGetInfo[1].Execute := TRUE;
				StnState[1]                := STN_GET_INFO;
			END_IF
			
		STN_GET_INFO:
			IF TrgPointGetInfo[1].Done THEN
				ShCopyUserData[1].Axis        := ADR(TrgPointGetInfo[1].TrgPointInfo.Axis);
				ShCopyUserData[1].DataAddress := ADR(StationData[1]);
				ShCopyUserData[1].DataSize    := SIZEOF(StationData[1]);
				ShCopyUserData[1].Mode        := mcACPTRAK_USERDATA_GET;
				ShCopyUserData[1].Execute     := TRUE;
				StnState[1]                   := STN_GET_USERDATA;
			END_IF
		
		STN_GET_USERDATA:
			IF ShCopyUserData[1].Done THEN
				ShCopyUserData[1].Execute := FALSE;
				IF (StationData[1].Color = GRAY) OR (StationData[1].Color = GREEN) THEN
					StnState[1] := STN_HANDLE_SHUTTLE;
				ELSE
					TrgPointGetInfo[1].Execute := FALSE;
					StnState[1]                := STN_WAIT_FOR_SHUTTLE;
				END_IF
			END_IF
			
		STN_HANDLE_SHUTTLE:
			IF (StationData[1].Color = GRAY) THEN
				StationData[1].Color                                      := YELLOW;
				StnRoutedMoveAbs[1].Axis                                  := ADR(TrgPointGetInfo[1].TrgPointInfo.Axis);
				StnRoutedMoveAbs[1].Sector                                := Stn[2];
				StnRoutedMoveAbs[1].Position                              := 0.005;
				StnRoutedMoveAbs[1].Acceleration                          := 5;
				StnRoutedMoveAbs[1].Deceleration                          := 5;
				StnRoutedMoveAbs[1].Velocity                              := 0.5;
				StnRoutedMoveAbs[5].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
				StnRoutedMoveAbs[1].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
				StnRoutedMoveAbs[1].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
			ELSIF (StationData[1].Color = GREEN) THEN
				IF (RejectIndex[1] = RejectRate) THEN
					StationData[1].Color                                      := RED;
					StnRoutedMoveAbs[1].Axis                                  := ADR(TrgPointGetInfo[1].TrgPointInfo.Axis);
					StnRoutedMoveAbs[1].Sector                                := Stn[6];
					StnRoutedMoveAbs[1].Position                              := 0.405;
					StnRoutedMoveAbs[1].Acceleration                          := 20;
					StnRoutedMoveAbs[1].Deceleration                          := 20;
					StnRoutedMoveAbs[1].Velocity                              := 2.5;
					StnRoutedMoveAbs[1].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					StnRoutedMoveAbs[1].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
					StnRoutedMoveAbs[1].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					RejectIndex[1]                                            := 0;
				ELSE
					StationData[1].Color := GRAY;
					StnRoutedMoveAbs[1].Axis                                  := ADR(TrgPointGetInfo[1].TrgPointInfo.Axis);
					StnRoutedMoveAbs[1].Sector                                := Stn[1];
					StnRoutedMoveAbs[1].Position                              := 0.004;
					StnRoutedMoveAbs[1].Acceleration                          := 20;
					StnRoutedMoveAbs[1].Deceleration                          := 20;
					StnRoutedMoveAbs[1].Velocity                              := 4;
					StnRoutedMoveAbs[5].AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					StnRoutedMoveAbs[1].AdvancedParameters.StartDirection     := mcDIR_POSITIVE;
					StnRoutedMoveAbs[1].AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					RejectIndex[1]                                            := RejectIndex[1] + 1;
				END_IF
			END_IF
			ShCopyUserData[1].Mode    := mcACPTRAK_USERDATA_SET;
			ShCopyUserData[1].Execute := TRUE;
			StnState[1]               := STN_SET_USERDATA;
				
		STN_SET_USERDATA:
			IF ShCopyUserData[1].Done THEN
				ShCopyUserData[1].Execute   := FALSE;
				StnRoutedMoveAbs[1].Execute := TRUE;
				StnState[1]                 := STN_SEND_SHUTTLE;
			END_IF
			
		STN_SEND_SHUTTLE:
			IF StnRoutedMoveAbs[1].Active THEN
				TrgPointGetInfo[1].Execute  := FALSE;
				StnRoutedMoveAbs[1].Execute := FALSE;
				StnState[1]                 := STN_WAIT_FOR_SHUTTLE;
			END_IF
			
	END_CASE
	
	TrgPointEnable[1]();
	TrgPointGetInfo[1]();
	ShCopyUserData[1]();
	StnRoutedMoveAbs[1]();
			
END_ACTION
