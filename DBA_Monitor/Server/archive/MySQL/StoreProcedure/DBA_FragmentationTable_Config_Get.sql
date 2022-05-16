/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_FragmentationTable_Config_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_FragmentationTable_Config_Get`()
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
    DECLARE lv_DateGMT7			DATE  DEFAULT DATE(DATE_ADD(NOW(), INTERVAL 11 HOUR));
	
    SELECT 	sv.SystemName 
		,	sv.SystemRole
        ,	sv.ID AS ServerID
		,	sv.ServerName 
		,	sv.ServerIP 
		,	sv.ServerPort 
		,	sv.MysqlUser 
		,	sv.MysqlPassword 

		,	job.Database 
		,	job.Table AS TableName

		,	noti.MetaData AS NotificationMetaData
        ,	job.ID AS JobID 
        ,	job.HasAlert 
		,	DATE(DATE_ADD(NOW(), INTERVAL 11 HOUR)) AS CurrentDate
	FROM MonDB.FragmentationTableJob AS job
		INNER JOIN MonDB.MysqlServer AS sv ON job.ServerID = sv.ID
		INNER JOIN MonDB.NotificationChannel AS noti ON job.NotificationChannelID = noti.ID
	WHERE   job.IsActive = 1
		AND sv.DBATaskStatus = 'None'
		AND job.LastExecuted != lv_DateGMT7;
END$$
DELIMITER ;
