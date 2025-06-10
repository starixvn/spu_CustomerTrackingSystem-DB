/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250527@Casey.Huynh
Task:	 	Match Monitor, Volleyball
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250527@Casey.Huynh: Created [Redmine ID: #226408]

Reviewer:
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetChoiceType,BetTypeName,BetTypeNameDetailsX,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status,BettypeOrder)
VALUES(@BetTypeID:=705,@BetteamOrder:=1,@BetteamName:='Over',@BetChoiceType:=2,@BetTypeName:='Match Points O/U',@BetTypeNameDetailsX:=NULL,@BetTypeNameDisplay:='Match Points O/U',@BetIDPattern:=NULL,@BetTeamDB:='o',@BetteamShortName:='o',@Status:=1,@BettypeOrder:='59000')
,	(@BetTypeID:=705,@BetteamOrder:=2,@BetteamName:='Under',@BetChoiceType:=2,@BetTypeName:='Match Points O/U',@BetTypeNameDetailsX:=NULL,@BetTypeNameDisplay:='Match Points O/U',@BetIDPattern:=NULL,@BetTeamDB:='u',@BetteamShortName:='u',@Status:=1,@BettypeOrder:='59000')
,	(@BetTypeID:=219,@BetteamOrder:=1,@BetteamName:='Home',@BetChoiceType:=2,@BetTypeName:='Set X Points Handicap',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Points HDP',@BetIDPattern:='80X',@BetTeamDB:='h',@BetteamShortName:='h',@Status:=1,@BettypeOrder:='60000')
,	(@BetTypeID:=219,@BetteamOrder:=2,@BetteamName:='Away',@BetChoiceType:=2,@BetTypeName:='Set X Points Handicap',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Points HDP',@BetIDPattern:='80X',@BetTeamDB:='a',@BetteamShortName:='a',@Status:=1,@BettypeOrder:='60000')
,	(@BetTypeID:=220,@BetteamOrder:=1,@BetteamName:='Over',@BetChoiceType:=2,@BetTypeName:='Set X Total Points Over/Under',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Total Points O/U',@BetIDPattern:='80X',@BetTeamDB:='o',@BetteamShortName:='o',@Status:=1,@BettypeOrder:='61000')
,	(@BetTypeID:=220,@BetteamOrder:=2,@BetteamName:='Under',@BetChoiceType:=2,@BetTypeName:='Set X Total Points Over/Under',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Total Points O/U',@BetIDPattern:='80X',@BetTeamDB:='u',@BetteamShortName:='u',@Status:=1,@BettypeOrder:='61000')
;

/*******************************INITIAL SportBettypeSetting*********************************/
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection
,IsMMParlayDetection,MMReason,IsDefaultSelected,Status,SportOrder)
VALUES 
(1,0,6,704,'Volleyball','Match Points Handicap',NULL,'Match Points HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,NULL,1,0,0,0,1,600),
(1,0,6,705,'Volleyball','Match Points Over/Under',NULL,'Match Points O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,NULL,1,0,0,0,1,600),
(1,0,6,219,'Volleyball','Set X Points Handicap','1,2,3,4,5','Set X Points HDP','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,'80X',1,0,0,0,1,600),
(1,0,6,220,'Volleyball','Set X Total Points Over/Under','1,2,3,4,5','Set X Total Points O/U','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,'80X',1,0,0,0,1,600)
;

#=================Initial Rule Setting============================================
INSERT INTO CTS_DataCenter.MatchMonitorRuleSetting(RuleGroupID,RuleStatus,RuleGroupDesc,Reason,SportType,LeagueGroupID,LeagueType,ReasonName,SportName,TimeStep,TotalStake,CustStake,TotalTicket,HighStake,HighStakeTicketPercent,MinOdds,MaxOdds,OddsSpread,ModifiedDate,Comments)
VALUES	(1, 1,'Group Betting Detect', 0, 6, 0, 2, 'Group Betting', 'Volleyball', 180, 300, NULL,NULL, NULL,NULL,NULL, NULL,NULL,NOW(), 'Time Step In Seconds');

/* Check data

SELECT *
FROM CTS_DataCenter.SportBettypeSetting
WHERE FunctionID = 1 AND BettypeID IN (704,705,219,220) AND SportTypeID = 6 AND LeagueGroupID = 0;

SELECT * FROM CTS_DataCenter.BettypeSetting WHERE BettypeID IN (704,705,219,220);

SELECT * FROM CTS_DataCenter.MatchMonitorRuleSetting WHERE SportType = 1;
*/