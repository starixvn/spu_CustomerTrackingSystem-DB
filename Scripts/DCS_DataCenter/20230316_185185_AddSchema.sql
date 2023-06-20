/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator: 20230316@Jonathan.Doan
Task:	 	Support return new device login for Alpha
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20230316@Jonathan.Doan: Created [#185185]
Reviewer:
*/

USE DCS_DataCenter;

DROP TABLE IF EXISTS DCS_DataCenter.NewAccountDevice;

CREATE TABLE DCS_DataCenter.NewAccountDevice(
		AssociationID		BIGINT UNSIGNED NOT NULL
	, 	AccountID			BIGINT UNSIGNED NOT NULL
	, 	DeviceID			BIGINT UNSIGNED NOT NULL
	, 	RawTransID			BIGINT UNSIGNED NOT NULL
	, 	RawCreatedDate		DATETIME
	, 	LoginName			VARCHAR(100)
	, 	TransTime			DATETIME(4)
	, 	UserAgentKey		VARCHAR(32)
	, 	IP					VARCHAR(50)
	,	Status 				BIT COMMENT '0: Default|Not send\n1: Sent'
	, 	CreatedDate			DATETIME
	, 	ModifiedDate		DATETIME
	,	PRIMARY KEY (`AssociationID`, `Status`, `CreatedDate`)
	,	INDEX `IX_NewAccountDevice_AccountID_DeviceID` (`AccountID`, `DeviceID`)
) ENGINE=InnoDB;
ALTER TABLE NewAccountDevice
    PARTITION BY RANGE(Status*10000000+YEARWEEK(createdDate))(
	PARTITION p10000000 VALUES LESS THAN (10000000),
    PARTITION p10202323 VALUES LESS THAN (10202324),
    PARTITION p10202324 VALUES LESS THAN (10202325),
    PARTITION p10202325 VALUES LESS THAN (10202326),
    PARTITION p10202326 VALUES LESS THAN (10202327),
    PARTITION p10202327 VALUES LESS THAN (10202328),
    PARTITION p10202328 VALUES LESS THAN (10202329),
    PARTITION p10202329 VALUES LESS THAN (10202330),
	PARTITION p19999999 VALUES LESS THAN MAXVALUE);

SET sql_safe_updates = 0;
DELETE FROM DCS_DataCenter.SystemSetting
WHERE VGroup LIKE 'DCS_AbnormalTransaction%';

INSERT IGNORE INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction', 'MaxAssociationID_NewAccountDevice', '0', NOW());

INSERT IGNORE INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction', 'MaxAssociationID_Pushed', '0', NOW());
