/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250318@Jonas.Huynh
Task:	 	Danger Monitor - Cricket
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250318@Jonas.Huynh: Created [Redmine ID: #217765]
Reviewer:
*/

USE CTS_DataCenter;

INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BetTypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status)
VALUES 
(2,0,50,501,'','Match Winner',NULL,'Match Winner','{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "a", "BetChoiceHomeDisplay": "h"}',2,NULL,0,0,NULL,0,1),
(2,0,50,9404,'','Home Inns Runs',NULL,'Home Inns Runs','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,NULL,0,0,NULL,0,1),
(2,0,50,9405,'','Away Inns Runs',NULL,'Away Inns Runs','{"BetChoiceAway": "u", "BetChoiceHome": "o", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}',2,NULL,0,0,NULL,0,1)
;