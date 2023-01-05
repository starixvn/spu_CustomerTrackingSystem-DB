/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20230105@Casey.Huynh
Task:	 	Enhance MatchMonitor Report
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230105@Casey.Huynh: Created [Redmine ID: #181995]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE MatchMonitor
	ADD COLUMN InsertDate DATETIME DEFAULT(DATE(InsertTime))
,	ADD INDEX IX_MatchMonitor_InsertDate(InsertDate);
