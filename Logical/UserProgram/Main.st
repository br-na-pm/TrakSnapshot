(*********************************************************************************
 * Copyright: B&R Industrial Automation GmbH 
 * Author:    nealj 
 * Created:   November 17, 2021/3:18 PM 
 *********************************************************************************)

PROGRAM _INIT
	(* Insert code here *)
	 
END_PROGRAM

PROGRAM _CYCLIC
	
	DEV_SnapshotTaker.Assembly              := ADR(gAssembly_1);
	DEV_SnapshotTaker.TrakSnapStructure     := ADR(gDEV_SnapshotStructure);
	DEV_SnapshotTaker.TrakSnapStructureName := 'gDEV_SnapshotStructure';
	DEV_SnapshotTaker.RecipeLink            := ADR(gRecipeXml);
	DEV_SnapshotTaker();
	
	DEV_SnapshotSpawner.TrakSnapStructure     := ADR(gDEV_SnapshotStructure);
	DEV_SnapshotSpawner.TrakSnapStructureName := 'gDEV_SnapshotStructure';
	DEV_SnapshotSpawner.RecipeLink            := ADR(gRecipeXml);
	DEV_SnapshotSpawner();
	
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

