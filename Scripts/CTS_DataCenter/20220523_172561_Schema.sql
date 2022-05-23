/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220519@Aries.Nguyen
    Task:	    Disable NAP CM PA flow, add PA directly from CTS [Redmine ID: #172561]
    DBName:		CTS_DataCenter
*/

USE CTS_DataCenter;
ALTER TABLE  CustomerCategory ADD  COLUMN IsPAProbation BIT;

ALTER TABLE CTSCustomerClassification 
ADD  COLUMN IsFromTVS BIT DEFAULT 0,
ADD  COLUMN IsFromTW BIT  DEFAULT 0,
ADD  COLUMN IsFromPAM BIT  DEFAULT 0,
ADD  COLUMN IsDirect BIT DEFAULT NULL;

USE CTS_DataCenter;
UPDATE CustomerCategory 
SET IsPAProbation = IsProbation;