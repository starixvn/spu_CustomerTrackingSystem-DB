/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230517@Victoria.Le
	Task:	 	TW BI - CTS Classname in EN and Simplified CN
	Server:  	CTSMain
	DBName:		CTS_DataCenter

Revisions: 
		- 20230517@Victoria.Le: 	Schema - CustomerCategory [Redmine ID: #188388]

*/

	USE CTS_DataCenter;
	
	ALTER TABLE CustomerCategory
	ADD COLUMN SabaIntelligent_RiskLevel 		VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL
,	ADD COLUMN SabaIntelligent_RiskLevel_TCN 	VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL
,	ADD COLUMN SabaIntelligent_RiskLevel_SCN 	VARCHAR(50) CHARACTER SET utf8 COLLATE utf8_unicode_ci DEFAULT NULL
;