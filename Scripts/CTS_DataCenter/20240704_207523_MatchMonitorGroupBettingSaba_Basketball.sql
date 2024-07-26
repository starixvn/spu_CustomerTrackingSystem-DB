/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240704@Casey.Huynh
Task:	 	Match Monitor Group Betting Saba 
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240704@Casey.Huynh: Created [Redmine ID: #207523]
Reviewer:
*/
USE CTS_DataCenter;
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
WHERE FunctionID = 1 AND SportTypeID = 2 AND IsMMDetection = 1;

#=================Initial Rule Setting============================================

DELETE FROM MatchMonitorRuleSetting WHERE RuleGroupID = 6;

INSERT INTO MatchMonitorRuleSetting(RuleGroupID, RuleGroupDesc, Reason, LeagueGroupID, SportType, ReasonName, SportName, TimeStep, TotalStake, CustStake, HighStake, ModifiedDate, Comments)
VALUES	(6, 'Group Betting Saba Detect', 0, 42, 1, 'Group Betting', 'Soccer', 60, 500, 50, NULL, NOW(), 'Time Step In Seconds')
,	(6, 'Group Betting Saba Detect', 0, 42, 2, 'Group Betting', 'BasketBall', 60, 300, 50,  NULL, NOW(), 'Time Step In Seconds');
