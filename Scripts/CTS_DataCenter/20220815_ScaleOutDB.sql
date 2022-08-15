/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	202208150@Casey.Huynh
Task:	 	Scale Out DB
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 202208150@Casey.Huynh: Created [Redmine ID: #176472]
Reviewer:
*/

USE CTS_DataCenter;

#================================================
ALTER TABLE MatchMonitorStagingLive
ADD COLUMN SequenceID BIGINT;

ALTER TABLE MatchMonitorStagingNonLive
ADD COLUMN SequenceID BIGINT;

