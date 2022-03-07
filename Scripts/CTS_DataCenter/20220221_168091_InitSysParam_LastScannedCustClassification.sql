/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Add new table and system parameter for monitor Classification		[Redmine ID: 168091]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('75', 'MonitorNeo4jClassification_LastScannedCustID', 'MonitorNeo4jClassification_LastScannedCustID', 'BIGINT', '0');

USE CTS_Log;
CREATE TABLE `CTS_Log`.`Monitor_Neo4j_CustClassification_Missing` (
	`CustID`		BIGINT UNSIGNED NOT NULL,
	`CategoryID` 	SMALLINT UNSIGNED NOT NULL,
PRIMARY KEY (`CustID`, `CategoryID`));
  