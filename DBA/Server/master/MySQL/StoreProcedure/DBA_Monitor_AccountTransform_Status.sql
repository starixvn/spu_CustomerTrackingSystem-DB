/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_AccountTransform_Status`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_AccountTransform_Status`()
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
			- CALL MonDB.DBA_Monitor_AccountTransform_Status();
	*/
    DECLARE lv_MinAccountTransformStatusID 	BIGINT UNSIGNED;
    DECLARE lv_MaxAccountTransformStatusID 	BIGINT UNSIGNED;
    
    IF NOT EXISTS (SELECT Status FROM information_schema.events WHERE EVENT_NAME = 'EV_DCS_DataCenter_Account_UpdateTransformStatus' AND STATUS = 'ENABLED') THEN
		SELECT CONCAT('AccountTransform-UpdateStatus: ', 'Stopped') AS MessageMetric;
        LEAVE sp;
    END IF;
    
	SELECT 	MIN(ID)
		,	MAX(ID)
	INTO 	lv_MinAccountTransformStatusID
		, 	lv_MaxAccountTransformStatusID
	FROM DCS_DataCenter.AccountTransformStatus;

    SELECT CONCAT('AccountTransform-UpdateStatus: ', 'Running - ', 'Data Pending: ', (IFNULL(lv_MaxAccountTransformStatusID,0) - IFNULL(lv_MaxAccountTransformStatusID,0))) AS MessageMetric;

END$$
DELIMITER ;
