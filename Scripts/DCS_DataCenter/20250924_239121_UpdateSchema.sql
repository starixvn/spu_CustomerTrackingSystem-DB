/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250924@Jonathan.Doan [Redmine ID: #233405]
	Task: New tables for storing MB transaction summary data
	DB: DCS_DataCenter
*/
USE DCS_DataCenter;

DROP TABLE IF EXISTS MBAccountIP;
CREATE TABLE `MBAccountIP` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `MBAccountID` BIGINT UNSIGNED NOT NULL,
  `IPID` DECIMAL(50,0) NOT NULL,
  `IP` VARCHAR(50) NOT NULL,
  `LastAccessedDate` DATE NULL,
  `InsertedTime` DATETIME NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_MBAccountIP_MBAccountID_IPID` (`MBAccountID`,`IPID`),
  KEY `IX_MBAccountIP_LastAccessedDate_MBAccountID` (`LastAccessedDate`, `MBAccountID`)
) ENGINE=InnoDB;