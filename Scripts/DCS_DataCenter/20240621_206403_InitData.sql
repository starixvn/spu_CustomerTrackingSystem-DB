/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20240621@Jonathan.Doan [Redmine ID: #206403]
	Task: Change Data Flow Ver. 6
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

INSERT INTO `DCS_DataCenter`.`SystemSetting`(`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`)
VALUES 	(23, 'DeviceEvolution', 'Max_FP_DeviceFingerprintAccountID', 0, NOW()),
		(24, 'DeviceMapping', 'Min_Transaction_TransID', 0, NOW()),
		(25, 'DeviceMapping', 'Minute_To_Wait_Evolution', 5, NOW()),
		(27, 'TransformDevice', 'SkipDeviceMapping', 0, NOW());

INSERT INTO `DCS_DataCenter`.`StaticList`(`ListID`, `ItemID`, `ListCode`, `ListName`, `ItemCode`, `ItemName`, `Status`, `Description`, `CreatedDate`)
VALUES 	(4, 1, 'DeviceMapping_RecoverType', 'DeviceMapping RecoverType', 'FP_Tagging', 'FP_Tagging', 1, 'Rule 1', NOW()),
		(4, 2, 'DeviceMapping_RecoverType', 'DeviceMapping RecoverType', 'FP_FingerPrint', 'FP_FingerPrint', 1, 'Rule 2', NOW()),
		(4, 3, 'DeviceMapping_RecoverType', 'DeviceMapping RecoverType', 'FP_DeviceFingerprintAccount', 'FP_DeviceFingerprintAccount', 1, 'Rule 3', NOW()),
		(4, 4, 'DeviceMapping_RecoverType', 'DeviceMapping RecoverType', 'FP_DeviceFingerprintAccount_Evolution', 'FP_DeviceFingerprintAccount_Evolution', 1, 'Rule 4', NOW()),
		(4, 5, 'DeviceMapping_RecoverType', 'DeviceMapping RecoverType', 'FP_DeviceFingerprintAccountOld', 'FP_DeviceFingerprintAccountOld', 1, 'Rule 5', NOW());