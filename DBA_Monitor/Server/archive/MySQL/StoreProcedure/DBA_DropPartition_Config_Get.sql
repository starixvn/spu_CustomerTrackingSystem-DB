/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_DropPartition_Config_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_DropPartition_Config_Get`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210816@Aries.Nguyen
		Task:		Grafana Monitor Table IO Metric
		DB:			MonDB
		Original: 

		Revisions:
			- 20210127@Aries.Nguyen: Created [Redmine ID: #160195]
            
		Param's Explanation (filtered by):
			- ip_RunType: Manual or Job
        Example:
			- CALL MonDB.DBA_ReOrganizeArchive_Config_Get();
	*/
    DECLARE lv_DayOfWeekGMT7 	SMALLINT DEFAULT DAYOFWEEK(DATE_ADD(NOW(), INTERVAL 11 HOUR));
	DECLARE lv_DayOfMonthGMT7 	SMALLINT DEFAULT DAYOFMONTH(DATE_ADD(NOW(), INTERVAL 11 HOUR));
	DECLARE lv_CurrTimeGMT7 	TIME DEFAULT TIME(DATE_ADD(NOW(), INTERVAL 11 HOUR));
    DECLARE lv_DateGMT7			DATE  DEFAULT DATE(DATE_ADD(NOW(), INTERVAL 11 HOUR));
   
    
    #SELECT lv_DayOfWeekGMT7,  lv_CurrTimeGMT7, lv_DateGMT7;
	
    SELECT 	sv.SystemName 
		,	sv.SystemRole
		,	sv.ServerName 
		,	sv.ServerIP 
		,	sv.ServerPort 
		,	sv.MysqlUser 
		,	sv.MysqlPassword 
    
		,	job.Database 
		,	job.Table 
		,	job.PartitionMax
        ,   CASE WHEN job.PartitionType = 'Weekly' THEN CONCAT(job.PartitionPrefix,YEARWEEK(DATE_SUB(DATE_ADD(NOW(), INTERVAL 11 HOUR), INTERVAL job.DayRange DAY))) 
				 WHEN job.PartitionType = 'Monthly' THEN CONCAT(job.PartitionPrefix,EXTRACT(YEAR_MONTH FROM DATE_SUB(DATE_ADD(NOW(), INTERVAL 11 HOUR), INTERVAL job.DayRange DAY)))
            END AS PartitionName
		,	DATE_SUB(DATE_ADD(NOW(), INTERVAL 11 HOUR), INTERVAL job.DayRange DAY) AS PartitionDate
		,	noti.MetaData AS NotificationMetaData
		,	DATE(DATE_ADD(NOW(), INTERVAL 11 HOUR)) AS CurrentDate
	FROM job.ReOrganizePartitionJob AS job
		INNER JOIN MonDB.MysqlServer AS sv ON job.ServerID = sv.ID
		INNER JOIN MonDB.NotificationChannel AS noti ON job.NotificationChannelID = noti.ID
	WHERE   sv.DBATaskStatus = 'None'
		AND job.IsActive = 1
        AND job.DateExecute = lv_DayOfWeekGMT7 
		AND job.TimeExecute <  lv_CurrTimeGMT7 
		AND job.LastExecuted != lv_DateGMT7
        AND (job.PartitionType = 'Weekly' 
				OR (job.PartitionType = 'Monthly' AND lv_DayOfMonthGMT7 <= 7));
END$$
DELIMITER ;
