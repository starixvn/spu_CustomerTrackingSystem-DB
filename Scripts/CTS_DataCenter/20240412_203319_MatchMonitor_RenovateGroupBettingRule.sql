/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240412@Casey.Huynh
Task:	 	Match Monitor Renovate Match Monitor Group Betting Rule
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231114@Casey.Huynh: Created [Redmine ID: #192172]
Reviewer:
*/

USE CTS_DataCenter;
/*
CREATE TABLE MatchMonitorStagingGroupBettingLive (
  SequenceID bigint unsigned NOT NULL,
  TransID bigint unsigned NOT NULL,
  TransDate datetime(3) DEFAULT NULL,
  MatchID int DEFAULT NULL,
  SportType int DEFAULT NULL,
  ScoreDiff int DEFAULT NULL,
  BettypeID int DEFAULT NULL,
  BetID bigint DEFAULT NULL,
  Betteam varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  CustID bigint unsigned DEFAULT NULL,
  Stake decimal(20,4) DEFAULT NULL,
  GroupID int DEFAULT '0',
  LiveHomeScore int DEFAULT NULL,
  LiveAwayScore int DEFAULT NULL,
  EventDate date DEFAULT NULL,
  KickOffTime datetime DEFAULT NULL,
  EventStatus varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  HomeID int DEFAULT NULL,
  AwayID int DEFAULT NULL,
  LeagueID int DEFAULT NULL,
  InsertTime datetime(3) DEFAULT NULL,
  LeagueName varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  IsMajorLeague tinyint(1) DEFAULT NULL,
  Odds decimal(10,4) DEFAULT NULL,
  Hdp decimal(8,4) DEFAULT NULL,
  Hdp1 decimal(8,4) DEFAULT NULL,
  Hdp2 decimal(8,4) DEFAULT NULL,
  PRIMARY KEY (SequenceID),
  KEY IX_MatchMonitorStagingGroupBettingLive_TransDate (TransDate),
  KEY IX_MatchMonitorStagingGroupBettingLive_RuleGroup (MatchID,ScoreDiff,BettypeID,BetID,GroupID),
  KEY IX_MatchMonitorStagingGroupBettingLive_TransID (TransID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

CREATE TABLE MatchMonitorStagingGroupBettingNonLive (
  SequenceID bigint unsigned NOT NULL,
  TransID bigint unsigned NOT NULL,
  TransDate datetime(3) DEFAULT NULL,
  MatchID int DEFAULT NULL,
  SportType int DEFAULT NULL,
  ScoreDiff int DEFAULT NULL,
  BettypeID int DEFAULT NULL,
  BetID bigint DEFAULT NULL,
  Betteam varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  CustID bigint unsigned DEFAULT NULL,
  Stake decimal(20,4) DEFAULT NULL,
  GroupID int DEFAULT '0',
  LiveHomeScore int DEFAULT NULL,
  LiveAwayScore int DEFAULT NULL,
  EventDate date DEFAULT NULL,
  KickOffTime datetime DEFAULT NULL,
  EventStatus varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  HomeID int DEFAULT NULL,
  AwayID int DEFAULT NULL,
  LeagueID int DEFAULT NULL,
  InsertTime datetime(3) DEFAULT NULL,
  LeagueName varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL,
  IsMajorLeague tinyint(1) DEFAULT NULL,
  Odds decimal(10,4) DEFAULT NULL,
  Hdp decimal(8,4) DEFAULT NULL,
  Hdp1 decimal(8,4) DEFAULT NULL,
  Hdp2 decimal(8,4) DEFAULT NULL,
  PRIMARY KEY (SequenceID),
  KEY IX_MatchMonitorStagingGroupBettingNonLive_TransDate (TransDate),
  KEY IX_MatchMonitorStagingGroupBettingNonLive_RuleGroup (MatchID,ScoreDiff,BettypeID,BetID,GroupID),
  KEY IX_MatchMonitorStagingGroupBettingNonLive_TransID (TransID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci;

*/
ALTER TABLE MatchMonitorStagingGroupBettingLive
	DROP INDEX IX_MatchMonitorStagingGroupBettingLive_TransDate
,	DROP INDEX IX_MatchMonitorStagingGroupBettingLive_RuleGroup
,	ADD CTSCustID BIGINT UNSIGNED AFTER CustID
,	ADD COLUMN SubscriberID INT UNSIGNED AFTER CTSCustID
,	ADD COLUMN IsLicensee BIGINT AFTER SubscriberID
,	ADD COLUMN TransDateToSecond BIGINT AFTER TransDate
,	ADD INDEX IX_MatchMonitorStagingGroupBettingLive_TransDateToSecond(TransDateToSecond)
,	ADD INDEX IX_MatchMonitorStagingGroupBettingLive_RuleGroup (MatchID,ScoreDiff,BettypeID,BetID,Betteam,GroupID);

ALTER TABLE MatchMonitorStagingGroupBettingNonLive
	DROP INDEX IX_MatchMonitorStagingGroupBettingNonLive_TransDate
,	DROP INDEX IX_MatchMonitorStagingGroupBettingNonLive_RuleGroup
,	ADD CTSCustID BIGINT UNSIGNED AFTER CustID
,	ADD COLUMN SubscriberID INT UNSIGNED AFTER CTSCustID
,	ADD COLUMN IsLicensee BIGINT AFTER SubscriberID
,	ADD COLUMN TransDateToSecond BIGINT AFTER TransDate
,	ADD INDEX IX_MatchMonitorStagingGroupBettingNonLive_TransDateToSecond(TransDateToSecond)
,	ADD INDEX IX_MatchMonitorStagingGroupBettingNonLive_RuleGroup (MatchID,ScoreDiff,BettypeID,BetID,Betteam,GroupID);

UPDATE MatchMonitorStagingGroupBettingLive
SET TransDateToSecond = UNIX_TIMESTAMP(TransDate);

UPDATE MatchMonitorStagingGroupBettingNonLive
SET TransDateToSecond = UNIX_TIMESTAMP(TransDate);

