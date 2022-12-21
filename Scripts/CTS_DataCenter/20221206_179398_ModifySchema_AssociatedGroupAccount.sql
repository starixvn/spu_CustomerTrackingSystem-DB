/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20221206@Victoria.Le
    Task:	    CTSCustomer: Add columns LastModifiedDate and LastModifiedBy to trigger when transfer an account [Redmine ID: #179398]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;

ALTER TABLE CTS_DataCenter.AssociatedGroupAccount 
ADD  COLUMN LastModifiedDate DATETIME DEFAULT NULL,
ADD  COLUMN LastModifiedBy INT UNSIGNED DEFAULT NULL;

