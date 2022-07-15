/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_ServerInfo_GetByID`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_ServerInfo_GetByID`(
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
			- CALL MonDB.DBA_ServerInfo_GetByID(1);
	*/
    SELECT 	svr.ServerIP
		,	svr.SSHUser 
		,	svr.SSHKey_File 
		,	svr.XtrabackupImageName
	FROM MonDB.MysqlServer AS svr
	WHERE svr.ID = ip_ID;
END$$
DELIMITER ;
