/*<info serverAlias="CTSMain-CTS_Archive" databaseType="2"></info>*/
/*
	Created: 20211027@Aries.Nguyen [Redmine ID: #163087]
	Task: Add table schema.
	DB: CTS_Archive
*/

CREATE DATABASE CTS_Archive;

USE CTS_Archive;
CREATE TABLE `AssociationByDevice_Arc` (
   `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `CTSCustID` BIGINT UNSIGNED DEFAULT NULL,
   `DCSDeviceID` BIGINT DEFAULT NULL,
   `SubscriberID` INT DEFAULT NULL,
   `AssociationDate` DATETIME NULL DEFAULT NULL,
   `Created` 	DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`),
   KEY `IX_AssociationByDevice_CTSCustID_DCSDeviceID` (`CTSCustID`,`DCSDeviceID`),
   KEY `IX_AssociationByDevice_DCSDeviceID_CTSCustID` (`DCSDeviceID`,`CTSCustID`)
 ) ENGINE=InnoDB;
 
 USE CTS_Archive;
 CREATE TABLE `AssociationByIP_Arc` (
   `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `FromCustID` BIGINT UNSIGNED NOT NULL,
   `ToCustID` BIGINT UNSIGNED NOT NULL,
   `AssociationDate` DATETIME DEFAULT NULL,
   `Created` 	DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`),
   UNIQUE `UX_AssociationByAI_FromCustIDToCustID` (`FromCustID`,`ToCustID`),
   UNIQUE `UX_AssociationByAI_ToCustIDFromCustID` (`ToCustID`,`FromCustID`)
 ) ENGINE=InnoDB;
 
 USE CTS_Archive;
 CREATE TABLE `AssociationByManual_Arc` (
   `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `FromSubscriberID` INT UNSIGNED DEFAULT NULL,
   `FromCTSCustID` BIGINT UNSIGNED NOT NULL,
   `ToSubscriberID` INT UNSIGNED DEFAULT NULL,
   `ToCTSCustID` BIGINT UNSIGNED NOT NULL,
   `Remark` VARCHAR(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
   `AssociationDate` DATETIME DEFAULT NULL,
   `CreatedBy` BIGINT DEFAULT NULL,
   `Created` DATETIME DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`ID`),
   KEY `IX_AssociationByManual_ToCTSCustID` (`ToCTSCustID`),
   UNIQUE `IX_AssociationByManual_FromCTSCustID` (`FromCTSCustID`,`ToCTSCustID`)
) ENGINE=InnoDB;
 
 
 USE CTS_Archive;
 CREATE TABLE `AssociationByAI_Arc` (
   `ID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
   `FromCustID` BIGINT UNSIGNED NOT NULL,
   `ToCustID` BIGINT UNSIGNED NOT NULL,
   `AssociationDate` DATETIME DEFAULT NULL,
   `Created` DATETIME DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (`ID`),
   KEY `IX_AssociationByAI_ToCustID` (`ToCustID`,`FromCustID`),
   KEY `IX_AssociationByAI_FromCustID` (`FromCustID`,`ToCustID`)
 ) ENGINE=InnoDB;
 
 USE CTS_Archive;
 CREATE TABLE `SystemParameter` (
   `ParameterID` SMALLINT UNSIGNED NOT NULL,
   `ParameterName` VARCHAR(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
   `ParameterDesc` VARCHAR(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
   `ParameterDataType` VARCHAR(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
   `ParameterValue` VARCHAR(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
   PRIMARY KEY (`ParameterID`)
 ) ENGINE=InnoDB;

USE CTS_Archive;
CREATE TABLE `CTSCustomerAssociationArchive_Process` (
   `CTSCustID` BIGINT UNSIGNED NOT NULL,
   `CustID` INT UNSIGNED NOT NULL,
   PRIMARY KEY (`CTSCustID`),
   KEY `IX_CTSCustomerAssociationArchive_CustID` (`CustID`)
) ENGINE=InnoDB;

USE CTS_Archive;
CREATE TABLE `CTSCustomerAssociationRollBack_Process` (
   `CTSCustID` BIGINT UNSIGNED NOT NULL,
   `CustID` INT UNSIGNED NOT NULL,
   PRIMARY KEY (`CTSCustID`),
   KEY `IX_CTSCustomerAssociationRollBack_CustID` (`CustID`)
) ENGINE=InnoDB;

USE CTS_Archive;
INSERT IGNORE INTO CTS_Archive.SystemParameter(ParameterID, ParameterName, ParameterDesc, ParameterDataType, ParameterValue)
VALUES  (1, 'Archive Association Cust Batch Size', 'Batch Size', 'INT', '500'),
	    (2, 'Archive Last Cust Archive ID', 'Last CTSCustID', 'INT', '0'),
        (3, 'Archive Association Data Batch Size', 'Batch Size', 'INT', '500'),
        (4, 'Archive Association Table Processing', 'Archive Association Table Process', 'INT', 'AssociationByAI-From'),
        
        (5, 'Rollback Association Cust Batch Size', 'Batch Size', 'INT', '500'),
        (6, 'Rollback Association Data Batch Size', 'Batch Size', 'INT', '500'),
        (7, 'Rollback Association Table Processing', 'Rollback Association Table Process', 'INT', 'AssociationByAI-From');
 
USE CTS_DataCenter;
CREATE TABLE `CTSCustomerAssociationStatus` (
   `CTSCustID` BIGINT UNSIGNED NOT NULL,
   `CustID` INT UNSIGNED NOT NULL,
   `LastTicketDate` DATETIME ,
   `IsArchived` BIT DEFAULT 0,
   `IsRollBack` BIT DEFAULT 0,
   `RollBackDate` DATETIME,
   `Created` DATETIME DEFAULT CURRENT_TIMESTAMP,
   PRIMARY KEY (`CTSCustID`),
   KEY `IX_CTSCustomerAssociationArchive_CustID` (`CustID`),
   KEY `IX_CTSCustomerAssociationArchive_LastTicketDate` (`LastTicketDate`),
   KEY `IX_CTSCustomerAssociationArchive_IsRollBack_RollBackDate` (`IsRollBack`,`RollBackDate`)
) ENGINE=InnoDB;


USE CTS_DataCenter;
ALTER TABLE CTS_DataCenter.CustomerCategory ADD COLUMN TaggingID SMALLINT, ALGORITHM=INSTANT;
ALTER TABLE CTS_DataCenter.CustomerCategory ADD COLUMN TaggingType SMALLINT, ALGORITHM=INSTANT;

USE CTS_DataCenter;
UPDATE CTS_DataCenter.CustomerCategory AS cate
INNER JOIN  CTS_DataCenter.TaggingToCategory AS tag ON cate.CategoryID = tag.CategoryID
SET 	cate.TaggingID = tag.TaggingID
	,	cate.TaggingType = tag.TaggingType;

UPDATE CTS_DataCenter.CustomerCategory
SET TaggingType = 0
WHERE CategoryID IN (1001, 1002);



USE CTS_Archive;
CREATE ROLE 'ArcWriter';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE TEMPORARY TABLES, EXECUTE ON `CTS_Archive`.* TO `ArcWriter`@`%`;
GRANT  `ArcWriter`@`%`  TO `ctsServiceAdmin`@`%`;
FLUSH PRIVILEGES;


 