/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220818@Aries.Nguyen
    Task:	 	Customer Class - Update Saba Danger Level  [Redmine ID: #176224] 
    DBName:		CTS_DataCenter
*/
USE CTS_DataCenter;
CREATE TABLE `CTSCustomerSabaDangerLevel` (
   CustID bigint unsigned NOT NULL,
   SportType int, 
   Created datetime  DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (CustID, SportType)
) ENGINE=InnoDB;
 
ALTER TABLE CTS_DataCenter.CustomerCategory 
ADD COLUMN SabaSportType JSON DEFAULT NULL COMMENT '1:Soccer or 2:Basketball';


UPDATE CTS_DataCenter.CustomerCategory 
SET SabaSportType = '[1,2]'
WHERE CustomerClass IN (8, 86, 9, 96);

UPDATE CTS_DataCenter.CustomerCategory 
SET SabaSportType = '[2]'
WHERE CustomerClass IN (10, 106, 131, 132);
 

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`)
VALUES ('102', 'SabaDangerLevel_LastHistoryID', 'SabaDangerLevel_LastHistoryID', 'BIGINT', '0');

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`)
VALUES ('103', 'SabaDangerLevel_LastCategoryID', 'SabaDangerLevel_LastCategoryID', 'BIGINT', '0');

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`)
VALUES ('104', 'SabaDangerLevel_LastCustID', 'SabaDangerLevel_LastCustID', 'BIGINT', '0');
 
 INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`)
VALUES ('105', 'SabaDangerLevel_ScanBatchSize', 'SabaDangerLevel_ScanBatchSize', 'BIGINT', '1000');

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`)
VALUES ('106', 'SabaDangerLevel_InitBatchSize', 'SabaDangerLevel_InitBatchSize', 'BIGINT', '1000');
