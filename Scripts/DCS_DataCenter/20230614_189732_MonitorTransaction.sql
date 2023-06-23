/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230614@Jonathan.Doan
	Task:	 	Monitor Transaction [Redmine ID: #189732]
	Server:  	Master
	DBName:		DCS_DataCenter

	Revisions: 
			- 20230614@Jonathan.Doan: Created [Redmine ID: #189732]
	Reviewer:
*/
USE DCS_DataCenter;

DROP TABLE IF EXISTS DCS_DataCenter.MonitorTransaction;
CREATE TABLE `MonitorTransaction` (
  `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `CustID` INT UNSIGNED DEFAULT NULL,
  `UserName` VARCHAR(50) NULL,
  `LoginName` VARCHAR(50) NULL,
  `SubscriberID` INT UNSIGNED NULL,
  `CTSSiteID` INT UNSIGNED NULL,
  `CTSSite` VARCHAR(50) NULL,
  `MainSite` VARCHAR(50) NULL,
  `CreatedDate` DATETIME NULL,
  `FirstLoginDate` DATETIME NULL,
  `LastLoginDate` DATETIME NULL,
  `LastTicketDate` DATETIME NULL,
  `FirstScanDate` DATETIME NULL,
  `LastScanDate` DATETIME NULL,
  `ScanCounter` SMALLINT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_MonitorTransaction_CustID` (`CustID`),
  KEY `IX_MonitorTransaction_FirstLoginDate` (`FirstLoginDate`),
  KEY `IX_MonitorTransaction_SubscriberID` (`SubscriberID`),
  KEY `IX_MonitorTransaction_LastScanDate` (`LastScanDate`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS DCS_DataCenter.NotifyMessage;
CREATE TABLE `NotifyMessage` (
  `ID` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `NotifyType` VARCHAR(100) NULL,
  `GroupID` VARCHAR(100) NULL,
  `Title` VARCHAR(1000) NULL,
  `Message` LONGTEXT NULL,
  `MoreInfo` LONGTEXT NULL,
  `CreatedDate` DATETIME NULL,
  `IsNotified` BOOLEAN,
  `SentDate` DATETIME NULL,
  PRIMARY KEY (`ID`),
  KEY `IX_NotifyMessage_NotifyType` (`NotifyType`),
  KEY `IX_NotifyMessage_SentDate` (`SentDate`)
) ENGINE=InnoDB;

DROP PROCEDURE IF EXISTS `DCS_DC_Monitor_GetCustByDate`;