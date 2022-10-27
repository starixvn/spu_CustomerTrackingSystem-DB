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

ALTER TABLE MatchMonitorStagingLive
	DROP COLUMN Rule03GroupID
,	DROP INDEX IX_MatchMonitorStagingLive_GroupRule03
,	DROP INDEX IX_MatchMonitorStagingLive_RuleGroupID
,	RENAME COLUMN Rule01GroupID TO GroupID
,	ADD INDEX IX_MatchMonitorStagingLive_GroupID(GroupID);


ALTER TABLE MatchMonitorStagingNonLive
	DROP COLUMN Rule03GroupID
,	DROP INDEX IX_MatchMonitorStagingNonLive_GroupRule03
,	DROP INDEX IX_MatchMonitorStagingNonLive_RuleGroupID
,	RENAME COLUMN Rule01GroupID TO GroupID
,	ADD INDEX IX_MatchMonitorStagingNonLive_GroupID(GroupID);


CREATE TABLE `MatchMonitorStagingLive03` (
  `SequenceID` bigint unsigned NOT NULL,
  `TransID` bigint unsigned NOT NULL,
  `TransDate` datetime(3) DEFAULT NULL,
  `MatchID` int DEFAULT NULL,
  `SportType` int DEFAULT NULL,
  `TotalScore` int DEFAULT NULL,
  `BettypeID` int DEFAULT NULL,
  `BetID` bigint DEFAULT NULL,
  `Betteam` varchar(10) DEFAULT NULL,
  `CustID` bigint unsigned DEFAULT NULL,
  `Stake` decimal(20,4) DEFAULT NULL,
  `GroupID` int DEFAULT '0',
  `LiveHomeScore` int DEFAULT NULL,
  `LiveAwayScore` int DEFAULT NULL,
  `EventDate` date DEFAULT NULL,
  `KickOffTime` datetime DEFAULT NULL,
  `EventStatus` varchar(50) DEFAULT NULL,
  `HomeID` int DEFAULT NULL,
  `AwayID` int DEFAULT NULL,
  `LeagueID` int DEFAULT NULL,
  `InsertTime` datetime(3) DEFAULT NULL,
  `LeagueName` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`SequenceID`),
  INDEX `IX_MatchMonitorStagingLive03_TransDate` (`TransDate`),
  INDEX `IX_MatchMonitorStagingLive03_GroupRule01` (`MatchID`,`TotalScore`,`BettypeID`,`BetID`,`GroupID`),
  INDEX `IX_MatchMonitorStagingLive03_TransID` (`TransID`),
  INDEX `IX_MatchMonitorStagingLive03_GroupID` (`GroupID`)
) ENGINE=InnoDB;



CREATE TABLE `MatchMonitorStagingNonLive03` (
  `SequenceID` bigint unsigned NOT NULL,
  `TransID` bigint unsigned NOT NULL,
  `TransDate` datetime(3) DEFAULT NULL,
  `MatchID` int DEFAULT NULL,
  `SportType` int DEFAULT NULL,
  `TotalScore` int DEFAULT NULL,
  `BettypeID` int DEFAULT NULL,
  `BetID` bigint DEFAULT NULL,
  `Betteam` varchar(10) DEFAULT NULL,
  `CustID` bigint unsigned DEFAULT NULL,
  `Stake` decimal(20,4) DEFAULT NULL,
  `GroupID` int DEFAULT '0',
  `LiveHomeScore` int DEFAULT NULL,
  `LiveAwayScore` int DEFAULT NULL,
  `EventDate` date DEFAULT NULL,
  `KickOffTime` datetime DEFAULT NULL,
  `EventStatus` varchar(50) DEFAULT NULL,
  `HomeID` int DEFAULT NULL,
  `AwayID` int DEFAULT NULL,
  `LeagueID` int DEFAULT NULL,
  `InsertTime` datetime(3) DEFAULT NULL,
  `LeagueName` varchar(500) DEFAULT NULL,
  PRIMARY KEY (`SequenceID`),
  INDEX `IX_MatchMonitorStagingNonLive03_TransDate` (`TransDate`),
  INDEX `IX_MatchMonitorStagingNonLive03_GroupRule01` (`MatchID`,`TotalScore`,`BettypeID`,`BetID`,`GroupID`),
  INDEX `IX_MatchMonitorStagingNonLive03_TransID` (`TransID`),
  INDEX `IX_MatchMonitorStagingNonLive03_GroupID` (`GroupID`)
) ENGINE=InnoDB;
