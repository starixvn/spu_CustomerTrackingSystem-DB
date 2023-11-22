/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20231108@Victoria.Le
	Task:	 	New CC for the first 5 Tickets
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20231108@Victoria.Le: 	Update Schema [Redmine ID: #195060]

*/

	USE CTS_DataCenter;

	ALTER TABLE CTSCustomerClassification_History
	ADD COLUMN First5TWGBTicketCount TINYINT UNSIGNED DEFAULT NULL;

	ALTER TABLE CTSCustomerClassification_Log
	ADD COLUMN First5TWGBTicketCount TINYINT UNSIGNED DEFAULT NULL;