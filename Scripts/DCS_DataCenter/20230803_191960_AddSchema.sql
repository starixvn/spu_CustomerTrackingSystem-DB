/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2"></info>*/
/*
	Creator:	20230803@Jonathan.Doan
	Task:	 	Add Column BotComponent.isHuman [Redmine ID: #191960]
	Server:  	Master
	DBName:		DCS_DataCenter
    
	Revisions: 
			- 20230803@Jonathan.Doan: Created [Redmine ID: #191960]
	Reviewer:
*/
USE DCS_DataCenter;

ALTER TABLE `DCS_DataCenter`.`BotComponent` 
ADD COLUMN `IsHuman` TINYINT(1) NULL,
ADD COLUMN `ModifiedDate` DATETIME NULL,
RENAME INDEX `IX_BotComponent_Code` TO `UX_BotComponent_Code`,
ADD KEY `IX_BotComponent_ModifiedDate` (`ModifiedDate`);


DROP PROCEDURE IF EXISTS `DCS_DC_Script_Update_Schema_Temp`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Script_Update_Schema_Temp`()
    SQL SECURITY INVOKER
BEGIN
    DECLARE lv_MaxTransID BIGINT UNSIGNED;
    
    SELECT IFNULL(MAX(TransID),0)
    INTO lv_MaxTransID
    FROM DCS_DataCenter.Transaction07;
    
	IF lv_MaxTransID >= 0
    THEN
		INSERT INTO DCS_DataCenter.SystemSetting(ID, VGroup, VName, VValue, UpdatedTime)
		SELECT 4963733, 'System_Archive', 'DCS_DataCenter.Transaction07.TransID', lv_MaxTransID, CURRENT_TIMESTAMP();
    END IF;
END$$
DELIMITER ;

CALL DCS_DC_Script_Update_Schema_Temp();
DROP PROCEDURE IF EXISTS `DCS_DC_Script_Update_Schema_Temp`;