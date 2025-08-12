/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20250806@Jonathan.Doan [Redmine ID: #233405]
	Task: Change device rule 
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

INSERT INTO `DCS_DataCenter`.`SystemSetting`(`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`)
VALUES 	(4, 'DCS_MBDevice_Transform', 'MaxMBTransaction07IDCompleted', 0, NOW());

UPDATE `DCS_DataCenter`.`SystemSetting`
SET `VValue` = 0,
    `VName` = 'MBTransaction07.TransID'
WHERE `ID` = 102;