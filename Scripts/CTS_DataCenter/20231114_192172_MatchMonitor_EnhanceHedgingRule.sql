/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231114@Casey.Huynh
Task:	 	Match Monitor Enhance Match Monitor Hedging Rule
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231114@Casey.Huynh: Created [Redmine ID: #192172]
Reviewer:
*/
USE CTS_DataCenter;
ALTER TABLE MatchMonitorStagingHedgingLive
	ADD CTSCustID BIGINT UNSIGNED AFTER CustID
,	ADD COLUMN IsHedging BOOLEAN DEFAULT 0 AFTER GroupID
,	ADD COLUMN SubscriberID INT UNSIGNED AFTER CustID;

ALTER TABLE MatchMonitorStagingHedgingNonLive
	ADD CTSCustID BIGINT UNSIGNED AFTER CustID
,	ADD COLUMN IsHedging BOOLEAN DEFAULT 0 AFTER GroupID
,	ADD COLUMN SubscriberID INT UNSIGNED AFTER CustID;

ALTER TABLE MatchMonitorDetails
DROP INDEX  IX_MatchMonitorDetails_GroupIDIsHedging;

