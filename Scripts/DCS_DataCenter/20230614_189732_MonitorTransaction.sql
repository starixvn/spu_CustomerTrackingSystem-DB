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
  `UserName` varchar(50) NULL,
  `RegisterName` varchar(50) NULL,
  `SubscriberID` INT UNSIGNED NULL,
  `CTSSiteID` INT UNSIGNED NULL,
  `CTSSite` varchar(50) NULL,
  `MainSite` varchar(50) NULL,
  `CreatedDate` DATETIME NULL,
  `FirstLoginDate` DATETIME NULL,
  `LastLoginDate` DATETIME NULL,
  `LastTicketDate` DATETIME NULL,
  `FirstScanDate` DATETIME NULL,
  `LastScanDate` DATETIME NULL,
  `ScanCounter` SMALLINT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_MonitorTransaction_CustID` (`CustID`)
) ENGINE=InnoDB;