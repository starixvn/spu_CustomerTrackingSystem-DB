/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230403@Victoria.Le
	Task:	 	TVS Abnormal Bet by Sporttype and Abnormal Account
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230403@Victoria.Le: 	Update Schema [Redmine ID: #185319]

*/

	USE CTS_DataCenter;

	ALTER TABLE CTSCustomerClassification
	ADD COLUMN IsParlay 	BIT(1) 		DEFAULT NULL
,	ADD COLUMN SportType 	SMALLINT 	DEFAULT NULL
,	ADD COLUMN IssueTypeID 	TINYINT 	DEFAULT NULL;

	ALTER TABLE CTSCustomerClassificationOldCategory
	ADD COLUMN IsParlay 	BIT(1) 		DEFAULT NULL
,	ADD COLUMN SportType 	SMALLINT 	DEFAULT NULL
,	ADD COLUMN IssueTypeID 	TINYINT 	DEFAULT NULL;

	ALTER TABLE CTSCustomerClassification_History
	ADD COLUMN IsParlay 	BIT(1) 		DEFAULT NULL
,	ADD COLUMN SportType 	SMALLINT 	DEFAULT NULL
,	ADD COLUMN IssueTypeID 	TINYINT 	DEFAULT NULL;

	ALTER TABLE CTSCustomerClassification_Log
	ADD COLUMN IsParlay 	BIT(1) 		DEFAULT NULL
,	ADD COLUMN SportType 	SMALLINT 	DEFAULT NULL
,	ADD COLUMN IssueTypeID 	TINYINT 	DEFAULT NULL;

	ALTER TABLE TVSVoidRequest_History
	ADD COLUMN IsParlay 	BIT(1) 		DEFAULT NULL
,	ADD COLUMN SportType 	SMALLINT 	DEFAULT NULL
,	ADD COLUMN IssueTypeID 	TINYINT 	DEFAULT NULL;


