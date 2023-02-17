/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20230208@Victoria.Le
Task:	 	Update Odds range for fixed game rule
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230208@Victoria.Le: Created [Redmine ID: #183277]
Reviewer:
*/

USE CTS_DataCenter;

UPDATE	MatchMonitorRuleSetting
SET 	MinOdds = 0.4
	,	MaxOdds = 0.4
WHERE 	RuleGroupID = 2;
