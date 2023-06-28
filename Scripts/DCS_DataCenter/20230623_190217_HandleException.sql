/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230614@Jonathan.Doan
	Task:	 	Monitor Transaction [Redmine ID: #189732]
	Server:  	Master
	DBName:		DCS_DataCenter

	Revisions: 
			- 20230614@Jonathan.Doan: Created [Redmine ID: #189732]
	Reviewer:
*/
USE DCS_DataCenter;
 
DROP TABLE IF EXISTS DCS_DataCenter.NewAccountDevice;
CREATE TABLE DCS_DataCenter.NewAccountDevice(
		ID					BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
	,	AssociationID		BIGINT UNSIGNED NOT NULL
	, 	AccountID			BIGINT UNSIGNED NOT NULL
	, 	DeviceID			BIGINT UNSIGNED NOT NULL
	, 	RawTransID			BIGINT UNSIGNED NOT NULL
	, 	RawCreatedDate		DATETIME
	, 	LoginName			VARCHAR(100)
	, 	TransTime			DATETIME(4)
	, 	UserAgentKey		VARCHAR(32)
	, 	IP					VARCHAR(50)
	,	Status 				SMALLINT COMMENT '0: Default|Not send\n1: Sent\n2: Sent Error'
	, 	CreatedDate			DATETIME
	, 	ModifiedDate		DATETIME
	,	PRIMARY KEY (`ID`, `Status`, `CreatedDate`)
	,	UNIQUE KEY `UX_NewAccountDevice_AssociationID` (`AssociationID`, `Status`, `CreatedDate`)
	,	INDEX `IX_NewAccountDevice_AccountID_DeviceID` (`AccountID`, `DeviceID`)
	,	INDEX `IX_NewAccountDevice_TransTime` (`TransTime`)
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
    PARTITION p19999999 VALUES LESS THAN (19999999),
	PARTITION p20000000 VALUES LESS THAN MAXVALUE);
    
SET sql_safe_updates = 0;
DELETE FROM DCS_DataCenter.SystemSetting
WHERE VGroup LIKE 'DCS_AbnormalTransaction%';

INSERT IGNORE INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction', 'MaxAssociationID_NewAccountDevice', '0', NOW());

INSERT IGNORE INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction', 'MaxID_Pushed', '0', NOW());
