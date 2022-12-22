/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20221003@Harvey.Nguyen
Task:	 	Change table name: CTSCustomerClassificationOldPA -> CTSCustomerClassificationOldCategory
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20221003@Harvey.Nguyen: Created [Redmine ID: #178601]
Reviewer:
*/

USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CTSCustomerClassificationOldPA RENAME TO  CTS_DataCenter.CTSCustomerClassificationOldCategory;