/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Archive_Config_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Archive_Config_Get`(
	IN 		ip_RunType VARCHAR(20)
)
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
			- CALL MonDB.DBA_Archive_Config_Get();
	*/
    DECLARE lv_DayOfWeekGMT7 	SMALLINT DEFAULT DAYOFWEEK(DATE_ADD(NOW(), INTERVAL 11 HOUR));
	DECLARE lv_CurrTimeGMT7 	TIME DEFAULT TIME(DATE_ADD(NOW(), INTERVAL 11 HOUR));
    DECLARE lv_DateGMT7			DATE  DEFAULT DATE(DATE_ADD(NOW(), INTERVAL 11 HOUR));
    
    # SELECT lv_DayOfWeekGMT7,  lv_CurrTimeGMT7;
	
    SELECT 	svSource.ID AS Source_ServerID
		,	svSource.SystemName AS Source_SystemName
		,	svSource.SystemRole AS Source_SystemRole
		,	svSource.ServerName AS Source_ServerName
		,	svSource.ContainerName AS Source_ContainerName
        ,	svSource.ServerIP AS Source_ServerIP
		,	svSource.ServerPort AS Source_ServerPort
        ,	svSource.MysqlUser AS Source_MysqlUser
        ,	svSource.MysqlPassword AS Source_MysqlPassword
        ,	svSource.SSHUser AS Source_SSHUser
        ,	svSource.SSHKey_File AS Source_SSHKey_File
		,	svSource.DataPath AS Source_DataPath
        
        ,	svSourceMaster.ServerIP AS SourceMaster_ServerIP
		,	svSourceMaster.ServerPort AS SourceMaster_ServerPort
        ,	svSourceMaster.MysqlUser AS SourceMaster_MysqlUser
        ,	svSourceMaster.MysqlPassword AS SourceMaster_MysqlPassword
        
		,	job.SourceDatabase AS Source_Database
		,	job.SourceTable AS  Source_Table
        ,	serDes.ID AS Des_ServerID
		,	serDes.SystemName AS Des_SystemName
		,	serDes.SystemRole AS Des_SystemRole
		,	serDes.ServerName AS Des_ServerName
		,	serDes.ContainerName AS Des_ContainerName
        ,	serDes.ServerIP AS Des_ServerIP
		,	serDes.ServerPort AS Des_ServerPort
        ,	serDes.MysqlUser AS Des_MysqlUser
        ,	serDes.MysqlPassword AS Des_MysqlPassword
        ,	serDes.SSHUser AS Des_SSHUser
        ,	serDes.SSHKey_File AS Des_SSHKey_File
		,	serDes.DataPath AS Des_DataPath
		,	serDes.DataFileOwner AS Des_DataFileOwner
        ,	job.ID AS JobID
		,	job.DesDatabase AS  Des_Database
		,	job.DesTable AS Des_Table
		,	job.PartitionType
        ,	CONCAT(job.PartitionPrefix,YEARWEEK(DATE_SUB(DATE_ADD(NOW(), INTERVAL 11 HOUR), INTERVAL 14 DAY)), "  " , DATE(DATE_SUB(DATE_ADD(NOW(), INTERVAL 11 HOUR), INTERVAL job.KeepDataRange DAY))) AS PartitionName
		,	job.PartitionPrefix
        ,	job.PartitionDelimiter
        ,	job.PartitionMax
		,	job.KeepDataRange
		,	job.DateExecute
		,	job.TimeExecute
		,	job.HasDropPartitionSourceTable
        ,	noti.MetaData AS NotificationMetaData
		,	job.HasAlert_Pre
		,	job.DateAlert_Pre
		,	job.IsAlerted_Pre
		,	job.HasAlert_Done
		,	job.LastExecuted
        ,	DATE(DATE_ADD(NOW(), INTERVAL 11 HOUR)) AS CurrentDate
	FROM MonDB.ArchivePartitionJob AS job
		INNER JOIN MonDB.MysqlServer AS svSource ON job.SourceServerID = svSource.ID
        INNER JOIN MonDB.MysqlServer AS svSourceMaster ON job.SourceMasterServerID = svSourceMaster.ID
		INNER JOIN MonDB.MysqlServer AS serDes ON job.DesServerID = serDes.ID
        INNER JOIN MonDB.NotificationChannel AS noti ON job.NotificationChannelID = noti.ID
	WHERE job.PartitionType = 'Weekly'
		AND job.DateExecute = lv_DayOfWeekGMT7
		AND job.TimeExecute <  lv_CurrTimeGMT7
		AND job.LastExecuteStatus != 'Processed'
        AND job.LastExecuted != lv_DateGMT7
        AND job.RunType = ip_RunType
        AND svSource.DBATaskStatus = 'None'
        AND serDes.DBATaskStatus = 'None';
END$$
DELIMITER ;
