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

DROP TABLE IF EXISTS DCS_DataCenter.AbnormalTransasction;
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
    PARTITION p10202314 VALUES LESS THAN (10202314),
    PARTITION p10202315 VALUES LESS THAN (10202315),
    PARTITION p10202316 VALUES LESS THAN (10202316),
    PARTITION p10202317 VALUES LESS THAN (10202317),
    PARTITION p10202318 VALUES LESS THAN (10202318),
    PARTITION p10202319 VALUES LESS THAN (10202319),
    PARTITION p10202320 VALUES LESS THAN (10202320),
	PARTITION p19999999 VALUES LESS THAN MAXVALUE);

DELETE FROM DCS_DataCenter.SystemSetting
WHERE VGroup LIKE 'DCS_AbnormalTransaction%';

INSERT INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction_Processed', 'MaxAssociationIDProcessed', '0', NOW());

INSERT INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction_Transform', 'MaxAssociationID', '0', NOW());

DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Delete`;
DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Transform`;
