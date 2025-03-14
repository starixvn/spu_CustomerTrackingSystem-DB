/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250313@Thomas.Nguyen
Task:	 	script init data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250313@Thomas.Nguyen: Created [Redmine ID: #219636]

Reviewer:
*/

USE CTS_DataCenter;

/*******************************SCRIPT FOR #217732*********************************/
/*Insert SportBettypeSetting
INSERT INTO SportBettypeSetting(FunctionID,SportTypeID,LeagueGroupID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status)
VALUES (1,2,0,21,'Basketball','1H Moneyline',null,'1H ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,'0',0,1);

/*Insert BettypeSetting*/
INSERT INTO BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetChoiceType,BetTypeName,BetTypeNameDetailsX,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
VALUES (21,1,'Home',2,'1H Moneyline',null,'1H ML',null,'h','h',1)
,(21,2,'Away',2,'1H Moneyline',null,'1H ML',null,'a','a',1);*/


/*******************************SCRIPT FOR #219681*********************************/
#=======================INITIAL SportBettypeSetting==========================
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,SportTypeID,LeagueGroupID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status)
VALUES (1,9,0,20,'Badminton','Moneyline',null,'ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,'0',0,1) 
, (1,9,0,704,'Badminton','Match Points Handicap',null,'Match Points HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,'0',0,1)
, (1,9,0,707,'Badminton','Game X Winner',null,'Game X Winner','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,'0',0,1)
, (1,9,0,708,'Badminton','Game X Points Handicap',null,'Game X Points HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,'0',0,1)
;

SELECT s.*
FROM CTS_DataCenter.SportBettypeSetting s
WHERE SportTypeID = 9 AND BetTypeID IN (20,704,707,708);

#=======================INITIAL BettypeSetting==========================
INSERT INTO CTS_DataCenter.BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetChoiceType,BetTypeName,BetTypeNameDetailsX,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
VALUES	(704,1,'Home',2,'Match Points Handicap',NULL,'Match Points HDP',NULL,'h','h',17250)
,	(704,2,'Away',2,'Match Points Handicap',NULL,'Match Points HDP',NULL,'a','a',17250)
,	(707,1,'Home',2,'Game X Winner',NULL,'Game X Winner',NULL,'h','h',17500)
,	(707,2,'Away',2,'Game X Winner',NULL,'Game X Winner',NULL,'a','a',17500)
,	(708,1,'Home',2,'Game X Points Handicap',NULL,'Game X Points HDP',NULL,'h','h',17750)
,	(708,2,'Away',2,'Game X Points Handicap',NULL,'Game X Points HDP',NULL,'a','a',17750);

SELECT * From BettypeSetting WHERE BetTypeID IN (20,704,707,708);

#=================Initial Rule Setting============================================
INSERT INTO MatchMonitorRuleSetting(RuleGroupID,RuleStatus,RuleGroupDesc,Reason,SportType,LeagueGroupID,LeagueType,ReasonName,SportName,TimeStep,TotalStake,CustStake,TotalTicket,HighStake,HighStakeTicketPercent,MinOdds,MaxOdds,OddsSpread,ModifiedDate,Comments)
VALUES	(1, 1,'Group Betting Detect', 0, 9, 0,2, 'Group Betting', 'Badminton', 180, 300, NULL,NULL, NULL,NULL,NULL, NULL,NULL,NOW(), 'Time Step In Seconds');

SELECT * FROM MatchMonitorRuleSetting;