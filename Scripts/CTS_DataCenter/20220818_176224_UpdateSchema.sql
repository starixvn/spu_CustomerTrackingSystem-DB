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
WHERE CategoryID IN (52,54,58,72,74,78,92,94,98,112,114,118,132,134,138,152,154,158);

UPDATE CTS_DataCenter.CustomerCategory 
SET SabaSportType = '[2]'
WHERE CategoryID IN (53,55,59,73,75,79,93,95,99,113,115,119,133,135,139,153,155,159,163,164);
 

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
