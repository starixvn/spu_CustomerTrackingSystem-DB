/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_ArchiveDeviceCode_Status`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_ArchiveDeviceCode_Status`()
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
			- CALL MonDB.DBA_Monitor_ArchiveDeviceCode_Status();
	*/
    DECLARE lv_ArcDeviceCode_LastDeviceCodeID 		BIGINT UNSIGNED;
    DECLARE lv_ArcDeviceCode_Date 					DATE;
    
    IF NOT EXISTS (SELECT Status FROM information_schema.events WHERE EVENT_NAME = 'EV_DCS_DataCenter_Archive_DeviceCode' AND STATUS = 'ENABLED') THEN
		SELECT CONCAT('ArchiveDeviceCode: ', 'Stopped') AS MessageMetric;
        LEAVE sp;
    END IF;

	SELECT VValue
	INTO lv_ArcDeviceCode_LastDeviceCodeID
	FROM DCS_DataCenter.SystemSetting WHERE ID = 8;
    
    SELECT CreatedDate 
    INTO lv_ArcDeviceCode_Date
	from DCS_DataCenter.DeviceCode 
	WHERE DeviceCodeID > lv_ArcDeviceCode_LastDeviceCodeID limit 1;
    
    SELECT CONCAT('ArchiveDeviceCode: ', 'Running - ', 'CurrentDate: ', lv_ArcDeviceCode_Date) AS MessageMetric;
    
END$$
DELIMITER ;
