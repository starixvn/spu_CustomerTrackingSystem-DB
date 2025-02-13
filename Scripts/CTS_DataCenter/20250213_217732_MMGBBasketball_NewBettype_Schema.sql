/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250213@Thomas.Nguyen
Task:	 	script init data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250213@Thomas.Nguyen: Created [Redmine ID: #217732]
Reviewer:
*/

USE CTS_DataCenter;

UPDATE SportBettypeSetting
SET PriorityOrder = PriorityOrder + 1
WHERE FunctionID = 1 AND SportTypeID = 2 AND LeagueGroupID = 0 AND BettypeID = 609;

INSERT INTO SportBettypeSetting(FunctionID,SportTypeID,LeagueGroupID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,PriorityOrder,Status)
VALUES (1,2,0,21,'Basketball','1H Moneyline',null,'1H ML','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,null,1,0,'0',0,10,1);

INSERT INTO BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetChoiceType,BetTypeName,BetTypeNameDetailsX,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status)
VALUES (21,1,'Home',2,'1H Moneyline',null,'1H ML',null,'h','h',1)
,(21,2,'Away',2,'1H Moneyline',null,'1H ML',null,'a','a',1);