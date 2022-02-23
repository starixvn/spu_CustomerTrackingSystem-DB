/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator:    20220210@Long.Luu
    Task:	 	Init more data for table CategoryToDangerLevel
    DBName:		CTS_DataCenter

    Revisions: 
		- 20220210@Long.Luu: Created [#167746]

*/
/*Add source stype*/
USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (52,0,2,1),(52,1,2,11),(72,0,2,1),(72,1,2,11),(152,0,2,1),(152,1,2,11);
INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (55,0,2,2),(55,1,2,12),(75,0,2,2),(75,1,2,12),(155,0,2,2),(155,1,2,12);
INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (54,0,2,3),(54,1,2,13),(74,0,2,3),(74,1,2,13),(154,0,2,3),(154,1,2,13);
INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (53,0,2,4),(53,1,2,14),(73,0,2,4),(73,1,2,14),(153,0,2,4),(153,1,2,14);
INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (58,0,2,5),(58,1,2,15),(78,0,2,5),(78,1,2,15),(158,0,2,5),(158,1,2,15);
INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (59,0,2,6),(59,1,2,16),(79,0,2,6),(79,1,2,16),(159,0,2,6),(159,1,2,16);
INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (56,1,2,17),(76,1,2,17),(156,1,2,17);
INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (60,1,2,18),(80,1,2,18);
INSERT INTO CTS_DataCenter.CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES (62,0,2,9),(62,1,2,19),(82,0,2,9),(82,1,2,19),(162,0,2,9),(162,1,2,19);


