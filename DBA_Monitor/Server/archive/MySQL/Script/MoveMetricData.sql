INSERT IGNORE INTO    MonDB.Monitor_SPMetric_Master(Object_Schema,Object_Name, Object_Type,GroupID, 
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
SELECT	metric.`Database` AS Object_Schema 
	,	metric.`Name` AS Object_Name 
	,	metric.`Type` AS Object_Type 
    ,	metric.GroupID 
	,	metric.Count_Star  
	,	0 AS Sum_Timer_Wait  
	,	metric.Min_Timer_Wait  
	,	metric.Avg_Timer_Wait  
	,	metric.Max_Timer_Wait  
	,	0 AS Count_Statements  
	,	0 AS Sum_Statements_Wait  
	,	0 AS Min_Statements_Wait  
	,	0 AS Avg_Statements_Wait  
	,	0 AS Max_Statements_Wait  
	,	metric.Sum_Lock_Time  
	,	metric.Sum_Errors  
	,	metric.Sum_Warnings  
	,	metric.Sum_Rows_Affected  
	,	metric.Sum_Rows_Sent  
	,	0 AS Sum_Rows_Examined  
	,	0 AS Sum_Created_Tmp_Disk_Tables  
	,	0 AS Sum_Created_Tmp_Tables  
	,	0 AS Sum_Select_Full_Join  
	,	0 AS Sum_Select_Full_Range_Join  
	,	0 AS Sum_Select_Range  
	,	0 AS Sum_Select_Range_Check  
	,	0 AS Sum_Select_Scan  
	,	0 AS Sum_Sort_Merge_Passes  
	,	0 AS Sum_Sort_Range  
	,	0 AS Sum_Sort_Rows  
	,	0 AS Sum_Sort_Scan  
	,	0 AS Sum_No_Index_Used  
	,	0 AS Sum_No_Good_Index_Used  
	,	0 AS Sum_CPU_Time  
	, 	metric.Created
FROM MonDB.DBA_SPMonitor_Replica185 AS metric
WHERE RowID BETWEEN 1 AND 1000000;

INSERT IGNORE INTO MonDB.Monitor_TableMetric_Master58(Created, Object_Type, Object_Schema, Object_Name,
													  Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
													  Count_Read, Sum_Timer_Read, Min_Timer_Read, Avg_Timer_Read, Max_Timer_Read,
													  Count_Write, Sum_Timer_Write, Min_Timer_Write, Avg_Timer_Write, Max_Timer_Write,
													  Count_Fetch, Sum_Timer_Fetch, Min_Timer_Fetch, Avg_Timer_Fetch, Max_Timer_Fetch,
													  Count_Insert, Sum_Timer_Insert, Min_Timer_Insert, Avg_Timer_Insert, Max_Timer_Insert,
													  Count_Update, Sum_Timer_Update, Min_Timer_Update, Avg_Timer_Update, Max_Timer_Update,
													  Count_Delete, Sum_Timer_Delete, Min_Timer_Delete, Avg_Timer_Delete, Max_Timer_Delete)
SELECT	Created
	,	Oblect_Type AS Object_Type
	,	`Database` AS Object_Schema 
	,	`TableName` AS Object_Name 
	,	Count_Star  
	,	0 AS Sum_Timer_Wait  
	,	0 AS Min_Timer_Wait  
	,	0 AS Avg_Timer_Wait  
	,	0 AS Max_Timer_Wait  
	,	Count_Read  
	,	0 AS Sum_Timer_Read  
	,	0 AS Min_Timer_Read  
	,	0 AS Avg_Timer_Read  
	,	0 AS Max_Timer_Read  
	,	Count_Write  
	,	0 AS Sum_Timer_Write  
	,	0 AS Min_Timer_Write  
	,	0 AS Avg_Timer_Write  
	,	0 AS Max_Timer_Write  
	,	Count_Fetch  
	,	0 AS Sum_Timer_Fetch  
	,	0 AS Min_Timer_Fetch  
	,	0 AS Avg_Timer_Fetch  
	,	0 AS Max_Timer_Fetch  
	,	Count_Insert  
	,	0 AS Sum_Timer_Insert  
	,	0 AS Min_Timer_Insert  
	,	0 AS Avg_Timer_Insert  
	,	0 AS Max_Timer_Insert  
	,	Count_Update  
	,	0 AS Sum_Timer_Update  
	,	0 AS Min_Timer_Update  
	,	0 AS Avg_Timer_Update  
	,	0 AS Max_Timer_Update  
	,	Count_Delete  
	,	0 AS Sum_Timer_Delete  
	,	0 AS Min_Timer_Delete  
	,	0 AS Avg_Timer_Delete  
	,	0 AS Max_Timer_Delete  
FROM MonDB.DBA_Table_IO_Monitor
WHERE RowID BETWEEN 1 AND 100000;

INSERT IGNORE INTO MonDB.Monitor_IndexMetric_Master58(Created,Object_Type, Object_Schema, Object_Name, Index_Name,
															  Count_Star, Sum_Timer_Wait, Min_Timer_Wait, Avg_Timer_Wait, Max_Timer_Wait,
															  Count_Read, Sum_Timer_Read, Min_Timer_Read, Avg_Timer_Read, Max_Timer_Read,
															  Count_Write, Sum_Timer_Write, Min_Timer_Write, Avg_Timer_Write, Max_Timer_Write,
															  Count_Fetch, Sum_Timer_Fetch, Min_Timer_Fetch, Avg_Timer_Fetch, Max_Timer_Fetch,
															  Count_Insert, Sum_Timer_Insert, Min_Timer_Insert, Avg_Timer_Insert, Max_Timer_Insert,
															  Count_Update, Sum_Timer_Update, Min_Timer_Update, Avg_Timer_Update, Max_Timer_Update,
															  Count_Delete, Sum_Timer_Delete, Min_Timer_Delete, Avg_Timer_Delete, Max_Timer_Delete)
SELECT	Created
	,	Oblect_Type AS Object_Type
	,	`Database` AS Object_Schema 
	,	`TableName` AS Object_Name 
    ,	`IndexName` AS Index_Name 
	,	Count_Star  
	,	0 AS Sum_Timer_Wait  
	,	0 AS Min_Timer_Wait  
	,	0 AS Avg_Timer_Wait  
	,	0 AS Max_Timer_Wait  
	,	Count_Read  
	,	0 AS Sum_Timer_Read  
	,	0 AS Min_Timer_Read  
	,	0 AS Avg_Timer_Read  
	,	0 AS Max_Timer_Read  
	,	Count_Write  
	,	0 AS Sum_Timer_Write  
	,	0 AS Min_Timer_Write  
	,	0 AS Avg_Timer_Write  
	,	0 AS Max_Timer_Write  
	,	Count_Fetch  
	,	0 AS Sum_Timer_Fetch  
	,	0 AS Min_Timer_Fetch  
	,	0 AS Avg_Timer_Fetch  
	,	0 AS Max_Timer_Fetch  
	,	Count_Insert  
	,	0 AS Sum_Timer_Insert  
	,	0 AS Min_Timer_Insert  
	,	0 AS Avg_Timer_Insert  
	,	0 AS Max_Timer_Insert  
	,	Count_Update  
	,	0 AS Sum_Timer_Update  
	,	0 AS Min_Timer_Update  
	,	0 AS Avg_Timer_Update  
	,	0 AS Max_Timer_Update  
	,	Count_Delete  
	,	0 AS Sum_Timer_Delete  
	,	0 AS Min_Timer_Delete  
	,	0 AS Avg_Timer_Delete  
	,	0 AS Max_Timer_Delete  
FROM MonDB.DBA_Index_IO_Monitor
WHERE RowID BETWEEN 1 AND 100000;