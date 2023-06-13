/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20230608@Casey.Huynh
Task:	 	Log trace Issue MatchMonitorHedging
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230608@Casey.Huynh: Created [Redmine ID: #185793]
Reviewer:
*/

USE CTS_DataCenter;
ALTER TABLE MatchMonitorDetails
	ADD COLUMN LogInfo LONGTEXT;
    
    
    