/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2"></info>*/
/*
	Creator:	20231026@Jonathan.Doan
	Task:	 	Update SystemSetting value [Redmine ID: #196078]
	Server:  	Master
	DBName:		DCS_Extra
    
	Revisions: 
			- 20231026@Jonathan.Doan: Created [Redmine ID: #196078]
	Reviewer:
*/
USE DCS_Extra;

UPDATE DCS_Extra.SystemSetting
SET VValue = '2023-08-03'
WHERE ID = 2;