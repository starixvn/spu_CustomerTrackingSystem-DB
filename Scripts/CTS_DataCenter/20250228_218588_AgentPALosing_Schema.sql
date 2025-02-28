/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250528@Thomas.Nguyen
Task:	 	Agent PA Losing
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250528@Thomas.Nguyen: Created [Redmine ID: #218588]
Reviewer:
*/

USE CTS_DataCenter;

DROP TABLE IF EXISTS CTSCustomerClassificationAgency_DailyPAQueue;
CREATE TABLE CTSCustomerClassificationAgency_DailyPAQueue (
    ID bigint unsigned NOT NULL AUTO_INCREMENT,
    CustID bigint unsigned NOT NULL,
    CreatedTime datetime NOT NULL,
    PRIMARY KEY (ID),
    KEY IX_CTSCustCCAgency_DailyPAQueue_CreatedTime_CustID (CreatedTime,CustID)
) ENGINE=InnoDB;

ALTER TABLE CustomerCategorySettingsAgency
ADD COLUMN FlowPADailyScan TINYINT DEFAULT 0;

UPDATE CustomerCategorySettingsAgency
SET FlowPADailyScan = 1
WHERE ParentID = 120000;

INSERT INTO CTS_DataCenter.SystemParameter(ParameterID,ParameterName,ParameterDesc,ParameterDataType,ParameterValue) 
VALUES(186,'DailyScan_PA_Agency_BatchSize','DailyScan_PA_Agency_BatchSize','BIGINT','500')
,(187,'DailyScan_PA_Agency_LastScannedTime','DailyScan_PA_Agency_LastScannedTime','DATETIME','');
