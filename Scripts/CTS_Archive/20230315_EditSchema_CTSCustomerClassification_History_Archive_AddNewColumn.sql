/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
	Creator:	20230315@Victoria.le
	Task:	 	Robot Imperva
	Server:  	CTSMain
	DBName:		CTS_Archive

Revisions: 
		- 20230315@Victoria.le: 	Update Schema - Initial Data [Redmine ID: #184773]

*/
USE CTS_Archive;

ALTER TABLE CTSCustomerClassification_History_Archive
ADD COLUMN IsFromImperva BIT(1) DEFAULT 0;
