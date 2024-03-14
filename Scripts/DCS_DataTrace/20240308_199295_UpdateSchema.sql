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

CREATE TABLE `RawTransaction07` (
  `TransID`			BIGINT UNSIGNED 	NOT NULL,
  `LoginName` 		VARCHAR(100) 		,
  `TransTime` 		TIMESTAMP(4) 		,
  `SubscriberID` 	INT 				,
  `AccountID` 		BIGINT UNSIGNED 	,
  `DeviceID` 		BIGINT UNSIGNED 	,
  `Flagged`			SMALLINT 			,
  `CreatedDate` 	DATETIME 			NOT NULL,
  `RawUserAgentID` 	BIGINT UNSIGNED 	,
  `FPDeviceID` 		BIGINT UNSIGNED 	,
  PRIMARY KEY (`TransID`)
) ENGINE=InnoDB;

ALTER TABLE DCS_DataTrace.LoginTransactionSummaryBySubscriber
ADD COLUMN TotalNoDeviceTrans INT UNSIGNED ,
ADD COLUMN TotalNoFPDeviceTrans INT UNSIGNED ;

CREATE TABLE `RawUserAgent` (
  `ID` 				BIGINT UNSIGNED 	NOT NULL,
  `UserAgent` 		VARCHAR(1000) 		NOT NULL,
  `BrowserID` 		BIGINT UNSIGNED 	,
  `OSID` 			BIGINT UNSIGNED 	,
  `DeviceTypeID` 	BIGINT UNSIGNED 	,
  `CreatedDate` 	DATETIME 			,
  PRIMARY KEY (`ID`),
  KEY `IX_RawUserAgent_BrowserID` (`BrowserID`),
  KEY `IX_RawUserAgent_OSID` (`OSID`),
  KEY `IX_RawUserAgent_DeviceTypeID` (`DeviceTypeID`)
) ENGINE=InnoDB;

CREATE TABLE `Browser` (
  `ID` 				BIGINT UNSIGNED 	NOT NULL AUTO_INCREMENT,
  `BrowserCode` 	VARCHAR(32) 		NOT NULL,
  `BrowserType` 	VARCHAR(15) 		,
  `BrowserName` 	VARCHAR(100) 		,
  `BrowserVersion` 	VARCHAR(50) 		,
  `CreatedDate` 	DATETIME 			,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_Browser_BrowserCode` (`BrowserCode`),
  KEY `IX_Browser_BrowserName_BrowserVersion` (`BrowserName`,`BrowserVersion`)
) ENGINE=InnoDB;

CREATE TABLE `OS` (
  `ID` 				BIGINT UNSIGNED 	NOT NULL AUTO_INCREMENT,
  `OSCode` 			VARCHAR(32) 		NOT NULL,
  `OSName` 			VARCHAR(100) 		,
  `OSShortName` 	VARCHAR(50) 		,
  `OSVersion` 		VARCHAR(50) 		,
  `CreatedDate` 	DATETIME 			,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_OS_OSCode` (`OSCode`),
  KEY `IX_OS_OSName_OSVersion` (`OSName`,`OSVersion`)
) ENGINE=InnoDB;

CREATE TABLE `DeviceType` (
  `ID` 				BIGINT UNSIGNED 	NOT NULL AUTO_INCREMENT,
  `DeviceTypeCode` 	VARCHAR(32) 		NOT NULL,
  `DeviceType` 		VARCHAR(50) 		,
  `Brand` 			VARCHAR(50) 		,
  `Model` 			VARCHAR(15) 		,
  `CreatedDate` 	DATETIME 			,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_DeviceType_DeviceTypeCode` (`DeviceTypeCode`),
  KEY `IX_DeviceType_DeviceType` (`DeviceType`),
  KEY `IX_DeviceType_Brand` (`Brand`)
) ENGINE=InnoDB;


INSERT INTO `DCS_DataTrace`.`SystemSetting` (`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`) VALUES ('5', 'RawTrans07', 'TransID', '0', CURRENT_TIMESTAMP());