/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_DailyReport_GetSetting`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_DailyReport_GetSetting`()
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
			- CALL MonDB.DBA_Monitor_AccountTransform_Status();
	*/
    SELECT 	grp.MessageGroupID
		,	grp.MessageGroupName
		,	mt.MessageMetricID
		,	mt.MessageMetricName
		,	mt.MessageMetricScript
		,	mt.ServerName
		,	mt.ScriptType
	FROM MonDB.MonitorReport_MessageGroup AS grp
		INNER JOIN MonDB.MonitorReport_MessageMetric AS mt ON grp.MessageGroupID = mt.MessageGroupID
	WHERE grp.Enable = 1
		AND mt.Enable = 1
	ORDER BY mt.MessageGroupID ASC
		,	 mt.MessageMetricID ASC; 
END$$
DELIMITER ;
