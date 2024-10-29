/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241024@Jonathan.Doan [Redmine ID: #212641]
	Task: Truncate Data for new FP flow
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

SET @maxTransID = (SELECT MAX(TransID) FROM Transaction07);

INSERT IGNORE INTO `DCS_DataCenter`.`SystemSetting`(`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`)
VALUES 	(1000, 'AdhocCorrectDataTransaction07', 'StartTransID', 6668822031, NOW()),
	(1001, 'AdhocCorrectDataTransaction07', 'LimitTransID', @maxTransID, NOW());

CALL DCS_DataCenter.adhoc_DCS_DC_CorrectData_Transaction07_FPDeviceID(1000);