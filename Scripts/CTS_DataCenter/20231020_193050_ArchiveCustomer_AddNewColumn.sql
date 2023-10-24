/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20231020@Jonas.Huynh
	Task:	 	Archive Customer 
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20231020@Jonas.Huynh: Create Schema [Redmine ID: #193050]

*/

ALTER TABLE CTS_DataCenter.ArchiveCustomer_CTSCustomer
ADD COLUMN CategoryID	SMALLINT DEFAULT NULL AFTER RoleID;
