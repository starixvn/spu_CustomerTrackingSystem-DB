/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250108@Jonathan.Doan [Redmine ID: #213401]
	Task: TRUNCATE Data Mobile App
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

DROP TABLE IF EXISTS MB_RawTransaction;

TRUNCATE TABLE MBAccount;
TRUNCATE TABLE MBAssociation;
TRUNCATE TABLE MBDevice;
TRUNCATE TABLE MBDeviceCodeMachine;
TRUNCATE TABLE MBDeviceCodeMediaDRM;
TRUNCATE TABLE MBDeviceCodeTagging;
TRUNCATE TABLE MBDeviceMapping;
TRUNCATE TABLE MBDeviceModel;
TRUNCATE TABLE MBOS;
TRUNCATE TABLE MBProcessedTransaction;
TRUNCATE TABLE MBRawTransaction;
TRUNCATE TABLE MBTransaction;
TRUNCATE TABLE MBTransaction07;
TRUNCATE TABLE MBUserSetting;

UPDATE `DCS_DataCenter`.`SystemSetting` 
SET `VValue` = '0',
	`UpdatedTime` = NOW()
WHERE `ID` = '30';
