/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20221115@Casey.Huynh
Task:	 	Match Monitor Irrigation
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 202211213@Casey.Huynh: Created [Redmine ID: #179499]
Reviewer:
*/

USE CTS_DataCenter;

UPDATE MatchMonitorDetails
SET ScoreDiff = TotalScore
WHERE ScoreDiff IS NULL;

#============================
ALTER TABLE MatchMonitor
	ADD COLUMN IsMajorLeage BOOLEAN AFTER MatchID
,	ADD COLUMN HDP DECIMAL (8,4) AFTER BettypeID;


ALTER TABLE MatchMonitorDetails
	ADD COLUMN IsMajorLeage BOOLEAN AFTER MatchID
,	ADD COLUMN HDP DECIMAL (8,4) AFTER BettypeID
,	RENAME COLUMN TotalScore TO ScoreDiff;

ALTER TABLE