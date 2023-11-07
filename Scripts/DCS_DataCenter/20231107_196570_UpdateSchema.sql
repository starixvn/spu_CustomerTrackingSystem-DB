/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20231107@Jonathan.Doan
	Task:	 	Integrate FPSjs to DCS [Redmine ID: #196570]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20231107@Jonathan.Doan: Created [Redmine ID: #196570]
	Reviewer:
*/
USE DCS_DataCenter;

CREATE TABLE `Cookie` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `CookieCode` VARCHAR(64) NOT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_Cookie_CookieCode` (`CookieCode`)
) ENGINE=InnoDB;

CREATE TABLE `RawFingerPrint` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FingerPrintCode` VARCHAR(64) NOT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_RawFingerPrint_FingerPrintCode` (`FingerPrintCode`)
) ENGINE=InnoDB;

CREATE TABLE `FingerPrintAttribute` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `RawFingerPrintID` BIGINT UNSIGNED NOT NULL,
  `Platform` VARCHAR(45) DEFAULT NULL,
  `LocalStorage` TINYINT DEFAULT NULL,
  `DoNotTrack` VARCHAR(15) DEFAULT NULL,
  `Cookies` TINYINT DEFAULT NULL,
  `Canvas` LONGTEXT,
  `GLRenderer` VARCHAR(200) DEFAULT NULL,
  `Audio` VARCHAR(25) DEFAULT NULL,
  `ColorDepth` SMALLINT DEFAULT NULL,
  `ColorGamut` VARCHAR(10) DEFAULT NULL,
  `Contrast` SMALLINT DEFAULT NULL,
  `CpuClass` VARCHAR(45) DEFAULT NULL,
  `DeviceMemory` TINYINT DEFAULT NULL,
  `DomBlockers` VARCHAR(45) DEFAULT NULL,
  `FontPreferencePrint` LONGTEXT,
  `Fonts` LONGTEXT,
  `ForcedColors` TINYINT DEFAULT NULL,
  `HardwareConcurrency` TINYINT DEFAULT NULL,
  `HDR` TINYINT DEFAULT NULL,
  `IndexedDB` TINYINT DEFAULT NULL,
  `InvertedColors` TINYINT DEFAULT NULL,
  `Languages` LONGTEXT,
  `Math` LONGTEXT,
  `Monochrome` TINYINT DEFAULT NULL,
  `OpenDatabase` TINYINT DEFAULT NULL,
  `OsCpu` VARCHAR(45) DEFAULT NULL,
  `Plugins` LONGTEXT,
  `ReducedMotion` TINYINT DEFAULT NULL,
  `Resolution` VARCHAR(200) DEFAULT NULL,
  `SessionStorage` TINYINT DEFAULT NULL,
  `Timezone` VARCHAR(45) DEFAULT NULL,
  `TouchSupport` VARCHAR(200) DEFAULT NULL,
  `Vendor` VARCHAR(45) DEFAULT NULL,
  `VendorFlavors` VARCHAR(45) DEFAULT NULL,
  `WebglPrint` VARCHAR(200) DEFAULT NULL,
  `ApplePay` SMALLINT DEFAULT NULL COMMENT 'Disabled = 0, Enabled = 1, NoAPI = -1, NotAvailableInInsecureContext = -2, NotAvailableInFrame = -3',
  `Architecture` INT DEFAULT NULL,
  `PDFViewerEnabled` TINYINT DEFAULT NULL,
  `PrivateClickMeasurement` VARCHAR(100) DEFAULT NULL,
  `ReducedTransparency` TINYINT DEFAULT NULL,
  `WebGlBasics` VARCHAR(100) DEFAULT NULL,
  `WebGlExtensions` VARCHAR(64) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FingerPrintAttribute_RawFingerPrintID` (`RawFingerPrintID`)
) ENGINE=InnoDB;

CREATE TABLE `BrowserInstance` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `BrowserInstanceCode` VARCHAR(64) NOT NULL COMMENT 'hash ALL',
  `UserAgent` LONGTEXT,
  `BrowserFamilyCode` VARCHAR(64) DEFAULT NULL COMMENT 'hash: OSName, BrowserName, Platform',
  `OSName` VARCHAR(100) DEFAULT NULL,
  `Platform` VARCHAR(45) DEFAULT NULL,
  `BrowserName` VARCHAR(100) DEFAULT NULL,
  `BrowserVersion` VARCHAR(50) DEFAULT NULL,
  `Accept` VARCHAR(100) DEFAULT NULL,
  `Encoding` VARCHAR(200) DEFAULT NULL,
  `Headers` LONGTEXT,
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_BrowserInstance_BrowserInstanceCode` (`BrowserInstanceCode`),
  KEY `IX_BrowserInstance_BrowserFamilyCode` (`BrowserFamilyCode`)
) ENGINE=InnoDB;

CREATE TABLE `BrowserInstanceRawFingerPrint` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `RawFingerPrintID` BIGINT UNSIGNED NOT NULL,
  `BrowserInstanceID` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_BrowserInstanceRawFingerPrint_FPId_BrowserInstanceId` (`RawFingerPrintID`,`BrowserInstanceID`)
) ENGINE=InnoDB;

CREATE TABLE `RawUserAgent` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `UserAgentCode` VARCHAR(100) NOT NULL,
  `UserAgent` LONGTEXT,
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
  `BotName` VARCHAR(100) DEFAULT NULL,
  `BotCategory` VARCHAR(50) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_RawUserAgent_UserAgentCode` (`UserAgentCode`),
  KEY `IX_RawUserAgent_Brand` (`Brand`)
) ENGINE=InnoDB;

ALTER TABLE RawTransaction
ADD COLUMN CookieID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN RawFingerPrintID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN BrowserInstanceID BIGINT UNSIGNED DEFAULT NULL;