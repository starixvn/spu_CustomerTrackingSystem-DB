/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20221205@Victoria.Le
    Task:	    CTSCustomer: Add columns DangerSabaSc (Saba Soccer) and DangerSabaBkb (Saba Baseketball) [Redmine ID: #181208]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

ALTER TABLE CTS_DataCenter.CTSCustomer 
ADD  COLUMN DangerSabaSc TINYINT DEFAULT 0,
ADD  COLUMN DangerSabaBkb TINYINT DEFAULT 0;

