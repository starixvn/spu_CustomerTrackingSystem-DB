/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20221215@Casey.Huynh
Task:	 	Match Monitor Irrigation
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20221215@Casey.Huynh: Created [Redmine ID: #181883]
Reviewer:
*/

ALTER TABLE MatchMonitorDetails
DROP INDEX UK_MatchMonitorDetails_MatchRuleGroup
, ADD INDEX UK_MatchMonitorDetails_MatchGroup(MatchID,LiveIndicator,TotalScore,BettypeID,BetID,Reason,Betteam,GroupID,EventDate);