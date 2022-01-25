/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_ArchiveDeviceByAccountInactive_Status`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_ArchiveDeviceByAccountInactive_Status`()
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20220110@Aries.Nguyen
		Task:		Monitor Daily Report 
		DB:			MonDB
		Original:

		Revisions:
			- 20220110@Aries.Nguyen: Created [Redmine ID: #167040]
            
		Param's Explanation (filtered by): 
        Example:
			- CALL MonDB.DBA_Monitor_ArchiveDeviceByAccountInactive_Status();
	*/
    DECLARE lv_ArchiveAccountInactive_LastDateScan 		DATE;
    
    IF NOT EXISTS (SELECT Status FROM information_schema.events WHERE EVENT_NAME = 'EV_DCS_DataCenter_ArchiveAccountInactive_Device' AND STATUS = 'ENABLED') THEN
		SELECT CONCAT('ArchiveDevice: ', 'Stopped') AS MessageMetric;
        LEAVE sp;
    END IF;

	SELECT VValue 
	INTO lv_ArchiveAccountInactive_LastDateScan
	FROM DCS_DataCenter.SystemSetting where id  = 14;
 
    SELECT CONCAT('ArchiveDevice: ', 'Running - ', 'LastDateScan: ', lv_ArchiveAccountInactive_LastDateScan) AS MessageMetric;
    
END$$
DELIMITER ;
