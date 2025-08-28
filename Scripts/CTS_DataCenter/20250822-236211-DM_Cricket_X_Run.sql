/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250822@Logan.Nguyen
Task:	 	Match Monitor, GroupBettingCricket
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250822@Logan.Nguyen: Created [Redmine ID: #236211]


Reviewer:
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status)
SELECT 2 AS FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,NULL AS BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,0 as IsMMDetection, 0 as IsMMParlayDetection, MMReason, IsDefaultSelected,Status 
FROM SportBettypeSetting 
WHERE  1 = (CASE WHEN SportTypeID = 50 AND BetTypeID IN (9608,9607,9411,9410,9429,9428) THEN 1 
				ELSE 0 END )
AND FunctionID = 1;



