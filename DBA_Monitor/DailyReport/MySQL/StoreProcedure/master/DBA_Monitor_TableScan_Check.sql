/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_TableScan_Check`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_TableScan_Check`()
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
			- CALL MonDB.DBA_Monitor_TableScan_Check(); 
	*/
    DECLARE lv_MessageAlert 	LONGTEXT;
    DECLARE lv_LastDate 		DATETIME;
    DECLARE lv_Server 			VARCHAR(20);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Table;
	CREATE TEMPORARY TABLE Temp_Table (
			DB 			VARCHAR(64) NOT NULL
	    ,	TableName 	VARCHAR(64) NOT NULL
		,	Count_Read 	BIGINT UNSIGNED
        ,	Created		DATETIME
        ,	PRIMARY KEY (DB,TableName)
    );
    
    SELECT Created
    INTO lv_LastDate
    FROM MonDB.DBA_Table_IO_Monitor 
    ORDER BY RowID DESC 
    LIMIT 1;
    
    IF lv_LastDate < DATE_SUB(NOW(), INTERVAL 45 MINUTE) THEN
		SELECT NULL AS MessageAlert;
        LEAVE sp;
    END IF;
	
    INSERT IGNORE INTO Temp_Table(DB,TableName,Count_Read,Created)
	SELECT `Database` 
		,	TableName
        ,	Count_Read
        ,	Created
    FROM MonDB.DBA_Table_IO_Monitor 
	WHERE Created = lv_LastDate
		AND Count_Read >= 10000000;
        
	IF @@hostname like '%master%' THEN
		SET lv_Server = 'Master(58)';
    ELSE 
		SET lv_Server = 'Replica(185)';
	END IF;
    
    IF NOT EXISTS (SELECT 1 FROM Temp_Table) THEN
        SELECT NULL AS MessageAlert;
		LEAVE sp; 
    END IF;
    
     SELECT CONCAT("<b>[Alerting] CTS Table Scan</b> \\n",
				  "Server: ",lv_Server, "\\n",
				  "Database: ",qu.DB, " \\n",
				  "Table Name: ",qu.TableName, " \\n",
				  "Row Read: ",FORMAT(qu.Count_Read,0), " \\n",
				  "Date: ",DATE_ADD(qu.Created, INTERVAL 11 HOUR)," \\n"
				) AS MessageAlert
    FROM Temp_Table AS qu;
    
END$$
DELIMITER ;
