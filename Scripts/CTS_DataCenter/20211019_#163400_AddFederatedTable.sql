/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20211019@Aries.Nguyen
    Task:	 	Add federted server
    DBName:		CTS_DataCenter
*/
/*Run on Master*/
CREATE ROLE 'FEDERATED';
GRANT SELECT  ON `CTS_DataCenter`.`MatchMonitorStagingLive` TO `FEDERATED`@`%`;
GRANT SELECT  ON `CTS_DataCenter`.`MatchMonitorStagingNonLive` TO `FEDERATED`@`%`;

CREATE USER 'CTSRemote'@'%' IDENTIFIED WITH mysql_native_password BY 'xxx';
GRANT 'FEDERATED' TO 'CTSRemote'@'%';

/*
 Master, Salve add config: federated  
*/


/*Run on Slave*/
CREATE SERVER master58
FOREIGN DATA WRAPPER mysql
OPTIONS (USER 'CTSRemote', HOST '10.40.40.58', PORT 3306, DATABASE 'CTS_DataCenter', PASSWORD 'xxx');


/*Run on Master*/
USE CTS_DataCenter;
CREATE TABLE `MatchMonitorStagingLive_Master` (
   `TransID` bigint NOT NULL,
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
   `EventStatus` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
   `HomeID` int DEFAULT NULL,
   `AwayID` int DEFAULT NULL,
   `LeagueID` int DEFAULT NULL,
   `GroupID` int unsigned DEFAULT '0',
   `InsertTime` datetime(3) DEFAULT NULL,
   PRIMARY KEY (`TransID`),
   KEY `IX_MatchMonitorStagingLive_Group` (`MatchID`,`TotalScore`,`BettypeID`,`GroupID`),
   KEY `IX_MatchMonitorStagingLive_TransDate` (`TransDate`)
 ) ENGINE=FEDERATED
CONNECTION='master58/MatchMonitorStagingLive';


CREATE TABLE `MatchMonitorStagingNonLive_Master` (
   `TransID` bigint NOT NULL,
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
   `EventStatus` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
   `HomeID` int DEFAULT NULL,
   `AwayID` int DEFAULT NULL,
   `LeagueID` int DEFAULT NULL,
   `GroupID` int unsigned DEFAULT '0',
   `InsertTime` datetime(3) DEFAULT NULL,
   PRIMARY KEY (`TransID`),
   KEY `IX_MatchMonitorStagingNonLive_Group` (`MatchID`,`TotalScore`,`BettypeID`,`GroupID`),
   KEY `IX_MatchMonitorStagingNonLive_TransDate` (`TransDate`)
 ) ENGINE=FEDERATED
CONNECTION='master58/MatchMonitorStagingNonLive'