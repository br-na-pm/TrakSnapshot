
FUNCTION_BLOCK TrakSnapCap (*Function block that captures all spawned shuttles and their data*)
	VAR_INPUT
		Enable : BOOL;
		Capture : BOOL;
		Assembly : REFERENCE TO McAssemblyType; (*Assembly to capture startup data*)
		TrakSnapStructure : REFERENCE TO TrakSnap_type;
		TrakSnapStructureName : {REDUND_UNREPLICABLE} STRING[100];
		RecipeLink : REFERENCE TO MpComIdentType;
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		Ready : BOOL;
		Busy : BOOL;
		Done : BOOL;
		NumShuttlesFound : UINT;
		Error : BOOL; (*Error present on diagnostic function*)
		ErrorID : DINT; (*Error ID of current error*)
	END_VAR
	VAR
		Internal : TrakSnapCapInternal_type; (*Internal datatype*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK TrakSnapSpawn (*Function block that spawns all shuttles and their data from a saved snapshot*)
	VAR_INPUT
		Enable : BOOL;
		Spawn : BOOL;
		TrakSnapStructure : REFERENCE TO TrakSnap_type;
		TrakSnapStructureName : {REDUND_UNREPLICABLE} STRING[100];
		RecipeLink : REFERENCE TO MpComIdentType;
		SnapshotToLoad : STRING[100];
		NumShuttles : UINT;
	END_VAR
	VAR_OUTPUT
		Active : BOOL;
		Ready : BOOL;
		Done : BOOL;
		Busy : BOOL;
		Error : BOOL; (*Error present on diagnostic function*)
		ErrorID : DINT; (*Error ID of current error*)
	END_VAR
	VAR
		Internal : TrakSnapSpawnInternal_type; (*Internal datatype*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK EpochConverter (*Converts epoch time to STR of format similar to DT but without the ":" character.*)
	VAR_INPUT
		Input : {REDUND_UNREPLICABLE} UDINT;
		Offset : {REDUND_UNREPLICABLE} DINT;
		Execute : BOOL;
	END_VAR
	VAR_OUTPUT
		DTString_For_Recipe : STRING[100];
	END_VAR
	VAR
		InternalState : USINT;
		Year : {REDUND_UNREPLICABLE} UDINT;
		Year_Str : {REDUND_UNREPLICABLE} STRING[5];
		Month : {REDUND_UNREPLICABLE} UDINT;
		Month_Str : {REDUND_UNREPLICABLE} STRING[5];
		Day : {REDUND_UNREPLICABLE} UDINT;
		Day_Str : {REDUND_UNREPLICABLE} STRING[5];
		Hour : {REDUND_UNREPLICABLE} UDINT;
		Hour_Str : {REDUND_UNREPLICABLE} STRING[5];
		Minute : {REDUND_UNREPLICABLE} UDINT;
		Minute_Str : {REDUND_UNREPLICABLE} STRING[5];
		Second : {REDUND_UNREPLICABLE} UDINT;
		Second_Str : {REDUND_UNREPLICABLE} STRING[5];
		Remainder : {REDUND_UNREPLICABLE} UDINT;
		DateWord : {REDUND_UNREPLICABLE} STRING[5] := 'date';
		TimeWord : {REDUND_UNREPLICABLE} STRING[5] := 'time';
		SpaceCharacter : {REDUND_UNREPLICABLE} STRING[2] := ' ';
		UnderscoreCharacter : {REDUND_UNREPLICABLE} STRING[2] := '_';
	END_VAR
END_FUNCTION_BLOCK
