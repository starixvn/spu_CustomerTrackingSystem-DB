/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20251017@Thomas.Nguyen
Task:	 	add index to MBTransaction07 table
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20251017@Thomas.Nguyen: Created [Redmine ID: #241782]
Reviewer:
*/

USE DCS_DataCenter;

ALTER TABLE MBTransaction07
ADD INDEX IX_MBTransaction07_MBAccountID_TransTime(MBAccountID, TransTime);