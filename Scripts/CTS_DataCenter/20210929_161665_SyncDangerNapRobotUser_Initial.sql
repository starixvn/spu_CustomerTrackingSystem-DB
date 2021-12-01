/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20211112@Casey.Huynh
Task:	 	Init CategoryToDangerLevel
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20211112@Casey.Huynh: Created [Redmine ID: #161665]
Reviewer:

*/
USE CTS_DataCenter;

INSERT INTO CategoryToDangerLevel(CategoryID,IsLicensee,TypeID,DangerLevel)
VALUES	(61,0,2,6)
	,	(61,1,2,16)
    ,	(81,0,2,6)
	,	(81,1,2,16)
    ,	(161,0,2,6)
	,	(161,1,2,16);