/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20231016@Casey.Huynh
Task:	 	Enhance MatchMonitor Rule
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20231016@Casey.Huynh: Enhance Rule for BasketBall. Adjust Group Stake to 300 [Redmine ID: #195473]
Reviewer:
*/
USE CTS_DataCenter;
UPDATE MatchMonitorRuleSetting
SET TotalStake = 300
WHERE RuleGroupID = 1 AND SportType = 2;

SELECT * FROM CTS_DataCenter.MatchMonitorRuleSetting WHERE RuleGroupID = 1 AND SportType = 2;
