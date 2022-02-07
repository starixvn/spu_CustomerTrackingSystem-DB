/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20220110@Casey.Huynh
Task:	 	Enhance MatchMonitor (SportType, Betteam, BetID)
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20211213@Casey.Huynh: Created [Redmine ID: #166986]
Reviewer:
*/

USE CTS_DataCenter;

/*===0. ALTER Tables: Column===========*/
DELETE sl
FROM MatchMonitorStagingLive AS sl
WHERE GroupID != 0;

DELETE sl
FROM MatchMonitorStagingNonLive AS sl
WHERE GroupID != 0;

/*===1. ALTER Tables: Column===========*/
ALTER TABLE MatchMonitorStagingLive
		ADD COLUMN SportType INT
	,	ADD COLUMN Betteam VARCHAR(10) 
    ,	ADD COLUMN BetID BIGINT DEFAULT 0;

ALTER TABLE MatchMonitorStagingNonLive
		ADD COLUMN SportType INT
	,	ADD COLUMN Betteam VARCHAR(10) 
    ,	ADD COLUMN BetID BIGINT DEFAULT 0;

ALTER TABLE MatchMonitor
		ADD COLUMN SportType INT DEFAULT 1
    ,	ADD COLUMN BetID BIGINT NOT NULL DEFAULT 0
    ,   CHANGE COLUMN IsHedging Reason TINYINT ;

ALTER TABLE MatchMonitorDetails
		ADD COLUMN BetID BIGINT NOT NULL DEFAULT 0
	 ,	CHANGE COLUMN IsHedging Reason TINYINT ;
    
ALTER TABLE MatchMonitorDetailsVerifiedTrans
    	ADD COLUMN BetID BIGINT  DEFAULT 0;        

ALTER TABLE AssociationRemove
		ADD COLUMN LeastCustID 			INT UNSIGNED
	,   ADD COLUMN LeastCustSubID 		INT UNSIGNED
    ,   ADD COLUMN GreatestCustID 		INT UNSIGNED   
    ,   ADD COLUMN GreatestCustSubID 	INT UNSIGNED;
    
/*===2. ALTER Tables: INDEX===========*/

ALTER TABLE MatchMonitorStagingLive
		DROP INDEX IX_MatchMonitorStagingLive_Group
	,	ADD INDEX IX_MatchMonitorStagingLive_Group (MatchID,TotalScore,BettypeID,BetID,GroupID);

ALTER TABLE MatchMonitorStagingNonLive
		DROP INDEX IX_MatchMonitorStagingNonLive_Group
	,	ADD INDEX IX_MatchMonitorStagingNonLive_Group(MatchID,TotalScore,BettypeID,BetID,GroupID);
    
ALTER TABLE MatchMonitorDetailsVerifiedTrans
		DROP INDEX IX_MatchMonitorDetailsVerifiedTrans
	,	ADD INDEX IX_MatchMonitorDetailsVerifiedTrans(MatchID,LiveIndicator,BettypeID, BetID);

ALTER TABLE AssociationRemove
		ADD INDEX IX_AssociationRemove_FromCustIDToCustID(FromCustID,ToCustID);

ALTER TABLE MatchMonitor
		DROP INDEX IX_MatchMonitor_EventDateBettypeMatchIDIsHedging #OLD UNIQUE KEY `IX_MatchMonitor_EventDateBettypeMatchIDIsHedging` (`EventDate`,`BettypeID`,`MatchID`,`LiveIndicator`,`IsHedging`),
	,	ADD UNIQUE KEY UK_MatchMonitor_MatchGroup (EventDate,BettypeID,BetID,MatchID,LiveIndicator,Reason);

ALTER TABLE MatchMonitor
		DROP INDEX IX_MatchMonitor_MatchID_BettypeID #OLD KEY `IX_MatchMonitor_MatchID_BettypeID` (`MatchID`,`BettypeID`),
	,	ADD INDEX IX_MatchMonitor_MatchIDBettype(MatchID,BettypeID,BetID);

ALTER TABLE MatchMonitorDetails
		DROP INDEX UK_MatchMonitorDetails_EventDateBettypeMatchID #OLD `UNIQUE KEY `UK_MatchMonitorDetails_EventDateBettypeMatchID` (`MatchID`,`LiveIndicator`,`TotalScore`,`BettypeID`,`GroupID`)
	,	ADD UNIQUE KEY UK_MatchMonitorDetails_MatchDetailGroup(MatchID,LiveIndicator,TotalScore,BettypeID,BetID,GroupID);
    
ALTER TABLE MatchMonitorDetails
		DROP INDEX IX_MatchMonitorDetails_MatchID_BettypeID # OLD KEY `IX_MatchMonitorDetails_MatchID_BettypeID` (`MatchID`,`BettypeID`)
	,	ADD INDEX IX_MatchMonitorDetails_MatchID_BettypeID (MatchID,BettypeID,BetID);
	
/*===3 INIT Data AssociationRemove===========*/
/* Check IF EXISTS data CustSub != 0
SELECT t.*
FROM (
SELECT c.CTSCustID, CustID, CustSubID FROM AssociationRemove a
iNNER JOIN CTSCustomer c on a.FromCTSCustID = c.CTSCustID
union
SELECT c.CTSCustID, CustID, CustSubID  FROM AssociationRemove a
iNNER JOIN CTSCustomer c on a.FromCTSCustID = c.CTSCustID) AS t
WHERE CustSubID <> 0;*/

UPDATE CTS_DataCenter.AssociationRemove AS ar
	INNER JOIN CTS_DataCenter.CTSCustomer AS c1 ON ar.FromCTSCustID = c1.CTSCustID AND c1.CustSubID = 0
	INNER JOIN CTS_DataCenter.CTSCustomer AS c2 ON ar.ToCTSCustID = c2.CTSCustID AND c2.CustSubID = 0
SET 	ar.LeastCustID = LEAST(c1.CustID,c2.CustID)
	,	ar.LeastCustSubID = 0
	,	ar.GreatestCustID = GREATEST(c1.CustID,c2.CustID)
    ,	ar.GreatestCustSubID = 0;

/****Update for CustSubID = <> 0*****/
    
SELECT * FROM CTS_DataCenter.AssociationRemove AS ar WHERE ar.LeastCustID IS NULL;
