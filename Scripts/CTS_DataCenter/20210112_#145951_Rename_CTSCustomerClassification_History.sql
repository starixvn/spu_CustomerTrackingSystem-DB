/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20210112@Aries.Nguyen
Task:	 	Rename table  CTSCustomerClassification_History for backup [Redmine ID: 145951]
DBName:		CTS_DataCenter
Revisions: 
	-	[20210112@Aries.Nguyen]: Rename table  CTSCustomerClassification_History for backup
*/

USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CTSCustomerClassification_History RENAME TO CTS_DataCenter.CTSCustomerClassification_History_Backup, ALGORITHM=INSTANT;