/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_MMT_Config_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_MMT_Config_Get`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221026@Aries.Nguyen
		Task:		Grafana Monitor MMT
		DB:			MonDB
		Original: 

		Revisions:
			- 20221026@Aries.Nguyen: Created [Redmine ID: #179439]
            
		Param's Explanation (filtered by):

        Example:
			- CALL MonDB.DBA_MMT_Config_Get();
	*/
    SELECT 	svr.ID AS ServerID
		,	svr.ServerIP AS ServerIP
		,	svr.ServerPort AS ServerPort
		,	svr.MysqlUser AS MysqlUser
		,	svr.MysqlPassword AS MysqlPassword
        
        ,	job.ID AS JobID
        ,	job.DBName
        ,	job.`Query` 
	FROM MonDB.MMTJob AS job
		INNER JOIN MonDB.MysqlServer AS svr ON job.ServerID = svr.ID
	WHERE job.IsActive = 1;
END$$
DELIMITER ;
