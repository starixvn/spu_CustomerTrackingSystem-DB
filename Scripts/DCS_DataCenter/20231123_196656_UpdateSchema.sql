/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20231123@Jonathan.Doan
	Task:	 	Integrate FPSjs to DCS Phrase 2 [Redmine ID: #196656]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20231123@Jonathan.Doan: Created [Redmine ID: #196656]
	Reviewer:
*/
USE DCS_DataCenter;

ALTER TABLE ProcessedTransaction
ADD COLUMN RawFingerPrintID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN CookieID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN RawUserAgentID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN BrowserInstanceID BIGINT UNSIGNED DEFAULT NULL;

ALTER TABLE Transaction
ADD COLUMN RawFingerPrintID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN CookieID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN RawUserAgentID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN BrowserInstanceID BIGINT UNSIGNED DEFAULT NULL;

ALTER TABLE Transaction07
ADD COLUMN RawFingerPrintID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN CookieID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN RawUserAgentID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN BrowserInstanceID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN FPDeviceID BIGINT UNSIGNED DEFAULT NULL,
ADD COLUMN RecoverType TINYINT DEFAULT NULL;


CREATE TABLE `FPDevice` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FirstRawFingerPrintID` BIGINT UNSIGNED DEFAULT NULL,
  `FirstCookieID` BIGINT UNSIGNED DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FPDevice_FirstRawFingerPrintID_FirstCookieID` (`FirstRawFingerPrintID`, `FirstCookieID`)
) ENGINE=InnoDB AUTO_INCREMENT=300000001;

CREATE TABLE `FPDeviceFingerPrint` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `RawFingerPrintID` BIGINT UNSIGNED DEFAULT NULL,
  `DeviceID` BIGINT UNSIGNED DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_FPDeviceFingerPrint_RawFingerPrintID` (`RawFingerPrintID`)
) ENGINE=InnoDB;

CREATE TABLE `DeviceCookie` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `CookieID` BIGINT UNSIGNED NOT NULL,
  `DeviceID` BIGINT UNSIGNED DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_DeviceCookie_CookieID` (`CookieID`)
) ENGINE=InnoDB;

CREATE TABLE `AccountFingerprint` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  `RawFingerPrintID` BIGINT UNSIGNED DEFAULT NULL,
  `IsEvolution` TINYINT DEFAULT '0',
  `CreatedDate` DATETIME DEFAULT NULL,
  `ModifiedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_AccountFingerprint_AccountID_RawFingerPrintID` (`AccountID`,`RawFingerPrintID`),
  KEY `IX_AccountFingerprint_IsEvolution` (`IsEvolution`)
) ENGINE=InnoDB;

CREATE TABLE `TransactionEvolution` (
  `RawFingerPrintID` BIGINT UNSIGNED NOT NULL,
  `RecoverRawFingerPrintID` BIGINT UNSIGNED NOT NULL,
  `DeviceID` BIGINT UNSIGNED NOT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`RawFingerPrintID`),
  UNIQUE KEY `UX_TransactionEvolution_RawFingerPrintID` (`RawFingerPrintID`)
) ENGINE=InnoDB;

CREATE TABLE `AssociationNew` (
  `AssociationID` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `AccountID` BIGINT UNSIGNED NOT NULL,
  `DeviceID` BIGINT UNSIGNED NOT NULL,
  `SubscriberID` int NOT NULL,
  `CreatedTime` TIMESTAMP(4) NOT NULL,
  `CreatedDate` TIMESTAMP NOT NULL,
  `InsertedTime` TIMESTAMP(4) NOT NULL,
  `IsCTSTransformed` tinyint NOT NULL DEFAULT '0'
) ENGINE=InnoDB;

INSERT INTO AssociationNew(AssociationID, AccountID, DeviceID, SubscriberID, CreatedTime, CreatedDate, InsertedTime, IsCTSTransformed)
SELECT	AssociationID
	,	AccountID
    ,	DeviceID
    ,	SubscriberID
    ,	CreatedTime
    ,	CreatedDate
    ,	InsertTime AS InsertedTime
    ,	IsCTSTransformed
FROM Association;

ALTER TABLE AssociationNew
ADD UNIQUE INDEX UX_AssociationNew_AccountID_DeviceID (AccountID, DeviceID),
ADD INDEX IX_AssociationNew_IsCTSTransformed (IsCTSTransformed),
ADD INDEX IX_AssociationNew_SubscriberID_AccountID_DeviceID_CreatedDate (SubscriberID, AccountID, DeviceID, CreatedDate),
ADD INDEX IX_Association_DeviceID_AccountID_CreatedDate (DeviceID, AccountID, CreatedDate);

CREATE TABLE `AssociationMapping` (
  `ID` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
  `AccountID` BIGINT UNSIGNED NOT NULL,
  `DeviceID` BIGINT UNSIGNED NOT NULL,
  `FPDeviceID` BIGINT UNSIGNED NOT NULL,
  `SubscriberID` int NOT NULL,
  `CreatedTime` TIMESTAMP(4) NOT NULL,
  `CreatedDate` TIMESTAMP NOT NULL,
  `InsertedTime` TIMESTAMP(4) NOT NULL,
  UNIQUE KEY `UX_AssociationMapping_AccountID_DeviceID_FPDeviceID` (`AccountID`,`DeviceID`,`FPDeviceID`)
) ENGINE=InnoDB;