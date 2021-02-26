/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210226@Irena.Vo
	Task: 	 150454-Update schema for Exclude Association With PA [Redmine ID: #150454]
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20210226@Irena.Vo]: Add new table: ExclusionAssociatedWithPA, Add new column IsExcludeAssWithPA for CTSCustomerClassification_History
*/
USE CTS_DataCenter;

-- Add new table
CREATE TABLE `ExclusionAssociatedWithPA` (
	`CustID` BIGINT	UNSIGNED NOT NULL PRIMARY KEY,
 	`CreatedTime` DATETIME NOT NULL
) ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Add new column    
ALTER TABLE `CTSCustomerClassification_History`
ADD COLUMN	`IsExcludeAssWithPA` BIT(1) DEFAULT 0, ALGORITHM=INSTANT;

-- Init Log Type
INSERT INTO CTS_Admin.LogType (LogTypeName, LogTypeDescription) 
VALUES 
('Exclude Association With PA', 'Exclude Association With PA for Normal Category'),('Include Association With PA', 'Include Association With PA for Normal Category');