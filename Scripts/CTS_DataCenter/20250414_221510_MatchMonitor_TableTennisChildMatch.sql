/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250414@Casey.Huynh
Task:	 	Match Monitor, Table Tennis Child match
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250414@Casey.Huynh: Created [Redmine ID: #221510]

Reviewer:
*/

USE CTS_DataCenter;

SELECT *
FROM CTS_DataCenter.SportBettypeSetting
WHERE FunctionID = 1 AND BettypeID IN (1,3,20) AND SportTypeID = 2 AND LeagueGroupID = 0;

/*******************************INITIAL SportBettypeSetting*********************************/
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status)
VALUES 
(1,0,18,1,'Table Tennis','Hadicap',NULL,'HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,NULL,1,0,0,0,1),
(1,0,18,3,'Table Tennis','Over/Under',NULL,'O/U','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,NULL,1,0,0,0,1),
(1,0,18,20,'Table Tennis','Moneyline',NULL,'ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,NULL,1,0,0,0,1)
;
/*******************************UPDATE Sport Order*********************************/
#All Sports Order (Soccer, Basketball, Badminton, Cricket, E-Sports, Table Tennis, Virtual Soccer, Virtual Basketball)
UPDATE SportBettypeSetting
SET SportOrder =  CASE SportTypeID WHEN 1 THEN 1
								   WHEN 2 THEN 100
								   WHEN 9 THEN 200
								   WHEN 50 THEN 300 
                                   WHEN 43 THEN 400
                                   WHEN 18 THEN 500
                                   END
WHERE FunctionID = 1;

SELECT DISTINCT LeagueGroupID, SportName, SportOrder 
FROM CTS_DataCenter.SportBettypeSetting 
WHERE FunctionID = 1 
ORDER BY LeagueGroupID, SportOrder;

#=================Initial Rule Setting============================================
INSERT INTO MatchMonitorRuleSetting(RuleGroupID,RuleStatus,RuleGroupDesc,Reason,SportType,LeagueGroupID,LeagueType,ReasonName,SportName,TimeStep,TotalStake,CustStake,TotalTicket,HighStake,HighStakeTicketPercent,MinOdds,MaxOdds,OddsSpread,ModifiedDate,Comments)
VALUES	(1, 1,'Group Betting Detect', 0, 18, 0, 2, 'Group Betting', 'Table Tennis', 180, 300, NULL,NULL, NULL,NULL,NULL, NULL,NULL,NOW(), 'Time Step In Seconds');
