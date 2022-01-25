/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_TableMetric_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_TableMetric_Insert`(
		IN	ip_Metric 	JSON
	,	IN 	ip_Server	VARCHAR(20)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220125@Aries.Nguyen
		Task:		Move Monitor Data to Archive Server
		DB:			MonDB
		Original: 

		Revisions:
			- 20220125@Aries.Nguyen: Created [Redmine ID: #167927]
            
		Param's Explanation (filtered by):
        Example:
			- CALL MonDB.DBA_Monitor_TableMetric_Insert();
	*/
    DROP TEMPORARY TABLE IF EXISTS Temp_Metrics;
	CREATE TEMPORARY TABLE Temp_Metrics (
			Object_Type 		VARCHAR(64) NOT NULL
		,	Object_Schema 		VARCHAR(64) NOT NULL
		,	Object_Name 		VARCHAR(64) NOT NULL
		,	Count_Star 			BIGINT UNSIGNED NOT NULL
		,	Sum_Timer_Wait 		BIGINT UNSIGNED NOT NULL
		,	Min_Timer_Wait 		BIGINT UNSIGNED NOT NULL
		,	Avg_Timer_Wait 		BIGINT UNSIGNED NOT NULL
		,	Max_Timer_Wait 		BIGINT UNSIGNED NOT NULL
		,	Count_Read 			BIGINT UNSIGNED NOT NULL
		,	Sum_Timer_Read 		BIGINT UNSIGNED NOT NULL
		,	Min_Timer_Read 		BIGINT UNSIGNED NOT NULL
		,	Avg_Timer_Read 		BIGINT UNSIGNED NOT NULL
		,	Max_Timer_Read		BIGINT UNSIGNED NOT NULL
		,	Count_Write 		BIGINT UNSIGNED NOT NULL
		,	Sum_Timer_Write 	BIGINT UNSIGNED NOT NULL
		,	Min_Timer_Write	 	BIGINT UNSIGNED NOT NULL
		,	Avg_Timer_Write 	BIGINT UNSIGNED NOT NULL
		,	Max_Timer_Write		BIGINT UNSIGNED NOT NULL
		,	Count_Fetch 		BIGINT UNSIGNED NOT NULL
		,	Sum_Timer_Fetch 	BIGINT UNSIGNED NOT NULL
		,	Min_Timer_Fetch 	BIGINT UNSIGNED NOT NULL
		,	Avg_Timer_Fetch 	BIGINT UNSIGNED NOT NULL
		,	Max_Timer_Fetch 	BIGINT UNSIGNED NOT NULL
		,	Count_Insert 		BIGINT UNSIGNED NOT NULL
		,	Sum_Timer_Insert 	BIGINT UNSIGNED NOT NULL
		,	Min_Timer_Insert 	BIGINT UNSIGNED NOT NULL
		,	Avg_Timer_Insert 	BIGINT UNSIGNED NOT NULL
		,	Max_Timer_Insert 	BIGINT UNSIGNED NOT NULL
		,	Count_Update 		BIGINT UNSIGNED NOT NULL
		,	Sum_Timer_Update 	BIGINT UNSIGNED NOT NULL
		,	Min_Timer_Update 	BIGINT UNSIGNED NOT NULL
		,	Avg_Timer_Update 	BIGINT UNSIGNED NOT NULL
		,	Max_Timer_Update 	BIGINT UNSIGNED NOT NULL
		,	Count_Delete 		BIGINT UNSIGNED NOT NULL
		,	Sum_Timer_Delete 	BIGINT UNSIGNED NOT NULL
		,	Min_Timer_Delete 	BIGINT UNSIGNED NOT NULL
		,	Avg_Timer_Delete 	BIGINT UNSIGNED NOT NULL
		,	Max_Timer_Delete 	BIGINT UNSIGNED NOT NULL
		,	PRIMARY KEY (Object_Type,Object_Schema,Object_Name)
	) ENGINE=InnoDB;
    
    INSERT IGNORE INTO Temp_Metrics(Object_Type, Object_Schema, Object_Name,
									Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
									Count_Read, Sum_Timer_Read, Min_Timer_Read, Avg_Timer_Read, Max_Timer_Read,
									Count_Write, Sum_Timer_Write, Min_Timer_Write, Avg_Timer_Write, Max_Timer_Write,
									Count_Fetch, Sum_Timer_Fetch, Min_Timer_Fetch, Avg_Timer_Fetch, Max_Timer_Fetch,
									Count_Insert, Sum_Timer_Insert, Min_Timer_Insert, Avg_Timer_Insert, Max_Timer_Insert,
									Count_Update, Sum_Timer_Update, Min_Timer_Update, Avg_Timer_Update, Max_Timer_Update,
									Count_Delete, Sum_Timer_Delete, Min_Timer_Delete, Avg_Timer_Delete, Max_Timer_Delete)
	SELECT	metric.Object_Type
		,	metric.Object_Schema 
		,	metric.Object_Name 
		,	metric.Count_Star  
		,	metric.Sum_Timer_Wait  
		,	metric.Min_Timer_Wait  
		,	metric.Avg_Timer_Wait  
		,	metric.Max_Timer_Wait  
		,	metric.Count_Read  
		,	metric.Sum_Timer_Read  
		,	metric.Min_Timer_Read  
		,	metric.Avg_Timer_Read  
		,	metric.Max_Timer_Read  
		,	metric.Count_Write  
		,	metric.Sum_Timer_Write  
		,	metric.Min_Timer_Write  
		,	metric.Avg_Timer_Write  
		,	metric.Max_Timer_Write  
		,	metric.Count_Fetch  
		,	metric.Sum_Timer_Fetch  
		,	metric.Min_Timer_Fetch  
		,	metric.Avg_Timer_Fetch  
		,	metric.Max_Timer_Fetch  
		,	metric.Count_Insert  
		,	metric.Sum_Timer_Insert  
		,	metric.Min_Timer_Insert  
		,	metric.Avg_Timer_Insert  
		,	metric.Max_Timer_Insert  
		,	metric.Count_Update  
		,	metric.Sum_Timer_Update  
		,	metric.Min_Timer_Update  
		,	metric.Avg_Timer_Update  
		,	metric.Max_Timer_Update  
		,	metric.Count_Delete  
		,	metric.Sum_Timer_Delete  
		,	metric.Min_Timer_Delete  
		,	metric.Avg_Timer_Delete  
		,	metric.Max_Timer_Delete  
	FROM JSON_TABLE(ip_Metric,
		 "$[*]" COLUMNS(
					Object_Type 		VARCHAR(64) 		PATH "$.Object_Type" 
				,	Object_Schema 		VARCHAR(64) 		PATH "$.Object_Schema" 
				,	Object_Name 		VARCHAR(64) 		PATH "$.Object_Name" 
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
    
    IF ip_Server = 'master' THEN
		INSERT IGNORE INTO MonDB.Monitor_TableMetric_Master58(Created, Object_Type, Object_Schema, Object_Name,
															  Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
															  Count_Read, Sum_Timer_Read, Min_Timer_Read, Avg_Timer_Read, Max_Timer_Read,
															  Count_Write, Sum_Timer_Write, Min_Timer_Write, Avg_Timer_Write, Max_Timer_Write,
															  Count_Fetch, Sum_Timer_Fetch, Min_Timer_Fetch, Avg_Timer_Fetch, Max_Timer_Fetch,
															  Count_Insert, Sum_Timer_Insert, Min_Timer_Insert, Avg_Timer_Insert, Max_Timer_Insert,
															  Count_Update, Sum_Timer_Update, Min_Timer_Update, Avg_Timer_Update, Max_Timer_Update,
															  Count_Delete, Sum_Timer_Delete, Min_Timer_Delete, Avg_Timer_Delete, Max_Timer_Delete)
		SELECT	CURRENT_TIMESTAMP()
			,	Object_Type
			,	Object_Schema 
			,	Object_Name 
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
		FROM Temp_Metrics;
    END IF;
    
    IF ip_Server = 'Replica' THEN
		INSERT IGNORE INTO MonDB.Monitor_IndexMetric_Replica185(Created, Object_Type, Object_Schema, Object_Name,
																Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
																Count_Read, Sum_Timer_Read, Min_Timer_Read, Avg_Timer_Read, Max_Timer_Read,
																Count_Write, Sum_Timer_Write, Min_Timer_Write, Avg_Timer_Write, Max_Timer_Write,
																Count_Fetch, Sum_Timer_Fetch, Min_Timer_Fetch, Avg_Timer_Fetch, Max_Timer_Fetch,
																Count_Insert, Sum_Timer_Insert, Min_Timer_Insert, Avg_Timer_Insert, Max_Timer_Insert,
																Count_Update, Sum_Timer_Update, Min_Timer_Update, Avg_Timer_Update, Max_Timer_Update,
																Count_Delete, Sum_Timer_Delete, Min_Timer_Delete, Avg_Timer_Delete, Max_Timer_Delete)
		SELECT	CURRENT_TIMESTAMP()
			,	Object_Type
			,	Object_Schema 
			,	Object_Name 
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
		FROM Temp_Metrics;
    END IF;
    
    IF ip_Server = 'archive' THEN
		INSERT IGNORE INTO  MonDB.Monitor_IndexMetric_Archive59(Created, Object_Type, Object_Schema, Object_Name,
																Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
																Count_Read, Sum_Timer_Read, Min_Timer_Read, Avg_Timer_Read, Max_Timer_Read,
																Count_Write, Sum_Timer_Write, Min_Timer_Write, Avg_Timer_Write, Max_Timer_Write,
																Count_Fetch, Sum_Timer_Fetch, Min_Timer_Fetch, Avg_Timer_Fetch, Max_Timer_Fetch,
																Count_Insert, Sum_Timer_Insert, Min_Timer_Insert, Avg_Timer_Insert, Max_Timer_Insert,
																Count_Update, Sum_Timer_Update, Min_Timer_Update, Avg_Timer_Update, Max_Timer_Update,
																Count_Delete, Sum_Timer_Delete, Min_Timer_Delete, Avg_Timer_Delete, Max_Timer_Delete)
		SELECT	CURRENT_TIMESTAMP()
			,	Object_Type
			,	Object_Schema 
			,	Object_Name 
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
		FROM Temp_Metrics;
    END IF;
END$$
DELIMITER ;
