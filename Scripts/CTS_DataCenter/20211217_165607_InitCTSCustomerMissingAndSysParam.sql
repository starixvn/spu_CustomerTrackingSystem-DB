INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('67', 'MonitorInsertCustomer_LastScannedDate', 'MonitorInsertCustomer_LastScannedDate', 'DATETIME', '2003-01-01');

CREATE TABLE `CTS_DataCenter`.`CTSCustomer_Missing` (
  `CustID` INT UNSIGNED NOT NULL,
  `CustSubID` INT UNSIGNED NOT NULL,
  `UserName` VARCHAR(50) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_ci' NULL,
  `ScannedDate` DATETIME NULL,
  `CreatedDate` DATETIME NULL,
  PRIMARY KEY (`CustSubID`, `CustID`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_bin;