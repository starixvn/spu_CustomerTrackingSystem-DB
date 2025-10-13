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
VALUES (9, 1001, 'TaggingType', 'TaggingType', 'IndexedDB', 'IndexedDB', '1', NOW())
	,	(9, 2002, 'TaggingType', 'TaggingType', 'Etag', 'Etag', '1', NOW())
	,	(9, 3003, 'TaggingType', 'TaggingType', 'CacheAPI', 'CacheAPI', '1', NOW())
	,	(9, 4004, 'TaggingType', 'TaggingType', 'Cookies', 'Cookies', '1', NOW())
	,	(9, 5005, 'TaggingType', 'TaggingType', 'LocalStorage', 'LocalStorage', '1', NOW())
	,	(9, 6006, 'TaggingType', 'TaggingType', 'WindowName', 'WindowName', '1', NOW())
	,	(9, 7000, 'TaggingType', 'TaggingType', 'Generated', 'Generated', '1', NOW())
	,	(9, 8000, 'TaggingType', 'TaggingType', 'Default', 'Default', '1', NOW());

ALTER TABLE RawTransaction
ADD COLUMN ActivatorVersion VARCHAR(10),
ADD COLUMN FingerprintVersion VARCHAR(10),
ADD COLUMN TaggingType SMALLINT;

ALTER TABLE ProcessedTransaction
ADD COLUMN ActivatorVersion VARCHAR(10),
ADD COLUMN FingerprintVersion VARCHAR(10),
ADD COLUMN TaggingType SMALLINT;

/*
ALTER TABLE Transaction
DROP COLUMN ActivatorVersion,
DROP COLUMN FingerprintVersion,
DROP COLUMN TaggingType;

ALTER TABLE Transaction07
DROP COLUMN ActivatorVersion,
DROP COLUMN FingerprintVersion,
DROP COLUMN TransFlow,
DROP COLUMN TaggingType;
*/

ALTER TABLE Transaction
ADD COLUMN ActivatorVersionID INT,
ADD COLUMN FingerprintVersionID INT,
ADD COLUMN TaggingType SMALLINT;

ALTER TABLE Transaction07
ADD COLUMN ActivatorVersionID INT COMMENT 'ScriptVersion.ScriptVersionType = 1',
ADD COLUMN FingerprintVersionID INT COMMENT 'ScriptVersion.ScriptVersionType = 2',
ADD COLUMN TransFlow TINYINT(1) COMMENT '1: New, 0: Old',
ADD COLUMN TaggingType SMALLINT COMMENT 'StaticList.ListID = 9';

