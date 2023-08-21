/*<info serverAlias="CTSMain-DCS_Extra" databaseType="2"></info>*/
/*
	Creator:	20230821@Jonathan.Doan
	Task:	 	Add Column BotComponent.isHuman [Redmine ID: #191960]
	Server:  	Master
	DBName:		DCS_Extra
    
	Revisions: 
			- 20230803@Jonathan.Doan: Created [Redmine ID: #191960]
	Reviewer:
*/
USE DCS_Extra;

ALTER TABLE `DCS_Extra`.`BotComponent` 
ADD COLUMN `IsHuman` TINYINT(1) NULL,
ADD COLUMN `ModifiedDate` DATETIME NULL,
ADD KEY `IX_BotComponent_ModifiedDate` (`ModifiedDate`);

INSERT INTO DCS_Extra.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
SELECT 4963733, 'System_Archive', 'Transaction07.TransID', MAX(TransID), CURRENT_TIMESTAMP()
FROM DCS_Extra.Transaction07
LIMIT 1;