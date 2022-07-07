/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_Config_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_Config_Get`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210816@Aries.Nguyen
		Task:		Grafana Monitor Table IO Metric
		DB:			MonDB
		Original: 

		Revisions:
			- 20210630@Aries.Nguyen: Created [Redmine ID: #172483]
            
		Param's Explanation (filtered by):
        Example:
			- CALL MonDB.DBA_Monitor_Config_Get();
	*/
    SELECT 	sv.ID AS ServerID 
		,	sv.ServerIP 
		,	sv.ServerPort 
		,	sv.MysqlUser 
		,	sv.MysqlPassword 
	FROM MonDB.MonitorJob AS job
		INNER JOIN MonDB.MysqlServer AS sv ON job.ServerID = sv.ID
	WHERE   job.IsActive = 1
		AND sv.DBATaskStatus != 'Backup';
END$$
DELIMITER ;
