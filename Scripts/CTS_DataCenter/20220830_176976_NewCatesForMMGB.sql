/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202200830@Casey.Huynh
Task:	 	NewCatesForMMGB
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20220726@Casey.Huynh: Created [Redmine ID: #176976]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE MatchMonitorDetails 
ADD COLUMN IsExistingHighStake BOOLEAN DEFAULT 0
, ADD INDEX IX_MatchMonitorDetails_IsExistingHighStake(IsExistingHighStake);