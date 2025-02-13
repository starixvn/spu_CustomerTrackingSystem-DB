/*<info serverAlias="CTSMain-DCS_DataTrace" databaseType="2"></info>*/
/*
	Creator:	20250213@Lando.Vu
	Task:	 	Optimize and Enhance OpenSearch [Redmine ID: #217768]
	DBName:		DCS_DataTrace
*/

USE DCS_DataTrace;

INSERT INTO `DCS_DataTrace`.`SystemSetting`(`ID`, `VGroup`, `VName`, `VValue`, `UpdatedTime`)
VALUES 	(200, 'OpenSearch', 'ListSubID', '4400,4629,4610', NOW())
	,	(201, 'OpenSearch', 'Transaction07.TransID', '1', NOW())

