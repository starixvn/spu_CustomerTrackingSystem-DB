/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202311203@Casey.Huynh
Task:	 	Match Monitor Adjust GB Esport Setting 
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 202311203@Casey.Huynh: Created [Redmine ID: #196396]
Reviewer:
*/
USE CTS_DataCenter;

SELECT * FROM MatchMonitorRuleSetting WHERE RuleGroupID = 1 AND SportType = 43;

UPDATE MatchMonitorRuleSetting
SET TotalStake = 300
WHERE RuleGroupID = 1 AND SportType = 43;
