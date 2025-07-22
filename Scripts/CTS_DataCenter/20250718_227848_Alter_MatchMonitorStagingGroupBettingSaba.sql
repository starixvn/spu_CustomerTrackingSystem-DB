/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250701@Logan.Nguyen
Task:	 	add column config and init config
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 	20250718@Logan.Nguyen: Saba Group Betting - Classify Saba Soccer Group Betting into CC3101-3201 [Redmine ID: #227848]

Reviewer:
*/


ALTER TABLE MatchMonitorStagingGroupBettingSabaNonLive
ADD COLUMN IsLicensee TINYINT(1) DEFAULT NULL;
ALTER TABLE MatchMonitorStagingGroupBettingSabaLive
ADD COLUMN IsLicensee TINYINT(1) DEFAULT NULL;
