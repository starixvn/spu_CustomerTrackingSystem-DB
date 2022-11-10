/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_MMTMetric_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_MMTMetric_Insert`(
		IN	ip_Metric 		JSON
	,	IN 	ip_ServerID		BIGINT UNSIGNED
    ,	IN 	ip_JobID		BIGINT UNSIGNED
)
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
			-  CALL MonDB.DBA_Monitor_MMTMetric_Insert('[{"Total": 3, "ObjectName": "55028204*0*1*a*0*0*", "IsProcessed": 0, "MaxTransDate": "2022-10-25 07:06:01.533000", "MinTransDate": "2022-10-25 07:01:01.533000", "MaxInsertTime": "2022-10-25 07:23:06.299000", "MinInsertTime": "2022-10-25 07:23:06.299000"}]',1,1);
	*/
	INSERT IGNORE INTO MonDB.Monitor_MMTMetric(JobID,ServerID,Created,ObjectName,Total,GroupID,IsProcessed,MinTransDate,MaxTransDate,MinInsertTime,MaxInsertTime)
	SELECT	ip_JobID  AS JobID
		,	ip_ServerID AS ServerID
		,	CURRENT_TIMESTAMP() AS Created
		,	ObjectName
        ,	Total
        ,	GroupID
        ,	IsProcessed
		,	MinTransDate 
		,	MaxTransDate 
		,	MinInsertTime 
		,	MaxInsertTime 
	FROM JSON_TABLE(ip_Metric,
		 "$[*]" COLUMNS(
					ObjectName 			VARCHAR(64) 		PATH "$.ObjectName" 
				,	Total 				BIGINT UNSIGNED  	PATH "$.Total" 
				,	GroupID 			INT UNSIGNED  		PATH "$.GroupID" 
				,	IsProcessed 		TINYINT 			PATH "$.IsProcessed" 
				,	MinTransDate 		DATETIME 			PATH "$.MinTransDate" 
				,	MaxTransDate 		DATETIME 			PATH "$.MaxTransDate" 
				,	MinInsertTime 		DATETIME 			PATH "$.MinInsertTime" 
                ,	MaxInsertTime 		DATETIME 			PATH "$.MaxInsertTime" 
		)
	) AS metric;
END$

DELIMITER ;
