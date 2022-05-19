/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220519@Aries.Nguyen
    Task:	     Init cust info: IsLicensee, IsInternal [Redmine ID: #202204]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

ALTER TABLE CTSCustomer ADD  COLUMN IsLicensee BIT;
ALTER TABLE CTSCustomer ADD  COLUMN IsInternal BIT;


