/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230515@Victoria.Le
	Task:	 	Customer Dangerous Score
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230515@Victoria.Le: 	Initial Writing [Redmine ID: #186191]

*/

	USE CTS_DataCenter;

	CREATE TABLE Customer_DangerousScore
	(
			CustID				BIGINT			NOT NULL
		,	DangerousScore		DECIMAL(6,4) 	NOT NULL
		,	CreateTime			DATETIME(3) 	NOT NULL
		,	LastModifiedDate	DATETIME(3) 	NOT NULL

		,	PRIMARY KEY PK_Customer_DangerousScore (CustID)
		,	INDEX IX_Customer_DangerousScore_CreateTime_LastModifiedDate (CustID, CreateTime, LastModifiedDate)
	);