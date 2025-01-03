/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241127@Lando.Vu [Redmine ID: #213401]
	Task: Init Data
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

INSERT INTO `DCS_DataCenter`.`SystemSetting` (`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`) 
VALUES ('30', 'UpdateLastAccessedDate', 'MaxMBTransaction07ID', '0', NOW());

INSERT IGNORE INTO `DCS_DataCenter`.`StaticList` (`ListID`, `ItemID`, `ListCode`, `ListName`, `ItemCode`, `ItemName`, `Status`, `CreatedDate`) 
VALUES ('5', '1', 'MBDeviceCodeMachine_MachineOSType', 'MBDeviceCodeMachine MachineOSType', 'Android', 'Android', '1', NOW())
	, ('5', '2', 'MBDeviceCodeMachine_MachineOSType', 'MBDeviceCodeMachine MachineOSType', 'IOS', 'IOS', '1', NOW())
	, ('6', '0', 'MBDeviceMapping_RecoverType', 'MBDeviceMapping RecoverType', 'NewDevice', 'New Device', '1', NOW())
	, ('6', '1', 'MBDeviceMapping_RecoverType', 'MBDeviceMapping RecoverType', 'MBDeviceCodeMediaDRM', 'MBDeviceCodeMediaDRM', '1', NOW())
	, ('6', '2', 'MBDeviceMapping_RecoverType', 'MBDeviceMapping RecoverType', 'MBDeviceCodeMachine', 'MBDeviceCodeMachine', '1', NOW())
	, ('6', '3', 'MBDeviceMapping_RecoverType', 'MBDeviceMapping RecoverType', 'MBDeviceCodeTagging', 'MBDeviceCodeTagging', '1', NOW())
    , ('7', '-1', 'MBTransaction07', 'MBTransaction07 DeviceStatus', 'EmptyDevice', 'Empty Device', '1', NOW())
	, ('7', '0', 'MBTransaction07', 'MBTransaction07 DeviceStatus', 'NewDevice', 'New Device', '1', NOW())
	, ('7', '1', 'MBTransaction07', 'MBTransaction07 DeviceStatus', 'RecoverByMBDeviceCodeMediaDRM', 'Recover By MBDeviceCodeMediaDRM', '1', NOW())
	, ('7', '2', 'MBTransaction07', 'MBTransaction07 DeviceStatus', 'RecoverByMBDeviceCodeMachine', 'Recover By MBDeviceCodeMachine', '1', NOW())
	, ('7', '3', 'MBTransaction07', 'MBTransaction07 DeviceStatus', 'RecoverByMBDeviceCodeTagging', 'Recover By MBDeviceCodeTagging', '1', NOW());