/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250807@Winfred.Pham
Task:	 	script init data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250807@Winfred.Pham: Created [Redmine ID: #235036 - 235035 - 235038]

Reviewer:
*/

USE CTS_DataCenter;


/*******************************SCRIPT FOR #217765*********************************/
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status)
SELECT 2 AS FunctionID,SportTypeID,BetTypeID,SportName,BetTypeName,NULL AS BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection, MMReason, IsDefaultSelected,Status 
FROM SportBettypeSetting 
WHERE  1 = (CASE WHEN SportTypeID = 5 AND BetTypeID IN (153,154,155,156) THEN 1 
				WHEN SportTypeID = 9 AND BetTypeID IN (704,707,708) THEN 1 
				WHEN SportTypeID = 6 AND BetTypeID IN (219,220,704,705) THEN 1 
				ELSE 0 END )
;