/*<info serverAlias="CTSMain-CTS_Adhoc" databaseType="2"></info>*/
/*
Creator: 	20240707@Victoria.Le
Task:	 	Match Monitoring Staging GB Live
Server:  	Master
DBName:		CTS_Adhoc

Revisions: 
		- 20240707@Victoria.Le: Initial Writing [#000000]
Reviewer:
*/

USE CTS_Adhoc;

CREATE TABLE `MatchMonitorStagingGroupBettingLive_BK20240707` ( 
`SequenceID` bigint unsigned NOT NULL
, `TransID` bigint unsigned NOT NULL
, `TransDate` datetime(3) DEFAULT NULL
, `MatchID` int DEFAULT NULL
, `SportType` int DEFAULT NULL
, `ScoreDiff` int DEFAULT NULL
, `BettypeID` int DEFAULT NULL
, `BetID` bigint DEFAULT NULL
, `Betteam` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL
, `CustID` bigint unsigned DEFAULT NULL
, `Stake` decimal(20,4) DEFAULT NULL
, `GroupID` int DEFAULT '0'
, `LiveHomeScore` int DEFAULT NULL
, `LiveAwayScore` int DEFAULT NULL
, `EventDate` date DEFAULT NULL
, `KickOffTime` datetime DEFAULT NULL
, `EventStatus` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL
, `HomeID` int DEFAULT NULL
, `AwayID` int DEFAULT NULL
, `LeagueID` int DEFAULT NULL
, `InsertTime` datetime(3) DEFAULT NULL
, `LeagueName` varchar(500) COLLATE utf8_unicode_ci DEFAULT NULL
, `IsMajorLeague` tinyint(1) DEFAULT NULL
, `Odds` decimal(10,4) DEFAULT NULL
, `Hdp` decimal(8,4) DEFAULT NULL
, `Hdp1` decimal(8,4) DEFAULT NULL
, `Hdp2` decimal(8,4) DEFAULT NULL
, PRIMARY KEY (`SequenceID`)
, KEY `IX_MMGBLBK20240707_TransDate` (`TransDate`)
, KEY `IX_MMGBLBK20240707_RuleGroup` (`MatchID`,`ScoreDiff`,`BettypeID`,`BetID`,`GroupID`)
, KEY `IX_MMGBLBK20240707_TransID` (`TransID`) ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci
;

SELECT COUNT(1) 
FROM CTS_DataCenter.MatchMonitorStagingGroupBettingLive AS mms
WHERE mms.MatchID in (87926549,88328859,88328860,88328861,88330018,88330056,88446059,88447340,88462549,88462550,88468181,88586221,88586222)
;


INSERT INTO  `MatchMonitorStagingGroupBettingLive_BK20240707`(SequenceID, TransID, TransDate, MatchID, SportType, ScoreDiff, BettypeID, BetID, Betteam, CustID, Stake, GroupID, LiveHomeScore, LiveAwayScore, EventDate, KickOffTime, EventStatus, HomeID, AwayID, LeagueID, InsertTime, LeagueName, IsMajorLeague, Odds, Hdp, Hdp1, Hdp2)
SELECT SequenceID, TransID, TransDate, MatchID, SportType, ScoreDiff, BettypeID, BetID, Betteam, CustID, Stake, GroupID, LiveHomeScore, LiveAwayScore, EventDate, KickOffTime, EventStatus, HomeID, AwayID, LeagueID, InsertTime, LeagueName, IsMajorLeague, Odds, Hdp, Hdp1, Hdp2
FROM CTS_DataCenter.MatchMonitorStagingGroupBettingLive AS mms
WHERE MatchID in (87926549,88328859,88328860,88328861,88330018,88330056,88446059,88447340,88462549,88462550,88468181,88586221,88586222)
;


SELECT COUNT(1) FROM MatchMonitorStagingGroupBettingLive_BK20240707;