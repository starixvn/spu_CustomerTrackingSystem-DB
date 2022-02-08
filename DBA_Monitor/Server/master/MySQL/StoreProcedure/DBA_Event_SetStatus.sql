/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Event_SetStatus`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Event_SetStatus`(
		IN ip_ListEvent		LONGTEXT
    ,	IN ip_Status		VARCHAR(15)
)
    SQL SECURITY INVOKER
sp: BEGIN 
	/*
		Created:	20210816@Aries.Nguyen
		Task:		Grafana Monitor Table IO Metric
		DB:			MonDB
		Original: 

		Revisions:
			- 20210127@Aries.Nguyen: Created [Redmine ID: #160195]
            
		Param's Explanation (filtered by):
        Example:
			- CALL MonDB.DBA_EventStatus_SET();
	*/
    DECLARE lv_EventName 	VARCHAR(100);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Event;
	CREATE TEMPORARY TABLE Temp_Event (
		EventName 	VARCHAR(100),
		PRIMARY KEY(EventName)
	) ENGINE=InnoDB;
    
    SET @sql = CONCAT("INSERT INTO Temp_Event (EventName) VALUES ('", REPLACE(ip_ListEvent, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
	DEALLOCATE PREPARE stmt1;
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_CTS_DataCenter_ArchiveCustomer') AND ip_Status = 'DISABLE' THEN
		ALTER EVENT CTS_DataCenter.EV_CTS_DataCenter_ArchiveCustomer DISABLE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_CTS_DataCenter_ArchiveCustomer') AND ip_Status = 'ENABLE' THEN
		ALTER EVENT CTS_DataCenter.EV_CTS_DataCenter_ArchiveCustomer ENABLE;
    END IF;
	
    /**************************************************/
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_DCS_DataCenter_Archive_DeviceCode') AND ip_Status = 'DISABLE' THEN
		ALTER EVENT DCS_DataCenter.EV_DCS_DataCenter_Archive_DeviceCode DISABLE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_DCS_DataCenter_Archive_DeviceCode') AND ip_Status = 'ENABLE' THEN
		ALTER EVENT DCS_DataCenter.EV_DCS_DataCenter_Archive_DeviceCode ENABLE;
    END IF;
    
    /**************************************************/
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_DCS_DataCenter_Account_UpdateTransformStatus') AND ip_Status = 'DISABLE' THEN
		ALTER EVENT DCS_DataCenter.EV_DCS_DataCenter_Account_UpdateTransformStatus DISABLE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_DCS_DataCenter_Account_UpdateTransformStatus') AND ip_Status = 'ENABLE' THEN
		ALTER EVENT DCS_DataCenter.EV_DCS_DataCenter_Account_UpdateTransformStatus ENABLE;
    END IF;
    
    /**************************************************/
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_DCS_DataCenter_Account_UpdateLastLoginTime') AND ip_Status = 'DISABLE' THEN
		ALTER EVENT DCS_DataCenter.EV_CTS_DataCenter_ArchiveCustomer DISABLE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_DCS_DataCenter_Account_UpdateLastLoginTime') AND ip_Status = 'ENABLE' THEN
		ALTER EVENT DCS_DataCenter.EV_CTS_DataCenter_ArchiveCustomer ENABLE;
    END IF;
    
    /**************************************************/
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_DCS_DataCenter_ArchiveAccountInactive_Device') AND ip_Status = 'DISABLE' THEN
		ALTER EVENT DCS_DataCenter.EV_CTS_DataCenter_ArchiveCustomer DISABLE;
    END IF;
    
    IF EXISTS (SELECT 1 FROM Temp_Event WHERE EventName = 'EV_DCS_DataCenter_ArchiveAccountInactive_Device') AND ip_Status = 'ENABLE' THEN
		ALTER EVENT DCS_DataCenter.EV_CTS_DataCenter_ArchiveCustomer ENABLE;
    END IF;
    
END$$
DELIMITER ;
