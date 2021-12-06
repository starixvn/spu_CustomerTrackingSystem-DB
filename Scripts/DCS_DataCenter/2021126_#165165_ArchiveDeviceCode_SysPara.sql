/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20211126@Aries.Nguyen 
	Task:	 	Tuning archive device code [Redmine ID: #165165]
	Server:  	Master
	DBName:		DCS_DataCenter

	Revisions: 
			- 20211126@Aries.Nguyen: Created [Redmine ID: #165165]
	Reviewer:
*/
USE DCS_DataCenter;
UPDATE DCS_DataCenter.SystemSetting AS ss
SET		VValue = 0
	,	VGroup = 'ArchiveDeviceCode'
WHERE	ID = 8;  

UPDATE DCS_DataCenter.SystemSetting AS ss
SET 	VValue = 500
	,	VGroup = 'ArchiveDeviceCode'
    ,	VName = 'Batch Size'
WHERE	ID = 9;  

DELETE 
FROM DCS_DataCenter.SystemSetting 
WHERE	ID = 10;  

USE DCS_DataCenter;
DROP TABLE DCS_DataCenter.zzArchiveDeviceCode;