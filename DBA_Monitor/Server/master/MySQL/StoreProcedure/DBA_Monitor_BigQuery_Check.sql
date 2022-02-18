/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_BigQuery_Check`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_BigQuery_Check`()
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
			- CALL MonDB.DBA_Monitor_BigQuery_Check(); 
	*/
    DECLARE lv_MessageAlert 	LONGTEXT;
    DECLARE lv_Server 			VARCHAR(20);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Query;
	CREATE TEMPORARY TABLE Temp_Query (
			ID				BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
		,	TRX_ID 			BIGINT UNSIGNED 
		,	ThreadID 		BIGINT UNSIGNED
		,	Latency 		VARCHAR(20)
        ,	TableLocked 	BIGINT UNSIGNED
        ,	RowLocked 		BIGINT UNSIGNED
        ,	RowModified 	BIGINT UNSIGNED
        ,	SPName			VARCHAR(100)
        ,	QueryText		TEXT
		,	TranState 		VARCHAR(20) 
        ,	ThreadState		VARCHAR(100) 
        ,	UserExec 		VARCHAR(32)
        ,	HostExec 		VARCHAR(255)
    );
    
    IF @@hostname like '%master%' THEN
		SET lv_Server = 'Master(58)';
    ELSE 
		SET lv_Server = 'Replica(185)';
	END IF;
    
    INSERT INTO Temp_Query(TRX_ID,ThreadID, Latency, TableLocked, RowLocked, RowModified, SPName, QueryText, TranState, ThreadState, UserExec, HostExec)
    SELECT  trx.trx_id
		,	trx.trx_mysql_thread_id AS 'ThreadID'
		,	FORMAT_PICO_TIME(TIMESTAMPDIFF(SECOND, trx.trx_started, NOW())*1000000000000) AS 'Latency'
		,	trx.trx_tables_locked AS 'TableLocked'
		,	trx.trx_rows_locked AS 'RowLocked'
		,	trx.trx_rows_modified AS 'RowModified'
		,	(SELECT sta.SQL_TEXT FROM performance_schema.events_statements_current AS sta WHERE sta.THREAD_ID = thd.THREAD_ID AND EVENT_NAME = 'statement/sql/call_procedure') AS SPName
		,	CASE	WHEN trx.trx_query IS NOT NULL  THEN trx.trx_query ELSE thd.PROCESSLIST_INFO END AS 'QueryText' 
		,	trx.trx_state AS 'TranState'
		,	thd.PROCESSLIST_STATE AS 'ThreadState'
		,	thd.PROCESSLIST_USER AS 'UserExec'
		,   thd.PROCESSLIST_HOST AS 'HostExec'
	FROM  INFORMATION_SCHEMA.INNODB_TRX AS trx 
		LEFT JOIN performance_schema.threads AS thd ON trx.trx_mysql_thread_id =  thd.PROCESSLIST_ID
	WHERE TIMESTAMPDIFF(SECOND, trx.trx_started , NOW()) >= 300;
    
    DELETE 
    FROM Temp_Query
    WHERE QueryText IS NULL;
    
    IF NOT EXISTS (SELECT 1 FROM Temp_Query) THEN
		DELETE 
        FROM MonDB.BigQuery_Check;
        SELECT NULL AS MessageAlert;
		LEAVE sp;
    END IF;
    
    DELETE 
    FROM Temp_Query AS qu 
    WHERE qu.TRX_ID IN (SELECT ck.TRX_ID FROM MonDB.BigQuery_Check AS ck);
    
    IF NOT EXISTS (SELECT 1 FROM Temp_Query) THEN
		SELECT NULL AS MessageAlert;
		LEAVE sp;
    END IF; 
    
    INSERT IGNORE INTO MonDB.BigQuery_Check(TRX_ID)
    SELECT TRX_ID
	FROM Temp_Query;
    
    SELECT CONCAT("<b>[Alerting] CTS Big Query</b>\\n",
				  "Server: ",lv_Server, "\\n",
				  "Latency: ",qu.Latency, "\\n",
				  "Table Locked: ",qu.TableLocked, "\\n",
				  "Row Locked: ",qu.RowLocked, "\\n",
				  "Row Modified: ",qu.RowModified,"\\n",
				  "User: ", qu.UserExec, "\\n",
                  "Host: ", qu.HostExec, "\\n",
                  "SPName: ", qu.SPName, "\\n"
                  "QueryText: ", qu.QueryText
				) AS MessageAlert
    FROM Temp_Query AS qu;
    
END$$
DELIMITER ;
