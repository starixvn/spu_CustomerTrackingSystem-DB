/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Backup_Incremental_UpdateInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Backup_Incremental_UpdateInfo`(
		IN 	ip_ID 		BIGINT UNSIGNED
	,	IN 	ip_Type 	VARCHAR(20)
    ,	IN 	ip_LSN 		BIGINT UNSIGNED
    ,	IN 	ip_Folder 	VARCHAR(200)
    ,	IN 	ip_Time 	TIME
    ,	IN 	ip_Date 	DATE
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
			- CALL MonDB.DBA_Backup_Incremental_UpdateInfo(1);
	*/
    UPDATE BackupJob
    SET 	LastType = ip_Type
		,	LastLSN = ip_LSN
		,	LastFolder = ip_Folder
		,	LastTime = ip_Time
		,	LastDate  = ip_Date
    WHERE ID = ip_ID;
END$$
DELIMITER ;
