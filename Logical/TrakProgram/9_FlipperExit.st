
ACTION FlipperExit: 

	GateTrgPointEnable[1].ProcessPoint := ADR(PP_FlipperExit);
	GateTrgPointEnable[1].Enable       := TRUE;
	
	GateTrgPointGetInfo[1].ProcessPoint := ADR(PP_FlipperExit);
	
	GateBarrierCommand[1].ProcessPoint                   := ADR(PP_FlipperEntrance);
	GateBarrierCommand[1].AdvancedParameters.TicketCount := 1;
	GateBarrierCommand[1].Command                        := mcACPTRAK_BARRIER_ADD_TICKETS;
	
	CASE ExitState[1] OF
		
		EXIT_INIT:
			IF NOT GateInit[1] THEN
				GateBarrierCommand[1].Command := mcACPTRAK_BARRIER_CLOSE;
				GateBarrierCommand[1].Execute := TRUE;
				GateInit[1]                   := TRUE;
			ELSIF GateInit[1] AND GateBarrierCommand[1].Done THEN
				GateBarrierCommand[1].Execute := FALSE;
			ELSIF GateInit[1] AND NOT GateBarrierCommand[1].Execute THEN
				GateBarrierCommand[1].Command := mcACPTRAK_BARRIER_ADD_TICKETS;
				GateBarrierCommand[1].Execute := TRUE;
				ExitState[1]                  := EXIT_WAIT_FOR_SHUTTLE;
			END_IF
			
		EXIT_WAIT_FOR_SHUTTLE:
			IF GateBarrierCommand[1].Done THEN
				GateBarrierCommand[1].Execute := FALSE;
			END_IF
			
			IF (GateTrgPointEnable[1].EventCount > 0) THEN
				GateTrgPointGetInfo[1].Execute := TRUE;
				ExitState[1]                   := EXIT_GET_INFO;
			END_IF
			
		EXIT_GET_INFO:
			IF GateTrgPointGetInfo[1].Done THEN
				GateTrgPointGetInfo[1].Execute := FALSE;
				GateBarrierCommand[1].Execute  := TRUE;
				ExitState[1]                   := EXIT_GIVE_TICKET;
			END_IF
			
		EXIT_GIVE_TICKET:
			IF GateBarrierCommand[1].Done THEN
				GateBarrierCommand[1].Execute := FALSE;
				ExitState[1]                  := EXIT_WAIT_FOR_SHUTTLE;
			END_IF
		
	END_CASE
	
	//FUB Calls
	GateTrgPointEnable[1]();
	GateTrgPointGetInfo[1]();
	GateBarrierCommand[1]();
	
END_ACTION
