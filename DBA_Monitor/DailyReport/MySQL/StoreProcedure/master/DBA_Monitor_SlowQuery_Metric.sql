/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_SlowQuery_Metric`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_SlowQuery_Metric`()
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
			- CALL MonDB.DBA_Monitor_SlowQuery_Metric(); 
	*/
    DECLARE lv_FromDate 		DATETIME;
    DECLARE lv_ToDate 			DATETIME;
    DECLARE lv_LongQueryTime	INT;
    DECLARE lv_Total			INT;
    DECLARE lv_Total2Min		INT;
    DECLARE lv_Total5Min		INT;
    DECLARE lv_Total10Min		INT;
    
    IF lv_FromDate IS NULL OR lv_ToDate IS NULL THEN
		SET lv_ToDate = NOW();
        SET lv_FromDate = DATE_SUB(lv_ToDate,INTERVAL 1 DAY);
    END IF;
    
    SELECT VARIABLE_VALUE
	INTO lv_LongQueryTime
	FROM  performance_schema.global_variables WHERE VARIABLE_NAME = 'long_query_time'; 
	
    SELECT count(1)
    INTO lv_Total
	FROM mysql.slow_log
	WHERE start_time BETWEEN lv_FromDate AND lv_ToDate;
        
	SELECT count(1)
    INTO lv_Total2Min
	FROM mysql.slow_log
	WHERE start_time BETWEEN lv_FromDate AND lv_ToDate
       AND query_time >= '00:02:00.000000' 
	   AND query_time < '00:05:00.000000';
        
	SELECT count(1)
    INTO lv_Total5Min
	FROM mysql.slow_log
	WHERE start_time BETWEEN lv_FromDate AND lv_ToDate
		AND query_time >= '00:05:00.000000' 
		AND query_time < '00:10:00.000000';
        
	SELECT count(1)
    INTO lv_Total10Min
	FROM mysql.slow_log
	WHERE start_time BETWEEN lv_FromDate AND lv_ToDate
		AND query_time >= '00:10:00.000000';
    
    SELECT CONCAT("Time Setting: ", lv_LongQueryTime,"\\n",
		"Total: ", lv_Total,"\\n",
        "Total > 2min: ", lv_Total2Min,"\\n",
        "Total > 5min: ", lv_Total5Min,"\\n",
        "Total > 10min: ", lv_Total10Min,"\\n"
        ) AS MessageMetric;
END$$
DELIMITER ;
