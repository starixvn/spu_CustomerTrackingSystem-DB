/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20250213@Lando.Vu
	Task:	 	Optimize and Enhance OpenSearch [Redmine ID: #217768]
	DBName:		DCS_DataTrace
*/

USE DCS_DataTrace;

INSERT INTO `DCS_DataTrace`.`SystemSetting`(`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`)
VALUES 	(20, 'OpenSearch', 'ListSubID', '2', NOW())
	,	(21, 'OpenSearch', 'Transaction07.TransID', '1', NOW())
    , 	(22, 'OpenSearch', 'CutoffMinutes', 5, NOW())

