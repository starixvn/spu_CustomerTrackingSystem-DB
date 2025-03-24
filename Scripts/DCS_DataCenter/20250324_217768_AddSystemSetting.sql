/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20250324@Jonathan.Doan
	Task:	 	Add a SystemSetting param [Redmine ID: #217768]
	DBName:		DCS_DataCenter
*/

USE DCS_DataCenter;

INSERT INTO `DCS_DataCenter`.`SystemSetting`(`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`)
VALUES 	(103, 'OpenSearch', 'MaxTransaction07IDCompleted', 0, NOW())

