/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_UpdateLastLoginTime_Status`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_UpdateLastLoginTime_Status`()
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
			- CALL MonDB.DBA_Monitor_UpdateLastLoginTime_Status();
	*/
    DECLARE lv_MaxAccountLastLoginTimeProcessID 		BIGINT UNSIGNED;
    DECLARE lv_MinAccountLastLoginTimeProcessID 		BIGINT UNSIGNED;
    
    DECLARE lv_MaxCTSCustomerLastLoginTimeProcessID 	BIGINT UNSIGNED;
    DECLARE lv_MinCTSCustomerLastLoginTimeProcessID 	BIGINT UNSIGNED;
    
    IF NOT EXISTS (SELECT Status FROM information_schema.events WHERE EVENT_NAME = 'EV_DCS_DataCenter_Account_UpdateLastLoginTime' AND STATUS = 'ENABLED') THEN
		SELECT CONCAT('AccountTransform-UpdateLastLoginTime: ', 'Stopped') AS MessageMetric;
        LEAVE sp;
    END IF;
     
	SELECT 	MAX(ID)
		,	MIN(ID)
	INTO 	lv_MaxAccountLastLoginTimeProcessID
		, 	lv_MinAccountLastLoginTimeProcessID
	FROM DCS_DataCenter.AccountLastLoginTimeProcess;

	SELECT 	MAX(ID)
		,	MIN(ID)
	INTO 	lv_MaxCTSCustomerLastLoginTimeProcessID
		, 	lv_MinCTSCustomerLastLoginTimeProcessID
	FROM DCS_DataCenter.CTSCustomerLastLoginTimeProcess;
    
    SELECT CONCAT('UpdateLastLoginTime: ', 'Running - ', 'Data Pending: ', ((IFNULL(lv_MaxAccountLastLoginTimeProcessID,0) - IFNULL(lv_MinAccountLastLoginTimeProcessID,0))) + ((IFNULL(lv_MaxCTSCustomerLastLoginTimeProcessID,0) - IFNULL(lv_MinCTSCustomerLastLoginTimeProcessID,0)))) AS MessageMetric;
    
END$$
DELIMITER ;
