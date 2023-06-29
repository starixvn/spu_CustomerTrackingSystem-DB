/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2"></info>*/
/*
Creator:	20230628@Casey.Huynh
Task:	 	New DB DCS_Extra
Server:  	Master
DBName:		DCS_Extra

Revisions: 
		- 20230628@Casey.Huynh: Created [Redmine ID: #190188]
Reviewer:
*/

CREATE DATABASE `DCS_Extra` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE DCS_Extra;
CREATE TABLE `ActionResult` (
  `ActionResultID` int NOT NULL AUTO_INCREMENT,
  `Action` varchar(100) NOT NULL,
  `ActionResult` varchar(100) NOT NULL,
  `ActionResultStatus` tinyint NOT NULL COMMENT '0: Inactive; 1: Active; -1: Unhandled(Action has not defined in Intergrated Action List)',
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  PRIMARY KEY (`ActionResultID`),
  UNIQUE KEY `UK_ActionResult_ActionResultDetails` (`Action`,`ActionResult`)
) ENGINE=InnoDB;

CREATE TABLE `Subscriber` (
  `SubscriberID` int NOT NULL AUTO_INCREMENT,
  `SubscriberName` varchar(50) DEFAULT NULL,
  `SubscriberPrefix` varchar(30) DEFAULT NULL,
  `SubscriberType` tinyint unsigned DEFAULT NULL COMMENT ' 0: Credit, 1: Deposit, 2: SUB not have Customer in MainDB (ex: CTMAX, AGENTCTMAX)',
  `SubscriberStatus` tinyint NOT NULL COMMENT '0: Inactive; 1: Active',
  `CreatedDate` datetime DEFAULT NULL,
  `CreatedBy` int DEFAULT NULL,
  `IsTest` tinyint DEFAULT NULL,
  `IntegrationDate` datetime DEFAULT NULL,
  `TerminatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`SubscriberID`),
  UNIQUE KEY `IX_Subscriber_SubscriberName_SubScriberPrefix` (`SubscriberName`,`SubscriberPrefix`),
  KEY `IX_Subscriber_SubscriberPrefix` (`SubscriberPrefix`),
  KEY `IX_Subscriber` (`SubscriberStatus`)
) ENGINE=InnoDB;
    
CREATE TABLE `Account` (
  `AccountID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `LoginName` varchar(100) NOT NULL,
  `SubscriberID` int NOT NULL,
  `SubscriberType` tinyint NOT NULL,
  `CreatedTime` timestamp(4) NOT NULL,
  `LastLoginTime` timestamp(4) NOT NULL,
  `CreatedDate` datetime NOT NULL,
  `InsertTime` timestamp(4) NOT NULL,
  `IsCTSTransformed` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`AccountID`),
  UNIQUE KEY `UK_Account_SubscriberIDLoginName` (`SubscriberID`,`LoginName`),
  KEY `IX_Account_IsCTSTransformed` (`IsCTSTransformed`),
  KEY `IXF_Account_LastLoginTime` ((cast(`LastLoginTime` as date)))
) ENGINE=InnoDB ;

CREATE TABLE `AccountDevice` (
  `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `AccountID` bigint unsigned NOT NULL,
  `DeviceID` bigint unsigned NOT NULL,
  `LastTransDate` date NOT NULL,
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UN_AccountDevice_AccountID_DeviceID` (`AccountID`,`DeviceID`),
  KEY `IX_AccountDevice_LastTransDate` (`LastTransDate`)
) ENGINE=InnoDB ;

CREATE TABLE `AccountLastLoginTimeProcess` (
  `ID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `AccountID` bigint unsigned DEFAULT NULL,
  `LastLoginTime` timestamp(4) NOT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB;

CREATE TABLE `Association` (
  `AssociationID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `DeviceID` bigint unsigned NOT NULL,
  `AccountID` bigint unsigned NOT NULL,
  `SubscriberID` int NOT NULL,
  `CreatedTime` timestamp(4) NOT NULL,
  `CreatedDate` timestamp(4) NOT NULL,
  `InsertTime` timestamp(4) NOT NULL,
  `IsCTSTransformed` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`AccountID`,`DeviceID`),
  KEY `IX_Association_SubscriberID_AccountID_DeviceID` (`SubscriberID`,`AccountID`,`DeviceID`),
  KEY `IX_Association_IsCTSTransformed` (`IsCTSTransformed`),
  KEY `IX_Association_CTSCustID_DeviceID_AccountID` (`DeviceID`,`AccountID`),
  KEY `KEY_AssociationID` (`AssociationID`)
) ENGINE=InnoDB;

CREATE TABLE `Device` (
  `DeviceID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `FirstDeviceCode` varchar(32) NOT NULL,
  `UserAgentKey` varchar(32) DEFAULT NULL,
  `FirstTransID` bigint DEFAULT NULL,
  `CreatedTime` timestamp(4) NOT NULL COMMENT 'CreatedTime of First Transaction',
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only, Date of First Transaction',
  `InsertTime` timestamp(4) NOT NULL COMMENT 'DateTime, the time that data Insert to Table',
  PRIMARY KEY (`DeviceID`),
  UNIQUE KEY `UK_Device_FirstDeviceCode` (`FirstDeviceCode`),
  KEY `IX_Device_CreatedDate` (`CreatedDate`)
) ENGINE=InnoDB;

CREATE TABLE `DeviceCode` (
  `DeviceCodeID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `DeviceCode` varchar(32) NOT NULL COMMENT ' DeviceCode Captured From DI',
  `DeviceID` bigint unsigned DEFAULT NULL,
  `FirstTransID` bigint DEFAULT NULL,
  `CreatedTime` timestamp(4) NOT NULL,
  `CreatedDate` datetime NOT NULL,
  `InsertTime` timestamp(4) NOT NULL,
  PRIMARY KEY (`DeviceCodeID`),
  UNIQUE KEY `UK_DeviceCode_DeviceID` (`DeviceCode`,`DeviceID`),
  KEY `IX_DeviceCode_CreatedDate` (`CreatedDate`),
  KEY `IX_DeviceCode_DeviceID` (`DeviceID`)
) ENGINE=InnoDB;

CREATE TABLE `DeviceFingerprint` (
  `DeviceFingerprintID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `DeviceID` bigint unsigned NOT NULL,
  `FingerprintCode` varchar(620) NOT NULL,
  `CreatedTime` timestamp(4) NOT NULL,
  `InsertTime` timestamp(4) NOT NULL,
  PRIMARY KEY (`DeviceID`,`FingerprintCode`),
  KEY `KEY_DeviceFingerprintID` (`DeviceFingerprintID`)
) ENGINE=InnoDB ;

CREATE TABLE `DeviceType` (
  `DeviceTypeID` int unsigned NOT NULL AUTO_INCREMENT,
  `DeviceTypeName` varchar(20) NOT NULL,
  `GroupName` varchar(20) NOT NULL,
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`DeviceTypeID`),
  UNIQUE KEY `UK_DeviceTypeName` (`DeviceTypeName`)
) ENGINE=InnoDB;

CREATE TABLE `OS` (
  `OSID` int unsigned NOT NULL AUTO_INCREMENT,
  `OSName` varchar(100) NOT NULL,
  `CreatedDate` datetime NOT NULL,
  PRIMARY KEY (`OSID`),
  UNIQUE KEY `UK_OSName` (`OSName`)
) ENGINE=InnoDB;

CREATE TABLE `ProcessedTransaction` (
  `LoginName` varchar(100) NOT NULL,
  `SubscriberName` varchar(50) NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  `DeviceCode` varchar(32) DEFAULT NULL,
  `FingerprintCode` varchar(620) DEFAULT NULL,
  `FingerprintMoreInfo` varchar(250) DEFAULT NULL,
  `UserAgent` varchar(1000) DEFAULT NULL,
  `IP` varchar(50) DEFAULT NULL,
  `IPID` decimal(50,0) DEFAULT NULL,
  `PluginID` bigint DEFAULT NULL,
  `URL` varchar(500) DEFAULT NULL,
  `Action` varchar(100) DEFAULT NULL,
  `ActionResult` varchar(100) DEFAULT NULL,
  `InvalidDevice` varchar(1000) DEFAULT NULL,
  `TransStatus` bit(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
  `FPSTransID` bigint unsigned DEFAULT NULL,
  `Flagged` smallint DEFAULT NULL,
  `IsProcessed` tinyint NOT NULL DEFAULT '0',
  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `InsertTime` timestamp(4) NULL DEFAULT NULL,
  `BotDetectionValue` bit(32) DEFAULT NULL,
  `BotComponentID` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`TransID`,`CreatedDate`),
  KEY `IX_RawTransaction_IsProcessed` (`IsProcessed`),
  KEY `IX_RawTransaction_TransTime` (`CreatedDate`),
  KEY `IX_RawTransaction_SubscriberName_CreatedDate` (`SubscriberName`,`CreatedDate`)
) ENGINE=InnoDB 
/*!50100 PARTITION BY RANGE (yearweek(`CreatedDate`,0))
(PARTITION pw202301 VALUES LESS THAN (202302) ENGINE = InnoDB,
 PARTITION pw202302 VALUES LESS THAN (202303) ENGINE = InnoDB,
 PARTITION pw202303 VALUES LESS THAN (202304) ENGINE = InnoDB,
 PARTITION pw202304 VALUES LESS THAN (202305) ENGINE = InnoDB,
 PARTITION pw202305 VALUES LESS THAN (202306) ENGINE = InnoDB,
 PARTITION pw202306 VALUES LESS THAN (202307) ENGINE = InnoDB,
 PARTITION pw202307 VALUES LESS THAN (202308) ENGINE = InnoDB,
 PARTITION pw202308 VALUES LESS THAN (202309) ENGINE = InnoDB,
 PARTITION pw202311 VALUES LESS THAN (202312) ENGINE = InnoDB,
 PARTITION pw202324 VALUES LESS THAN (202325) ENGINE = InnoDB,
 PARTITION pw202325 VALUES LESS THAN (202326) ENGINE = InnoDB,
 PARTITION pw202326 VALUES LESS THAN (202327) ENGINE = InnoDB,
 PARTITION pw202327 VALUES LESS THAN (202328) ENGINE = InnoDB,
 PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

CREATE TABLE `RawTransaction` (
  `LoginName` varchar(100) NOT NULL,
  `SubscriberName` varchar(50) NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  `DeviceCode` varchar(32) DEFAULT NULL,
  `FingerprintCode` varchar(620) DEFAULT NULL,
  `FingerprintMoreInfo` varchar(250) DEFAULT NULL,
  `UserAgent` varchar(1000) DEFAULT NULL,
  `IP` varchar(50) DEFAULT NULL,
  `IPID` decimal(50,0) DEFAULT NULL,
  `PluginID` bigint DEFAULT NULL,
  `URL` varchar(500) DEFAULT NULL,
  `Action` varchar(100) DEFAULT NULL,
  `ActionResult` varchar(100) DEFAULT NULL,
  `InvalidDevice` varchar(1000) DEFAULT NULL,
  `TransStatus` bit(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
  `FPSTransID` bigint unsigned DEFAULT NULL,
  `Flagged` smallint DEFAULT NULL,
  `IsProcessed` tinyint NOT NULL DEFAULT '0',
  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `InsertTime` timestamp(4) NULL DEFAULT NULL,
  `BotDetectionValue` bit(32) DEFAULT NULL,
  `BotComponentID` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`TransID`,`CreatedDate`),
  KEY `IX_RawTransaction_IsProcessed` (`IsProcessed`),
  KEY `IX_RawTransaction_SubscriberName` (`SubscriberName`,`CreatedDate`)
) ENGINE=InnoDB 
/*!50100 PARTITION BY RANGE (yearweek(`CreatedDate`,0))
(PARTITION pw202301 VALUES LESS THAN (202302) ENGINE = InnoDB,
 PARTITION pw202302 VALUES LESS THAN (202303) ENGINE = InnoDB,
 PARTITION pw202303 VALUES LESS THAN (202304) ENGINE = InnoDB,
 PARTITION pw202304 VALUES LESS THAN (202305) ENGINE = InnoDB,
 PARTITION pw202305 VALUES LESS THAN (202306) ENGINE = InnoDB,
 PARTITION pw202306 VALUES LESS THAN (202307) ENGINE = InnoDB,
 PARTITION pw202307 VALUES LESS THAN (202308) ENGINE = InnoDB,
 PARTITION pw202308 VALUES LESS THAN (202309) ENGINE = InnoDB,
 PARTITION pw202311 VALUES LESS THAN (202312) ENGINE = InnoDB,
 PARTITION pw202321 VALUES LESS THAN (202322) ENGINE = InnoDB,
 PARTITION pw202322 VALUES LESS THAN (202323) ENGINE = InnoDB,
 PARTITION pw202323 VALUES LESS THAN (202324) ENGINE = InnoDB,
 PARTITION pw202324 VALUES LESS THAN (202325) ENGINE = InnoDB,
 PARTITION pw202325 VALUES LESS THAN (202326) ENGINE = InnoDB,
 PARTITION pw202326 VALUES LESS THAN (202327) ENGINE = InnoDB,
 PARTITION pw202327 VALUES LESS THAN (202328) ENGINE = InnoDB,
 PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

CREATE TABLE `StaticList` (
  `ListID` int NOT NULL,
  `ItemID` smallint NOT NULL,
  `ListCode` varchar(100) DEFAULT NULL,
  `ListName` varchar(200) DEFAULT NULL,
  `ItemCode` varchar(100) DEFAULT NULL,
  `ItemName` varchar(200) DEFAULT NULL,
  `Status` tinyint(1) DEFAULT NULL,
  `Description` varchar(200) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`ListID`,`ItemID`),
  UNIQUE KEY `UX_StaticList_ListCode_ItemCode` (`ListCode`,`ItemCode`)
) ENGINE=InnoDB ;

CREATE TABLE `Transaction` (
  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `LoginName` varchar(100) NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `SubscriberID` int DEFAULT NULL,
  `AccountID` bigint unsigned DEFAULT NULL,
  `URLID` bigint unsigned DEFAULT NULL,
  `DeviceCodeID` bigint unsigned DEFAULT NULL,
  `DeviceID` bigint unsigned DEFAULT NULL,
  `FirstDeviceCode` varchar(64) DEFAULT NULL,
  `DeviceStatus` tinyint DEFAULT NULL,
  `DeviceFingerprintID` bigint unsigned DEFAULT NULL,
  `UserAgentKey` varchar(32) DEFAULT NULL,
  `IP` varchar(50) DEFAULT NULL,
  `IPID` decimal(50,0) DEFAULT NULL,
  `ActionResultID` bigint DEFAULT NULL,
  `Flagged` smallint DEFAULT NULL COMMENT 'captcha & browserless',
  `PluginID` bigint DEFAULT NULL,
  `TransStatus` bit(16) DEFAULT NULL,
  `CreatedDate` datetime NOT NULL COMMENT 'Date Only',
  `InsertTime` timestamp(4) NOT NULL,
  `DeviceCode` varchar(32) DEFAULT NULL,
  `FingerprintCode` varchar(620) DEFAULT NULL,
  `FingerprintMoreInfo` varchar(250) DEFAULT NULL,
  `RawTransID` bigint unsigned NOT NULL,
  `BotDetectionValue` bit(32) DEFAULT NULL,
  `BotComponentID` bigint unsigned DEFAULT NULL,
  PRIMARY KEY (`TransID`),
  UNIQUE KEY `UN_RawTransID` (`RawTransID`)
) ENGINE=InnoDB;

CREATE TABLE `Transaction07` (
  `TransID` bigint unsigned NOT NULL AUTO_INCREMENT,
  `LoginName` varchar(100) NOT NULL,
  `TransTime` timestamp(4) NOT NULL,
  `SubscriberID` int DEFAULT NULL,
  `AccountID` bigint unsigned DEFAULT NULL,
  `URLID` bigint unsigned DEFAULT NULL,
  `DeviceCodeID` bigint unsigned DEFAULT NULL,
  `DeviceID` bigint unsigned DEFAULT NULL,
  `FirstDeviceCode` varchar(64) DEFAULT NULL,
  `DeviceStatus` tinyint DEFAULT NULL,
  `DeviceFingerprintID` bigint unsigned DEFAULT NULL,
  `UserAgentKey` varchar(32) DEFAULT NULL,
  `IP` varchar(50) DEFAULT NULL,
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
  PRIMARY KEY (`TransID`,`CreatedDate`),
  KEY `IX_Transaction07_TransTime` (`TransTime` DESC),
  KEY `IX_Transaction07_SubscriberID_TransTime` (`SubscriberID`,`TransTime` DESC),
  KEY `IX_Transaction07_AccountID` (`AccountID`),
  KEY `IX_Transaction07_CreatedDate_AccountID` (`CreatedDate`,`AccountID`)
) ENGINE=InnoDB
/*!50100 PARTITION BY RANGE (yearweek(`CreatedDate`,0))
(PARTITION pw202251 VALUES LESS THAN (202252) ENGINE = InnoDB,
 PARTITION pw202252 VALUES LESS THAN (202253) ENGINE = InnoDB,
 PARTITION pw202301 VALUES LESS THAN (202302) ENGINE = InnoDB,
 PARTITION pw202302 VALUES LESS THAN (202303) ENGINE = InnoDB,
 PARTITION pw202303 VALUES LESS THAN (202304) ENGINE = InnoDB,
 PARTITION pw202304 VALUES LESS THAN (202305) ENGINE = InnoDB,
 PARTITION pw202305 VALUES LESS THAN (202306) ENGINE = InnoDB,
 PARTITION pw202306 VALUES LESS THAN (202307) ENGINE = InnoDB,
 PARTITION pw202307 VALUES LESS THAN (202308) ENGINE = InnoDB,
 PARTITION pw202308 VALUES LESS THAN (202309) ENGINE = InnoDB,
 PARTITION pw202309 VALUES LESS THAN (202310) ENGINE = InnoDB,
 PARTITION pw202311 VALUES LESS THAN (202312) ENGINE = InnoDB,
 PARTITION pw202313 VALUES LESS THAN (202314) ENGINE = InnoDB,
 PARTITION pw202314 VALUES LESS THAN (202315) ENGINE = InnoDB,
 PARTITION pw202316 VALUES LESS THAN (202317) ENGINE = InnoDB,
 PARTITION pw202317 VALUES LESS THAN (202318) ENGINE = InnoDB,
 PARTITION pw202318 VALUES LESS THAN (202319) ENGINE = InnoDB,
 PARTITION pw202319 VALUES LESS THAN (202320) ENGINE = InnoDB,
 PARTITION pw202320 VALUES LESS THAN (202321) ENGINE = InnoDB,
 PARTITION pw202321 VALUES LESS THAN (202322) ENGINE = InnoDB,
 PARTITION pw202322 VALUES LESS THAN (202323) ENGINE = InnoDB,
 PARTITION pw202323 VALUES LESS THAN (202324) ENGINE = InnoDB,
 PARTITION pw202324 VALUES LESS THAN (202325) ENGINE = InnoDB,
 PARTITION pw202325 VALUES LESS THAN (202326) ENGINE = InnoDB,
 PARTITION pw202326 VALUES LESS THAN (202327) ENGINE = InnoDB,
 PARTITION pw202327 VALUES LESS THAN (202328) ENGINE = InnoDB,
 PARTITION pw999999 VALUES LESS THAN MAXVALUE ENGINE = InnoDB) */;

CREATE TABLE `TransStatus` (
  `TransStatusName` varchar(100) DEFAULT NULL,
  `StatusValue` bit(16) NOT NULL,
  `Notes` varchar(200) DEFAULT NULL,
  `IsTransformed` bit(1) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`StatusValue`)
) ENGINE=InnoDB ;

CREATE TABLE `URL` (
  `URLID` int NOT NULL AUTO_INCREMENT,
  `SubscriberID` int DEFAULT NULL,
  `URLDetails` varchar(250) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  PRIMARY KEY (`URLID`),
  UNIQUE KEY `UK_URL_URLDetails` (`URLDetails`)
) ENGINE=InnoDB;

CREATE TABLE `UserAgent` (
  `UserAgentKey` varchar(32) NOT NULL,
  `UserAgent` varchar(10000) DEFAULT NULL,
  `BrowserID` int unsigned DEFAULT NULL,
  `OSID` int unsigned DEFAULT NULL,
  `OS` varchar(100) DEFAULT NULL,
  `Browser` varchar(100) DEFAULT NULL,
  `CreatedDate` datetime DEFAULT NULL,
  `DeviceTypeID` int unsigned DEFAULT NULL,
  `Created` datetime DEFAULT CURRENT_TIMESTAMP,
  `Modified` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`UserAgentKey`),
  KEY `IX_BrowserID_OSID` (`BrowserID`,`OSID`) /*!80000 INVISIBLE */,
  KEY `IX_UserAgent_BrowserID` (`BrowserID`),
  KEY `IX_UserAgent_OSID` (`OSID`),
  KEY `IX_UserAgent_DeviceTypeID` (`DeviceTypeID`)
) ENGINE=InnoDB ;

CREATE TABLE `SystemSetting` (
  `ID` int NOT NULL AUTO_INCREMENT,
  `VGroup` varchar(128) DEFAULT NULL,
  `VName` varchar(128) DEFAULT NULL,
  `VValue` varchar(255) DEFAULT NULL,
  `UpdatedTime` datetime DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `VName_UNIQUE` (`VName`),
  UNIQUE KEY `UN_Group_Name` (`VName`,`VGroup`)
) ENGINE=InnoDB;
#==========================================================================
#==========================INITIAL DATA================================================

INSERT INTO DCS_Extra.Subscriber(SubscriberID, SubscriberName, SubscriberPrefix, SubscriberType, SubscriberStatus, CreatedDate, CreatedBy, IsTest, IntegrationDate, TerminatedDate)
VALUES (8000001,'CTMAX','',10,1,NOW(),NULL,0,NOW(),NULL)
	,  (8000002,'Velki','',10,1,NOW(),NULL,0,NOW(),NULL);

LOAD DATA LOCAL INFILE 'D:/SPU/FPSChangeSource/DCS_Extra/DeviceType.csv'
INTO TABLE DCS_Extra.DeviceType
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/SPU/FPSChangeSource/DCS_Extra/TransStatus.csv'
INTO TABLE DCS_Extra.TransStatus
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/SPU/FPSChangeSource/DCS_Extra/SystemSetting.csv'
INTO TABLE DCS_Extra.SystemSetting
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/SPU/FPSChangeSource/DCS_Extra/StaticList.csv'
INTO TABLE DCS_Extra.StaticList
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;