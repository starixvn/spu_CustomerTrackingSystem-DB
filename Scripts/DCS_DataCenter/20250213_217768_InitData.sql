/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20250213@Lando.Vu
	Task:	 	Optimize and Enhance OpenSearch [Redmine ID: #217768]
	DBName:		DCS_DataCenter
*/

USE DCS_DataCenter;

INSERT INTO `DCS_DataCenter`.`SystemSetting`(`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`)
VALUES 	(100, 'OpenSearch', 'ListSubID', '2', NOW())
	,	(101, 'OpenSearch', 'Transaction07.TransID', '1', NOW())
    , 	(102, 'OpenSearch', 'CutoffMinutes', 5, NOW())

