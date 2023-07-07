/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2"></info>*/
/*
Creator:	20230628@Casey.Huynh
Task:	 	New DB DCS_Extra
Server:  	Master
DBName:		DCS_Extra

Revisions: 
		- 20230628@Casey.Huynh: Created [Redmine ID: #190118]
Reviewer:
*/

CREATE DATABASE `DCS_Extra` /*!40100 DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE DCS_Extra;
CREATE TABLE `BotComponent` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `Code` VARCHAR(100) NOT NULL,
  `Component` LONGTEXT NOT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_BotComponent_Code` (`Code`)
) ENGINE=InnoDB;

CREATE TABLE `BotDetection` (
  `Value` BIT(32) NOT NULL,
  `Name` VARCHAR(100) NOT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`Value`),
  KEY `IX_BotDetection_Name` (`Name`)
) ENGINE=InnoDB;

CREATE TABLE `Browser` (
  `BrowserID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `BrowserName` VARCHAR(100) NOT NULL,
  `CreatedDate` DATETIME NOT NULL,
  PRIMARY KEY (`BrowserID`),
  UNIQUE KEY `UX_Browser_BrowserName` (`BrowserName`)
) ENGINE=InnoDB ;

CREATE TABLE `ActionResult` (
  `ActionResultID` INT NOT NULL AUTO_INCREMENT,
  `Action` VARCHAR(100) NOT NULL,
  `ActionResult` VARCHAR(100) NOT NULL,
  `ActionResultStatus` TINYINT NOT NULL COMMENT '0: Inactive; 1: Active; -1: Unhandled(Action has not defined in INTergrated Action List)',
  `CreatedDate` DATETIME NOT NULL COMMENT 'Date Only',
  PRIMARY KEY (`ActionResultID`),
  UNIQUE KEY `UX_ActionResult_Action_ActionResult` (`Action`,`ActionResult`)
) ENGINE=InnoDB;

CREATE TABLE `Subscriber` (
  `SubscriberID` INT NOT NULL AUTO_INCREMENT,
  `SubscriberName` VARCHAR(50) DEFAULT NULL,
  `SubscriberPrefix` VARCHAR(30) DEFAULT NULL,
  `SubscriberType` TINYINT UNSIGNED DEFAULT NULL COMMENT ' 0: Credit, 1: Deposit, 2: SUB not have Customer in MainDB (ex: CTMAX, AGENTCTMAX)',
  `SubscriberStatus` TINYINT NOT NULL COMMENT '0: Inactive; 1: Active',
  `CreatedDate` DATETIME DEFAULT NULL,
  `CreatedBy` INT DEFAULT NULL,
  `IsTest` TINYINT DEFAULT NULL,
  `IntegrationDate` DATETIME DEFAULT NULL,
  `TerminatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`SubscriberID`),
  UNIQUE KEY `UX_Subscriber_SubscriberName_SubScriberPrefix` (`SubscriberName`,`SubscriberPrefix`),
  KEY `IX_Subscriber_SubscriberPrefix` (`SubscriberPrefix`),
  KEY `IX_Subscriber_SubscriberStatus` (`SubscriberStatus`)
) ENGINE=InnoDB;
    
CREATE TABLE `Account` (
  `AccountID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `LoginName` VARCHAR(100) NOT NULL,
  `SubscriberID` INT NOT NULL,
  `SubscriberType` TINYINT NOT NULL,
  `CreatedTime` TIMESTAMP(4) NOT NULL,
  `LastLoginTime` TIMESTAMP(4) NOT NULL,
  `CreatedDate` DATETIME NOT NULL,
  `InsertTime` TIMESTAMP(4) NOT NULL,
  PRIMARY KEY (`AccountID`),
  UNIQUE KEY `UX_Account_SubscriberID_LoginName` (`SubscriberID`,`LoginName`),
  KEY `IX_Account_LastLoginTime` ((cast(`LastLoginTime` AS DATE)))
) ENGINE=InnoDB ;


CREATE TABLE `AccountLastLoginTimeProcess` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  `LastLoginTime` TIMESTAMP(4) NOT NULL,
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
  PRIMARY KEY (`AccountID`,`DeviceID`),
  UNIQUE KEY `UX_Association_AssociationID` (`AssociationID`),
  KEY `IX_Association_SubscriberID_AccountID_DeviceID` (`SubscriberID`,`AccountID`,`DeviceID`)
) ENGINE=InnoDB;

CREATE TABLE `Device` (
  `DeviceID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `FirstDeviceCode` VARCHAR(32) NOT NULL,
  `UserAgentKey` VARCHAR(32) DEFAULT NULL,
  `FirstTransID` BIGINT DEFAULT NULL,
  `CreatedTime` TIMESTAMP(4) NOT NULL COMMENT 'CreatedTime of First Transaction',
  `CreatedDate` DATETIME NOT NULL COMMENT 'Date Only, Date of First Transaction',
  `InsertTime` TIMESTAMP(4) NOT NULL COMMENT 'DATETIME, the time that data Insert to Table',
  PRIMARY KEY (`DeviceID`),
  UNIQUE KEY `UX_Device_FirstDeviceCode` (`FirstDeviceCode`),
  KEY `IX_Device_CreatedDate` (`CreatedDate`)
) ENGINE=InnoDB;

CREATE TABLE `DeviceCode` (
  `DeviceCodeID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `DeviceCode` VARCHAR(32) NOT NULL COMMENT ' DeviceCode Captured From DI',
  `DeviceID` BIGINT UNSIGNED DEFAULT NULL,
  `FirstTransID` BIGINT DEFAULT NULL,
  `CreatedTime` TIMESTAMP(4) NOT NULL,
  `CreatedDate` DATETIME NOT NULL,
  `InsertTime` TIMESTAMP(4) NOT NULL,
  PRIMARY KEY (`DeviceCodeID`),
  UNIQUE KEY `UX_DeviceCode_DeviceCode_DeviceID` (`DeviceCode`,`DeviceID`),
  KEY `IX_DeviceCode_CreatedDate` (`CreatedDate`),
  KEY `IX_DeviceCode_DeviceID` (`DeviceID`)
) ENGINE=InnoDB;

CREATE TABLE `DeviceFingerprint` (
  `DeviceFingerprintID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `DeviceID` BIGINT UNSIGNED NOT NULL,
  `FingerprintCode` VARCHAR(620) NOT NULL,
  `CreatedTime` TIMESTAMP(4) NOT NULL,
  `InsertTime` TIMESTAMP(4) NOT NULL,
  PRIMARY KEY (`DeviceID`,`FingerprintCode`),
  KEY `IX_DeviceFingerprint_DeviceFingerprintID` (`DeviceFingerprintID`)
) ENGINE=InnoDB ;

CREATE TABLE `DeviceType` (
  `DeviceTypeID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `DeviceTypeName` VARCHAR(20) NOT NULL,
  `GroupName` VARCHAR(20) NOT NULL,
  `Created` DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`DeviceTypeID`),
  UNIQUE KEY `UX_DeviceType_DeviceTypeName` (`DeviceTypeName`)
) ENGINE=InnoDB;

CREATE TABLE `OS` (
  `OSID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `OSName` VARCHAR(100) NOT NULL,
  `CreatedDate` DATETIME NOT NULL,
  PRIMARY KEY (`OSID`),
  UNIQUE KEY `UX_OS_OSName` (`OSName`)
) ENGINE=InnoDB;

CREATE TABLE `ProcessedTransaction` (
  `LoginName` VARCHAR(100) NOT NULL,
  `SubscriberName` VARCHAR(50) NOT NULL,
  `TransTime` TIMESTAMP(4) NOT NULL,
  `CreatedDate` DATETIME NOT NULL COMMENT 'Date Only',
  `DeviceCode` VARCHAR(32) DEFAULT NULL,
  `FingerprintCode` VARCHAR(620) DEFAULT NULL,
  `FingerprintMoreInfo` VARCHAR(250) DEFAULT NULL,
  `UserAgent` VARCHAR(1000) DEFAULT NULL,
  `IP` VARCHAR(50) DEFAULT NULL,
  `IPID` DECIMAL(50,0) DEFAULT NULL,
  `PluginID` BIGINT DEFAULT NULL,
  `URL` VARCHAR(500) DEFAULT NULL,
  `Action` VARCHAR(100) DEFAULT NULL,
  `ActionResult` VARCHAR(100) DEFAULT NULL,
  `InvalidDevice` VARCHAR(1000) DEFAULT NULL,
  `TransStatus` BIT(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
  `FPSTransID` BIGINT UNSIGNED DEFAULT NULL,
  `Flagged` SMALLINT DEFAULT NULL,
  `IsProcessed` TINYINT NOT NULL DEFAULT '0',
  `TransID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `InsertTime` TIMESTAMP(4) NULL DEFAULT NULL,
  `BotDetectionValue` BIT(32) DEFAULT NULL,
  `BotComponentID` BIGINT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`TransID`,`CreatedDate`),
  KEY `IX_ProcessedTransaction_IsProcessed` (`IsProcessed`),
  KEY `IX_ProcessedTransaction_TransTime` (`CreatedDate`),
  KEY `IX_ProcessedTransaction_SubscriberName_CreatedDate` (`SubscriberName`,`CreatedDate`)
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
  `LoginName` VARCHAR(100) NOT NULL,
  `SubscriberName` VARCHAR(50) NOT NULL,
  `TransTime` TIMESTAMP(4) NOT NULL,
  `CreatedDate` DATETIME NOT NULL COMMENT 'Date Only',
  `DeviceCode` VARCHAR(32) DEFAULT NULL,
  `FingerprintCode` VARCHAR(620) DEFAULT NULL,
  `FingerprintMoreInfo` VARCHAR(250) DEFAULT NULL,
  `UserAgent` VARCHAR(1000) DEFAULT NULL,
  `IP` VARCHAR(50) DEFAULT NULL,
  `IPID` DECIMAL(50,0) DEFAULT NULL,
  `PluginID` BIGINT DEFAULT NULL,
  `URL` VARCHAR(500) DEFAULT NULL,
  `Action` VARCHAR(100) DEFAULT NULL,
  `ActionResult` VARCHAR(100) DEFAULT NULL,
  `InvalidDevice` VARCHAR(1000) DEFAULT NULL,
  `TransStatus` BIT(16) DEFAULT NULL COMMENT 'Refer Table TransStatus',
  `FPSTransID` BIGINT UNSIGNED DEFAULT NULL,
  `Flagged` SMALLINT DEFAULT NULL,
  `IsProcessed` TINYINT NOT NULL DEFAULT '0',
  `TransID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `InsertTime` TIMESTAMP(4) NULL DEFAULT NULL,
  `BotDetectionValue` BIT(32) DEFAULT NULL,
  `BotComponentID` BIGINT UNSIGNED DEFAULT NULL,
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
  `ListID` INT NOT NULL,
  `ItemID` SMALLINT NOT NULL,
  `ListCode` VARCHAR(100) DEFAULT NULL,
  `ListName` VARCHAR(200) DEFAULT NULL,
  `ItemCode` VARCHAR(100) DEFAULT NULL,
  `ItemName` VARCHAR(200) DEFAULT NULL,
  `Status` TINYINT(1) DEFAULT NULL,
  `Description` VARCHAR(200) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ListID`,`ItemID`),
  UNIQUE KEY `UX_StaticList_ListCode_ItemCode` (`ListCode`,`ItemCode`)
) ENGINE=InnoDB ;

CREATE TABLE `Transaction` (
  `TransID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `LoginName` VARCHAR(100) NOT NULL,
  `TransTime` TIMESTAMP(4) NOT NULL,
  `SubscriberID` INT DEFAULT NULL,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  `URLID` BIGINT UNSIGNED DEFAULT NULL,
  `FirstDeviceCode` VARCHAR(64) DEFAULT NULL,
  `UserAgentKey` VARCHAR(32) DEFAULT NULL,
  `IP` VARCHAR(50) DEFAULT NULL,
  `IPID` DECIMAL(50,0) DEFAULT NULL,
  `ActionResultID` BIGINT DEFAULT NULL,
  `Flagged` SMALLINT DEFAULT NULL COMMENT 'captcha & browserless',
  `PluginID` BIGINT DEFAULT NULL,
  `TransStatus` BIT(16) DEFAULT NULL,
  `CreatedDate` DATETIME NOT NULL COMMENT 'Date Only',
  `InsertTime` TIMESTAMP(4) NOT NULL,
  `DeviceCode` VARCHAR(32) DEFAULT NULL,
  `FingerprintCode` VARCHAR(620) DEFAULT NULL,
  `FingerprintMoreInfo` VARCHAR(250) DEFAULT NULL,
  `RawTransID` BIGINT UNSIGNED NOT NULL,
  `BotDetectionValue` BIT(32) DEFAULT NULL,
  `BotComponentID` BIGINT UNSIGNED DEFAULT NULL,
  PRIMARY KEY (`TransID`),
  UNIQUE KEY `UX_Transaction_RawTransID` (`RawTransID`)
) ENGINE=InnoDB;

CREATE TABLE `Transaction07` (
  `TransID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `LoginName` VARCHAR(100) NOT NULL,
  `TransTime` TIMESTAMP(4) NOT NULL,
  `SubscriberID` INT DEFAULT NULL,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  `URLID` BIGINT UNSIGNED DEFAULT NULL,
  `DeviceCodeID` BIGINT UNSIGNED DEFAULT NULL,
  `DeviceID` BIGINT UNSIGNED DEFAULT NULL,
  `FirstDeviceCode` VARCHAR(64) DEFAULT NULL,
  `DeviceStatus` TINYINT DEFAULT NULL,
  `DeviceFingerprintID` BIGINT UNSIGNED DEFAULT NULL,
  `UserAgentKey` VARCHAR(32) DEFAULT NULL,
  `IP` VARCHAR(50) DEFAULT NULL,
  `IPID` DECIMAL(50,0) DEFAULT NULL,
  `ActionResultID` BIGINT DEFAULT NULL,
  `Flagged` SMALLINT DEFAULT NULL COMMENT 'captcha & browserless',
  `PluginID` BIGINT DEFAULT NULL,
  `TransStatus` BIT(16) DEFAULT NULL,
  `CreatedDate` DATETIME NOT NULL COMMENT 'Date Only',
  `InsertTime` TIMESTAMP(4) NOT NULL,
  `RawTransID` BIGINT UNSIGNED DEFAULT NULL,
  `BotDetectionValue` BIT(32) DEFAULT NULL,
  `BotComponentID` BIGINT UNSIGNED DEFAULT NULL,
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
  `TransStatusName` VARCHAR(100) DEFAULT NULL,
  `StatusValue` BIT(16) NOT NULL,
  `Notes` VARCHAR(200) DEFAULT NULL,
  `IsTransformed` BIT(1) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`StatusValue`)
) ENGINE=InnoDB ;

CREATE TABLE `URL` (
  `URLID` INT NOT NULL AUTO_INCREMENT,
  `SubscriberID` INT DEFAULT NULL,
  `URLDetails` VARCHAR(250) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  PRIMARY KEY (`URLID`),
  UNIQUE KEY `UX_URL_URLDetails` (`URLDetails`)
) ENGINE=InnoDB;

CREATE TABLE `UserAgent` (
  `UserAgentKey` VARCHAR(32) NOT NULL,
  `UserAgent` VARCHAR(10000) DEFAULT NULL,
  `BrowserID` INT UNSIGNED DEFAULT NULL,
  `OSID` INT UNSIGNED DEFAULT NULL,
  `OS` VARCHAR(100) DEFAULT NULL,
  `Browser` VARCHAR(100) DEFAULT NULL,
  `CreatedDate` DATETIME DEFAULT NULL,
  `DeviceTypeID` INT UNSIGNED DEFAULT NULL,
  `Created` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `Modified` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`UserAgentKey`),
  KEY `IX_UserAgent_BrowserID_OSID` (`BrowserID`,`OSID`),# /*!80000 INVISIBLE */,
  KEY `IX_UserAgent_BrowserID` (`BrowserID`),
  KEY `IX_UserAgent_OSID` (`OSID`),
  KEY `IX_UserAgent_DeviceTypeID` (`DeviceTypeID`)
) ENGINE=InnoDB ;

CREATE TABLE `SystemSetting` (
  `ID` INT NOT NULL AUTO_INCREMENT,
  `VGroup` VARCHAR(128) DEFAULT NULL,
  `VName` VARCHAR(128) DEFAULT NULL,
  `VValue` VARCHAR(255) DEFAULT NULL,
  `UpdatedTime` DATETIME DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_SystemSetting_VName_VGroup` (`VName`,`VGroup`)
) ENGINE=InnoDB;
#==========================================================================
#==========================INITIAL DATA================================================

INSERT INTO DCS_Extra.Subscriber(SubscriberID, SubscriberName, SubscriberPrefix, SubscriberType, SubscriberStatus, CreatedDate, CreatedBy, IsTest, INTegrationDate, TerminatedDate)
VALUES (8000001,'CTMax','',10,1,NOW(),NULL,0,NOW(),NULL)
	,  (8000002,'Velki','',10,1,NOW(),NULL,0,NOW(),NULL)
    ,  (8000003,'Sky','',10,1,NOW(),NULL,0,NOW(),NULL)
    ,  (8000004,'AgentSky','',10,1,NOW(),NULL,0,NOW(),NULL)
    ,  (8000005,'AgentCTMax','',10,1,NOW(),NULL,0,NOW(),NULL)
    ,  (8000006,'AgentVelki','',10,1,NOW(),NULL,0,NOW(),NULL);

INSERT INTO CTS_DataCenter.SystemEventStatus(EventName,Status,LastExecTime)
VALUES('EV_DCS_Extra_Account_UpdateLastLoginTime','Stop',NOW());

#=============COPY DATA FILE FROM git ...Scripts\DCS_Extra== to 'D:/SPU/DCS_Extra/..' then import======================

LOAD DATA LOCAL INFILE 'D:/SPU/DCS_Extra/20230628_190118_DeviceType.csv'
INTO TABLE DCS_Extra.DeviceType
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/SPU/DCS_Extra/20230628_190118_TransStatus.csv'
INTO TABLE DCS_Extra.TransStatus
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(TransStatusName, @StatusValue, Notes, @IsTransformed, CreatedDate) SET
	StatusValue=Cast(@StatusValue as signed)
    , IsTransformed=Cast(@IsTransformed as signed);

LOAD DATA LOCAL INFILE 'D:/SPU/DCS_Extra/20230628_190118_SystemSetting.csv'
INTO TABLE DCS_Extra.SystemSetting
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/SPU/DCS_Extra/20230628_190118_StaticList.csv'
INTO TABLE DCS_Extra.StaticList
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'D:/SPU/DCS_Extra/20230628_190118_BotDetection.csv'
INTO TABLE DCS_Extra.BotDetection
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@Value, Name, CreatedDate) SET
	Value=Cast(@Value as signed);

#==============================DEPLOY EVENT "EV_DCS_Extra_Account_UpdateLastLogINTime" (Refer GIT: ..\dbscript\DCS_DeviceCaptureSystem\DCS_Extra\Event\..)========================================================
SHOW Events;
DROP EVENT IF EXISTS EV_DCS_Extra_Account_UpdateLastLoginTime;
DELIMITER //

/*
	Creator:	20230628@Casey.Huynh
	Task:	 	New DB DCS_Extra
	Server:  	Master
	DBName:		DCS_Extra

	Revisions: 
			- 20230628@Casey.Huynh: Created [Redmine ID: #190118]
		Reviewer:
*/
CREATE DEFINER=`DBMaintainer`@`%` EVENT `EV_DCS_Extra_Account_UpdateLastLoginTime` ON SCHEDULE EVERY 4 SECOND STARTS '2023-06-30 00:00:00' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
	IF EXISTS(SELECT 1 FROM CTS_DataCenter.SystemEventStatus WHERE EventName = 'EV_DCS_Extra_Account_UpdateLastLoginTime' AND Status = 'Stop') THEN
		UPDATE CTS_DataCenter.SystemEventStatus 
		SET Status = 'Start',  LastExecTime = NOW()
		WHERE EventName = 'EV_DCS_Extra_Account_UpdateLastLoginTime' ;

		CALL DCS_Extra.DCS_ET_Transform_Account_UpdateLastLoginTime(1000); 

		UPDATE CTS_DataCenter.SystemEventStatus 
		SET Status = 'Stop' ,  LastExecTime = NOW()
		WHERE EventName = 'EV_DCS_Extra_Account_UpdateLastLoginTime' ;

	END IF;
      
END //
DELIMITER ;