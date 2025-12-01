/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20251201@Thomas.Nguyen
Task:	 	
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20251201@Thomas.Nguyen: [CTS] - Upgrade SportType DataType from TINYINT to SMALLINT [Redmine ID: #245209]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE MatchMonitorUserComment
MODIFY COLUMN SportType SMALLINT;