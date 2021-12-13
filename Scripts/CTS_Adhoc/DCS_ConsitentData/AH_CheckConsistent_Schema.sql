USE CTS_Adhoc;
CREATE TABLE AH_CTS_CheckConsistent_AssociationByDevice_MissDevice (
  `CTSAssDevID` bigint unsigned NOT NULL ,
  `CTSCustID` bigint unsigned DEFAULT NULL,
  `DCSDeviceID` bigint DEFAULT NULL,
  `SubscriberID` int DEFAULT NULL,
  `CreatedTime` timestamp(4) NULL DEFAULT NULL,
  `InsertTime` timestamp(4) NULL DEFAULT NULL,
  PRIMARY KEY (`CTSAssDevID`),
  UNIQUE KEY `IX_AssociationByDevice_CTSCustID_DCSDeviceID` (`CTSCustID`,`DCSDeviceID`),
  KEY `IX_AssociationByDevice_SubscriberID_DeviceID` (`SubscriberID`,`DCSDeviceID`),
  KEY `IX_AssociationByDevice_DCSDeviceID_CTSCustID` (`DCSDeviceID`,`CTSCustID`),
  KEY `IX_AssociationByDevice_CreatedTime` (`CreatedTime`)
) ENGINE=InnoDB ;

CREATE TABLE AH_CTS_CheckConsistent_AssociationByDevice_MissDevice (
  `CTSAssDevID` bigint unsigned NOT NULL ,
  `CTSCustID` bigint unsigned DEFAULT NULL,
  `DCSDeviceID` bigint DEFAULT NULL,
  `SubscriberID` int DEFAULT NULL,
  `CreatedTime` timestamp(4) NULL DEFAULT NULL,
  `InsertTime` timestamp(4) NULL DEFAULT NULL,
  PRIMARY KEY (`CTSAssDevID`),
  UNIQUE KEY `IX_AssociationByDevice_CTSCustID_DCSDeviceID` (`CTSCustID`,`DCSDeviceID`),
  KEY `IX_AssociationByDevice_SubscriberID_DeviceID` (`SubscriberID`,`DCSDeviceID`),
  KEY `IX_AssociationByDevice_DCSDeviceID_CTSCustID` (`DCSDeviceID`,`CTSCustID`),
  KEY `IX_AssociationByDevice_CreatedTime` (`CreatedTime`)
) ENGINE=InnoDB ;

CREATE TABLE `AH_CheckConsistent_Association_MissAccount` (
  `AssociationID` bigint unsigned NOT NULL ,
  `DeviceID` bigint unsigned NOT NULL,
  `AccountID` bigint unsigned NOT NULL,
  `SubscriberID` int ,
  `CreatedTime` timestamp(4) ,
  `CreatedDate` timestamp(4) ,
  `InsertTime` timestamp(4) ,
  `IsCTSTransformed` tinyint ,
  PRIMARY KEY (AssociationID),
  KEY KEY_Association_AccountIDDeviceID(`AccountID`,`DeviceID`)
) ENGINE=InnoDB;

USE CTS_Adhoc;		
CREATE TABLE `AH_CheckConsistent_Association_MissDevice` (
  `AssociationID` bigint unsigned NOT NULL ,
  `DeviceID` bigint unsigned NOT NULL,
  `AccountID` bigint unsigned NOT NULL,
  `SubscriberID` int ,
  `CreatedTime` timestamp(4) ,
  `CreatedDate` timestamp(4) ,
  `InsertTime` timestamp(4) ,
  `IsCTSTransformed` tinyint ,
  PRIMARY KEY (AssociationID),
  KEY KEY_Association_AccountIDDeviceID(`AccountID`,`DeviceID`)
) ENGINE=InnoDB;

CREATE TABLE AH_CheckConsistent_DeviceFingerprint (
  `DeviceFingerprintID` bigint unsigned NOT NULL ,
  `DeviceID` bigint unsigned NOT NULL,
  `FingerprintCode` varchar(620) COLLATE utf8_unicode_ci NOT NULL,
  `FingerprintMoreInfo` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `CreatedTime` timestamp(4) ,
  `CreatedDate` datetime ,
  `InsertTime` timestamp(4) ,
  MissingDevice TINYINT,
  PRIMARY KEY (`DeviceID`,`FingerprintCode`),
  KEY `KEY_DeviceFingerprintID` (`DeviceFingerprintID`)
) ENGINE=InnoDB ;

CREATE TABLE AH_CheckConsistent_DeviceCode (
  `DeviceCodeID` bigint unsigned NOT NULL ,
  `DeviceCode` varchar(32) COLLATE utf8_unicode_ci NOT NULL COMMENT ' DeviceCode Captured From DI',
  `DeviceID` bigint unsigned DEFAULT NULL,
  `FirstTransID` bigint DEFAULT NULL,
  `CreatedTime` timestamp(4) ,
  `CreatedDate` datetime ,
  `InsertTime` timestamp(4) ,
  MissingDevice TINYINT,
  PRIMARY KEY (`DeviceCodeID`),
  UNIQUE KEY `UK_DeviceCode_DeviceID` (`DeviceCode`,`DeviceID`),
  KEY `IX_DeviceCode_CreatedDate` (`CreatedDate`),
  KEY `IX_DeviceCode_DeviceID` (`DeviceID`)
) ENGINE=InnoDB ;

CREATE TABLE AH_CheckConsistent_Device (
  `DeviceID` bigint unsigned NOT NULL,
  `FirstDeviceCode` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
  `UserAgentKey` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FirstTransID` bigint DEFAULT NULL,
  `CreatedTime` timestamp(4)  COMMENT 'CreatedTime of First Transaction',
  `CreatedDate` datetime COMMENT 'Date Only, Date of First Transaction',
  `InsertTime` timestamp(4)  COMMENT 'DateTime, the time that data Insert to Table',
  MissingDeviceCode TINYINT DEFAULT 0,
  MissingDeviceFingerprint TINYINT DEFAULT 0,
  
  PRIMARY KEY (`DeviceID`),
  UNIQUE KEY `UK_Device_FirstDeviceCode` (`FirstDeviceCode`),
  KEY `IX_Device_CreatedDate` (`CreatedDate`)
) ENGINE=InnoDB ;


CREATE TABLE CS_Adhoc_Setting(ID INT PRIMARY KEY, ParameterName VARCHAR(100), ParameterValue VARCHAR(100));

INSERT IGNORE INTO CS_Adhoc_Setting(ID, ParameterName ,ParameterValue)
VALUES	(1, 'AH_CheckConsistent_DCS_Device', 0)
	,	(2, 'AH_CheckConsistent_DCS_DeviceCode', 0)
    ,	(3, 'AH_CheckConsistent_DCS_DeviceFingerprint', 0)
    ,	(4, 'AH_CheckConsistent_DCS_Association', 0)
    ,	(5, 'AH_CheckConsistent_CTS_AssociationByDevice', 0);