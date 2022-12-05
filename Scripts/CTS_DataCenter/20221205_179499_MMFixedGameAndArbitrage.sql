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
,	DROP COLUMN TotalScore;

ALTER TABLE MatchMonitorTransLive
	ADD COLUMN HDP DECIMAL (8,4) AFTER BettypeID
,	RENAME TO MatchMonitorStagingFixedGameLive;

ALTER TABLE MatchMonitorTransNonLive
	ADD COLUMN HDP DECIMAL (8,4) AFTER BettypeID
,	RENAME TO MatchMonitorStagingFixedGameNonLive;

ALTER TABLE MatchMonitorStagingLive
RENAME MatchMonitorStagingGroupBettingLive;

ALTER TABLE MatchMonitorStagingNonLive
RENAME MatchMonitorStagingGroupBettingNonLive;

ALTER TABLE MatchMonitorStagingLive03
RENAME MatchMonitorStagingHedgingLive;

ALTER TABLE MatchMonitorStagingNonLive03
RENAME MatchMonitorStagingHedgingNonLive;

#======INITAIL============================================================

#========Move Parameter From System Parameter To MatchMonitorRuleSetting
ALTER TABLE MatchMonitorRuleSetting
  ADD COLUMN HighStakePercent DECIMAL(6,2) AFTER HighStake
, ADD COLUMN MinOdds DECIMAL(10,4) AFTER HighStakePercent
, ADD COLUMN MaxOdds DECIMAL(10,4) AFTER MinOdds 
, ADD COLUMN IsMajorLeague SMALLINT DEFAULT 0 COMMENT '0: All Types, 1: Major League, 2: Other Leagues'  AFTER SportType 
, DROP PRIMARY KEY 
, ADD PRIMARY KEY  PK_MatchMonitorRuleSetting(RuleGroupID,Reason,SportType, IsMajorLeague);

#=================Fixed Game==========================
INSERT INTO CTS_DataCenter.MatchMonitorRuleSetting(RuleGroupID, RuleGroupDesc, Reason, SportType, ReasonName, SportName, TimeStep, HighStake, MinOdds, MaxOdds, ModifiedDate)
VALUES (5, 'Fixed Game Detect', 3 , 1, 'Fixed Game', 'Soccer', 420, 500, 0.5, 2, CURRENT_TIMESTAMP())
	, (5, 'Fixed Game Detect', 3 , 2, 'Fixed Game', 'Basketball', 420, 500, 0.5, 2, CURRENT_TIMESTAMP())
    , (5, 'Fixed Game Detect', 3 , 43, 'Fixed Game', 'E-Sports', 420, 500, 0.5, 2, CURRENT_TIMESTAMP());
    
#=================Arbitrage==========================
INSERT INTO CTS_DataCenter.MatchMonitorRuleSetting(RuleGroupID, RuleGroupDesc, Reason, SportType, ReasonName, SportName, TimeStep, TotalStake, IsMajorLeague, ModifiedDate)
VALUES (6, 'Arbitrage Detect', 2 , 1, 'Arbitrage', 'Soccer', 180, 5000, 1, CURRENT_TIMESTAMP())
	, (6, 'Arbitrage Detect', 2 , 1, 'Arbitrage', 'Soccer', 180, 1000, 2, CURRENT_TIMESTAMP());    

UPDATE CTS_DataCenter.MatchMonitorRuleSetting
SET RuleGroupDesc = 'Group Betting Detect'
WHERE RuleGroupID = 1;

UPDATE CTS_DataCenter.MatchMonitorRuleSetting
SET RuleGroupDesc = 'Hedging Detect'
WHERE RuleGroupID = 3;

#========Parameter Batch Size
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES	(126,'MatchMonitorFixedGame_RuleLive_BatchSize','MatchMonitorFixedGame_RuleLive_BatchSize','INT','5000')
	,	(127,'MatchMonitorFixedGame_RuleNonLive_BatchSize','MatchMonitorFixedGame_RuleNonLive_BatchSize','INT','5000')
    ,	(128,'MatchMonitorArbitrage_RuleNonLive_BatchSize','MatchMonitorArbitrage_RuleNonLive_BatchSize','INT','5000');
    
    
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