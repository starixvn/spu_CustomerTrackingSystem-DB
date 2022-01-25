/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_SPMetric_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_SPMetric_Insert`(
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
			- CALL MonDB.DBA_Monitor_SPMetric_Insert();
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Metrics;
	CREATE TEMPORARY TABLE Temp_Metrics (
			Object_Schema 				VARCHAR(64) NOT NULL
		,	Object_Name 				VARCHAR(64) NOT NULL
		,	Object_Type 				VARCHAR(64) NOT NULL
        ,	GroupID 					INT DEFAULT NULL
	   	,	Count_Star 					BIGINT UNSIGNED NOT NULL
		,	Sum_Timer_Wait 				BIGINT UNSIGNED NOT NULL
		,	Min_Timer_Wait 				BIGINT UNSIGNED NOT NULL
		,	Avg_Timer_Wait 				BIGINT UNSIGNED NOT NULL
		,	Max_Timer_Wait				BIGINT UNSIGNED NOT NULL
		,	Count_Statements 			BIGINT UNSIGNED NOT NULL
		,	Sum_Statements_Wait 		BIGINT UNSIGNED NOT NULL
		,	Min_Statements_Wait 		BIGINT UNSIGNED NOT NULL
		,	Avg_Statements_Wait 		BIGINT UNSIGNED NOT NULL
		,	Max_Statements_Wait 		BIGINT UNSIGNED NOT NULL
		,	Sum_Lock_Time 				BIGINT UNSIGNED NOT NULL
		,	Sum_Errors 					BIGINT UNSIGNED NOT NULL
		,	Sum_Warnings 				BIGINT UNSIGNED NOT NULL
		,	Sum_Rows_Affected 			BIGINT UNSIGNED NOT NULL
		,	Sum_Rows_Sent 				BIGINT UNSIGNED NOT NULL
		,	Sum_Rows_Examined 			BIGINT UNSIGNED NOT NULL
		,	Sum_Created_Tmp_Disk_Tables BIGINT UNSIGNED NOT NULL
		,	Sum_Created_Tmp_Tables 		BIGINT UNSIGNED NOT NULL
		,	Sum_Select_Full_Join 		BIGINT UNSIGNED NOT NULL
		,	Sum_Select_Full_Range_Join 	BIGINT UNSIGNED NOT NULL
		,	Sum_Select_Range 			BIGINT UNSIGNED NOT NULL
		,	Sum_Select_Range_Check 		BIGINT UNSIGNED NOT NULL
		,	Sum_Select_Scan 			BIGINT UNSIGNED NOT NULL
		,	Sum_Sort_Merge_Passes 		BIGINT UNSIGNED NOT NULL
		,	Sum_Sort_Range 				BIGINT UNSIGNED NOT NULL
		,	Sum_Sort_Rows 				BIGINT UNSIGNED NOT NULL
		,	Sum_Sort_Scan 				BIGINT UNSIGNED NOT NULL
		,	Sum_No_Index_Used 			BIGINT UNSIGNED NOT NULL
		,	Sum_No_Good_Index_Used 		BIGINT UNSIGNED NOT NULL
		,	Sum_CPU_Time 				BIGINT UNSIGNED NOT NULL
		,	PRIMARY KEY (Object_Type,Object_Schema, Object_Name)
	 ) ENGINE=InnoDB;

	INSERT IGNORE INTO Temp_Metrics(Object_Schema, Object_Name, Object_Type,
									Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
									Count_Statements, Sum_Statements_Wait, Min_Statements_Wait, Avg_Statements_Wait, Max_Statements_Wait,
									Sum_Lock_Time, Sum_Errors,Sum_Warnings, 
									Sum_Rows_Affected, Sum_Rows_Sent, Sum_Rows_Examined, 
									Sum_Created_Tmp_Disk_Tables, Sum_Created_Tmp_Tables,
									Sum_Select_Full_Join, Sum_Select_Full_Range_Join, Sum_Select_Range, Sum_Select_Range_Check, 
									Sum_Select_Scan, Sum_Sort_Merge_Passes, Sum_Sort_Range, Sum_Sort_Rows, Sum_Sort_Scan,
									Sum_No_Index_Used,Sum_No_Good_Index_Used,
									Sum_CPU_Time)
	SELECT	metric.Object_Schema 
		,	metric.Object_Name 
		,	metric.Object_Type 
		,	metric.Count_Star  
		,	metric.Sum_Timer_Wait  
		,	metric.Min_Timer_Wait  
		,	metric.Avg_Timer_Wait  
		,	metric.Max_Timer_Wait  
		,	metric.Count_Statements  
		,	metric.Sum_Statements_Wait  
		,	metric.Min_Statements_Wait  
		,	metric.Avg_Statements_Wait  
		,	metric.Max_Statements_Wait  
		,	metric.Sum_Lock_Time  
		,	metric.Sum_Errors  
		,	metric.Sum_Warnings  
		,	metric.Sum_Rows_Affected  
		,	metric.Sum_Rows_Sent  
		,	metric.Sum_Rows_Examined  
		,	metric.Sum_Created_Tmp_Disk_Tables  
		,	metric.Sum_Created_Tmp_Tables  
		,	metric.Sum_Select_Full_Join  
		,	metric.Sum_Select_Full_Range_Join  
		,	metric.Sum_Select_Range  
		,	metric.Sum_Select_Range_Check  
		,	metric.Sum_Select_Scan  
		,	metric.Sum_Sort_Merge_Passes  
		,	metric.Sum_Sort_Range  
		,	metric.Sum_Sort_Rows  
		,	metric.Sum_Sort_Scan  
		,	metric.Sum_No_Index_Used  
		,	metric.Sum_No_Good_Index_Used  
		,	metric.Sum_CPU_Time  
	FROM JSON_TABLE(ip_Metric,
		 "$[*]" COLUMNS(
					Object_Schema 				VARCHAR(64) 	PATH "$.Object_Schema" 
				,	Object_Name 				VARCHAR(64) 	PATH "$.Object_Name" 
				,	Object_Type 				VARCHAR(64) 	PATH "$.Object_Type" 
				,	Count_Star 					BIGINT UNSIGNED PATH "$.Count_Star" 
				,	Sum_Timer_Wait 				BIGINT UNSIGNED PATH "$.Sum_Timer_Wait" 
				,	Min_Timer_Wait 				BIGINT UNSIGNED PATH "$.Min_Timer_Wait" 
				,	Avg_Timer_Wait 				BIGINT UNSIGNED PATH "$.Avg_Timer_Wait" 
				,	Max_Timer_Wait				BIGINT UNSIGNED PATH "$.Max_Timer_Wait" 
				,	Count_Statements 			BIGINT UNSIGNED PATH "$.Count_Statements" 
				,	Sum_Statements_Wait 		BIGINT UNSIGNED PATH "$.Sum_Statements_Wait" 
				,	Min_Statements_Wait 		BIGINT UNSIGNED PATH "$.Min_Statements_Wait" 
				,	Avg_Statements_Wait 		BIGINT UNSIGNED PATH "$.Avg_Statements_Wait" 
				,	Max_Statements_Wait 		BIGINT UNSIGNED PATH "$.Max_Statements_Wait" 
				,	Sum_Lock_Time 				BIGINT UNSIGNED PATH "$.Sum_Lock_Time" 
				,	Sum_Errors 					BIGINT UNSIGNED PATH "$.Sum_Errors" 
				,	Sum_Warnings 				BIGINT UNSIGNED PATH "$.Sum_Warnings" 
				,	Sum_Rows_Affected 			BIGINT UNSIGNED PATH "$.Sum_Rows_Affected" 
				,	Sum_Rows_Sent 				BIGINT UNSIGNED PATH "$.Sum_Rows_Sent" 
				,	Sum_Rows_Examined 			BIGINT UNSIGNED PATH "$.Sum_Rows_Examined" 
				,	Sum_Created_Tmp_Disk_Tables BIGINT UNSIGNED PATH "$.Sum_Created_Tmp_Disk_Tables" 
				,	Sum_Created_Tmp_Tables 		BIGINT UNSIGNED PATH "$.Sum_Created_Tmp_Tables" 
				,	Sum_Select_Full_Join 		BIGINT UNSIGNED PATH "$.Sum_Select_Full_Join" 
				,	Sum_Select_Full_Range_Join 	BIGINT UNSIGNED PATH "$.Sum_Select_Full_Range_Join" 
				,	Sum_Select_Range 			BIGINT UNSIGNED PATH "$.Sum_Select_Range" 
				,	Sum_Select_Range_Check 		BIGINT UNSIGNED PATH "$.Sum_Select_Range_Check" 
				,	Sum_Select_Scan 			BIGINT UNSIGNED PATH "$.Sum_Select_Scan" 
				,	Sum_Sort_Merge_Passes 		BIGINT UNSIGNED PATH "$.Sum_Sort_Merge_Passes" 
				,	Sum_Sort_Range 				BIGINT UNSIGNED PATH "$.Sum_Sort_Range" 
				,	Sum_Sort_Rows 				BIGINT UNSIGNED PATH "$.Sum_Sort_Rows" 
				,	Sum_Sort_Scan 				BIGINT UNSIGNED PATH "$.Sum_Sort_Scan" 
				,	Sum_No_Index_Used 			BIGINT UNSIGNED PATH "$.Sum_No_Index_Used" 
				,	Sum_No_Good_Index_Used 		BIGINT UNSIGNED PATH "$.Sum_No_Good_Index_Used" 
				,	Sum_CPU_Time 				BIGINT UNSIGNED PATH "$.Sum_CPU_Time" 
			)
	) AS metric;
	   
	
    UPDATE Temp_Metrics AS tmp
		LEFT JOIN  MonDB.Monitor_CTSDataFlow AS flow ON tmp.Object_Name = flow.SPName
	SET tmp.GroupID =  IFNULL(flow.GroupID,0);
    
    IF ip_Server = 'master' THEN
		INSERT INTO MonDB.Monitor_SPMetric_Master58(Object_Schema, Object_Name, Object_Type,GroupID,
													 Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
													 Count_Statements, Sum_Statements_Wait, Min_Statements_Wait, Avg_Statements_Wait, Max_Statements_Wait,
													 Sum_Lock_Time, Sum_Errors,Sum_Warnings, 
													 Sum_Rows_Affected, Sum_Rows_Sent, Sum_Rows_Examined, 
													 Sum_Created_Tmp_Disk_Tables, Sum_Created_Tmp_Tables,
													 Sum_Select_Full_Join, Sum_Select_Full_Range_Join, Sum_Select_Range, Sum_Select_Range_Check, 
													 Sum_Select_Scan, Sum_Sort_Merge_Passes, Sum_Sort_Range, Sum_Sort_Rows, Sum_Sort_Scan,
													 Sum_No_Index_Used,Sum_No_Good_Index_Used,
													 Sum_CPU_Time,
                                                     Created)
		SELECT	metric.Object_Schema 
			,	metric.Object_Name 
			,	metric.Object_Type 
            ,	metric.GroupID 
			,	metric.Count_Star  
			,	metric.Sum_Timer_Wait  
			,	metric.Min_Timer_Wait  
			,	metric.Avg_Timer_Wait  
			,	metric.Max_Timer_Wait  
			,	metric.Count_Statements  
			,	metric.Sum_Statements_Wait  
			,	metric.Min_Statements_Wait  
			,	metric.Avg_Statements_Wait  
			,	metric.Max_Statements_Wait  
			,	metric.Sum_Lock_Time  
			,	metric.Sum_Errors  
			,	metric.Sum_Warnings  
			,	metric.Sum_Rows_Affected  
			,	metric.Sum_Rows_Sent  
			,	metric.Sum_Rows_Examined  
			,	metric.Sum_Created_Tmp_Disk_Tables  
			,	metric.Sum_Created_Tmp_Tables  
			,	metric.Sum_Select_Full_Join  
			,	metric.Sum_Select_Full_Range_Join  
			,	metric.Sum_Select_Range  
			,	metric.Sum_Select_Range_Check  
			,	metric.Sum_Select_Scan  
			,	metric.Sum_Sort_Merge_Passes  
			,	metric.Sum_Sort_Range  
			,	metric.Sum_Sort_Rows  
			,	metric.Sum_Sort_Scan  
			,	metric.Sum_No_Index_Used  
			,	metric.Sum_No_Good_Index_Used  
			,	metric.Sum_CPU_Time  
            , 	CURRENT_TIMESTAMP()
		FROM Temp_Metrics AS metric;
    END IF;
    
    IF ip_Server = 'replica' THEN
		INSERT IGNORE INTO MonDB.Monitor_SPMetric_Replica185(Object_Schema, Object_Name, Object_Type,GroupID,
															 Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
														     Count_Statements, Sum_Statements_Wait, Min_Statements_Wait, Avg_Statements_Wait, Max_Statements_Wait,
														     Sum_Lock_Time, Sum_Errors,Sum_Warnings, 
														     Sum_Rows_Affected, Sum_Rows_Sent, Sum_Rows_Examined, 
														     Sum_Created_Tmp_Disk_Tables, Sum_Created_Tmp_Tables,
														     Sum_Select_Full_Join, Sum_Select_Full_Range_Join, Sum_Select_Range, Sum_Select_Range_Check, 
														     Sum_Select_Scan, Sum_Sort_Merge_Passes, Sum_Sort_Range, Sum_Sort_Rows, Sum_Sort_Scan,
														     Sum_No_Index_Used,Sum_No_Good_Index_Used,
														     Sum_CPU_Time,
														     Created)
		SELECT	metric.Object_Schema 
			,	metric.Object_Name 
			,	metric.Object_Type 
            ,	metric.GroupID 
			,	metric.Count_Star  
			,	metric.Sum_Timer_Wait  
			,	metric.Min_Timer_Wait  
			,	metric.Avg_Timer_Wait  
			,	metric.Max_Timer_Wait  
			,	metric.Count_Statements  
			,	metric.Sum_Statements_Wait  
			,	metric.Min_Statements_Wait  
			,	metric.Avg_Statements_Wait  
			,	metric.Max_Statements_Wait  
			,	metric.Sum_Lock_Time  
			,	metric.Sum_Errors  
			,	metric.Sum_Warnings  
			,	metric.Sum_Rows_Affected  
			,	metric.Sum_Rows_Sent  
			,	metric.Sum_Rows_Examined  
			,	metric.Sum_Created_Tmp_Disk_Tables  
			,	metric.Sum_Created_Tmp_Tables  
			,	metric.Sum_Select_Full_Join  
			,	metric.Sum_Select_Full_Range_Join  
			,	metric.Sum_Select_Range  
			,	metric.Sum_Select_Range_Check  
			,	metric.Sum_Select_Scan  
			,	metric.Sum_Sort_Merge_Passes  
			,	metric.Sum_Sort_Range  
			,	metric.Sum_Sort_Rows  
			,	metric.Sum_Sort_Scan  
			,	metric.Sum_No_Index_Used  
			,	metric.Sum_No_Good_Index_Used  
			,	metric.Sum_CPU_Time  
            , 	CURRENT_TIMESTAMP()
		FROM Temp_Metrics AS metric;
    END IF;
    
    IF ip_Server = 'archive' THEN
		INSERT IGNORE INTO MonDB.Monitor_SPMetric_Archive59(Object_Schema, Object_Name, Object_Type,GroupID, 
															Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
															Count_Statements, Sum_Statements_Wait, Min_Statements_Wait, Avg_Statements_Wait, Max_Statements_Wait,
															Sum_Lock_Time, Sum_Errors,Sum_Warnings, 
															Sum_Rows_Affected, Sum_Rows_Sent, Sum_Rows_Examined, 
															Sum_Created_Tmp_Disk_Tables, Sum_Created_Tmp_Tables,
															Sum_Select_Full_Join, Sum_Select_Full_Range_Join, Sum_Select_Range, Sum_Select_Range_Check, 
															Sum_Select_Scan, Sum_Sort_Merge_Passes, Sum_Sort_Range, Sum_Sort_Rows, Sum_Sort_Scan,
															Sum_No_Index_Used,Sum_No_Good_Index_Used,
															Sum_CPU_Time,
															Created)
		SELECT	metric.Object_Schema 
			,	metric.Object_Name 
			,	metric.Object_Type 
            ,	metric.GroupID 
			,	metric.Count_Star  
			,	metric.Sum_Timer_Wait  
			,	metric.Min_Timer_Wait  
			,	metric.Avg_Timer_Wait  
			,	metric.Max_Timer_Wait  
			,	metric.Count_Statements  
			,	metric.Sum_Statements_Wait  
			,	metric.Min_Statements_Wait  
			,	metric.Avg_Statements_Wait  
			,	metric.Max_Statements_Wait  
			,	metric.Sum_Lock_Time  
			,	metric.Sum_Errors  
			,	metric.Sum_Warnings  
			,	metric.Sum_Rows_Affected  
			,	metric.Sum_Rows_Sent  
			,	metric.Sum_Rows_Examined  
			,	metric.Sum_Created_Tmp_Disk_Tables  
			,	metric.Sum_Created_Tmp_Tables  
			,	metric.Sum_Select_Full_Join  
			,	metric.Sum_Select_Full_Range_Join  
			,	metric.Sum_Select_Range  
			,	metric.Sum_Select_Range_Check  
			,	metric.Sum_Select_Scan  
			,	metric.Sum_Sort_Merge_Passes  
			,	metric.Sum_Sort_Range  
			,	metric.Sum_Sort_Rows  
			,	metric.Sum_Sort_Scan  
			,	metric.Sum_No_Index_Used  
			,	metric.Sum_No_Good_Index_Used  
			,	metric.Sum_CPU_Time  
            , 	CURRENT_TIMESTAMP()
		FROM Temp_Metrics AS metric;
    END IF;
END$$
DELIMITER ;
