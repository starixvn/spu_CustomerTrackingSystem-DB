/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20251009@Jonathan.Doan
Task:	 	Indicate Tagging Type
Server:  	Master
DBName:		DCS_DataCenter

Revisions: 
		- 20251009@Jonathan.Doan: Created [Redmine ID: #240781]
Reviewer:
*/

USE DCS_DataCenter;

DROP TABLE IF EXISTS ScriptVersion;
CREATE TABLE ScriptVersion(
		ScriptVersionID		INT AUTO_INCREMENT PRIMARY KEY
	,	ScriptVersionType 	INT NOT NULL COMMENT 'StaticList.ListID = 8'
	,	ScriptVersion		VARCHAR(10) NOT NULL
	,	CreatedDate			DATE NOT NULL
	,	LastUsedDate		DATE NOT NULL
    
	,	UNIQUE KEY UX_ScriptVersion_ScriptVersionType_ScriptVersion (ScriptVersionType, ScriptVersion)
    ,	INDEX IX_ScriptVersion_LastUsedDate(LastUsedDate)
);

INSERT IGNORE INTO `DCS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListCode`, `ListName`, `ItemCode`, `ItemName`, `Status`, `CreatedDate`) 
VALUES (8, 1, 'ScriptVersion_ScriptVersionType', 'ScriptVersion ScriptVersionType', 'ActivatorVersion', 'ActivatorVersion', '1', NOW())
	,	(8, 2, 'ScriptVersion_ScriptVersionType', 'ScriptVersion ScriptVersionType', 'FingerprintVersion', 'FingerprintVersion', '1', NOW());


INSERT IGNORE INTO `DCS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListCode`, `ListName`, `ItemCode`, `ItemName`, `Status`, `CreatedDate`) 
VALUES (9, -1, 'ScriptVersion_Exception', 'ScriptVersion Exception', 'NotExists', 'NotExists', '1', NOW())
	,	(9, -2, 'ScriptVersion_Exception', 'ScriptVersion Exception', 'Empty', 'Empty', '1', NOW())
	,	(9, -3, 'ScriptVersion_Exception', 'ScriptVersion Exception', 'MaxLength', 'MaxLength', '1', NOW());

INSERT IGNORE INTO `DCS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListCode`, `ListName`, `ItemCode`, `ItemName`, `Status`, `CreatedDate`) 
VALUES (10, 1001, 'TaggingType', 'TaggingType', 'IndexedDB', 'IndexedDB', '1', NOW())
	,	(10, 2002, 'TaggingType', 'TaggingType', 'Etag', 'Etag', '1', NOW())
	,	(10, 3003, 'TaggingType', 'TaggingType', 'CacheAPI', 'CacheAPI', '1', NOW())
	,	(10, 4004, 'TaggingType', 'TaggingType', 'Cookies', 'Cookies', '1', NOW())
	,	(10, 5005, 'TaggingType', 'TaggingType', 'LocalStorage', 'LocalStorage', '1', NOW())
	,	(10, 6006, 'TaggingType', 'TaggingType', 'WindowName', 'WindowName', '1', NOW())
	,	(10, 7000, 'TaggingType', 'TaggingType', 'Generated', 'Generated', '1', NOW())
	,	(10, 8000, 'TaggingType', 'TaggingType', 'Default', 'Default', '1', NOW());

ALTER TABLE RawTransaction
ADD COLUMN ActivatorVersion VARCHAR(10),
ADD COLUMN FingerprintVersion VARCHAR(10),
ADD COLUMN TaggingType SMALLINT;

ALTER TABLE ProcessedTransaction
ADD COLUMN ActivatorVersion VARCHAR(10),
ADD COLUMN FingerprintVersion VARCHAR(10),
ADD COLUMN TaggingType SMALLINT;

ALTER TABLE Transaction
ADD COLUMN ActivatorVersionID INT,
ADD COLUMN FingerprintVersionID INT,
ADD COLUMN TaggingType SMALLINT;

ALTER TABLE Transaction07
ADD COLUMN ActivatorVersionID INT COMMENT 'ScriptVersion.ScriptVersionType = 1 || StaticList.ListID = 9',
ADD COLUMN FingerprintVersionID INT COMMENT 'ScriptVersion.ScriptVersionType = 2 || StaticList.ListID = 9',
ADD COLUMN TransFlow TINYINT(1) COMMENT '1: New, 0: Old',
ADD COLUMN TaggingType SMALLINT COMMENT 'StaticList.ListID = 9';

