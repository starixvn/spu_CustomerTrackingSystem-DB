/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231114@Casey.Huynh
Task:	 	Match Monitor Enhance Match Monitor Group Betting Rule
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240530@Casey.Huynh: Created [Redmine ID: #192972]
Reviewer:
*/
USE CTS_DataCenter;

CREATE TABLE MatchMonitorStagingGroupBettingSabaLive(
		SequenceID			BIGINT UNSIGNED NOT NULL
	,	TransID				BIGINT UNSIGNED NOT NULL
	,	TransDate			DATETIME(3) NOT NULL
    ,	TransDateToSecond	BIGINT NOT NULL
	,	MatchID				INT NOT NULL
	,	SportType			INT NOT NULL
	,	ScoreDiff			INT NOT NULL
	,	BettypeID			INT NOT NULL
	,	Betteam				VARCHAR(10) DEFAULT NULL
	,	CustID				BIGINT UNSIGNED DEFAULT NULL
	,	Stake				DECIMAL(20,4) DEFAULT NULL
	,	GroupID				INT DEFAULT '0'
	,	LiveHomeScore		INT DEFAULT NULL
	,	LiveAwayScore		INT DEFAULT NULL
	,	EventDate			DATE DEFAULT NULL
	,	KickOffTime			DATETIME DEFAULT NULL
	,	EventStatus			VARCHAR(50) DEFAULT NULL
	,	HomeID				INT DEFAULT NULL
	,	AwayID				INT DEFAULT NULL
	,	LeagueID			INT DEFAULT NULL	
	,	LeagueName			VARCHAR(500) DEFAULT NULL
	,	IsMajorLeague		TINYINT(1) DEFAULT NULL
    ,	InsertTime			DATETIME(3) DEFAULT NULL
	,	PRIMARY KEY (SequenceID)
	,	INDEX IX_MatchMonitorStagingGroupBettingSabaLive_TransToDate(TransToDate)
	,	INDEX IX_MatchMonitorStagingGroupBettingSabaLive_RuleGroup(MatchID,ScoreDiff,BettypeID,Betteam,GroupID)
) ENGINE=InnoDB;


CREATE TABLE MatchMonitorStagingGroupBettingSabaNonLive(
		SequenceID			BIGINT UNSIGNED NOT NULL
	,	TransID				BIGINT UNSIGNED NOT NULL
	,	TransDate			DATETIME(3) NOT NULL
    ,	TransDateToSecond	BIGINT NOT NULL
	,	MatchID				INT NOT NULL
	,	SportType			INT NOT NULL
	,	ScoreDiff			INT NOT NULL
	,	BettypeID			INT NOT NULL
	,	Betteam				VARCHAR(10) DEFAULT NULL
	,	CustID				BIGINT UNSIGNED DEFAULT NULL
	,	Stake				DECIMAL(20,4) DEFAULT NULL
	,	GroupID				INT DEFAULT '0'
	,	LiveHomeScore		INT DEFAULT NULL
	,	LiveAwayScore		INT DEFAULT NULL
	,	EventDate			DATE DEFAULT NULL
	,	KickOffTime			DATETIME DEFAULT NULL
	,	EventStatus			VARCHAR(50) DEFAULT NULL
	,	HomeID				INT DEFAULT NULL
	,	AwayID				INT DEFAULT NULL
	,	LeagueID			INT DEFAULT NULL	
	,	LeagueName			VARCHAR(500) DEFAULT NULL
	,	IsMajorLeague		TINYINT(1) DEFAULT NULL
    ,	InsertTime			DATETIME(3) DEFAULT NULL
	,	PRIMARY KEY (SequenceID)
	,	INDEX IX_MatchMonitorStagingGroupBettingSabaLive_TransToDate(TransToDate)
	,	INDEX IX_MatchMonitorStagingGroupBettingSabaLive_RuleGroup(MatchID,ScoreDiff,BettypeID,Betteam,GroupID)
) ENGINE=InnoDB;


