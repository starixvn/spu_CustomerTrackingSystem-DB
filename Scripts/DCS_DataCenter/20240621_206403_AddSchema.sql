/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20240621@Jonathan.Doan [Redmine ID: #206403]
	Task: Change Data Flow Ver. 6
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

/* ========= NEW TABLES ========= */
CREATE TABLE `FP_LastModifiedDate` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `TableName` VARCHAR(255) NOT NULL,
  `RecordID` BIGINT UNSIGNED NOT NULL,
  `LastModifiedDate` DATE,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  `ModifiedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_LastModifiedDate_TableName_RecordID` (`TableName`,`RecordID`)
) ENGINE=InnoDB;

CREATE TABLE `FP_Tagging` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Tagging` VARCHAR(32) NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_Tagging_Tagging` (`Tagging`)
) ENGINE=InnoDB;

CREATE TABLE `FP_FingerPrint` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Code` VARCHAR(32) NOT NULL,
  `Attribute` JSON NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_FingerPrint_Code` (`Code`)
) ENGINE=InnoDB;

CREATE TABLE `FP_FingerPrintExtra` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Code` VARCHAR(32) NOT NULL,
  `Attribute` JSON NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_FingerPrintExtra_Code` (`Code`)
) ENGINE=InnoDB;

CREATE TABLE `FP_FingerPrintOld` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Code` VARCHAR(32) NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_FingerPrintOld_Code` (`Code`)
) ENGINE=InnoDB;

CREATE TABLE `FP_UserAgent` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Code` VARCHAR(32) NOT NULL,
  `UserAgent` VARCHAR(1000) NOT NULL,
  `BrowserID` BIGINT UNSIGNED DEFAULT NULL,
  `OSID` BIGINT UNSIGNED DEFAULT NULL,
  `DeviceTypeID` BIGINT UNSIGNED DEFAULT NULL,
  `InsertedTime` DATETIME DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_UserAgent_Code` (`Code`),
  KEY `IX_FP_UserAgent_BrowserID` (`BrowserID`),
  KEY `IX_FP_UserAgent_OSID` (`OSID`),
  KEY `IX_FP_UserAgent_DeviceTypeID` (`DeviceTypeID`)
) ENGINE=InnoDB;

CREATE TABLE `FP_Browser` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `BrowserCode` VARCHAR(32) NOT NULL,
  `BrowserType` VARCHAR(15) DEFAULT NULL,
  `BrowserName` VARCHAR(100) DEFAULT NULL,
  `BrowserVersion` VARCHAR(50) DEFAULT NULL,
  `InsertedTime` DATETIME DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_Browser_BrowserCode` (`BrowserCode`),
  KEY `IX_FP_Browser_BrowserName_BrowserVersion` (`BrowserName`,`BrowserVersion`)
) ENGINE=InnoDB;

CREATE TABLE `FP_OS` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `OSCode` VARCHAR(32) NOT NULL,
  `OSName` VARCHAR(100) DEFAULT NULL,
  `OSShortName` VARCHAR(50) DEFAULT NULL,
  `OSVersion` VARCHAR(50) DEFAULT NULL,
  `InsertedTime` DATETIME DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_OS_OSCode` (`OSCode`),
  KEY `IX_FP_OS_OSName_OSVersion` (`OSName`,`OSVersion`)
) ENGINE=InnoDB;

CREATE TABLE `FP_DeviceType` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `DeviceTypeCode` VARCHAR(32) NOT NULL,
  `DeviceType` VARCHAR(50) DEFAULT NULL,
  `Brand` VARCHAR(50) DEFAULT NULL,
  `Model` VARCHAR(15) DEFAULT NULL,
  `InsertedTime` DATETIME DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_DeviceType_DeviceTypeCode` (`DeviceTypeCode`),
  KEY `IX_FP_DeviceType_DeviceType` (`DeviceType`),
  KEY `IX_FP_DeviceType_Brand` (`Brand`)
) ENGINE=InnoDB;

CREATE TABLE `FP_DeviceFingerprintAccount` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FP_FingerPrintID` BIGINT UNSIGNED NOT NULL,
  `AccountID` BIGINT UNSIGNED NOT NULL,
  `EvolveByID` BIGINT UNSIGNED DEFAULT 0,
  `DeviceID` BIGINT UNSIGNED DEFAULT 0,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_DeviceFingerprintAccount_FP_FingerPrintID_AccountID` (`FP_FingerPrintID`,`AccountID`),
  KEY `IX_FP_DeviceFingerprintAccount_DeviceID` (`DeviceID`)
) ENGINE=InnoDB;

CREATE TABLE `FP_EvolvedMapping` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FP_DeviceFingerprintAccountID` BIGINT UNSIGNED NOT NULL,
  `FP_FingerPrintExtraID` BIGINT UNSIGNED NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_EvolvedMapping_FP_DeviceFingerprintAccountID` (`FP_DeviceFingerprintAccountID`,`FP_FingerPrintExtraID`)
) ENGINE=InnoDB;

CREATE TABLE `FP_DeviceFingerprintAccountOld` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FP_FingerPrintOldID` BIGINT UNSIGNED NOT NULL,
  `AccountID` BIGINT UNSIGNED NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_DeviceFingerprintAccount_FP_FingerPrintOldID_AccountID` (`FP_FingerPrintOldID`,`AccountID`)
) ENGINE=InnoDB;

CREATE TABLE `FP_DeviceMapping` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FP_TaggingID` BIGINT UNSIGNED NOT NULL,
  `FP_FingerPrintID` BIGINT UNSIGNED NOT NULL,
  `FP_DeviceFingerprintAccountID` BIGINT UNSIGNED NOT NULL,
  `FP_DeviceFingerprintAccount_EvolutionID` BIGINT UNSIGNED NOT NULL,
  `FP_DeviceFingerprintAccountOldID` BIGINT UNSIGNED NOT NULL,
  `FP_DeviceID` BIGINT UNSIGNED NOT NULL,
  `FirstRawTransID` BIGINT UNSIGNED NOT NULL,
  `RecoverType` SMALLINT UNSIGNED NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_DeviceMapping_Group` (`FP_TaggingID`,`FP_FingerPrintID`,`FP_DeviceFingerprintAccountID`,`FP_DeviceFingerprintAccount_EvolutionID`,`FP_DeviceFingerprintAccountOldID`),
  KEY `UK_FP_DeviceMapping_FP_TaggingID` (`FP_TaggingID`),
  KEY `UK_FP_DeviceMapping_FP_FingerPrintID` (`FP_FingerPrintID`),
  KEY `UK_FP_DeviceMapping_FP_DeviceFingerprintAccountID` (`FP_DeviceFingerprintAccountID`),
  KEY `UK_FP_DeviceMapping_FP_DeviceFingerprintAccount_EvolutionID` (`FP_DeviceFingerprintAccount_EvolutionID`),
  KEY `UK_FP_DeviceMapping_FP_DeviceFingerprintAccountOldID` (`FP_DeviceFingerprintAccountOldID`)
) ENGINE=InnoDB;

CREATE TABLE `FP_TransactionDeviceMapping` (
  `RawTransID` BIGINT UNSIGNED NOT NULL,
  `FP_DeviceMappingID` BIGINT UNSIGNED NOT NULL,
  `FP_DeviceID` BIGINT UNSIGNED NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`RawTransID`)
) ENGINE=InnoDB;

CREATE TABLE `FP_Device` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FirstRawTransID` BIGINT UNSIGNED NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_Device_FirstRawTransID` (`FirstRawTransID`)
) ENGINE=InnoDB AUTO_INCREMENT=300000001;

CREATE TABLE `FP_Association` (
  `AssociationID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `AccountID` BIGINT UNSIGNED NOT NULL,
  `DeviceID` BIGINT UNSIGNED NOT NULL,
  `SubscriberID` INT NOT NULL,
  `CreatedTime` TIMESTAMP(4) NOT NULL,
  `CreatedDate` TIMESTAMP NOT NULL,
  `InsertedTime` TIMESTAMP(4) NOT NULL,
  `IsCTSTransformed` TINYINT NOT NULL DEFAULT '0',
  
  PRIMARY KEY (`AssociationID`),
  UNIQUE KEY `UX_FP_Association_AccountID_DeviceID` (`AccountID`,`DeviceID`),
  KEY `IX_FP_Association_IsCTSTransformed` (`IsCTSTransformed`),
  KEY `IX_FP_Association_SubscriberID_AccountID_DeviceID` (`SubscriberID`,`AccountID`,`DeviceID`),
  KEY `IX_FP_Association_DeviceID_AccountID_CreatedDate` (`DeviceID`,`AccountID`)
) ENGINE=InnoDB;


CREATE TABLE `FP_AssociationMapping` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `AccountID` BIGINT UNSIGNED NOT NULL,
  `DeviceID` BIGINT UNSIGNED NOT NULL,
  `FP_DeviceID` BIGINT UNSIGNED NOT NULL,
  `SubscriberID` INT NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_AssociationMapping_AccountID_DeviceID_FP_DeviceID` (`AccountID`,`DeviceID`,`FP_DeviceID`)
) ENGINE=InnoDB;

/* ========= Update Schema ========= */
DELETE FROM `DCS_DataCenter`.`RawTransaction` WHERE  IsProcessed = -1 AND CreatedDate < '2024-06-30';

ALTER TABLE `DCS_DataCenter`.`RawTransaction`
REMOVE PARTITIONING;

ALTER TABLE `DCS_DataCenter`.`RawTransaction`
DROP PRIMARY KEY,
ADD PRIMARY KEY (TransID);

ALTER TABLE `DCS_DataCenter`.`RawTransaction`
ADD COLUMN `IsIncognitoMode` BOOLEAN,
ADD COLUMN `ChallengeCode` VARCHAR(50) NULL,
ADD COLUMN `FP_Tagging` VARCHAR(32) NULL,
ADD COLUMN `FP_FingerPrintCode` VARCHAR(32) NULL,
ADD COLUMN `FP_FingerPrintExtraCode` VARCHAR(32) NULL,
ADD COLUMN `FP_FingerPrintOldCode` VARCHAR(32) NULL,
ADD COLUMN `FP_UserAgentCode` VARCHAR(32) NULL,
DROP COLUMN `CookieID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `JsChallengeID`,
ADD KEY `IX_RawTransaction_CreatedDate` (`CreatedDate`);

ALTER TABLE `DCS_DataCenter`.`ProcessedTransaction`
ADD COLUMN `IsIncognitoMode` BOOLEAN,
ADD COLUMN `ChallengeCode` VARCHAR(50) NULL,
ADD COLUMN `FP_Tagging` VARCHAR(32) NULL,
ADD COLUMN `FP_FingerPrintCode` VARCHAR(32) NULL,
ADD COLUMN `FP_FingerPrintExtraCode` VARCHAR(32) NULL,
ADD COLUMN `FP_FingerPrintOldCode` VARCHAR(32) NULL,
ADD COLUMN `FP_UserAgentCode` VARCHAR(32) NULL,
DROP COLUMN `CookieID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `JsChallengeID`;


ALTER TABLE `DCS_DataCenter`.`Transaction`
ADD COLUMN `IsIncognitoMode` BOOLEAN,
ADD COLUMN `JSChallengeInfoID` BIGINT UNSIGNED,
ADD COLUMN `FP_TaggingID` BIGINT UNSIGNED,
ADD COLUMN `FP_FingerPrintID` BIGINT UNSIGNED,
ADD COLUMN `FP_FingerPrintExtraID` BIGINT UNSIGNED,
ADD COLUMN `FP_FingerPrintOldID` BIGINT UNSIGNED,
ADD COLUMN `FP_UserAgentID` BIGINT UNSIGNED,
DROP COLUMN `CookieID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`;

ALTER TABLE `DCS_DataCenter`.`Transaction07`
ADD COLUMN `IsIncognitoMode` BOOLEAN,
ADD COLUMN `JSChallengeInfoID` BIGINT UNSIGNED,
ADD COLUMN `FP_TaggingID` BIGINT UNSIGNED,
ADD COLUMN `FP_FingerPrintID` BIGINT UNSIGNED,
ADD COLUMN `FP_FingerPrintExtraID` BIGINT UNSIGNED,
ADD COLUMN `FP_FingerPrintOldID` BIGINT UNSIGNED,
ADD COLUMN `FP_UserAgentID` BIGINT UNSIGNED,
ADD COLUMN `FP_MappingDeviceID` BIGINT UNSIGNED NULL,
ADD COLUMN `FP_DeviceID` BIGINT UNSIGNED NULL,
DROP COLUMN `CookieID`,
DROP COLUMN `RawUserAgentID`,
DROP COLUMN `RawFingerPrintID`,
DROP COLUMN `BrowserInstanceID`,
DROP COLUMN `FPDeviceID`,
DROP COLUMN `RecoverType`;

ALTER TABLE `DCS_DataCenter`.`JSChallengeInfo`
CHANGE COLUMN `ChallengeCode` `ChallengeCode` VARCHAR(50) NOT NULL,
CHANGE COLUMN `Expect` `Expect` VARCHAR(1000) NULL DEFAULT '' ,
CHANGE COLUMN `Actual` `Actual` VARCHAR(1000) NULL DEFAULT '' ;

