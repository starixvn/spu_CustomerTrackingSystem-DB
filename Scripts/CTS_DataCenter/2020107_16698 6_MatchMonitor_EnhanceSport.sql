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
/*===1. ALTER Tables: Column===========*/
ALTER TABLE MatchMonitorStagingLive
		ADD COLUMN SportType INT
	,	ADD COLUMN Betteam VARCHAR(10) 
    ,	ADD COLUMN BetID BIGINT;

ALTER TABLE MatchMonitorStagingNonLive
		ADD COLUMN SportType INT
	,	ADD COLUMN Betteam VARCHAR(10) 
    ,	ADD COLUMN BetID BIGINT;

ALTER TABLE MatchMonitor
		ADD COLUMN SportType INT
    ,	ADD COLUMN BetID BIGINT
    ,   CHANGE COLUMN IsHedging Reason TINYINT ;

ALTER TABLE MatchMonitorDetails
		ADD COLUMN BetID 		BIGINT
	 ,	CHANGE COLUMN IsHedging Reason TINYINT ;
    
ALTER TABLE MatchMonitorDetailsVerifiedTrans
    	ADD COLUMN BetID 		BIGINT;        

ALTER TABLE AssociationRemove
		ADD COLUMN FromCustID 		INT UNSIGNED
	,   ADD COLUMN FromCustSubID 	INT UNSIGNED
    ,   ADD COLUMN ToCustID 		INT UNSIGNED   
    ,   ADD COLUMN ToCustSubID 		INT UNSIGNED;
    
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
        
/*===3 INIT Data AssociationRemove===========*/
UPDATE CTS_DataCenter.AssociationRemove AS ar
	INNER JOIN CTS_DataCenter.CTSCustomer AS c1 ON ar.FromCTSCustID = c1.CTSCustID
	INNER JOIN CTS_DataCenter.CTSCustomer AS c2 ON ar.ToCTSCustID = c2.CTSCustID
SET 	ar.FromCustID = LEAST(c1.CTSCustID,c2.CTSCustID)
	,	ar.ToCustID = GREATEST(c1.CTSCustID,c2.CTSCustID);