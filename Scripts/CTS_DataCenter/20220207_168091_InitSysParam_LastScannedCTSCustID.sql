/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Add new table and  system parameter		[Redmine ID: 168091]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('68', 'MonitorNeo4jCustomer_LastScannedCTSCustID', 'MonitorNeo4jCustomer_LastScannedCTSCustID', 'BIGINT', '0');

USE CTS_Log
CREATE TABLE `CTS_Log`.`Monitor_Neo4j_CTSCustomer_Missing` (
  `CTSCustID` 	BIGINT UNSIGNED NOT NULL,
  `ScannedDate` DATETIME NULL,
  `IsResolved` 	BIT NULL,
  PRIMARY KEY (`CTSCustID`));
