/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20250328@Jonathan.Doan
	Task:	 	Delete SystemSetting unused [Redmine ID: #217768]
	DBName:		DCS_DataCenter
*/

USE DCS_DataCenter;

DELETE FROM `DCS_DataCenter`.`SystemSetting` WHERE ID = 103;