
PROGRAM _CYCLIC
	
	BarrierReadInfo.ProcessPoint := ADR(PP_RejectEntrance);
	BarrierReadInfo.Enable       := TRUE;
	BarrierReadInfo();
	
	CASE TrakState OF 
		TRAK_IDLE:
			IF gPowerOn THEN
				AsmPowerOn.Assembly := ADR(gAssembly_1);
				AsmPowerOn.Execute  := TRUE;
				TrakState           := TRAK_POWERON;
			END_IF
			
		TRAK_POWERON:
			IF AsmPowerOn.Done THEN
				AsmGetShuttle.Assembly := ADR(gAssembly_1);
				AsmGetShuttle.Enable   := TRUE;
				TrakState              := TRAK_FIND_SHUTTLE;   //USE THIS FOR REGULAR OPERATION
//				TrakState              := TRAK_SYSTEM_RUNNING; //USE THIS FOR SPAWNING OPERATION
			END_IF
			
		TRAK_FIND_SHUTTLE:
			IF AsmGetShuttle.Valid THEN
				AsmData.Color                 := GRAY;
				AsmCopyUserData.Axis          := ADR(AsmGetShuttle.Axis);
				AsmCopyUserData.DataAddress   := ADR(AsmData);
				AsmCopyUserData.DataSize      := SIZEOF(AsmData);
				AsmCopyUserData.Mode          := mcACPTRAK_USERDATA_SET;
				AsmCopyUserData.Execute       := TRUE;
				
				AsmGetShuttle.Next            := FALSE;
				AsmRoutedMoveAbs.Axis         := ADR(AsmGetShuttle.Axis);
				AsmRoutedMoveAbs.Sector       := Stn[1];
				AsmRoutedMoveAbs.Position     := 0.005;
				AsmRoutedMoveAbs.Acceleration := 20;
				AsmRoutedMoveAbs.Deceleration := 20;
				AsmRoutedMoveAbs.Velocity     := 4;
				AsmRoutedMoveAbs.Execute      := TRUE;
				
				TrakState                     := TRAK_SEND_SHUTTLE;
			END_IF
			
		TRAK_SEND_SHUTTLE:
			IF AsmRoutedMoveAbs.Active AND AsmCopyUserData.Done THEN
				IF (AsmGetShuttle.RemainingCount > 0) THEN
					AsmCopyUserData.Execute  := FALSE;
					AsmRoutedMoveAbs.Execute := FALSE;
					AsmGetShuttle.Next       := TRUE;
					//AsmIndex               := AsmIndex + 1;
					TrakState                := TRAK_FIND_SHUTTLE;
				ELSE
					AsmGetShuttle.Enable := FALSE;
					gTrakRunning         := TRUE;
					TrakState            := TRAK_SYSTEM_RUNNING;
				END_IF
			END_IF
			
		TRAK_SYSTEM_RUNNING:
			
			
	END_CASE
	
	//Call FUBs
	AsmPowerOn();
	AsmGetShuttle();
	AsmCopyUserData();
	AsmRoutedMoveAbs();
	
	//Call action files
	Load_Unload;
	Process_1;
	Process_2;
	Process_3;
	Reject;
	RejectExit;
	Flipper;
	FlipperExit;
	
END_PROGRAM
