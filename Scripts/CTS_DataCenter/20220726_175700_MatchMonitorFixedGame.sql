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
    StatusRule01		TINYINT COMMENT 'Applied Reason: 0:GroupBetting, 1:Hedging, 2:Arbitrage' DEFAULT 0,
    StatusRule02		TINYINT COMMENT 'Applied Reason: 3:Fixed Game' DEFAULT 0,
	PRIMARY KEY (TransID),
	INDEX IX_MatchMonitorTransLive_TransDate (TransDate),
	INDEX IX_MatchMonitorTransLive_Group (MatchID,TotalScore,BettypeID,BetID,Betteam,GroupID),
    INDEX IX_MatchMonitorTransLive_StatusRule01(StatusRule01),
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
    StatusRule01		TINYINT COMMENT 'Applied For GroupBetting, Headging, Abitrage' DEFAULT 0,
    StatusRule02		TINYINT COMMENT 'Applied For: Fixed Game' DEFAULT 0,
	PRIMARY KEY (TransID),
	INDEX IX_MatchMonitorTransNonLive_TransDate (TransDate),
	INDEX IX_MatchMonitorTransNonLive_Group (MatchID,TotalScore,BettypeID,BetID,Betteam,GroupID),
    INDEX IX_MatchMonitorTransNonLive_StatusRule01(StatusRule01),
    INDEX IX_MatchMonitorTransNonLive_StatusRule02(StatusRule02)
) ENGINE=InnoDB;

/******************ALTER TABLE *************************/
ALTER TABLE MatchMonitorDetails
ADD COLUMN Betteam VARCHAR(10) DEFAULT NULL;

ALTER TABLE MatchMonitorDetails
ADD INDEX IX_MatchMonitorDetails_MatchIDBettypeIDBetIDBetteam(MatchID,BettypeID,BetID,Betteam);

ALTER TABLE MatchMonitorDetails
DROP INDEX IX_MatchMonitorDetails_MatchID_BettypeID;

/******************Init SystemParameter***************************
INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue)
VALUES	(95,'Classification_MatchMonitor_PackSize','Last Classification_MatchMonitor_PackSize.ID','INT','100')
	,	(96,'Classification_MatchMonitor_InProcessMatchID','In_process MatchMonitor.MatchID','INT ',0);
*/
