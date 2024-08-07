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

CREATE TABLE `FP_EvolvedMapping` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FP_FingerPrintID` BIGINT UNSIGNED NOT NULL,
  `FP_FingerPrintExtraID` BIGINT UNSIGNED NOT NULL,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_EvolvedMapping_FP_FingerPrintID_FP_FingerPrintExtraID` (`FP_FingerPrintID`,`FP_FingerPrintExtraID`)
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
  `ClientType` VARCHAR(15) DEFAULT NULL,
  `ClientName` VARCHAR(100) DEFAULT NULL,
  `ClientVersion` VARCHAR(50) DEFAULT NULL,
  `OSName` VARCHAR(100) DEFAULT NULL,
  `OSShortName` VARCHAR(50) DEFAULT NULL,
  `OSVersion` VARCHAR(50) DEFAULT NULL,
  `OSPlatform` VARCHAR(15) DEFAULT NULL,
  `Device` VARCHAR(50) DEFAULT NULL,
  `Brand` VARCHAR(50) DEFAULT NULL,
  `Model` VARCHAR(15) DEFAULT NULL,
  `InsertedTime` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_UserAgent_Code` (`Code`)
) ENGINE=InnoDB;

CREATE TABLE `FP_DeviceFingerprintAccount` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FP_FingerPrintID` BIGINT UNSIGNED NOT NULL,
  `AccountID` BIGINT UNSIGNED NOT NULL,
  `EvolveByID` BIGINT UNSIGNED,
  `DeviceID` BIGINT UNSIGNED DEFAULT 0,
  `InsertedTime` TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FP_DeviceFingerprintAccount_FP_FingerPrintID_AccountID` (`FP_FingerPrintID`,`AccountID`),
  KEY `IX_FP_DeviceFingerprintAccount_DeviceID` (`DeviceID`)
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
DROP COLUMN `JsChallengeID`;

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
CHANGE COLUMN `ChallengeCode` `ChallengeCode` VARCHAR(50) NOT NULL;

/* ========= CLEAN DB ========= */
DROP TABLE `DCS_DataCenter`.`Cookie`;
DROP TABLE `DCS_DataCenter`.`RawFingerPrint`;
DROP TABLE `DCS_DataCenter`.`FingerPrintAttribute`;
DROP TABLE `DCS_DataCenter`.`BrowserInstance`;
DROP TABLE `DCS_DataCenter`.`BrowserInstanceRawFingerPrint`;
DROP TABLE `DCS_DataCenter`.`RawUserAgent`;
DROP TABLE `DCS_DataCenter`.`DeviceCookie`;
DROP TABLE `DCS_DataCenter`.`FPDevice`;
DROP TABLE `DCS_DataCenter`.`FPDeviceFingerPrint`;
DROP TABLE `DCS_DataCenter`.`AccountFingerprint`;
DROP TABLE `DCS_DataCenter`.`EvolvedTransaction`;
DROP TABLE `DCS_DataCenter`.`AssociationMapping`;
DROP TABLE `DCS_DataCenter`.`AssociationNew`;


INSERT INTO `DCS_DataCenter`.`SystemSetting`(`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`)
VALUES 	(23, 'DeviceEvolution', 'Min_FP_DeviceFingerprintAccountID', 0, NOW()),
		(24, 'DeviceMapping', 'Min_Transaction_TransID', 0, NOW());

INSERT INTO `DCS_DataCenter`.`StaticList`(`ListID`, `ItemID`, `ListCode`, `ListName`, `ItemCode`, `ItemName`, `Status`, `Description`, `CreatedDate`)
VALUES 	(4, 1, 'DeviceMapping', 'DeviceMapping', 'Tagging', 'Tagging', 1, 'Rule 1', NOW()),
		(4, 2, 'DeviceMapping', 'DeviceMapping', 'RawFingerprint', 'RawFingerprint', 1, 'Rule 2', NOW()),
		(4, 3, 'DeviceMapping', 'DeviceMapping', 'DeviceFingerprintAccount', 'DeviceFingerprintAccount', 1, 'Rule 3', NOW()),
		(4, 4, 'DeviceMapping', 'DeviceMapping', 'DeviceFingerprintAccountEvolution', 'DeviceFingerprintAccountEvolution', 1, 'Rule 4', NOW()),
		(4, 5, 'DeviceMapping', 'DeviceMapping', 'DeviceFingerprintAccountOld', 'DeviceFingerprintAccountOld', 1, 'Rule 5', NOW());


/*
- Unused SPs:
 + DCS_DC_Transform_Cookie_Insert
 + DCS_DC_Transform_RawUserAgent_Insert
 + DCS_DC_Transform_RawFingerPrint_Insert
 + DCS_DC_Transform_FingerprintAttribute_Insert
 + DCS_DC_Transform_BrowserInstance_Insert
 + DCS_DC_Identity_Evolution_Insert
 + DCS_DC_Identity_EvolvedTransaction_Insert
 + DCS_DC_Identity_Evolution_GetAttributes
 + DCS_DC_Identity_AccountFingerPrint_Insert
 + DCS_DC_Identity_Device_Insert
 + DCS_DC_Identity_Device_Recover
 + DCS_DC_Identity_Device_UpdateExistsDeviceID
 + DCS_DC_Identity_DeviceCookie_Insert
 + DCS_DC_Identity_DeviceFingerPrint_Insert
 + DCS_DC_Identity_TransactionEvolution_Insert
*/