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
	,	Status 				TINYINT COMMENT '0: Default\n1: Sent\n2:Not send'
	, 	CreatedDate			DATETIME
	, 	ModifiedDate		DATETIME
	,	PRIMARY KEY (`AssociationID`)
	,	UNIQUE KEY `UX_AbnormalTransasction_AccountID_DeviceID` (`AccountID`, `DeviceID`)
	,	INDEX `UX_AbnormalTransasction_AccountID` (`AccountID`)
) ENGINE=InnoDB;

INSERT INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction_Processed', 'MaxID', '0', NOW());

INSERT INTO DCS_DataCenter.SystemSetting(VGroup, VName, VValue, UpdatedTime)
VALUES ('DCS_AbnormalTransaction_Transform', 'MaxAssociationID', '0', NOW());

DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Delete`;
DROP PROCEDURE IF EXISTS `DCS_DC_Abnormal_Transasction_Transform`;
