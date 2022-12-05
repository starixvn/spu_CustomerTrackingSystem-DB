/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20221205@Victoria.Le
    Task:	    CTSCustomer: Add columns Danger6 (Saba Soccer) and Danger7 (Saba Baseketball) [Redmine ID: #181208]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

ALTER TABLE CTS_DataCenter.CTSCustomer 
ADD  COLUMN Danger6 TINYINT DEFAULT NULL,
ADD  COLUMN Danger7 TINYINT DEFAULT NULL;

