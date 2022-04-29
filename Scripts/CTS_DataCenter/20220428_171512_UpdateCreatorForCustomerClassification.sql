/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20220428@Casey.Huynh
Task:	 	Update Creator for CustomerClassification
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20220428@Casey.Huynh.Huynh: Update Creator for CustomerClassification [Redmine ID: #171512]
Reviewer:
*/

USE CTS_DataCenter;

ALTER TABLE PinCustomerCategory
		ADD COLUMN CreatedBy INT UNSIGNED;

ALTER TABLE TaggingExclusion
		ADD COLUMN CreatedBy INT UNSIGNED;
    
