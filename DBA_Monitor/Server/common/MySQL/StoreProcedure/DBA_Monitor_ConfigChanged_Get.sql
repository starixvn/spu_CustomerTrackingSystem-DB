/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_ConfigChanged_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_ConfigChanged_Get`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220110@Aries.Nguyen
		Task:		Monitor Daily Report 
		DB:			MonDB
		Original:

		Revisions:
			- 20220110@Aries.Nguyen: Created [Redmine ID: #167040]
            
		Param's Explanation (filtered by): 
        Example:
			- CALL MonDB.DBA_Monitor_ConfigChanged_Get();
	*/
    DECLARE lv_FromDate 		DATETIME;
    DECLARE lv_ToDate 			DATETIME;
    DECLARE lv_MessageMetric 	LONGTEXT;
    DECLARE lv_Server 			VARCHAR(20);
    
    IF @@hostname like '%master%' THEN
		SET lv_Server = 'Master';
    ELSE 
		SET lv_Server = 'Replica';
	END IF;
    
    IF lv_FromDate IS NULL OR lv_ToDate IS NULL THEN
		SET lv_ToDate = NOW();
        SET lv_FromDate = DATE_SUB(lv_ToDate,INTERVAL 1 DAY); 
    END IF;
    
    SELECT CONCAT(lv_Server, ' Configs: ', GROUP_CONCAT(var.VARIABLE_NAME SEPARATOR ', ')) 
    INTO lv_MessageMetric
	FROM performance_schema.variables_info  AS var
	WHERE var.SET_TIME IS NOT NULL 
		AND var.SET_TIME BETWEEN lv_FromDate AND lv_ToDate
		AND var.VARIABLE_NAME NOT IN (SELECT se.SettingValue FROM MonDB.MonitorReport_Setting AS se WHERE se.SettingGroupID = 1);
	
    IF lv_MessageMetric IS NULL THEN
		SET lv_MessageMetric = CONCAT(lv_Server, ' Configs: None');
	END IF;
    
    SELECT lv_MessageMetric AS MessageMetric;
END$$
DELIMITER ;
