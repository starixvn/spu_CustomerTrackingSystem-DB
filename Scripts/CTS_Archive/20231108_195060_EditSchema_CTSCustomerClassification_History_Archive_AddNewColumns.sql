/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
	Creator:	20231108@Victoria.Le
	Task:	 	New CC for the first 5 Tickets
	Server:  	CTSMain
	DBName:		CTS_Archive

Revisions: 
		- 20231108@Victoria.Le: 	Update Schema [Redmine ID: #195060]

*/
	USE CTS_Archive;

	ALTER TABLE CTSCustomerClassification_History_Archive
	ADD COLUMN First5TWGBTicketCount TINYINT UNSIGNED DEFAULT NULL;
