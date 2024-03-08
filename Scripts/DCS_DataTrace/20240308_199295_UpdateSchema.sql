/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20240221@Jonathan.Doan
	Task:	 	Add more columns into FPSClientTransaction_Exception [Redmine ID: #200900]
	Server:  	Master
	DBName:		DCS_DataTrace
    
	Revisions: 
			- 20240221@Jonathan.Doan: Created [Redmine ID: #200900]
	Reviewer:
*/
USE DCS_DataTrace;

CREATE TABLE `LoginTransactionSummary_Daily` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `TransDate` DATETIME NOT NULL,
  `SubscriberID` INT UNSIGNED DEFAULT NULL,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  `RawUserAgentID` BIGINT UNSIGNED DEFAULT NULL,
  `Flagged` SMALLINT DEFAULT NULL,
  `TotalTrans` INT UNSIGNED DEFAULT NULL,
  `TotalNoDeviceTrans` INT UNSIGNED DEFAULT NULL,
  `TotalNoFPDeviceTrans` INT UNSIGNED DEFAULT NULL,
  `FlaggedGroupID` SMALLINT UNSIGNED DEFAULT NULL,
  `FirstLoginTransTime` DATETIME DEFAULT NULL,
  `LastLoginTransTime` DATETIME DEFAULT NULL,
  `CreatedTime` DATETIME DEFAULT NULL,
  `ModifiedTime` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`,`TransDate`),
  UNIQUE KEY `UX_LoginTransactionSummary_Daily_Group` (`TransDate`,`SubscriberID`,`AccountID`,`RawUserAgentID`,`Flagged`),
  KEY `IX_LoginTransactionSummary_Daily_FlaggedGroupID` (`TransDate`,`SubscriberID`,`FlaggedGroupID`),
  KEY `IX_LoginTransactionSummary_Daily_AccountIDTransDate` (`AccountID`,`TransDate`)
) ENGINE=InnoDB;

ALTER TABLE DCS_DataTrace.LoginTransactionSummaryBySubscriber
ADD COLUMN TotalNoDeviceTrans INT UNSIGNED DEFAULT NULL,
ADD COLUMN TotalNoFPDeviceTrans INT UNSIGNED DEFAULT NULL;

CREATE TABLE `RawUserAgent` (
  `ID` BIGINT UNSIGNED NOT NULL,
  `RawUserAgent` VARCHAR(1000) NOT NULL,
  `BrowserID` BIGINT UNSIGNED DEFAULT NULL,
  `OSID` BIGINT UNSIGNED DEFAULT NULL,
  `DeviceTypeID` BIGINT UNSIGNED DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  KEY `IX_RawUserAgent_BrowserID` (`BrowserID`),
  KEY `IX_RawUserAgent_OSID` (`OSID`),
  KEY `IX_RawUserAgent_DeviceTypeID` (`DeviceTypeID`)
) ENGINE=InnoDB;

CREATE TABLE `Browser` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `BrowserCode` VARCHAR(100) NOT NULL,
  `BrowserType` VARCHAR(15) DEFAULT NULL,
  `BrowserName` VARCHAR(100) DEFAULT NULL,
  `BrowserVersion` VARCHAR(50) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_Browser_BrowserCode` (`BrowserCode`),
  KEY `IX_Browser_BrowserName_BrowserVersion` (`BrowserName`,`BrowserVersion`)
) ENGINE=InnoDB;

CREATE TABLE `OS` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `OSCode` VARCHAR(100) NOT NULL,
  `OSName` VARCHAR(100) DEFAULT NULL,
  `OSShortName` VARCHAR(50) DEFAULT NULL,
  `OSVersion` VARCHAR(50) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_OS_OSCode` (`OSCode`),
  KEY `IX_OS_OSName_OSVersion` (`OSName`,`OSVersion`)
) ENGINE=InnoDB;

CREATE TABLE `DeviceType` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `DeviceTypeCode` VARCHAR(100) NOT NULL,
  `DeviceType` VARCHAR(50) DEFAULT NULL,
  `Brand` VARCHAR(50) DEFAULT NULL,
  `Model` VARCHAR(15) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_DeviceType_DeviceTypeCode` (`DeviceTypeCode`),
  KEY `IX_DeviceType_DeviceType` (`DeviceType`),
  KEY `IX_DeviceType_Brand` (`Brand`)
) ENGINE=InnoDB;