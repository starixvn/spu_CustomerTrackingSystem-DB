/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230428@Jonas.Huynh
	Task:	 	Normal Renovation
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230428@Jonas.Huynh: Create Schema [Redmine ID: #186678]

*/

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History
ADD COLUMN PerformanceTime	DATETIME DEFAULT NULL;

ALTER TABLE CTS_DataCenter.CTSCustomerClassification_Log
ADD COLUMN PerformanceTime	DATETIME DEFAULT NULL;

ALTER TABLE CTS_Archive.CTSCustomerClassification_History_Archive
ADD COLUMN PerformanceTime	DATETIME DEFAULT NULL;