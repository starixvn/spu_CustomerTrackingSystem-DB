/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	2022009290@Casey.Huynh
Task:	 	Enhance Fixed Game
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 2022009290@Casey.Huynh: Created [Redmine ID: #178310]
Reviewer:
*/

USE CTS_DataCenter;

#=============================================================
DROP TABLE IF EXISTS MatchMonitorRuleSetting;
CREATE TABLE MatchMonitorRuleSetting (
		RuleGroupID TINYINT
    ,	RuleGroupDesc VARCHAR(100)
    ,	Reason TINYINT
	,	SportType INT
	,	ReasonName	VARCHAR(100)
    ,	SportName VARCHAR(100)
    ,	TimeStep SMALLINT
    ,	TotalStake DECIMAL(20,4)
    ,	HighStakeValue DECIMAL(20,4)
    ,	TotalHighStakeTicket INT	
    ,	ModifiedDate DATETIME(3)
    ,	Comments VARCHAR(300)
    
    ,	PRIMARY KEY PK_MatchMonitorRuleSetting(RuleGroupID, Reason, SportType )
);

#===========================================================================
ALTER TABLE MatchMonitorStagingLive
CHANGE COLUMN SequenceID SequenceID BIGINT UNSIGNED FIRST
, CHANGE COLUMN SportType SportType INT AFTER MatchID
, CHANGE COLUMN BetID BetID BIGINT AFTER BettypeID
, CHANGE COLUMN Betteam Betteam VARCHAR(10) AFTER BetID
, CHANGE COLUMN GroupID Rule01GroupID INT DEFAULT 0 AFTER Stake
, ADD COLUMN Rule03GroupID INT DEFAULT 0 AFTER Rule01GroupID
, RENAME INDEX IX_MatchMonitorStagingLive_Group TO IX_MatchMonitorStagingLive_Rule01GroupID
, ADD INDEX IX_MatchMonitorStagingLive_Rule03GroupID(`MatchID`,`TotalScore`,`BettypeID`,`BetID`,`Rule03GroupID`);

#===========================================================================
ALTER TABLE MatchMonitorStagingNonLive
CHANGE COLUMN SequenceID SequenceID BIGINT UNSIGNED FIRST
, CHANGE COLUMN SportType SportType INT AFTER MatchID
, CHANGE COLUMN BetID BetID BIGINT AFTER BettypeID
, CHANGE COLUMN Betteam Betteam VARCHAR(10) AFTER BetID
, CHANGE COLUMN GroupID Rule01GroupID INT DEFAULT 0 AFTER Stake
, ADD COLUMN Rule03GroupID INT DEFAULT 0 AFTER Rule01GroupID
, RENAME INDEX IX_MatchMonitorStagingNonLive_Group TO IX_MatchMonitorStagingNonLive_Rule01GroupID
, ADD INDEX IX_MatchMonitorStagingNonLive_Rule03GroupID(`MatchID`,`TotalScore`,`BettypeID`,`BetID`,`Rule03GroupID`);
/*
DROP TABLE MatchMonitorStagingLive;
CREATE TABLE `MatchMonitorStagingLive` (
  `TransID` bigint unsigned NOT NULL,
  `TransDate` datetime(3) DEFAULT NULL,
  `MatchID` int DEFAULT NULL,
  `TotalScore` int DEFAULT NULL,
  `BettypeID` int DEFAULT NULL,
  `CustID` bigint unsigned DEFAULT NULL,
  `Stake` decimal(20,4) DEFAULT NULL,
  `LiveHomeScore` int DEFAULT NULL,
  `LiveAwayScore` int DEFAULT NULL,
  `EventDate` date DEFAULT NULL,
  `KickOffTime` datetime DEFAULT NULL,
  `EventStatus` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `HomeID` int DEFAULT NULL,
  `AwayID` int DEFAULT NULL,
  `LeagueID` int DEFAULT NULL,
  `GroupID` int unsigned DEFAULT '0',
  `InsertTime` datetime(3) DEFAULT NULL,
  `LeagueName` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `SportType` int DEFAULT NULL,
  `Betteam` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `BetID` bigint DEFAULT '0',
  `SequenceID` bigint unsigned NOT NULL,
  PRIMARY KEY (`SequenceID`),
  KEY `IX_MatchMonitorStagingLive_TransDate` (`TransDate`),
  KEY `IX_MatchMonitorStagingLive_Group` (`MatchID`,`TotalScore`,`BettypeID`,`BetID`,`GroupID`),
  KEY `IX_MatchMonitorStagingLive_TransID` (`TransID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

DROP TABLE MatchMonitorStagingNonLive;
CREATE TABLE `MatchMonitorStagingNonLive` (
  `TransID` bigint unsigned NOT NULL,
  `TransDate` datetime(3) DEFAULT NULL,
  `MatchID` int DEFAULT NULL,
  `TotalScore` int DEFAULT NULL,
  `BettypeID` int DEFAULT NULL,
  `CustID` bigint unsigned DEFAULT NULL,
  `Stake` decimal(20,4) DEFAULT NULL,
  `LiveHomeScore` int DEFAULT NULL,
  `LiveAwayScore` int DEFAULT NULL,
  `EventDate` date DEFAULT NULL,
  `KickOffTime` datetime DEFAULT NULL,
  `EventStatus` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `HomeID` int DEFAULT NULL,
  `AwayID` int DEFAULT NULL,
  `LeagueID` int DEFAULT NULL,
  `GroupID` int unsigned DEFAULT '0',
  `InsertTime` datetime(3) DEFAULT NULL,
  `LeagueName` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `SportType` int DEFAULT NULL,
  `Betteam` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `BetID` bigint DEFAULT '0',
  `SequenceID` bigint unsigned NOT NULL,
  PRIMARY KEY (`SequenceID`),
  KEY `IX_MatchMonitorStagingNonLive_TransDate` (`TransDate`),
  KEY `IX_MatchMonitorStagingNonLive_Group` (`MatchID`,`TotalScore`,`BettypeID`,`BetID`,`GroupID`),
  KEY `IX_MatchMonitorStagingNonLive_TransID` (`TransID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;
*/
#=======================INITIAL SERVICE PARAMETERs================================
INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
Values(120,'MatchMonitor_Rule03_Process_LiveLastSequenceID', 'MatchMonitor_Rule03_Process_LiveLastSequenceID','BIGINT UNSIGNED',0)
, (121,'MatchMonitor_Rule03_Process_NonLiveLastSequenceID', 'MatchMonitor_Rule03_Process_NonLiveLastSequenceID','BIGINT UNSIGNED',0);

#=================Initial Rule Setting============================================
INSERT INTO MatchMonitorRuleSetting(RuleGroupID, RuleGroupDesc, Reason, SportType, ReasonName, SportName, TimeStep, TotalStake, HighStakeValue, TotalHighStakeTicket, ModifiedDate, Comments)
VALUES	(1, 'Rule01', 0, 1, 'Group Betting', 'Soccer', 180, 1000, NULL, NULL,  NOW(), 'Time Step In Seconds')
	,	(1, 'Rule01', 0, 2, 'Group Betting', 'Basketball', 180, 500, NULL, NULL,  NOW(), 'Time Step In Seconds')
    ,	(1, 'Rule01', 0, 43, 'Group Betting', 'E-Sports', 180, 500, NULL, NULL,  NOW(), 'Time Step In Seconds')
    ,	(3, 'Rule03', 3, 1, 'Hedging', 'Soccer', 180, 2500, NULL, NULL,  NOW(), 'Time Step In Seconds');
    
    
CREATE TABLE `MatchMonitor` (
  `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `EventDate` date NOT NULL,
  `BettypeID` int NOT NULL,
  `MatchID` int NOT NULL,
  `LiveIndicator` tinyint(1) NOT NULL,
  `Reason` tinyint DEFAULT NULL,
  `KickOffTime` datetime DEFAULT NULL,
  `EventStatus` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `HomeID` int DEFAULT NULL,
  `AwayID` int DEFAULT NULL,
  `LeagueID` int DEFAULT NULL,
  `IsVerified` tinyint(1) DEFAULT '0',
  `VerifiedDate` datetime DEFAULT NULL,
  `VerifiedBy` int unsigned DEFAULT NULL,
  `LeagueName` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `SportType` int DEFAULT '1',
  `BetID` bigint NOT NULL DEFAULT '0',
  `ClassifyStatus` tinyint DEFAULT '0' COMMENT '0: Default, 1: Classify Done, 2: Ready To Classify (Match Complete)',
  `InsertTime` datetime(3) DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UK_MatchMonitor_MatchGroup` (`EventDate`,`BettypeID`,`BetID`,`MatchID`,`LiveIndicator`,`Reason`),
  KEY `IX_MatchMonitor_IsVerified` (`IsVerified`),
  KEY `IX_MatchMonitor_MatchIDBettype` (`MatchID`,`BettypeID`,`BetID`),
  KEY `IX_MatchMonitor_SportTypeClassifyStatus` (`SportType`,`ClassifyStatus`,`KickOffTime`)
) ENGINE=InnoDB;

DROP PROCEDURE CTS_DC_MatchMonitor_Rule_Get;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule_Proces;
DROP PROCEDURE CTS_DC_MatchMonitor_Rule_Complete;

