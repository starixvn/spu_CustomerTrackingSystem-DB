/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250822@Casey.Huynh
Task:	 	AI Power Device Fingerprint
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20250822@Casey.Huynh: Created [Redmine ID: #236716]
Reviewer:
*/

USE DCS_DataCenter;
# ---------------------NEW TABLES--------------------------------------
DROP TABLE IF EXISTS WebRTCIP;
CREATE TABLE WebRTCIP(
		WebRTCIPID		BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	WebRTCIPCode 	VARCHAR(32) NOT NULL   
	,	WebRTCIPDetails	LONGTEXT NULL   
	,	CreatedDate		DATE NOT NULL    
	,	LastUsedDate	DATE NOT NULL
    
	,	UNIQUE KEY UX_FPDetailsWebRTCIP_FPDetailsCode(WebRTCIPID)
    ,	INDEX IX_FPDetailsWebRTCIP_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupHardware;
CREATE TABLE FPGroupHardware(
		FPGroupHardwareID	BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	HardwareCode 		VARCHAR(32) NOT NULL   
	,	HardwareDetails		LONGTEXT NULL 
	,	CreatedDate			DATE NOT NULL    
	,	LastUsedDate		DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupHardware_FPGroupCode(HardwareCode)
    ,	INDEX IX_FPGroupHardware_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupGraphic;
CREATE TABLE FPGroupGraphic(
		FPGroupGraphicID		BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	GraphicCode 			VARCHAR(32) NOT NULL   
	,	GraphicDetails			LONGTEXT NULL 
	,	CreatedDate				DATE NOT NULL    
	,	LastUsedDate			DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupGraphic_FPGroupCode(GraphicCode)
    ,	INDEX IX_FPGroupGraphic_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupAudio;
CREATE TABLE FPGroupAudio(
		FPGroupAudioID	BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	AudioCode 		VARCHAR(32) NOT NULL   
	,	AudioDetails	LONGTEXT NULL  
	,	CreatedDate		DATE NOT NULL    
	,	LastUsedDate	DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupAudio_FPGroupCode(AudioCode)
    ,	INDEX IX_FPGroupAudio_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupBrowser;
CREATE TABLE FPGroupBrowser(
		FPGroupBrowserID		BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	BrowserCode 			VARCHAR(32) NOT NULL   
	,	BrowserDetails			LONGTEXT NULL 
	,	CreatedDate				DATE NOT NULL    
	,	LastUsedDate			DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupBrowser_FPGroupCode(BrowserCode)
    ,	INDEX IX_FPGroupBrowser_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPGroupPreferences;
CREATE TABLE FPGroupPreferences(
		FPGroupPreferencesID		BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	PreferencesCode 			VARCHAR(32) NOT NULL   
	,	PreferencesDetails			LONGTEXT NULL  
	,	CreatedDate					DATE NOT NULL    
	,	LastUsedDate				DATE NOT NULL
    
	,	UNIQUE KEY UX_FPGroupPreferences_FPGroupCode(PreferencesCode)
    ,	INDEX IX_FPGroupPreferences_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS FPPattern;
CREATE TABLE FPPattern(
		FPPatternID 	BIGINT UNSIGNED	AUTO_INCREMENT PRIMARY KEY
	,	FPPatternType	TINYINT NOT NULL COMMENT 'Pattern Group Combinition'
    ,	FPPatternCode 	VARCHAR(32) NOT NULL    
    ,	CreatedDate		DATE NOT NULL    
	,	LastUsedDate	DATE NOT NULL
	
    ,	UNIQUE KEY UX_FPPattern_FPCode(FPPatternType, FPPatternCode)
    ,	INDEX IX_FPPattern_LastUsedDate(LastUsedDate)
);

DROP TABLE IF EXISTS RawFingerprintQueue;
CREATE TABLE RawFingerprintQueue(
		ID					BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
	,	FPPatternID01		BIGINT UNSIGNED
	,	FPPatternID02		BIGINT UNSIGNED
	,	HardwareCode		VARCHAR(32)
	,	GraphicCode			VARCHAR(32)
	,	AudioCode			VARCHAR(32)
	,	BrowserCode			VARCHAR(32)
	,	PreferencesCode		VARCHAR(32)
	,	HardwareDetails		LONGTEXT
	,	GraphicDetails		LONGTEXT
	,	AudioDetails		LONGTEXT
	,	BrowserDetails		LONGTEXT
	,	PreferencesDetails	LONGTEXT
    ,	CreatedDate			DATE
);

DROP TABLE IF EXISTS FPPatternGroup;
CREATE TABLE FPPatternGroup(
		FPPatternID 	BIGINT UNSIGNED NOT NULL
	,	FPPatternType	TINYINT NOT NULL COMMENT 'Pattern Group Combinition'
    ,	FPGroupID 		BIGINT UNSIGNED	NOT NULL
    ,	FPGroupType 	TINYINT UNSIGNED NOT NULL COMMENT '1:Hardware, 2:Graphic, 3.Audio, 4. Browser, 5.Prereference'
	
    ,	PRIMARY KEY PK_FPPatternGroup_FPCode(FPPatternID, FPGroupType, FPGroupID)
);

DROP TABLE IF EXISTS DeviceFPPattern;
CREATE TABLE DeviceFPPattern(
		DeviceID		BIGINT UNSIGNED NOT NULL
    ,	FPPatternID		BIGINT UNSIGNED NOT NULL
    ,	FPPatternType	TINYINT NOT NULL
	,	InsertedTime	DATETIME(4) NOT NULL

    ,	PRIMARY KEY PK_FPPattern_FPCode(DeviceID, FPPatternID)
    ,	INDEX IX_FPPattern_FPPatternTypeFPPatternID(FPPatternType, FPPatternID)
);

DROP TABLE IF EXISTS FPAttribute;
CREATE TABLE FPAttribute(
		FPAttributeID		INT NOT NULL
    ,   AttributeName		VARCHAR(100) NOT NULL
    ,	AttributeShortName  VARCHAR(4) NOT NULL
    ,	GroupName			VARCHAR(100) NOT NULL
	,	IsActive			BOOLEAN NOT NULL
    ,	CreatedTime			DATETIME(4) NOT NULL

    ,	PRIMARY KEY PK_FPAttribute(FPAttributeID)
    ,	INDEX IX_FPAttribute(GroupName,FPAttributeID)
); 

INSERT INTO FPAttribute(FPAttributeID, AttributeName, GroupName, AttributeShortName, IsActive, CreatedTime)
VALUES(1,'Platform','Hardware','A1',1, NOW())
,(2,'Architecture','Hardware','A2',1, NOW())
,(3,'OsCpu','Hardware','A3',1, NOW())
,(4,'CpuClass','Hardware','A4',1, NOW())
,(5,'HardwareConcurrency','Hardware','A5',1, NOW())
,(6,'DeviceMemory','Hardware','A6',1, NOW())
,(7,'Canvas','Graphic','A7',1, NOW())
,(8,'WebGlBasicsRaw','Graphic','A8',1, NOW())
,(9,'WebGlExtensions','Graphic','A9',1, NOW())
,(10,'FontsRaw','Graphic','A10',1, NOW())
,(11,'FontPreferencesRaw','Graphic','A11',1, NOW())
,(12,'ScreenResolution','Graphic','A12',1, NOW())
,(13,'ScreenFrame','Graphic','A13',1, NOW())
,(14,'ColorDepth','Graphic','A14',1, NOW())
,(15,'ColorGamut','Graphic','A15',1, NOW())
,(16,'Audio','Audio','A16',1, NOW())
,(17,'AudioBaseLatency','Audio','A17',1, NOW())
,(18,'UserAgent','Browser','A18',1, NOW())
,(19,'BrowserName','Browser','A19',1, NOW())
,(20,'OSName','Browser','A20',1, NOW())
,(21,'Plugins','Browser','A21',1, NOW())
,(22,'Vendor','Browser','A22',1, NOW())
,(23,'VendorFlavors','Browser','A23',1, NOW())
,(24,'PdfViewerEnabled','Browser','A24',1, NOW())
,(25,'LanguagesRaw','Preference','A25',1, NOW())
,(26,'Timezone','Preference','A26',1, NOW())
,(27,'TouchSupportRaw','Preference','A27',1, NOW())
,(28,'CookiesEnabled','Preference','A28',1, NOW())
,(29,'LocalStorage','Preference','A29',1, NOW())
,(30,'SessionStorage','Preference','A30',1, NOW())
,(31,'IndexedDB','Preference','A31',1, NOW())
,(32,'OpenDatabase','Preference','A32',1, NOW())
;

SELECT * FROM FPAttribute;

#====================ALTER TABLE RawTransaction===================================
/* BK RawTransaction SCHEMA DEV LOCAL
DROP TABLE RawTransaction;
CREATE TABLE `RawTransaction` (
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `SubscriberName` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  `DeviceCode` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `FingerprintCode` varchar(620) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `FingerprintMoreInfo` varchar(250) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IP` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IPID` decimal(50,0) DEFAULT NULL,
  `PluginID` bigint DEFAULT NULL,
  `URL` varchar(500) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `Action` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `ActionResult` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `InvalidDevice` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TransStatus` bit(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
  `FPSTransID` bigint unsigned DEFAULT NULL,
  `Flagged` smallint DEFAULT NULL,
  `IsProcessed` tinyint NOT NULL DEFAULT '0',
  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `InsertTime` timestamp(4) NULL DEFAULT NULL,
  `BotDetectionValue` bit(32) DEFAULT NULL,
  `BotComponentID` bigint unsigned DEFAULT NULL,
  `FakeIP` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IsIncognitoMode` tinyint(1) DEFAULT NULL,
  `ChallengeCode` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_Tagging` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_FingerPrintCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_FingerPrintExtraCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_FingerPrintOldCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `UserAgent` varchar(1000) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_UserAgentCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`TransID`),
  KEY `IX_RawTransaction_IsProcessed` (`IsProcessed`),
  KEY `IX_RawTransaction_SubscriberName` (`SubscriberName`,`CreatedDate`),
  KEY `IX_RawTransaction_CreatedDate` (`CreatedDate`)
) ENGINE=InnoDB;
*/

ALTER TABLE RawTransaction
		ADD COLUMN WebRTCIPCode 		VARCHAR(32)
	,	ADD COLUMN FPPatternCode01	VARCHAR(32) COMMENT 'Hash Code of combine Multi-Group ' 
	,	ADD COLUMN FPPatternCode02	VARCHAR(32) COMMENT 'Hash Code of combine Multi-Group '
    
    ,	DROP COLUMN FingerprintCode
    ,	DROP COLUMN FingerprintMoreInfo
    ,	DROP COLUMN FP_Tagging
    ,	DROP COLUMN FP_FingerPrintCode
    ,	DROP COLUMN FP_FingerPrintExtraCode
    ,	DROP COLUMN FP_FingerPrintOldCode
    ,	DROP COLUMN FP_UserAgentCode    

;
/* BK ProcessedTransaction SCHEMA DEV LOCAL 
DROP TABLE   ProcessedTransaction;
CREATE TABLE `ProcessedTransaction` (
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `SubscriberName` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  `DeviceCode` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `FingerprintCode` varchar(620) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `FingerprintMoreInfo` varchar(250) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `UserAgent` varchar(1000) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IP` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IPID` decimal(50,0) DEFAULT NULL,
  `PluginID` bigint DEFAULT NULL,
  `URL` varchar(500) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `Action` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `ActionResult` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `InvalidDevice` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TransStatus` bit(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
  `FPSTransID` bigint unsigned DEFAULT NULL,
  `Flagged` smallint DEFAULT NULL,
  `IsProcessed` tinyint NOT NULL DEFAULT '0',
  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `InsertTime` timestamp(4) NULL DEFAULT NULL,
  `BotDetectionValue` bit(32) DEFAULT NULL,
  `BotComponentID` bigint unsigned DEFAULT NULL,
  `FakeIP` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IsIncognitoMode` tinyint(1) DEFAULT NULL,
  `ChallengeCode` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_Tagging` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_FingerPrintCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_FingerPrintExtraCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_FingerPrintOldCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `FP_UserAgentCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_AndroidCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_CustomCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_MediaDRMCode` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_IsMobileApp` tinyint NOT NULL DEFAULT '0',
  `MB_IsEmulator` tinyint NOT NULL DEFAULT '0',
  `MB_ModelName` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_Manufacturer` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_Brand` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_OS` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_Timezone` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_Language` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_Country` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  `MB_SDKVersion` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`TransID`,`CreatedDate`),
  KEY `IX_RawTransaction_IsProcessed` (`IsProcessed`),
  KEY `IX_RawTransaction_TransTime` (`CreatedDate`),
  KEY `IX_RawTransaction_SubscriberName_CreatedDate` (`SubscriberName`,`CreatedDate`)
) ENGINE=InnoDB AUTO_INCREMENT=8072154509 DEFAULT CHARSET=utf8mb3 COLLATE=utf8_unicode_ci
/*!50100 PARTITION BY RANGE (yearweek(`CreatedDate`,0))
(PARTITION pw202534 VALUES LESS THAN (202535) ENGINE = InnoDB,
 PARTITION pw202535 VALUES LESS THAN (202536) ENGINE = InnoDB,
 PARTITION pw202536 VALUES LESS THAN (202537) ENGINE = InnoDB,
 PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

ALTER TABLE ProcessedTransaction
		ADD COLUMN WebRTCIPCode 		VARCHAR(32)
	,	ADD COLUMN FPPatternCode01	VARCHAR(32) COMMENT 'Hash Code of combine Multi-Group ' 
	,	ADD COLUMN FPPatternCode02	VARCHAR(32) COMMENT 'Hash Code of combine Multi-Group '
    
	,	DROP COLUMN FingerprintCode
    ,	DROP COLUMN FingerprintMoreInfo
    ,	DROP COLUMN FP_Tagging
    ,	DROP COLUMN FP_FingerPrintCode
    ,	DROP COLUMN FP_FingerPrintExtraCode
    ,	DROP COLUMN FP_FingerPrintOldCode
    ,	DROP COLUMN FP_UserAgentCode    
;
/* BK Transaction SCHEMA DEV LOCAL  
	DROP TABLE   Transaction;
	CREATE TABLE `Transaction` (
	  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
	  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
	  `TransTime` timestamp(4) NOT NULL,
	  `SubscriberID` int DEFAULT NULL,
	  `AccountID` bigint unsigned DEFAULT NULL,
	  `URLID` bigint unsigned DEFAULT NULL,
	  `DeviceCodeID` bigint unsigned DEFAULT NULL,
	  `DeviceID` bigint unsigned DEFAULT NULL,
	  `FirstDeviceCode` varchar(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
	  `DeviceStatus` tinyint DEFAULT NULL,
	  `DeviceFingerprintID` bigint unsigned DEFAULT NULL,
	  `UserAgentKey` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
	  `IP` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
	  `IPID` decimal(50,0) DEFAULT NULL,
	  `ActionResultID` bigint DEFAULT NULL,
	  `Flagged` smallint DEFAULT NULL COMMENT 'captcha & browserless',
	  `PluginID` bigint DEFAULT NULL,
	  `TransStatus` bit(16) DEFAULT NULL,
	  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
	  `InsertTime` timestamp(4) NOT NULL,
	  `DeviceCode` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
	  `FingerprintCode` varchar(620) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
	  `FingerprintMoreInfo` varchar(250) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
	  `RawTransID` bigint unsigned NOT NULL,
	  `BotDetectionValue` bit(32) DEFAULT NULL,
	  `BotComponentID` bigint unsigned DEFAULT NULL,
	  `FakeIP` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
	  `IsIncognitoMode` tinyint(1) DEFAULT NULL,
	  `JSChallengeInfoID` bigint unsigned DEFAULT NULL,
	  `FP_TaggingID` bigint unsigned DEFAULT NULL,
	  `FP_FingerPrintID` bigint unsigned DEFAULT NULL,
	  `FP_FingerPrintExtraID` bigint unsigned DEFAULT NULL,
	  `FP_FingerPrintOldID` bigint unsigned DEFAULT NULL,
	  `FP_UserAgentID` bigint unsigned DEFAULT NULL,
	  PRIMARY KEY (`TransID`),
	  UNIQUE KEY `UN_RawTransID` (`RawTransID`)
	) ENGINE=InnoDB;
*/

ALTER TABLE Transaction
		ADD COLUMN WebRTCIPID 		BIGINT        
	,	ADD COLUMN FPPatternID01	VARCHAR(32) COMMENT 'Hash Code of combine Multi-Group' 
	,	ADD COLUMN FPPatternID02	VARCHAR(32)  
   
	,	DROP COLUMN DeviceCodeID
    ,	DROP COLUMN DeviceID
    ,	DROP COLUMN FirstDeviceCode
    ,	DROP COLUMN DeviceStatus
    ,	DROP COLUMN DeviceFingerprintID
    
	,	DROP COLUMN FingerprintCode
    ,	DROP COLUMN FingerprintMoreInfo
    ,	DROP COLUMN FP_TaggingID
    ,	DROP COLUMN FP_FingerPrintID
    ,	DROP COLUMN FP_FingerPrintExtraID
    ,	DROP COLUMN FP_FingerPrintOldID
    ,	DROP COLUMN FP_UserAgentID   
;

/*
DROP TABLE Transaction07;
CREATE TABLE `Transaction07` (
  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `LoginName` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `SubscriberID` int DEFAULT NULL,
  `AccountID` bigint unsigned DEFAULT NULL,
  `URLID` bigint unsigned DEFAULT NULL,
  `DeviceCodeID` bigint unsigned DEFAULT NULL,
  `DeviceID` bigint unsigned DEFAULT NULL,
  `FirstDeviceCode` varchar(64) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `DeviceStatus` tinyint DEFAULT NULL,
  `DeviceFingerprintID` bigint unsigned DEFAULT NULL,
  `UserAgentKey` varchar(32) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IP` varchar(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IPID` decimal(50,0) DEFAULT NULL,
  `ActionResultID` bigint DEFAULT NULL,
  `Flagged` smallint DEFAULT NULL COMMENT 'captcha & browserless',
  `PluginID` bigint DEFAULT NULL,
  `TransStatus` bit(16) DEFAULT NULL,
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  `InsertTime` timestamp(4) NOT NULL,
  `RawTransID` bigint unsigned DEFAULT NULL,
  `BotDetectionValue` bit(32) DEFAULT NULL,
  `BotComponentID` bigint unsigned DEFAULT NULL,
  `FakeIP` varchar(100) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL,
  `IsIncognitoMode` tinyint(1) DEFAULT NULL,
  `JSChallengeInfoID` bigint unsigned DEFAULT NULL,
  `FP_UserAgentID` bigint unsigned DEFAULT NULL,
  `FP_DeviceMappingID` bigint unsigned DEFAULT NULL,
  `FP_DeviceID` bigint unsigned DEFAULT NULL,
  `FP_DeviceStatus` tinyint DEFAULT NULL,
  PRIMARY KEY (`TransID`,`CreatedDate`),
  KEY `IX_Transaction07_TransTime` (`TransTime` DESC),
  KEY `IX_Transaction07_SubscriberID_TransTime` (`SubscriberID`,`TransTime` DESC),
  KEY `IX_Transaction07_AccountID` (`AccountID`),
  KEY `IX_Transaction07_CreatedDate_AccountID` (`CreatedDate`,`AccountID`),
  KEY `IX_Transaction07_FP_DeviceMappingID` (`FP_DeviceMappingID`)
) ENGINE=InnoDB
/*!50100 PARTITION BY RANGE (yearweek(`CreatedDate`,0))
(PARTITION pw202534 VALUES LESS THAN (202535) ENGINE = InnoDB,
 PARTITION pw202535 VALUES LESS THAN (202536) ENGINE = InnoDB,
 PARTITION pw202536 VALUES LESS THAN (202537) ENGINE = InnoDB,
 PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */
;

ALTER TABLE Transaction07
		ADD COLUMN WebRTCIPID BIGINT
    
	,	ADD COLUMN FPPatternID01  VARCHAR(32) COMMENT 'Hash Code of combine Multi-Group' 
	,	ADD COLUMN FPPatternID02  VARCHAR(32)    
;
