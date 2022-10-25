/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20221021@Casey.Huynh
Task:	 	Enhance Fixed Game
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20221021@Casey.Huynh: Created [Redmine ID: #179427]
Reviewer:
*/

USE CTS_DataCenter;

UPDATE MatchMonitorStagingLive
SET Rule03GroupID = -1
WHERE SportType <> 1;

UPDATE MatchMonitorStagingNonLive
SET Rule03GroupID = -1
WHERE SportType <> 1;
