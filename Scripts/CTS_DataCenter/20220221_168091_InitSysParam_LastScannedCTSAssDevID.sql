/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Add new table and system parameter for Association		[Redmine ID: 168091]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('71', 'MonitorNeo4jAssociation_LastScannedCTSAssDevID', 'MonitorNeo4jAssociation_LastScannedCTSAssDevID', 'BIGINT', '0');

USE CTS_Log;
CREATE TABLE `CTS_Log`.`Monitor_Neo4j_AssByDevice_Missing` (
	`CTSAssDevID`	BIGINT UNSIGNED NOT NULL,
	`CTSCustID` 	BIGINT UNSIGNED NOT NULL,
	`DCSDeviceID`	BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`CTSAssDevID`));
