/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20240530@Casey.Huynh
Task:	 	Match Monitor Group Betting Saba
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20240530@Casey.Huynh: Created [Redmine ID: #192972]
Reviewer:
*/
USE CTS_DataCenter;

#=======================INITIAL SportBettypeSetting==========================
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status)
VALUES (1,0,50,501,'Cricket','Match Winner',NULL,'Match Winner','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,NULL,1,0,'0',0,1)
, (1,0,50,9404,'Cricket','Home Inns Runs',NULL,'Home Inns Runs','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,NULL,1,0,'0',0,1)
, (1,0,50,9405,'Cricket','Away Inns Runs',NULL,'Away Inns Runs','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,NULL,1,0,'0',0,1)
;

SELECT s.*
FROM CTS_DataCenter.SportBettypeSetting s
WHERE BetTypeID IN (20,21,501,9404,9405);

#=======================INITIAL BettypeSetting==========================
INSERT INTO CTS_DataCenter.BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetChoiceType,BetTypeName,BetTypeNameDetailsX,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
VALUES	(501,1,'Home',2,'Match Winner',NULL,'Match Winner',NULL,'h','h',1)
,	(501,2,'Away',2,'Match Winner',NULL,'Match Winner',NULL,'a','a',1)
,	(9404,1,'Over',2,'Home Inns Runs',NULL,'Home Inns Runs',NULL,'o','o',1)
,	(9404,2,'Under',2,'Home Inns Runs',NULL,'Home Inns Runs',NULL,'u','u',1)
,	(9405,1,'Over',2,'Away Inns Runs',NULL,'Away Inns Runs',NULL,'o','o',1)
,	(9405,2,'Under',2,'Away Inns Runs',NULL,'Away Inns Runs',NULL,'u','u',1);

SELECT * From BettypeSetting WHERE BetTypeID IN (20,21,501,9404,9405);

#===========REMOVE Staticlist Sport ListID = 17 (no longer using)==============
DELETE del
FROM StaticList AS del
WHERE ListID = 17;

#=================Initial Rule Setting============================================
INSERT INTO MatchMonitorRuleSetting(RuleGroupID,RuleStatus,RuleGroupDesc,Reason,SportType,LeagueGroupID,LeagueType,ReasonName,SportName,TimeStep,TotalStake,CustStake,TotalTicket,HighStake,HighStakeTicketPercent,MinOdds,MaxOdds,OddsSpread,ModifiedDate,Comments)
VALUES	(1, 1,'Group Betting Detect', 0, 50, NULL,2, 'Group Betting', 'Cricket', 180, 300, NULL,NULL, NULL,NULL,NULL, NULL,NULL,NOW(), 'Time Step In Seconds');

SELECT * FROM MatchMonitorRuleSetting;