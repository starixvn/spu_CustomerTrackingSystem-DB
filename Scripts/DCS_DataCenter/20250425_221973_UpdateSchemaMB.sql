/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250425@Jonathan.Doan [Redmine ID: #221973]
	Task: Update schema Mobile/App-Android
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;


# MBAccount
ALTER TABLE DCS_DataCenter.MBAccount
ADD CreatedDate DATE,
ADD CreatedTime DATETIME(4),
ADD IsCTSTransformed TINYINT NOT NULL DEFAULT '0';

UPDATE DCS_DataCenter.MBAccount
SET CreatedDate = DATE(InsertedTime),
	CreatedTime = InsertedTime
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBAccount
ADD INDEX `IX_MBAccount_CreatedDate` (`CreatedDate`),
ADD INDEX `IX_MBAccount_IsCTSTransformed` (`IsCTSTransformed`),
ADD INDEX `IXF_MBAccount_LastLoginTime` ((CAST(`LastLoginTime` AS DATE)));


# MBAssociation
ALTER TABLE DCS_DataCenter.MBAssociation
ADD CreatedDate DATE,
ADD CreatedTime DATETIME(4),
ADD LastAccessedDate DATE,
ADD IsCTSTransformed TINYINT NOT NULL DEFAULT '0';

UPDATE DCS_DataCenter.MBAssociation
SET CreatedDate = DATE(InsertedTime),
	CreatedTime = InsertedTime,
	LastAccessedDate = DATE(InsertedTime)
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBAssociation
ADD INDEX `IX_MBAssociation_CreatedDate` (`CreatedDate`),
ADD INDEX `IX_MBAssociation_IsCTSTransformed` (`IsCTSTransformed`);


# MBDevice
ALTER TABLE DCS_DataCenter.MBDevice
ADD CreatedDate DATE,
ADD CreatedTime DATETIME(4);

UPDATE DCS_DataCenter.MBDevice
SET CreatedDate = DATE(InsertedTime),
	CreatedTime = InsertedTime
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBDevice
ADD INDEX `IX_MBDevice_CreatedDate` (`CreatedDate`);


# MBDeviceCodeMachine
ALTER TABLE DCS_DataCenter.MBDeviceCodeMachine
ADD CreatedDate DATE;

UPDATE DCS_DataCenter.MBDeviceCodeMachine
SET CreatedDate = DATE(InsertedTime)
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBDeviceCodeMachine
ADD INDEX `IX_MBDeviceCodeMachine_CreatedDate` (`CreatedDate`);


# MBDeviceCodeMediaDRM
ALTER TABLE DCS_DataCenter.MBDeviceCodeMediaDRM
ADD CreatedDate DATE;

UPDATE DCS_DataCenter.MBDeviceCodeMediaDRM
SET CreatedDate = DATE(InsertedTime)
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBDeviceCodeMediaDRM
ADD INDEX `IX_MBDeviceCodeMediaDRM_CreatedDate` (`CreatedDate`);


# MBDeviceCodeTagging
ALTER TABLE DCS_DataCenter.MBDeviceCodeTagging
ADD CreatedDate DATE;

UPDATE DCS_DataCenter.MBDeviceCodeTagging
SET CreatedDate = DATE(InsertedTime)
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBDeviceCodeTagging
ADD INDEX `IX_MBDeviceCodeTagging_CreatedDate` (`CreatedDate`);


# MBDeviceMapping
ALTER TABLE DCS_DataCenter.MBDeviceMapping
ADD CreatedDate DATE;

UPDATE DCS_DataCenter.MBDeviceMapping
SET CreatedDate = DATE(InsertedTime)
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBDeviceMapping
ADD INDEX `IX_MBDeviceMapping_CreatedDate` (`CreatedDate`);


# MBDeviceModel
ALTER TABLE DCS_DataCenter.MBDeviceModel
ADD CreatedDate DATE;

UPDATE DCS_DataCenter.MBDeviceModel
SET CreatedDate = DATE(InsertedTime)
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBDeviceModel
ADD INDEX `IX_MBDeviceModel_CreatedDate` (`CreatedDate`);


# MBOS
ALTER TABLE DCS_DataCenter.MBOS
ADD CreatedDate DATE;

UPDATE DCS_DataCenter.MBOS
SET CreatedDate = DATE(InsertedTime)
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBOS
ADD INDEX `IX_MBOS_CreatedDate` (`CreatedDate`);


# MBUserSetting
ALTER TABLE DCS_DataCenter.MBUserSetting
ADD CreatedDate DATE;

UPDATE DCS_DataCenter.MBUserSetting
SET CreatedDate = DATE(InsertedTime)
WHERE CreatedDate IS NULL;

ALTER TABLE DCS_DataCenter.MBUserSetting
ADD INDEX `IX_MBUserSetting_CreatedDate` (`CreatedDate`);
