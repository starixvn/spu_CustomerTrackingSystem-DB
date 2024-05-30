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
    ,	InsertTime			DATETIME(3) DEFAULT NULL
	,	PRIMARY KEY (SequenceID)
	,	INDEX IX_MatchMonitorStagingGroupBettingSabaLive_TransDateToSecond(TransDateToSecond)
	,	INDEX IX_MatchMonitorStagingGroupBettingSabaLive_RuleGroup(MatchID, ScoreDiff, BettypeID, Betteam, GroupID)
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
    ,	InsertTime			DATETIME(3) DEFAULT NULL
	,	PRIMARY KEY (SequenceID)
	,	INDEX IX_MatchMonitorStagingGroupBettingSabaLive_TransDateToSecond(TransDateToSecond)
	,	INDEX IX_MatchMonitorStagingGroupBettingSabaLive_RuleGroup(MatchID, ScoreDiff, BettypeID, Betteam, GroupID)
) ENGINE=InnoDB;

ALTER TABLE MatchMonitor
ADD COLUMN LeagueGroupID INT AFTER LeagueID;

ALTER TABLE SportBettypeSetting
ADD COLUMN LeagueGroupID INT DEFAULT 0 AFTER SportTypeID,
DROP PRIMARY KEY,
ADD PRIMARY KEY (FunctionID,LeagueGroupID,SportTypeID,BetTypeID);

ALTER TABLE MatchMonitorRuleSetting
ADD COLUMN LeagueGroupID INT DEFAULT 0 AFTER Reason;

#=======================INITIAL SPORTSETTING
# 4 rows
INSERT INTO CTS_DataCenter.SportBettypeSetting(FunctionID, LeagueGroupID, SportTypeID, BetTypeID, SportName, BetTypeName, BetTypeNameDetailsX, BettypeNameDisplay, BetChoicePattern, BetChoiceType, BetIDPattern, IsMMDetection, MMReason, IsDefaultSelected, PriorityOrder, Status)
SELECT
		FunctionID
	,	42 LeagueGroupID
	,	SportTypeID
	,	BetTypeID
	,	SportName
	,	BetTypeName
	,	BetTypeNameDetailsX
	,	BettypeNameDisplay
	,	BetChoicePattern
	,	BetChoiceType
	,	BetIDPattern
	,	IsMMDetection
	,	0 AS MMReason
	,	IsDefaultSelected
	,	PriorityOrder
	,	Status
FROM SportBettypeSetting
WHERE FunctionID = 1 AND SportTypeID = 1 AND IsMMDetection = 1;

#=======================INITIAL SERVICE PARAMETERs================================
# DELETE del FROM SystemParameter del WHERE ParameterID IN (162, 163, 164);
INSERT INTO SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUE	(162,'MatchMonitor_GBSabaLive_LastSequenceID', NULL,'BIGINT UNSIGNED',0)
	,	(163,'MatchMonitor_GBSabaNonLive_LastSequenceID', NULL,'BIGINT UNSIGNED',0)
	,	(164,'MatchMonitor_GBSabaNonLive_BatchSize', NULL,'INT',5000);
#=================Initial Rule Setting============================================

INSERT INTO MatchMonitorRuleSetting(RuleGroupID, RuleGroupDesc, Reason, LeagueGroupID, SportType, ReasonName, SportName, TimeStep, TotalStake, HighStake, ModifiedDate, Comments)
VALUES	(6, 'Group Betting Saba Detect', 0, 42, 1, 'Group Betting', NULL, 60, 500, NULL, NOW(), 'Time Step In Seconds');
