/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240412@Casey.Huynh
Task:	 	Match Monitor Renovate Match Monitor Arbitrage Rule
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231114@Casey.Huynh: Created [Redmine ID: #203639]
Reviewer:
*/

USE CTS_DataCenter;
/*
CREATE TABLE `MatchMonitorStagingArbitrageNonLive` (
  `SequenceID` bigint unsigned NOT NULL,
  `TransID` bigint unsigned NOT NULL,
  `TransDate` datetime(3) DEFAULT NULL,
  `MatchID` int DEFAULT NULL,
  `IsMajorLeague` tinyint(1) DEFAULT NULL,
  `SportType` int DEFAULT NULL,
  `ScoreDiff` int DEFAULT NULL,
  `BettypeID` int DEFAULT NULL,
  `BetID` bigint DEFAULT NULL,
  `HDP` decimal(8,4) DEFAULT NULL,
  `Betteam` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `CustID` bigint unsigned DEFAULT NULL,
  `Stake` decimal(20,4) DEFAULT NULL,
  `GroupID` int DEFAULT '0',
  `LiveHomeScore` int DEFAULT NULL,
  `LiveAwayScore` int DEFAULT NULL,
  `EventDate` date DEFAULT NULL,
  `KickOffTime` datetime DEFAULT NULL,
  `EventStatus` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `HomeID` int DEFAULT NULL,
  `AwayID` int DEFAULT NULL,
  `LeagueID` int DEFAULT NULL,
  `InsertTime` datetime(3) DEFAULT NULL,
  `LeagueName` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Hdp1` decimal(8,4) DEFAULT NULL,
  `Hdp2` decimal(8,4) DEFAULT NULL,
  PRIMARY KEY (`SequenceID`),
  KEY `IX_MMStagingArbitrageNonLive_TransDate` (`TransDate`),
  KEY `IX_MMStagingArbitrageNonLive_RuleGroup` (`MatchID`,`ScoreDiff`,`BettypeID`,`BetID`,`HDP`,`GroupID`,`IsMajorLeague`),
  KEY `IX_MMStagingArbitrageNonLive_TransID` (`TransID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;
*/
ALTER TABLE MatchMonitorStagingArbitrageNonLive
	DROP INDEX IX_MMStagingArbitrageNonLive_TransDate
,	DROP INDEX IX_MMStagingArbitrageNonLive_RuleGroup
,	ADD CTSCustID BIGINT UNSIGNED AFTER CustID
,	ADD COLUMN SubscriberID INT AFTER CTSCustID
,	ADD COLUMN TransDateToSecond BIGINT AFTER TransDate
,	ADD INDEX IX_MatchMonitorStagingArbitrageNonLive_TransDateToSecond(TransDateToSecond)
,	ADD INDEX IX_MatchMonitorStagingArbitrageNonLive_RuleGroup (MatchID,ScoreDiff,BettypeID,BetID,Betteam,HDP,GroupID);

UPDATE MatchMonitorStagingArbitrageNonLive AS arb
	INNER JOIN CTSCustomer AS cus ON cus.CustID = arb.CustID
SET TransDateToSecond = UNIX_TIMESTAMP(TransDate)
	, arb.CTSCustID  = cus.CustID
    , arb.SubscriberID  = cus.SubscriberID;
    
ALTER TABLE MatchMonitorRuleSetting
ADD COLUMN CustStake decimal(20,4) AFTER TotalStake;

UPDATE MatchMonitorRuleSetting
SET CustStake = TotalStake
WHERE RuleGroupID = 5; 

UPDATE MatchMonitorRuleSetting
SET TotalStake = 0
WHERE RuleGroupID = 5;



