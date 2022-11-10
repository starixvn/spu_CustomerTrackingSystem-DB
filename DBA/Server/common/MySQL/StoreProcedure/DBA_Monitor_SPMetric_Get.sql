/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_SPMetric_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_SPMetric_Get`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210127@Aries.Nguyen
		Task:		Grafana Monitor SP Metric 
		DB:			MonDB
		Original:
 
		Revisions:
			- 20210127@Aries.Nguyen: Created [Redmine ID: #149662]
            
		Param's Explanation (filtered by):
        Example:
			- CALL MonDB.DBA_Monitor_SPMetric_Get();
	*/	
	SELECT	JSON_ARRAYAGG(JSON_OBJECT(
			'Object_Schema', metric.Object_Schema 
		,	'Object_Name', metric.Object_Name 
		,	'Object_Type', metric.Object_Type 
		,	'Count_Star', metric.Count_Star  
		,	'Sum_Timer_Wait', metric.Sum_Timer_Wait  
		,	'Min_Timer_Wait', metric.Min_Timer_Wait  
		,	'Avg_Timer_Wait', metric.Avg_Timer_Wait  
		,	'Max_Timer_Wait', metric.Max_Timer_Wait  
		,	'Count_Statements', metric.Count_Statements  
		,	'Sum_Statements_Wait', metric.Sum_Statements_Wait  
		,	'Min_Statements_Wait', metric.Min_Statements_Wait  
		,	'Avg_Statements_Wait', metric.Avg_Statements_Wait  
		,	'Max_Statements_Wait', metric.Max_Statements_Wait  
		,	'Sum_Lock_Time', metric.Sum_Lock_Time  
		,	'Sum_Errors', metric.Sum_Errors  
		,	'Sum_Warnings', metric.Sum_Warnings  
		,	'Sum_Rows_Affected', metric.Sum_Rows_Affected  
		,	'Sum_Rows_Sent', metric.Sum_Rows_Sent  
		,	'Sum_Rows_Examined', metric.Sum_Rows_Examined  
		,	'Sum_Created_Tmp_Disk_Tables', metric.Sum_Created_Tmp_Disk_Tables  
		,	'Sum_Created_Tmp_Tables', metric.Sum_Created_Tmp_Tables  
		,	'Sum_Select_Full_Join', metric.Sum_Select_Full_Join  
		,	'Sum_Select_Full_Range_Join', metric.Sum_Select_Full_Range_Join  
		,	'Sum_Select_Range', metric.Sum_Select_Range  
		,	'Sum_Select_Range_Check', metric.Sum_Select_Range_Check  
		,	'Sum_Select_Scan', metric.Sum_Select_Scan  
		,	'Sum_Sort_Merge_Passes', metric.Sum_Sort_Merge_Passes  
		,	'Sum_Sort_Range', metric.Sum_Sort_Range  
		,	'Sum_Sort_Rows', metric.Sum_Sort_Rows  
		,	'Sum_Sort_Scan', metric.Sum_Sort_Scan  
		,	'Sum_No_Index_Used', metric.Sum_No_Index_Used  
		,	'Sum_No_Good_Index_Used', metric.Sum_No_Good_Index_Used  
		,	'Sum_CPU_Time', 0 )) AS Metrics
	FROM  	performance_schema.events_statements_summary_by_program AS metric;

	TRUNCATE TABLE  performance_schema.events_statements_summary_by_program;
END$$
DELIMITER ;
