/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250429@Jonathan.Doan [Redmine ID: #224502]
	Task: New Table TableIDRange
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

CREATE TABLE TableIDRange (
    ID				INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
    DatabaseName	VARCHAR(255) NOT NULL,
    TableName   	VARCHAR(255) NOT NULL,
    CreatedDate		DATE NOT NULL,
    MinID			BIGINT UNSIGNED,
    MaxID			BIGINT UNSIGNED,
    InsertedTime	DATETIME,
    UNIQUE KEY `UX_TableIDRange_DatabaseNameTableNameCreatedDate` (`DatabaseName`, `TableName`, `CreatedDate`)
);
