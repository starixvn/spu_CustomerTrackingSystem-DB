/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250213@Thomas.Nguyen
Task:	 	script init data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250213@Thomas.Nguyen: Created [Redmine ID: #217732]
        - 20250213@Casey.Huynh: Add script [Redmine ID: #217745]
Reviewer:
*/

USE CTS_DataCenter;

/*******************************SCRIPT FOR #217732*********************************/
/*Update SportBettypeSetting*/
UPDATE SportBettypeSetting
SET PriorityOrder = PriorityOrder * 100
WHERE FunctionID = 1 AND SportTypeID = 2 AND LeagueGroupID = 0;

UPDATE SportBettypeSetting
SET PriorityOrder = 650
WHERE FunctionID = 1 AND SportTypeID = 2 AND LeagueGroupID = 0 AND BettypeID = 20;

/*Insert SportBettypeSetting*/
INSERT INTO SportBettypeSetting(FunctionID,SportTypeID,LeagueGroupID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,PriorityOrder,Status)
VALUES (1,2,0,21,'Basketball','1H Moneyline',null,'1H ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,'0',0,900,1);

/*Insert BettypeSetting*/
INSERT INTO BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetChoiceType,BetTypeName,BetTypeNameDetailsX,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
VALUES (21,1,'Home',2,'1H Moneyline',null,'1H ML',null,'h','h',1)
,(21,2,'Away',2,'1H Moneyline',null,'1H ML',null,'a','a',1);


/*******************************SCRIPT FOR #217745*********************************/
#=======================INITIAL SportBettypeSetting==========================
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,PriorityOrder,Status)
VALUES (1,0,50,501,'Cricket','Match Winner',NULL,'Match Winner','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,NULL,1,0,'0',0,9,1)
, (1,0,50,9404,'Cricket','Home Inns Runs',NULL,'Home Inns Runs','{"BetChoiceAway": "o", "BetChoiceHome": "u", "BetChoiceAwayDisplay": "o", "BetChoiceHomeDisplay": "u"}',2,NULL,1,0,'0',0,9,1)
, (1,0,50,9405,'Cricket','Away Inns Runs',NULL,'Away Inns Runs','{"BetChoiceAway": "o", "BetChoiceHome": "u", "BetChoiceAwayDisplay": "o", "BetChoiceHomeDisplay": "u"}',2,NULL,1,0,'0',0,9,1)
;

SELECT s.PriorityOrder, s.*
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