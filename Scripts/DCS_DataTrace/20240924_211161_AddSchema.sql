/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20240924@Jonathan.Doan
	Task:	 	Create new table to Cook data device [Redmine ID: #211161]
	Server:  	Master
	DBName:		DCS_DataTrace
    
	Revisions: 
			- 20240924@Jonathan.Doan: Created [Redmine ID: #211161]
	Reviewer:
*/

USE DCS_DataTrace;

SET @InitialMaxTransID = (SELECT VValue FROM `DCS_DataTrace`.`SystemSetting` WHERE ID = 5);

INSERT INTO `DCS_DataTrace`.`SystemSetting`(`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`)
VALUES 	(7, 'CookDataByDevice', 'ListSubID', '4400,4629,4610', NOW())
	,	(100, 'InitialCookDataByDevice', 'MaxTransID', @InitialMaxTransID, NOW())
	,	(101, 'InitialCookDataByDevice', 'LimitTransID', '0', NOW());

DROP TABLE IF EXISTS `DCS_DataTrace`.`LoginTransactionSummaryByDevice`;
CREATE TABLE `LoginTransactionSummaryByDevice` (
  `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `TransDate` DATETIME NOT NULL,
  `SubscriberID` INT UNSIGNED DEFAULT NULL,
  `AccountID` BIGINT UNSIGNED DEFAULT NULL,
  `DeviceID` BIGINT UNSIGNED DEFAULT NULL,
  `TotalTrans` INT UNSIGNED DEFAULT NULL,
  `CreatedTime` DATETIME DEFAULT NOW(),
  `ModifiedTime` DATETIME DEFAULT NULL,
  
  PRIMARY KEY (`ID`),
  UNIQUE KEY `UX_LoginTransactionSummaryByDevice_Group` (`TransDate`,`SubscriberID`,`AccountID`,`DeviceID`),
  KEY `IX_LoginTransactionSummaryByDevice_SubscriberID_DeviceID` (`SubscriberID`,`DeviceID`),
  KEY `IX_LoginTransactionSummaryByDevice_SubscriberID_AccountID` (`SubscriberID`,`AccountID`)
) ENGINE=InnoDB;

