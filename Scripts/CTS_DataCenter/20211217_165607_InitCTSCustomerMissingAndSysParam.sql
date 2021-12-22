/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20211222@Harvey.Nguyen
Task:	 	Monitor insert new customer
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20211222@Harvey.Nguyen: Created [Redmine ID: #165607]
Reviewer:
*/

INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) 
VALUES ('67', 'MonitorInsertCustomer_LastScannedDate', 'MonitorInsertCustomer_LastScannedDate', 'DATETIME', '2003-01-01');

CREATE TABLE `CTS_DataCenter`.`CTSCustomer_Missing` (
  `CustID` 		INT UNSIGNED NOT NULL,
  `CustSubID` 	INT UNSIGNED NOT NULL,
  `UserName` 	VARCHAR(50) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_ci' NULL,
  `ScannedDate` DATETIME NULL,
  `CreatedDate` DATETIME NULL,
  PRIMARY KEY (`CustID`, `CustSubID`))
ENGINE = InnoDB;