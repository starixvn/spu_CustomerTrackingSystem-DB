/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20210226@Irena.Vo
	Task: 	 150454-Update schema for Mark/Unmark Tagging By Association With PA [Redmine ID: #150454]
	DB: 	 CTS_DataCenter
    
    Revisions: 
	-	[20210226@Irena.Vo]: Add new table: TaggingExclusion, Add new column TaggingType for CTSCustomerClassification_History. Init log and types.
*/
USE CTS_DataCenter;

-- Add new table
CREATE TABLE `TaggingExclusion` (
	`CustID` BIGINT	UNSIGNED NOT NULL PRIMARY KEY,
 	`CreatedTime` DATETIME NOT NULL
) ENGINE=INNODB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Add new column    
ALTER TABLE `CTSCustomerClassification_History`
ADD COLUMN	`TaggingType` SMALLINT DEFAULT 1, ALGORITHM=INSTANT;

-- Init Tagging Type
INSERT INTO CTS_DataCenter.StaticList (ListID,ItemID,ListName,ListNameDisplay,ItemName,ItemNameDisplay,PriorityOrder,Status,Description,CreatedDate)
VALUES 
(9,0,'Tagging Type','Tagging Type','No Tagging By Association With PA','No Tagging By Association With PA',0,1,'No Tagging By Association With PA',CURRENT_TIMESTAMP),
(9,1,'Tagging Type','Tagging Type','Tagging By Association with PA','Tagging By Association With PA',1,1,'Tagging By Association With PA',CURRENT_TIMESTAMP);

-- Init Log Type
INSERT INTO CTS_Admin.LogType (LogTypeName, LogTypeDescription) 
VALUES 
('Unmark Tagging By Association With PA', 'Unmark Tagging By Association With PA for Normal Category'),
('Mark Tagging By Association With PA', 'Mark Tagging By Association With PA for Normal Category');