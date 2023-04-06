/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
	Creator:	20230403@Victoria.Le
	Task:	 	TVS Abnormal Bet by Sporttype and Abnormal Account
	Server:  	CTSMain
	DBName:		CTS_Archive

Revisions: 
		- 20230403@Victoria.Le: 	Update Schema [Redmine ID: #185319]

*/
	USE CTS_Archive;

	ALTER TABLE CTSCustomerClassification_History_Archive
	ADD COLUMN IsParlay 	BIT(1) 		DEFAULT NULL
,	ADD COLUMN SportType 	SMALLINT 	DEFAULT NULL
,	ADD COLUMN IssueTypeID 	TINYINT 	DEFAULT NULL;
