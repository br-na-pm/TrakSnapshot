
ACTION RejectExit: 

	GateTrgPointEnable[0].ProcessPoint := ADR(PP_RejectExit);
	GateTrgPointEnable[0].Enable       := TRUE;
	
	GateTrgPointGetInfo[0].ProcessPoint := ADR(PP_RejectExit);
	
	GateBarrierCommand[0].ProcessPoint                   := ADR(PP_RejectEntrance);
	GateBarrierCommand[0].AdvancedParameters.TicketCount := 1;
	
	CASE ExitState[0] OF
		
		EXIT_INIT:
			IF NOT GateInit[0] THEN
				GateBarrierCommand[0].Command := mcACPTRAK_BARRIER_CLOSE;
				GateBarrierCommand[0].Execute := TRUE;
				GateInit[0]                   := TRUE;
			ELSIF GateInit[0] AND GateBarrierCommand[0].Done THEN
				GateBarrierCommand[0].Execute := FALSE;
			ELSIF GateInit[0] AND NOT GateBarrierCommand[0].Execute THEN
				GateBarrierCommand[0].Command := mcACPTRAK_BARRIER_ADD_TICKETS;
				GateBarrierCommand[0].Execute := TRUE;
				ExitState[0]                  := EXIT_WAIT_FOR_SHUTTLE;
			END_IF
			
		EXIT_WAIT_FOR_SHUTTLE:
			IF GateBarrierCommand[0].Done THEN
				GateBarrierCommand[0].Execute := FALSE;
			END_IF
			
			IF (GateTrgPointEnable[0].EventCount > 0) THEN
				GateTrgPointGetInfo[0].Execute := TRUE;
				ExitState[0]                   := EXIT_GET_INFO;
			END_IF
			
		EXIT_GET_INFO:
			IF GateTrgPointGetInfo[0].Done THEN
				GateTrgPointGetInfo[0].Execute := FALSE;
				GateBarrierCommand[0].Execute  := TRUE;
				ExitState[0]                   := EXIT_GIVE_TICKET;
			END_IF
			
		EXIT_GIVE_TICKET:
			IF GateBarrierCommand[0].Done THEN
				GateBarrierCommand[0].Execute := FALSE;
				Temp_NumTickets               := Temp_NumTickets + 1;
				ExitState[0]                  := EXIT_WAIT_FOR_SHUTTLE;
			END_IF
		
	END_CASE
	
	//FUB Calls
	GateTrgPointEnable[0]();
	GateTrgPointGetInfo[0]();
	GateBarrierCommand[0]();
	
END_ACTION
