/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Created: 20241127@Lando.Vu [Redmine ID: #213401]
	Task: Init Data
	DB: DCS_DataCenter
*/

USE DCS_DataCenter;

INSERT INTO `DCS_DataCenter`.`SystemSetting` (`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`) 
VALUES ('30', 'UpdateLastAccessedDate', 'MaxMBTransaction07ID', '0', NOW());

