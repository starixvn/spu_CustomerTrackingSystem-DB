/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_SlowLog_Config_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_SlowLog_Config_Get`()
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
    SELECT 	sv.SystemName 
		,	sv.SystemRole
		,	sv.ServerName 
		,	sv.ServerIP 
		,	sv.ServerPort 
		,	sv.MysqlUser 
		,	sv.MysqlPassword 
		,	job.HasAlert
		,	noti.MetaData AS NotificationMetaData
		,	DATE(DATE_ADD(NOW(), INTERVAL 11 HOUR)) AS CurrentDate
	FROM MonDB.SlowLogJob AS job
		INNER JOIN MonDB.MysqlServer AS sv ON job.ServerID = sv.ID
		INNER JOIN MonDB.NotificationChannel AS noti ON job.NotificationChannelID = noti.ID
	WHERE   job.IsActive = 1;
END$$
DELIMITER ;
