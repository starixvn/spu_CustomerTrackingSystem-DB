/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_IndexMetric_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_IndexMetric_Get`()
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
			- CALL MonDB.DBA_Monitor_IndexMetric_Get();
	*/
	SELECT	JSON_ARRAYAGG(JSON_OBJECT(
			'Object_Type', Object_Type
		,	'Object_Schema', Object_Schema 
		,	'Object_Name', Object_Name 
        ,	'Index_Name', Index_Name 
		,	'Count_Star', Count_Star  
		,	'Sum_Timer_Wait', Sum_Timer_Wait  
		,	'Min_Timer_Wait', Min_Timer_Wait  
		,	'Avg_Timer_Wait', Avg_Timer_Wait  
		,	'Max_Timer_Wait', Max_Timer_Wait  
		,	'Count_Read', Count_Read  
		,	'Sum_Timer_Read', Sum_Timer_Read  
		,	'Sum_Timer_Read', Min_Timer_Read  
		,	'Avg_Timer_Read', Avg_Timer_Read  
		,	'Max_Timer_Read', Max_Timer_Read  
		,	'Count_Write', Count_Write  
		,	'Sum_Timer_Write', Sum_Timer_Write  
		,	'Min_Timer_Write', Min_Timer_Write  
		,	'Avg_Timer_Write', Avg_Timer_Write  
		,	'Max_Timer_Write', Max_Timer_Write  
		,	'Count_Fetch', Count_Fetch  
		,	'Sum_Timer_Fetch', Sum_Timer_Fetch  
		,	'Min_Timer_Fetch', Min_Timer_Fetch  
		,	'Avg_Timer_Fetch', Avg_Timer_Fetch  
		,	'Max_Timer_Fetch', Max_Timer_Fetch  
		,	'Count_Insert', Count_Insert  
		,	'Sum_Timer_Insert', Sum_Timer_Insert  
		,	'Min_Timer_Insert', Min_Timer_Insert  
		,	'Avg_Timer_Insert', Avg_Timer_Insert  
		,	'Max_Timer_Insert', Max_Timer_Insert  
		,	'Count_Update', Count_Update  
		,	'Sum_Timer_Update', Sum_Timer_Update  
		,	'Min_Timer_Update', Min_Timer_Update  
		,	'Avg_Timer_Update', Avg_Timer_Update  
		,	'Max_Timer_Update', Max_Timer_Update  
		,	'Count_Delete', Count_Delete  
		,	'Sum_Timer_Delete', Sum_Timer_Delete  
		,	'Min_Timer_Delete', Min_Timer_Delete  
		,	'Avg_Timer_Delete', Avg_Timer_Delete  
		,	'Max_Timer_Delete', Max_Timer_Delete )) AS Metrics 
	FROM performance_schema.table_io_waits_summary_by_index_usage
	WHERE OBJECT_SCHEMA NOT IN ('performance_schema','mysql');

	TRUNCATE TABLE  performance_schema.table_io_waits_summary_by_index_usage;
END$$
DELIMITER ;
