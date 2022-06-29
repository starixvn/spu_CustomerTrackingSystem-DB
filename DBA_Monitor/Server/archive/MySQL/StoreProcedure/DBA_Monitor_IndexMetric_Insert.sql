/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_IndexMetric_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_IndexMetric_Insert`(
		IN	ip_Metric 		JSON
	,	IN 	ip_ServerID		BIGINT UNSIGNED
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
            - 20220630@Aries.Nguyen: Update monitor [Redmine ID: #172483]
            
		Param's Explanation (filtered by):
        Example:
			- CALL MonDB.DBA_Monitor_TableMetric_Get();
	*/
	INSERT IGNORE INTO   MonDB.Monitor_IndexMetric_Master58(ServerID,Created,
															Object_Type, Object_Schema, Object_Name, Index_Name,
															Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
															Count_Read, Sum_Timer_Read, Min_Timer_Read, Avg_Timer_Read, Max_Timer_Read,
															Count_Write, Sum_Timer_Write, Min_Timer_Write, Avg_Timer_Write, Max_Timer_Write,
															Count_Fetch, Sum_Timer_Fetch, Min_Timer_Fetch, Avg_Timer_Fetch, Max_Timer_Fetch,
															Count_Insert, Sum_Timer_Insert, Min_Timer_Insert, Avg_Timer_Insert, Max_Timer_Insert,
															Count_Update, Sum_Timer_Update, Min_Timer_Update, Avg_Timer_Update, Max_Timer_Update,
															Count_Delete, Sum_Timer_Delete, Min_Timer_Delete, Avg_Timer_Delete, Max_Timer_Delete)
	SELECT	ip_ServerID AS ServerID
		,	CURRENT_TIMESTAMP() AS Created
		,	Object_Type
		,	Object_Schema 
		,	Object_Name 
		,	Index_Name
		,	Count_Star  
		,	Sum_Timer_Wait  
		,	Min_Timer_Wait  
		,	Avg_Timer_Wait  
		,	Max_Timer_Wait  
		,	Count_Read  
		,	Sum_Timer_Read  
		,	Min_Timer_Read  
		,	Avg_Timer_Read  
		,	Max_Timer_Read  
		,	Count_Write  
		,	Sum_Timer_Write  
		,	Min_Timer_Write  
		,	Avg_Timer_Write  
		,	Max_Timer_Write  
		,	Count_Fetch  
		,	Sum_Timer_Fetch  
		,	Min_Timer_Fetch  
		,	Avg_Timer_Fetch  
		,	Max_Timer_Fetch  
		,	Count_Insert  
		,	Sum_Timer_Insert  
		,	Min_Timer_Insert  
		,	Avg_Timer_Insert  
		,	Max_Timer_Insert  
		,	Count_Update  
		,	Sum_Timer_Update  
		,	Min_Timer_Update  
		,	Avg_Timer_Update  
		,	Max_Timer_Update  
		,	Count_Delete  
		,	Sum_Timer_Delete  
		,	Min_Timer_Delete  
		,	Avg_Timer_Delete  
		,	Max_Timer_Delete  
	FROM JSON_TABLE(ip_Metric,
		 "$[*]" COLUMNS(
					Object_Type 		VARCHAR(64) 		PATH "$.Object_Type" 
				,	Object_Schema 		VARCHAR(64) 		PATH "$.Object_Schema" 
				,	Object_Name 		VARCHAR(64) 		PATH "$.Object_Name" 
				,	Index_Name 			VARCHAR(64) 		PATH "$.Index_Name" 
				,	Count_Star 			BIGINT UNSIGNED 	PATH "$.Count_Star" 
				,	Sum_Timer_Wait 		BIGINT UNSIGNED 	PATH "$.Sum_Timer_Wait" 
				,	Min_Timer_Wait 		BIGINT UNSIGNED 	PATH "$.Min_Timer_Wait" 
				,	Avg_Timer_Wait 		BIGINT UNSIGNED 	PATH "$.Avg_Timer_Wait" 	
				,	Max_Timer_Wait 		BIGINT UNSIGNED 	PATH "$.Max_Timer_Wait" 
				,	Count_Read 			BIGINT UNSIGNED 	PATH "$.Count_Read" 
				,	Sum_Timer_Read 		BIGINT UNSIGNED 	PATH "$.Sum_Timer_Read" 
				,	Min_Timer_Read 		BIGINT UNSIGNED 	PATH "$.Min_Timer_Read" 
				,	Avg_Timer_Read 		BIGINT UNSIGNED 	PATH "$.Avg_Timer_Read" 	
				,	Max_Timer_Read		BIGINT UNSIGNED 	PATH "$.Max_Timer_Read" 
				,	Count_Write 		BIGINT UNSIGNED 	PATH "$.Count_Write" 
				,	Sum_Timer_Write 	BIGINT UNSIGNED 	PATH "$.Sum_Timer_Write" 
				,	Min_Timer_Write	 	BIGINT UNSIGNED 	PATH "$.Min_Timer_Write" 
				,	Avg_Timer_Write 	BIGINT UNSIGNED 	PATH "$.Avg_Timer_Write" 
				,	Max_Timer_Write		BIGINT UNSIGNED 	PATH "$.Max_Timer_Write" 
				,	Count_Fetch 		BIGINT UNSIGNED 	PATH "$.Count_Fetch" 
				,	Sum_Timer_Fetch 	BIGINT UNSIGNED 	PATH "$.Sum_Timer_Fetch" 
				,	Min_Timer_Fetch 	BIGINT UNSIGNED 	PATH "$.Min_Timer_Fetch" 
				,	Avg_Timer_Fetch 	BIGINT UNSIGNED 	PATH "$.Avg_Timer_Fetch" 
				,	Max_Timer_Fetch 	BIGINT UNSIGNED 	PATH "$.Avg_Timer_Fetch" 
				,	Count_Insert 		BIGINT UNSIGNED 	PATH "$.Count_Insert" 
				,	Sum_Timer_Insert 	BIGINT UNSIGNED 	PATH "$.Sum_Timer_Insert" 
				,	Min_Timer_Insert 	BIGINT UNSIGNED 	PATH "$.Min_Timer_Insert" 
				,	Avg_Timer_Insert 	BIGINT UNSIGNED 	PATH "$.Avg_Timer_Insert" 
				,	Max_Timer_Insert 	BIGINT UNSIGNED 	PATH "$.Max_Timer_Insert" 
				,	Count_Update 		BIGINT UNSIGNED 	PATH "$.Count_Update" 
				,	Sum_Timer_Update 	BIGINT UNSIGNED 	PATH "$.Sum_Timer_Update" 
				,	Min_Timer_Update 	BIGINT UNSIGNED 	PATH "$.Min_Timer_Update" 
				,	Avg_Timer_Update 	BIGINT UNSIGNED 	PATH "$.Avg_Timer_Update" 
				,	Max_Timer_Update 	BIGINT UNSIGNED 	PATH "$.Max_Timer_Update" 
				,	Count_Delete 		BIGINT UNSIGNED 	PATH "$.Count_Delete" 
				,	Sum_Timer_Delete 	BIGINT UNSIGNED 	PATH "$.Sum_Timer_Delete" 
				,	Min_Timer_Delete 	BIGINT UNSIGNED 	PATH "$.Min_Timer_Delete" 
				,	Avg_Timer_Delete 	BIGINT UNSIGNED 	PATH "$.Avg_Timer_Delete" 
				,	Max_Timer_Delete 	BIGINT UNSIGNED 	PATH "$.Max_Timer_Delete" 
			)
	) AS metric;
END$$
DELIMITER ;
