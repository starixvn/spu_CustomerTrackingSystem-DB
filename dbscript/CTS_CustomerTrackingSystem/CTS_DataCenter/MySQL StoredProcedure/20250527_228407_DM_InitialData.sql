/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250527_228407@Tony.Nguyen
Task:	 	script init data
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250527@Tony.Nguyen: Created [Redmine ID: #228407]

Reviewer:
*/

USE CTS_DataCenter;


/*******************************SCRIPT FOR #228407*********************************/
INSERT INTO CTS_DataCenter.SportBettypeSetting
(FunctionID,LeagueGroupID,SportTypeID,BetTypeID,SportName,BetTypeName,BettypeNameDetailsX,BettypeNameDisplay,BetChoicePattern,BetChoiceType,BetIDPattern,IsMMDetection,IsMMParlayDetection,MMReason,IsDefaultSelected,Status)
VALUES
('2', '0', '0', '5','', '1X2', NULL, '1X2', NULL, '1', NULL, '0', '0', NULL, '1', '1'),
('2', '0', '0', '15', '', '1H 1X2', NULL, '1H 1X2', NULL, '1', NULL, '0', '0', NULL, '1', '1');