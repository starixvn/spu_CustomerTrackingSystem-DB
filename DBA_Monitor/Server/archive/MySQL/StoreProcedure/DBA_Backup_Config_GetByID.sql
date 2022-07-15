/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Backup_Config_GetByID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Backup_Config_GetByID`(
	IN 	ip_ID BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220717@Aries.Nguyen
		Task:		Grafana Monitor Table IO Metric
		DB:			MonDB
		Original: 

		Revisions:
			- 20220717@Aries.Nguyen: Created [Redmine ID: #160195]
            
		Param's Explanation (filtered by):

        Example:
			- CALL MonDB.DBA_Backup_Full_GetID(1);
	*/
    DECLARE  lv_CurrTimeGMT7 TIME DEFAULT TIME(DATE_ADD(NOW(), INTERVAL 11 HOUR));
    DECLARE  lv_CurrTimeGMT7_Str VARCHAR(20) DEFAULT DATE_FORMAT(lv_CurrTimeGMT7, '%H_%i');
	DECLARE  lv_CurrDateGMT7 DATE DEFAULT DATE(DATE_ADD(NOW(), INTERVAL 11 HOUR));
	DECLARE  lv_CurrDateGMT7_Str VARCHAR(20) DEFAULT DATE_FORMAT(lv_CurrDateGMT7, '%Y_%m_%d');
    
    SELECT 	svr.ID AS Source_ServerID
		,	svr.ServerIP AS Source_ServerIP
        ,	svr.ServerName AS Source_ServerName
        ,	svr.ContainerName AS Source_ContainerName
        ,	svr.ContainerNetwork AS Source_ContainerNetwork
        ,	svr.XtrabackupImageName AS Source_XtrabackupImageName
        
		,	svr.ServerPort AS Source_Port
		,	svr.MysqlUser AS Source_MysqlUser
		,	svr.MysqlPassword AS Source_MysqlPassword
		,	svr.SSHUser AS Source_SSHUser
		,	svr.SSHKey_File AS Source_SSHKey_File
		,	svr.DataPath AS Source_DataPath
		,	svr.BinlogPath AS Source_BinlogPath
        
		,	des.ID AS Des_ServerID
        ,	des.ServerIP AS Des_ServerIP
        ,	des.ServerName AS Des_ServerName
		,	des.SSHUser AS Des_SSHUser
		,	des.SSHKey_File AS Des_SSHKey_File
		
		,	CASE WHEN job.Type = 'Full' THEN 'Full'
				 WHEN job.FullSchedule < lv_CurrTimeGMT7 AND (job.LastTime IS NULL OR (job.LastType = 'Incremental_Inc' AND job.FullSchedule > job.LastTime )) THEN 'Incremental_Full'
				 ELSE  'Incremental_Inc' END AS BackupType
		
        ,  	job.Folder AS Source_Folder
        ,	job.DesFolder AS Des_RootFolder
		,	CASE WHEN job.Type = 'Full' THEN job.DesFolder 
				 WHEN job.Type = 'Incremental' 
					AND job.FullSchedule < lv_CurrTimeGMT7 
                    AND (job.LastTime IS NULL OR (job.LastType = 'Incremental_Inc'  AND job.FullSchedule > job.LastTime)) THEN CONCAT(job.DesFolder,"/",lv_CurrDateGMT7_Str)
				 ELSE CONCAT(job.DesFolder,"/",IFNULL(DATE_FORMAT(job.LastDate, '%Y_%m_%d'),lv_CurrDateGMT7_Str))  
			END AS Des_Folder
        ,	CASE WHEN job.Type = 'Full' THEN CONCAT("BKFull_",lv_CurrDateGMT7_Str,"_",lv_CurrTimeGMT7_Str)
				 WHEN job.Type = 'Incremental' 
					AND job.FullSchedule > lv_CurrTimeGMT7 THEN CONCAT("BKInc_",job.LastDate,'-',lv_CurrTimeGMT7_Str) 
				 ELSE CONCAT("BKInc_",lv_CurrDateGMT7_Str,'-',lv_CurrTimeGMT7_Str) 
			END AS Des_FolderName
        ,	job.DiskThreshold
		
        ,	job.LastTime
		,	job.LastDate
        ,	job.LastLSN
        ,	job.LastFolder
		,	noti.MetaData AS NotificationMetaData
        
        ,	lv_CurrTimeGMT7 AS CurrTime
        ,	CASE WHEN job.Type = 'Full' THEN lv_CurrDateGMT7
				 WHEN job.FullSchedule < lv_CurrTimeGMT7 AND (job.LastTime IS NULL OR job.LastType = 'Incremental_Inc') THEN lv_CurrDateGMT7
				 ELSE job.LastDate END  AS CurrDate
	FROM MonDB.BackupJob AS job
		INNER JOIN MonDB.MysqlServer AS svr ON job.ServerID = svr.ID
		INNER JOIN MonDB.MysqlServer AS des ON job.DesServerID = des.ID
		INNER JOIN MonDB.NotificationChannel AS noti ON job.NotificationChannelID = noti.ID
	WHERE job.ID = ip_ID
		AND svr.DBATaskStatus = 'None'
		AND job.IsActive = 1;
END$$
DELIMITER ;
