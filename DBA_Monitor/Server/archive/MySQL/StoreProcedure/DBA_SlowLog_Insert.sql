/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_SlowLog_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_SlowLog_Insert`(
		IN ip_Logs		JSON
    ,	IN ip_ServerID 	INT UNSIGNED
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
            
		Param's Explanation (filtered by):
			- ip_RunType: Manual or Job
        Example:
			- CALL MonDB.DBA_ReOrganizeArchive_Config_Get();
	*/
    INSERT IGNORE INTO MonDB.SlowLog(ServerID,Start_Time,User_Host,Query_Time,Lock_Time,Rows_Sent,Rows_Examined,DB,Last_Insert_ID,Insert_ID,Server_ID,Sql_Text,Thread_ID)
	SELECT 	ip_ServerID AS ServerID
		, 	Start_Time 		
		, 	User_Host		
		,	Query_Time 		
		,	Lock_Time 		
		,	Rows_Sent 	
		,	Rows_Examined 	
		,	DB 			
		,	Last_Insert_ID 
		,	Insert_ID 	
		,	Server_ID 
		,	Sql_Text 
		,	Thread_ID
	FROM JSON_TABLE(ip_Logs,
		 "$[*]" COLUMNS(
				Start_Time 		TIMESTAMP(6)		PATH "$.Start_Time"
			, 	User_Host		MEDIUMTEXT			PATH "$.User_Host"
            ,	Query_Time 		TIME(6) 			PATH "$.Query_Time"
            ,	Lock_Time 		TIME(6)  			PATH "$.Lock_Time"
			,	Rows_Sent 		INT  				PATH "$.Rows_Sent"
			,	Rows_Examined 	INT  				PATH "$.Rows_Examined"
			,	DB 				VARCHAR(512)  		PATH "$.DB"
			,	Last_Insert_ID 	INT  				PATH "$.Last_Insert_ID"
			,	Insert_ID 		INT  				PATH "$.Insert_ID"
			,	Server_ID 		INT UNSIGNED  		PATH "$.Server_ID"
			,	Sql_Text 		LONGTEXT  			PATH "$.Sql_Text"
			,	Thread_ID 		BIGINT UNSIGNED  	PATH "$.Thread_ID"
		 )) AS tmp;  
END$$
DELIMITER ;
