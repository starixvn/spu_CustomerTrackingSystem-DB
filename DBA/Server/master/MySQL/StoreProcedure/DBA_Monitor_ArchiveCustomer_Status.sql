/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_ArchiveCustomer_Status`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_ArchiveCustomer_Status`()
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
			- CALL MonDB.DBA_Monitor_ArchiveCustomer_Status();
	*/
    DECLARE lv_LastArchiveID 	BIGINT UNSIGNED;
    DECLARE lv_MaxArchiveID 	BIGINT UNSIGNED;
    
    IF NOT EXISTS (SELECT Status FROM information_schema.events WHERE EVENT_NAME = 'EV_CTS_DataCenter_ArchiveCustomer' AND STATUS = 'ENABLED') THEN
		SELECT CONCAT('ArchiveCustomer: ', 'Stopped') AS MessageMetric;
        LEAVE sp;
    END IF;
    
	SELECT ParameterValue 
	INTO lv_LastArchiveID
	FROM CTS_DataCenter.SystemParameter
	WHERE ParameterID = 45;
    
	SELECT MAX(ID) 
	INTO lv_MaxArchiveID
	FROM CTS_DataCenter.ArchiveCustomer_CTSCustomer;
    
    SELECT CONCAT('ArchiveCustomer: ', 'Running - ', 'Data Pending: ', ((IFNULL(lv_MaxArchiveID,0) - IFNULL(lv_LastArchiveID,0)))) AS MessageMetric;
    
END$$
DELIMITER ;
