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

#============================
ALTER TABLE MatchMonitorStagingLive
	RENAME MatchMonitorStagingGroupBettingLive
	,	RENAME COLUMN TotalScore TO ScoreDiff
    ,	ADD COLUMN IsMajorLeague BOOLEAN
    ,	ADD COLUMN Odds DECIMAL(10,4)
    ,	ADD COLUMN Hdp DECIMAL(8,4)
    ,	ADD COLUMN Hdp1 DECIMAL(8,4)
    ,	ADD COLUMN Hdp2 DECIMAL(8,4);

ALTER TABLE MatchMonitorStagingNonLive
	RENAME MatchMonitorStagingGroupBettingNonLive
	,	RENAME COLUMN TotalScore TO ScoreDiff
    ,	ADD COLUMN IsMajorLeague BOOLEAN
    ,	ADD COLUMN Odds DECIMAL(10,4)
    ,	ADD COLUMN Hdp DECIMAL(8,4)
    ,	ADD COLUMN Hdp1 DECIMAL(8,4)
    ,	ADD COLUMN Hdp2 DECIMAL(8,4);

ALTER TABLE MatchMonitorTransLive
	RENAME MatchMonitorStagingFixedGameLive
	,	Change COLUMN TotalScore  ScoreDiff INT
    ,	ADD COLUMN Hdp DECIMAL(8,4)
    ,	ADD COLUMN Hdp1 DECIMAL(8,4)
    ,	ADD COLUMN Hdp2 DECIMAL(8,4)
	,	DROP COLUMN StatusRule02;

ALTER TABLE MatchMonitorTransNonLive
	RENAME MatchMonitorStagingFixedGameNonLive
    ,	Change COLUMN TotalScore  ScoreDiff INT
    ,	ADD COLUMN Hdp DECIMAL(8,4)
    ,	ADD COLUMN Hdp1 DECIMAL(8,4)
    ,	ADD COLUMN Hdp2 DECIMAL(8,4)
    ,	DROP COLUMN StatusRule02;

ALTER TABLE MatchMonitorStagingLive03
	RENAME MatchMonitorStagingHedgingLive
	,	RENAME COLUMN TotalScore TO ScoreDiff;

ALTER TABLE MatchMonitorStagingNonLive03
	RENAME MatchMonitorStagingHedgingNonLive
	,	RENAME COLUMN TotalScore TO ScoreDiff;
#============================================================
ALTER TABLE MatchMonitor
	ADD COLUMN IsMajorLeage BOOLEAN AFTER MatchID
,	ADD COLUMN HDP DECIMAL (8,4) AFTER BettypeID;

UPDATE MatchMonitorDetails
SET ScoreDiff = TotalScore
WHERE ScoreDiff IS NULL;

ALTER TABLE MatchMonitorDetails
	ADD COLUMN IsMajorLeague BOOLEAN AFTER MatchID
,	ADD COLUMN HDP DECIMAL (8,4) AFTER BettypeID
,	DROP COLUMN TotalScore
,   DROP INDEX UK_MatchMonitorDetails_MatchRuleGroup;
#====================================================================

CREATE TABLE MatchMonitorStagingArbitrageNonLive (
	SequenceID bigint unsigned NOT NULL,
	TransID bigint unsigned NOT NULL,
	TransDate datetime(3) DEFAULT NULL,
	MatchID int DEFAULT NULL,
	IsMajorLeague BOOLEAN,
	SportType int DEFAULT NULL,
	ScoreDiff int DEFAULT NULL,
	BettypeID int DEFAULT NULL,
	BetID bigint DEFAULT NULL,
	HDP	DECIMAL(8,4),	
	Betteam varchar(10) DEFAULT NULL,
	CustID bigint unsigned DEFAULT NULL,
	Stake decimal(20,4) DEFAULT NULL,
	GroupID int DEFAULT '0',
	LiveHomeScore int DEFAULT NULL,
	LiveAwayScore int DEFAULT NULL,
	EventDate date DEFAULT NULL,
	KickOffTime datetime DEFAULT NULL,
	EventStatus varchar(50) DEFAULT NULL,
	HomeID int DEFAULT NULL,
	AwayID int DEFAULT NULL,
	LeagueID int DEFAULT NULL,
	InsertTime datetime(3) DEFAULT NULL,
	LeagueName varchar(500) DEFAULT NULL,
	Hdp1	DECIMAL(8,4),
	Hdp2	DECIMAL(8,4),
	PRIMARY KEY (SequenceID),
	KEY IX_MMStagingArbitrageNonLive_TransDate(TransDate),
	KEY IX_MMStagingArbitrageNonLive_RuleGroup(MatchID,ScoreDiff,BettypeID,BetID,HDP,GroupID,IsMajorLeague),
	KEY IX_MMStagingArbitrageNonLive_TransID(TransID)
) ENGINE=InnoDB;

#======INITAIL============================================================

#========Move Parameter From System Parameter To MatchMonitorRuleSetting
ALTER TABLE MatchMonitorRuleSetting
	ADD COLUMN RuleStatus INT DEFAULT 1 COMMENT '1:Active, 0:Inactive' AFTER RuleGroupID 
,	ADD COLUMN TotalTicket INT AFTER TotalStake
,	ADD COLUMN HighStakeTicketPercent DECIMAL(6,2) AFTER HighStake
,	ADD COLUMN MinOdds DECIMAL(10,4) AFTER HighStakeTicketPercent
,	ADD COLUMN MaxOdds DECIMAL(10,4) AFTER MinOdds 
,	ADD COLUMN LeagueType TINYINT DEFAULT 2 COMMENT '0: Others League, 1: Major League, 2: Any League'  AFTER SportType 
,	DROP PRIMARY KEY 
,	ADD PRIMARY KEY  PK_MatchMonitorRuleSetting(RuleGroupID,Reason,SportType,LeagueType);

#=================Fixed Game==========================
INSERT INTO CTS_DataCenter.MatchMonitorRuleSetting(RuleGroupID, RuleGroupDesc, Reason, SportType, ReasonName, SportName, TotalTicket, TimeStep, HighStake, HighStakeTicketPercent, MinOdds, MaxOdds, OddsSpread, LeagueType, ModifiedDate)
VALUES (2, 'Fixed Game Detect', 3 , 1, 'Fixed Game', 'Soccer', 40, 420, 500, 0.35, 0.5, 2, 10, 0, CURRENT_TIMESTAMP())
	, (2, 'Fixed Game Detect', 3 , 2, 'Fixed Game', 'Basketball', 40, 420, 500, 0.35, 0.5, 2, 10, 0,  CURRENT_TIMESTAMP())
    , (2, 'Fixed Game Detect', 3 , 43, 'Fixed Game', 'E-Sports', 40, 420, 500, 0.35, 0.5, 2, 10, 0,  CURRENT_TIMESTAMP());
    
#=================Arbitrage==========================
INSERT INTO CTS_DataCenter.MatchMonitorRuleSetting(RuleGroupID, RuleGroupDesc, Reason, SportType, ReasonName, SportName, TimeStep, TotalStake, LeagueType, ModifiedDate)
VALUES (5, 'Arbitrage Detect', 2 , 1, 'Arbitrage', 'Soccer', 180, 5000, 1, CURRENT_TIMESTAMP())
	, (5, 'Arbitrage Detect', 2 , 1, 'Arbitrage', 'Soccer', 180, 1000, 0, CURRENT_TIMESTAMP());    

UPDATE CTS_DataCenter.MatchMonitorRuleSetting
SET RuleGroupDesc = 'Group Betting Detect'
WHERE RuleGroupID = 1;

UPDATE CTS_DataCenter.MatchMonitorRuleSetting
SET RuleGroupDesc = 'Hedging Detect'
WHERE RuleGroupID = 3;

#========Parameter Batch Size
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES	(126,'MatchMonitor_FixedGameLive_BatchSize',NULL,'INT','5000')
	,	(127,'MatchMonitor_FixedGameNonLive_BatchSize',NULL,'INT','5000')
     ,	(128,'MatchMonitor_ArbitrageNonLive_LastSequenceID','MatchMonitorStagingArbitrageNonLive.SequenceID','BIGINT UNSINGED','5000')
    ,	(129,'MatchMonitor_ArbitrageNonLive_BatchSize',NULL,'INT','5000');
    
#=====UPDATE NAME OF SYSTEM PARAMETER=============
#=====Group betting===================================    
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_GroupBettingLive_LastSequenceID', ParameterDesc = 'MatchMonitorStagingGroupBettingLive.SequenceID' WHERE ParameterID = 47 ;
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_GroupBettingNonLive_LastSequenceID', ParameterDesc = 'MatchMonitorStagingGroupBettingNonLive.SequenceID' WHERE ParameterID = 48 ;
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_GroupBetting_BatchSize',  ParameterDesc = NULL WHERE ParameterID = 122 ;

#=====FixGame===================================    
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_FixedGameLive_LastSequenceID', ParameterDesc = 'MatchMonitorStagingFixedGameLive.SequenceID' WHERE ParameterID = 100 ;
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_FixedGameNonLive_LastSequenceID', ParameterDesc = 'MatchMonitorStagingFixedGameNonLive.SequenceID' WHERE ParameterID = 101 ;
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_FixedGameLive_BatchSize',  ParameterDesc = NULL WHERE ParameterID = 126 ;
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_FixedGameNonLive_BatchSize',  ParameterDesc = NULL WHERE ParameterID = 127 ;

#=====Heding===================================    
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_HedgingLive_LastSequenceID', ParameterDesc = 'MatchMonitorStagingHedgingLive.SequenceID' WHERE ParameterID = 120 ;
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_HedgingNonLive_LastSequenceID', ParameterDesc = 'MatchMonitorStagingHedgingNonLive.SequenceID' WHERE ParameterID = 121 ;
UPDATE  CTS_DataCenter.SystemParameter SET ParameterName = 'MatchMonitor_Hedging_BatchSize',  ParameterDesc = NULL WHERE ParameterID = 123 ;    

 SELECT * FROM CTS_DataCenter.MatchMonitorRuleSetting;   
 SELECT * FROM SystemParameter WHERE ParameterName LIKE '%MatchMonitor%'
    /*
DROP PROCEDURE CTS_DC_MatchMonitor_Rule01_Complete ;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule01_Get ;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule01_Process;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule01_StagingClean;

DROP PROCEDURE CTS_DC_MatchMonitor_Rule02_Complete;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule02_Get;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule02_Process;
DROP PROCEDURE CTS_DC_MatchMonitor_Staging_CleanTrans;

DROP PROCEDURE CTS_DC_MatchMonitor_Rule03_Complete;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule03_Process;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule03_Get;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule03_StagingClean;

*/
/*
DROP TABLE MatchMonitorRuleSetting;
CREATE TABLE MatchMonitorRuleSetting (
  RuleGroupID tinyint NOT NULL,
  RuleGroupDesc varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  Reason tinyint NOT NULL,
  SportType int NOT NULL,
  ReasonName varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  SportName varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
  TimeStep smallint DEFAULT NULL,
  TotalStake decimal(20,4) DEFAULT NULL,
  HighStake decimal(20,4) DEFAULT NULL,
  OddsSpread decimal(4,2) DEFAULT NULL,
  ModifiedDate datetime(3) DEFAULT NULL,
  Comments varchar(300) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (RuleGroupID,Reason,SportType)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

LOAD DATA LOCAL INFILE 'D:/SPU/Test/MMRuleSetting.csv'
INTO TABLE CTS_DataCenter.MatchMonitorRuleSetting
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
*/