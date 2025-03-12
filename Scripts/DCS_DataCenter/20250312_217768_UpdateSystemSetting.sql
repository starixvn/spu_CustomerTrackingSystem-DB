/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20250213@Lando.Vu
	Task:	 	Optimize and Enhance OpenSearch [Redmine ID: #217768]
	DBName:		DCS_DataCenter
*/

USE DCS_DataCenter;

UPDATE `DCS_DataCenter`.`SystemSetting`
SET
`VName` = 'ListIgnoredSubID',
`VValue` = '',
`UpdatedTime` = CURRENT_TIMESTAMP()
WHERE `ID` = 100;
