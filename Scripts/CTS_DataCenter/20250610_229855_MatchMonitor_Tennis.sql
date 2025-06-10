/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250610@Casey.Huynh
Task:	 	Match Monitor, Tenis
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250610@Casey.Huynh: Created [Redmine ID: #229855]

Reviewer:
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.BettypeSetting(BetTypeID,BetteamOrder,BetteamName,BetChoiceType,BetTypeName,BetTypeNameDetailsX,BetTypeNameDisplay,BetIDPattern,BetTeamDB,BetteamShortName,Status,BettypeOrder)
VALUES(@BetTypeID:=153,@BetteamOrder:=1,@BetteamName:='Home',@BetChoiceType:=2,@BetTypeName:='Game Handicap',@BetTypeNameDetailsX:=NULL,@BetTypeNameDisplay:='Game HDP',@BetIDPattern:=NULL,@BetTeamDB:='h',@BetteamShortName:='h',@Status:=1,@BettypeOrder:='58500')
,	(@BetTypeID:=153,@BetteamOrder:=2,@BetteamName:='Away',@BetChoiceType:=2,@BetTypeName:='Game Handicap',@BetTypeNameDetailsX:=NULL,@BetTypeNameDisplay:='Game HDP',@BetIDPattern:=NULL,@BetTeamDB:='a',@BetteamShortName:='a',@Status:=1,@BettypeOrder:='58500')
,	(@BetTypeID:=154,@BetteamOrder:=1,@BetteamName:='Home',@BetChoiceType:=2,@BetTypeName:='Set X Winner',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Winner',@BetIDPattern:='80X',@BetTeamDB:='h',@BetteamShortName:='h',@Status:=1,@BettypeOrder:='58600')
,	(@BetTypeID:=154,@BetteamOrder:=2,@BetteamName:='Away',@BetChoiceType:=2,@BetTypeName:='Set X Winner',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Winner',@BetIDPattern:='80X',@BetTeamDB:='a',@BetteamShortName:='a',@Status:=1,@BettypeOrder:='58600')
,	(@BetTypeID:=155,@BetteamOrder:=1,@BetteamName:='Home',@BetChoiceType:=2,@BetTypeName:='Set X Game Handicap',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Game Handicap',@BetIDPattern:='80X',@BetTeamDB:='h',@BetteamShortName:='h',@Status:=1,@BettypeOrder:='58700')
,	(@BetTypeID:=155,@BetteamOrder:=2,@BetteamName:='Away',@BetChoiceType:=2,@BetTypeName:='Set X Game Handicap',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Game Handicap',@BetIDPattern:='80X',@BetTeamDB:='a',@BetteamShortName:='a',@Status:=1,@BettypeOrder:='58700')
,	(@BetTypeID:=156,@BetteamOrder:=1,@BetteamName:='Over',@BetChoiceType:=2,@BetTypeName:='Set X Total Game Over/Under',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Total Game O/U',@BetIDPattern:='80X',@BetTeamDB:='o',@BetteamShortName:='o',@Status:=1,@BettypeOrder:='58800')
,	(@BetTypeID:=156,@BetteamOrder:=2,@BetteamName:='Under',@BetChoiceType:=2,@BetTypeName:='Set X Total Game Over/Under',@BetTypeNameDetailsX:='1,2,3,4,5',@BetTypeNameDisplay:='Set X Total Game O/U',@BetIDPattern:='80X',@BetTeamDB:='u',@BetteamShortName:='u',@Status:=1,@BettypeOrder:='58800')
;

/*******************************INITIAL SportBettypeSetting*********************************/
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection
,IsMMParlayDetection,MMReason,IsDefaultSelected,Status,SportOrder)
VALUES	(@FunctionID:=1,@LeagueGroupID:=0,@SportTypeID:=5,@BetTypeID:=153,@SportName:='Tennis',@BetTypeName:='Game Handicap',@BetTypeNameDetailsX:=NULL,@BettypeNameDisplay:='Game HDP',@BetChoicePattern:='{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',@BetChoiceType:=2,@BetIDPattern:=NULL,@IsMMDetection:=1,@IsMMParlayDetection:=0,@MMReason:=0,@IsDefaultSelected:=0,@Status:=1,@SportOrder:=550)
	,	(@FunctionID:=1,@LeagueGroupID:=0,@SportTypeID:=5,@BetTypeID:=154,@SportName:='Tennis',@BetTypeName:='Set X Winner',@BetTypeNameDetailsX:='1,2,3,4,5',@BettypeNameDisplay:='Set X Winner',@BetChoicePattern:='{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',@BetChoiceType:=2,@BetIDPattern:='80X',@IsMMDetection:=1,@IsMMParlayDetection:=0,@MMReason:=0,@IsDefaultSelected:=0,@Status:=1,@SportOrder:=550)
	,	(@FunctionID:=1,@LeagueGroupID:=0,@SportTypeID:=5,@BetTypeID:=155,@SportName:='Tennis',@BetTypeName:='Set X Game Handicap',@BetTypeNameDetailsX:='1,2,3,4,5',@BettypeNameDisplay:='Set X Game HDP',@BetChoicePattern:='{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',@BetChoiceType:=2,@BetIDPattern:='80X',@IsMMDetection:=1,@IsMMParlayDetection:=0,@MMReason:=0,@IsDefaultSelected:=0,@Status:=1,@SportOrder:=550)
	,	(@FunctionID:=1,@LeagueGroupID:=0,@SportTypeID:=5,@BetTypeID:=156,@SportName:='Tennis',@BetTypeName:='Set X Total Game Over/Under',@BetTypeNameDetailsX:='1,2,3,4,5',@BettypeNameDisplay:='Set X Total Game O/U',@BetChoicePattern:='{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',@BetChoiceType:=2,@BetIDPattern:='80X',@IsMMDetection:=1,@IsMMParlayDetection:=0,@MMReason:=0,@IsDefaultSelected:=0,@Status:=1,@SportOrder:=550)
;

#=================Initial Rule Setting============================================
INSERT INTO CTS_DataCenter.MatchMonitorRuleSetting(RuleGroupID,RuleStatus,RuleGroupDesc,Reason,SportType,LeagueGroupID,LeagueType,ReasonName,SportName,TimeStep,TotalStake,CustStake,TotalTicket,HighStake,HighStakeTicketPercent,MinOdds,MaxOdds,OddsSpread,ModifiedDate,Comments)
VALUES	(@RuleGroupID:=1,@RuleStatus:=1,@RuleGroupDesc:='Group Betting Detect',@Reason:=0,@SportType:=5,@LeagueGroupID:=0,@LeagueType:=2,@ReasonName:='Group Betting',@SportName:='Tennis',@TimeStep:=180,@TotalStake:=300,@CustStake:=NULL,@TotalTicket:=NULL,@HighStake:=NULL,@HighStakeTicketPercent:=NULL,@MinOdds:=NULL,@MaxOdds:=NULL,@OddsSpread:=NULL,@ModifiedDate:=NOW(),@Comments:='Time Step In Seconds')


/* Check data

SELECT *
FROM CTS_DataCenter.SportBettypeSetting
WHERE FunctionID = 1  AND SportTypeID IN (5) AND LeagueGroupID = 0;

SELECT *
FROM CTS_DataCenter.SportBettypeSetting
WHERE FunctionID = 1  AND SportTypeID IN (5,6) AND LeagueGroupID = 0;

SELECT * FROM CTS_DataCenter.BettypeSetting  WHERE BettypeID IN (153,154,155,156) ;

SELECT * FROM CTS_DataCenter.MatchMonitorRuleSetting WHERE SportType = 5;
*/