/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20201207@Irena.Vo
	Task: 	 145951-Update schema for View History  [Redmine ID: #145951]
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20201207@Irena.Vo]: Update index in table: CTSCustomerClassification_History & Insert new columns
*/
USE CTS_DataCenter;

CREATE TABLE `CTS_DataCenter.PinCustomerCategory` (
	`CustID` BIGINT	UNSIGNED NOT NULL PRIMARY KEY,
 	`CreatedTime` DATETIME NOT NULL
) ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
    
CREATE TABLE `CTSCustomerClassification_History` (
	`ID` bigint unsigned NOT NULL AUTO_INCREMENT,
	`CustID` bigint unsigned DEFAULT NULL,
	`CTSCustID` bigint unsigned DEFAULT NULL,
	`SportGroupID` smallint unsigned DEFAULT NULL,
	`CategoryID` smallint unsigned DEFAULT NULL,
	`TurnoverRM` decimal(20,4) DEFAULT NULL,
	`WinlossRM` decimal(20,4) DEFAULT NULL,
	`BetCount` bigint DEFAULT NULL,
	`ActiveDays` int DEFAULT NULL,
	`LastXDaysMargin` decimal(20,4) DEFAULT NULL,
	`ProbationPeriodWinloss` decimal(20,4) DEFAULT NULL,
	`TargetCC` tinyint DEFAULT NULL,
	`SourceTypeID` smallint unsigned DEFAULT NULL,
	`FromCategoryID` smallint unsigned DEFAULT NULL,
	`ToCategoryID` smallint unsigned DEFAULT NULL,
	`IsAppliedCC` bit(1) DEFAULT b'0',
	`IsDataChanged` bit(1) DEFAULT b'0',
	`ActionType` tinyint DEFAULT NULL,
    `IsAuto` bit(1) DEFAULT NULL,
	`LastModifiedDate` datetime DEFAULT NULL,
	`LastModifiedBy` int unsigned DEFAULT NULL,
	`InsertDate` datetime DEFAULT NULL,
   PRIMARY KEY (`ID`),
   KEY `IX_CTSCustomerClassification_History_CustID_SportGroupID` (`CustID`,`SportGroupID`),
   KEY `IX_CTSCustomerClassification_History_InsertDate` (`InsertDate`),
   KEY `IX_CTSCustomerClassification_History_CTSCustID` (`CTSCustID`)
 ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;