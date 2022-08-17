/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20220726@Casey.Huynh
Task:	 	Match Monitor Fixed Game
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20220726@Casey.Huynh: Created [Redmine ID: #175700]
Reviewer:
*/

USE CTS_DataCenter;

/******************CREATE TABLE *************************/
# DROP TABLE MatchMonitorTransLive;
CREATE TABLE MatchMonitorTransLive (
	TransID 			BIGINT UNSIGNED NOT NULL,
	TransDate 			DATETIME(3) DEFAULT NULL,
	MatchID 			BIGINT UNSIGNED DEFAULT NULL,
	TotalScore 			SMALLINT UNSIGNED DEFAULT NULL,
	BettypeID 			INT UNSIGNED DEFAULT NULL,
	CustID 				BIGINT UNSIGNED DEFAULT NULL,
	Stake 				DECIMAL(20,4) DEFAULT NULL,
	LiveHomeScore 		SMALLINT UNSIGNED DEFAULT NULL,
	LiveAwayScore 		SMALLINT UNSIGNED DEFAULT NULL,
	EventDate 			DATE DEFAULT NULL,
	KickOffTime 		DATETIME DEFAULT NULL,
	EventStatus 		VARCHAR(50) DEFAULT NULL,
	HomeID 				INT UNSIGNED DEFAULT NULL,
	AwayID 				INT UNSIGNED DEFAULT NULL,
	LeagueID 			INT UNSIGNED DEFAULT NULL,
	GroupID 			INT UNSIGNED DEFAULT '0',
	InsertTime 			DATETIME(3) DEFAULT NULL,
	LeagueName 			VARCHAR(500) DEFAULT NULL,
	SportType 			INT DEFAULT NULL,
	Betteam 			VARCHAR(10) DEFAULT NULL,
	BetID 				BIGINT DEFAULT NULL,
    IsMajorLeague		BOOLEAN,
    Odds				DECIMAL(10,4),
    StatusRule02		TINYINT COMMENT 'Applied Reason: 3:Fixed Game' DEFAULT 0,
	PRIMARY KEY (TransID),
	INDEX IX_MatchMonitorTransLive_TransDate (TransDate),
	INDEX IX_MatchMonitorTransLive_Group (MatchID,TotalScore,BettypeID,BetID,Betteam,GroupID),
    INDEX IX_MatchMonitorTransLive_StatusRule02(StatusRule02)
) ENGINE=InnoDB;
# DROP TABLE MatchMonitorTransNonLive;
CREATE TABLE MatchMonitorTransNonLive (
	TransID 			BIGINT UNSIGNED NOT NULL,
	TransDate 			DATETIME(3) DEFAULT NULL,
	MatchID 			BIGINT UNSIGNED DEFAULT NULL,
	TotalScore 			SMALLINT UNSIGNED DEFAULT NULL,
	BettypeID 			INT UNSIGNED DEFAULT NULL,
	CustID 				BIGINT UNSIGNED DEFAULT NULL,
	Stake 				DECIMAL(20,4) DEFAULT NULL,
	LiveHomeScore 		SMALLINT UNSIGNED DEFAULT NULL,
	LiveAwayScore 		SMALLINT UNSIGNED DEFAULT NULL,
	EventDate 			DATE DEFAULT NULL,
	KickOffTime 		DATETIME DEFAULT NULL,
	EventStatus 		VARCHAR(50) DEFAULT NULL,
	HomeID 				INT UNSIGNED DEFAULT NULL,
	AwayID 				INT UNSIGNED DEFAULT NULL,
	LeagueID 			INT UNSIGNED DEFAULT NULL,
	GroupID 			INT UNSIGNED DEFAULT '0',
	InsertTime 			DATETIME(3) DEFAULT NULL,
	LeagueName 			VARCHAR(500) DEFAULT NULL,
	SportType 			INT DEFAULT NULL,
	Betteam 			VARCHAR(10) DEFAULT NULL,
	BetID 				BIGINT DEFAULT NULL,
    IsMajorLeague		BOOLEAN,
    Odds				DECIMAL(10,4),
    StatusRule02		TINYINT COMMENT 'Applied For: Fixed Game' DEFAULT 0,
	PRIMARY KEY (TransID),
	INDEX IX_MatchMonitorTransNonLive_TransDate (TransDate),
	INDEX IX_MatchMonitorTransNonLive_Group (MatchID,TotalScore,BettypeID,BetID,Betteam,GroupID,TransDate),
    INDEX IX_MatchMonitorTransNonLive_StatusRule02(StatusRule02)
) ENGINE=InnoDB;

/******************ALTER TABLE *************************/
ALTER TABLE MatchMonitorDetails
ADD COLUMN Betteam VARCHAR(10) DEFAULT NULL;

ALTER TABLE MatchMonitorDetails
ADD INDEX IX_MatchMonitorDetails_MatchGroup(MatchID,BettypeID,BetID,Betteam);

ALTER TABLE MatchMonitorDetails
ADD UNIQUE KEY UK_MatchMonitorDetails_MatchRuleGroup(MatchID,LiveIndicator,TotalScore,BettypeID,BetID,Betteam,GroupID);

ALTER TABLE MatchMonitorDetails
DROP INDEX IX_MatchMonitorDetails_MatchID_BettypeID;

ALTER TABLE MatchMonitorDetails
DROP INDEX UK_MatchMonitorDetails_MatchDetailGroup;

#******************Init SystemParameter***************************
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES	(100,'MatchMonitor_Rule02_Process_Live','In_process MatchMonitorTransLive.TransID','BIGINT UNSIGNED','0')
	,	(101,'MatchMonitor_Rule02_Process_NonLive','In_process MatchMonitorTransNonLive.TransID','BIGINT UNSIGNED ','0')
    ,	(107,'MatchMonitor_Rule_FixedGame_Duration','Duration in Minute','SMALL INT','7')
	,	(108,'MatchMonitor_Rule_FixedGame_HighStake','High Stake Value','SMALL INT','500')
	,	(109,'MatchMonitor_Rule_FixedGame_TotalTicket','Min of Total Ticket','SMALL INT','40')    
	,	(110,'MatchMonitor_Rule_FixedGame_HighStakePercent','Total HighStake per Total Ticket','DECIMAL(1,1)','0.5')
    ,	(111,'MatchMonitor_Rule_FixedGame_MinOdds','Min Odds','SMALL INT','10')
	,	(112,'MatchMonitor_Rule_FixedGame_MaxOdds','Max Odds','SMALL INT','20');

