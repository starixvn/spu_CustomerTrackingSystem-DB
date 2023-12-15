/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231215@Casey.Huynh
Task:	 	Adjust betteam of Basketball - 1H Over/Under
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231215@Casey.Huynh: Created [Redmine ID: #196396]
Reviewer:
*/
SELECT *
FROM SportBettypeSetting
WHERE SportTypeID = 2 AND  BettypeID = 8;

UPDATE SportBettypeSetting
SET BetChoicePattern = '{"BetChoiceAway": "a", "BetChoiceHome": "h", "BetChoiceAwayDisplay": "u", "BetChoiceHomeDisplay": "o"}'
WHERE SportTypeID = 2 AND BettypeID = 8;
