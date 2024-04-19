/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20240419@Jonathan.Doan [Redmine ID: #203691]
	Task: New Tables for archive data
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

DROP TABLE IF EXISTS DCS_DataCenter.ArchiveAccount_NotUsed;
CREATE TABLE `ArchiveAccount_NotUsed` (
  `AccountID` BIGINT UNSIGNED NOT NULL PRIMARY KEY
) ENGINE=InnoDB;
 
DROP TABLE IF EXISTS DCS_DataCenter.ArchiveAccountIP_NotUsed;
CREATE TABLE `ArchiveAccountIP_NotUsed` (
  `ID` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  KEY `IX_ArchiveAccountIP_NotUsed_AccountID` (`AccountID`)
) ENGINE=InnoDB;
 
DROP TABLE IF EXISTS DCS_DataCenter.ArchiveAccountFingerprint_NotUsed;
CREATE TABLE `ArchiveAccountFingerprint_NotUsed` (
  `ID` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  KEY `IX_ArchiveAccountFingerprint_NotUsed_AccountID` (`AccountID`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS DCS_DataCenter.ArchiveAccountDevice_NotUsed;
CREATE TABLE `ArchiveAccountDevice_NotUsed` (
  `ID` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  KEY `IX_ArchiveAccountDevice_NotUsed_AccountID` (`AccountID`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS DCS_DataCenter.ArchiveAssociation_NotUsed;
CREATE TABLE `ArchiveAssociation_NotUsed` (
  `AccountID` BIGINT UNSIGNED NOT NULL,
  `DeviceID` BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`AccountID`,`DeviceID`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS DCS_DataCenter.ArchiveDevice_NotUsed;
CREATE TABLE `ArchiveDevice_NotUsed` (
  `DeviceID` BIGINT UNSIGNED NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

DROP TABLE IF EXISTS DCS_DataCenter.ArchiveDeviceCode_NotUsed;
CREATE TABLE `ArchiveDeviceCode_NotUsed` (
  `DeviceCodeID` BIGINT UNSIGNED NOT NULL PRIMARY KEY,
  `DeviceCode` VARCHAR(32),
  `DeviceID` BIGINT UNSIGNED,
  KEY `IX_ArchiveDeviceCode_NotUsed_DeviceID` (`DeviceID`)
) ENGINE=InnoDB;

