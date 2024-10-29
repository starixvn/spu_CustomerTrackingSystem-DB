/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241030@Jonathan.Doan [Redmine ID: #212641]
	Task: Clean DB
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

DROP PROCEDURE IF EXISTS `adhoc_DCS_DC_CorrectData_Transaction07_FPDeviceID`;

DELETE FROM DCS_DataCenter.SystemSetting
WHERE ID IN (1000, 1001);