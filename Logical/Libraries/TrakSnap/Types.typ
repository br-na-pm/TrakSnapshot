(*User Structure for Snapshot*)

TYPE
	TrakSnap_type : 	STRUCT 
		UserData : ARRAY[0..TRAKSNAP_NUM_SHUTTLES]OF UserDataTyp; (*User data for the shuttles*)
		SegmentInfo : ARRAY[0..TRAKSNAP_NUM_SHUTTLES]OF SegmentInfo_type; (*Position and orientation output from the ShReadSecPos FUB*)
		ShuttleInfo : ARRAY[0..TRAKSNAP_NUM_SHUTTLES]OF ShuttleInfo_type; (*Abbreviated output of the ShReadInfo FUB*)
		NumShuttlesFound : UINT;
	END_STRUCT;
END_TYPE

(**)
(*Shuttle User Data*)

TYPE
	UserDataTyp : 	STRUCT  (*User data structure*)
		Color : UserColorEnum; (*Shuttle colour*)
		ShuttleID : UINT; (*Shuttle ID*)
		StationNum : USINT; (*Station number *)
		ShuttleSerialNum : ARRAY[0..11]OF USINT; (*Shuttle serial number*)
	END_STRUCT;
	UserColorEnum : 
		( (*Shuttle colours*)
		GRAY := 0,
		BLUE := 1,
		RED := 2,
		GREEN := 3,
		YELLOW := 4,
		ORANGE := 5
		);
END_TYPE

(**)
(*An abbreviated segment info structure*)

TYPE
	SegmentInfo_type : 	STRUCT 
		CurrentPosition : ARRAY[0..3]OF LREAL;
		CurrentSegment : ARRAY[0..3]OF STRING[32];
	END_STRUCT;
END_TYPE

(**)
(*An abbreviated shuttle info structure*)

TYPE
	ShuttleInfo_type : 	STRUCT 
		CurrentPosition : LREAL;
		CurrentSector : STRING[32];
		CurrentVelocity : REAL;
		TargetPosition : LREAL;
		TargetSector : STRING[32];
		VelocityAtDestination : REAL;
	END_STRUCT;
END_TYPE

(**)
(*Internal Structure for SnapshotTaker FUB*)

TYPE
	TrakSnapCapInternal_type : 	STRUCT 
		State : TrakSnapCapState_enum;
		FB : TrakSnapCapInternalFB_type;
		Shuttles : ARRAY[0..TRAKSNAP_NUM_SHUTTLES]OF McAxisType;
		Index : UINT;
		CountRemaining : UINT;
		CurrentDateTime : DATE_AND_TIME;
		CurrentDateTime_Str : STRING[100];
	END_STRUCT;
	TrakSnapCapState_enum : 
		(
		SNAPCAP_IDLE,
		SNAPCAP_GET_SHUTTLES,
		SNAPCAP_CHECK_REMAINING_COUNT,
		SNAPCAP_READY,
		SNAPCAP_CAPTURE,
		SNAPCAP_SAVE,
		SNAPCAP_DONE,
		SNAPCAP_RESET,
		SNAPCAP_ERROR
		);
	TrakSnapCapInternalFB_type : 	STRUCT 
		AsmGetShuttle : MC_BR_AsmGetShuttle_AcpTrak;
		ShCopyUserData : ARRAY[0..TRAKSNAP_NUM_SHUTTLES]OF MC_BR_ShCopyUserData_AcpTrak;
		ShReadSegmentInfo : ARRAY[0..TRAKSNAP_NUM_SHUTTLES]OF MC_BR_ShReadSegmentInfo_AcpTrak;
		ShReadInfo : ARRAY[0..TRAKSNAP_NUM_SHUTTLES]OF MC_BR_ShReadInfo_AcpTrak;
		RecipeXML : MpRecipeXml;
		RecipeRegPar : MpRecipeRegPar;
		GetTime : DTGetTime;
		DTRecipeConverter : EpochConverter;
	END_STRUCT;
END_TYPE

(**)
(*Internal Structure for SnapshotSpawner FUB*)

TYPE
	TrakSnapSpawnInternal_type : 	STRUCT 
		State : TrakSnapSpawnState_enum;
		FB : TrakSnapSpawnInternalFB_type;
		Shuttles : ARRAY[0..TRAKSNAP_NUM_SHUTTLES]OF McAxisType;
		NumShuttles : UINT;
		Index : UINT;
		SegmentSector : SegmentSector_type;
		SectorReference : UDINT;
		SectorReferenceSize : UDINT;
		PV_XGETADR_ERROR_ID : UINT;
	END_STRUCT;
	TrakSnapSpawnState_enum : 
		(
		SNAPSPAWN_IDLE,
		SNAPSPAWN_READY,
		SNAPSPAWN_LOAD_RECIPE,
		SNAPSPAWN_PICK_SEGSEC,
		SNAPSPAWN_SPAWN_SHUTTLE,
		SNAPSPAWN_SET_USERDATA,
		SNAPSPAWN_DONE,
		SNAPSPAWN_RESET,
		SNAPSPAWN_ERROR
		);
	TrakSnapSpawnInternalFB_type : 	STRUCT 
		SecAddShuttle : MC_BR_SecAddShuttle_AcpTrak;
		ShCopyUserData : MC_BR_ShCopyUserData_AcpTrak;
		RecipeXML : MpRecipeXml;
		RecipeRegPar : MpRecipeRegPar;
	END_STRUCT;
	SegmentSector_type : 	STRUCT 
		Prefix : STRING[8] := 'SECTOR_';
		Name : STRING[32];
		Index : USINT;
		BestOption : USINT;
		Valid : ARRAY[0..3]OF BOOL;
		Position : ARRAY[0..3]OF LREAL;
	END_STRUCT;
END_TYPE
