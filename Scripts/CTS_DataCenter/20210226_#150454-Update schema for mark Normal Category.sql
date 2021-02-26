/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210226@Irena.Vo
	Task: 	 150454-Update schema for mark Normal Category [Redmine ID: #150454]
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20210226@Irena.Vo]: Add new table: MarkNormalCategory, Add new column IsNormalCategory for CTSCustomerClassification_History
*/
USE CTS_DataCenter;

-- Add new table
CREATE TABLE `MarkNormalCategory` (
	`CustID` BIGINT	UNSIGNED NOT NULL PRIMARY KEY,
 	`CreatedTime` DATETIME NOT NULL
) ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Add new column    
ALTER TABLE `CTSCustomerClassification_History`
ADD COLUMN	`IsNormalCategory` BIT(1) DEFAULT 0, ALGORITHM=INSTANT;

-- Init Log Type
INSERT INTO CTS_Admin.LogType (LogTypeName, LogTypeDescription) 
VALUES 
('Mark Normal Category', 'Mark Normal Category manually'),('Unmark Normal Category', 'Unmark Normal Category manually');