/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250701@Logan.Nguyen
Task:	 	add column config and init config
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250701@Logan.Nguyen: Created [Redmine ID: #229875]

Reviewer:
*/


ALTER TABLE MatchMonitorStagingGroupBettingSabaNonLive
ADD COLUMN IsLicensee TINYINT(1) DEFAULT 0;
ALTER TABLE MatchMonitorStagingGroupBettingSabaLive
ADD COLUMN IsLicensee TINYINT(1) DEFAULT 0;
