/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 	20220328@Aries.Nguyen
Task:	 	Init New Categories for Losing PA [Redmine ID: 170468] 	
DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
ALTER TABLE CTSCustomerClassification ADD INDEX IX_CTSCustomerClassification_CategoryID_CustID(CategoryID,CustID,LastScannedDate);
ALTER TABLE CTSCustomerClassification DROP INDEX IX_CTSCustomerClassification_CategoryIDLastScannedDate;