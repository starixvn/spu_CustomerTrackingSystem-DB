/*
Creator: 	20200603@Harvey
Task:	 	CTS_Schema
Server:  	Slave
DBName:		CTS_DataCenter

Revisions: 
		- 20200603@Harvey: Modify for table
Reviewer:
*/

ALTER TABLE  CTS_DataCenter.CTSCustomer ADD COLUMN RegisterName varchar(50) NULL, ALGORITHM=INSTANT;
ALTER TABLE CTS_DataCenter.CTSCustomer ADD INDEX IX_CTSCustomer_RegisterName (RegisterName);
-- DROP INDEX IX_FullText_CTSCustomer_UserName_UserName2 ON CTS_DataCenter.CTSCustomer;