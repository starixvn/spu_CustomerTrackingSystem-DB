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
    DECLARE lv_MessageAlert 				LONGTEXT;
    DECLARE lv_LastDate_Master 				DATETIME;
    DECLARE lv_LastDate_Replica 			DATETIME;
    DECLARE lv_LastDate_Archive				DATETIME;
    DECLARE lv_BeforeLastDate_Master 		DATETIME;
    DECLARE lv_BeforeLastDate_Replica 		DATETIME;
    DECLARE lv_BeforeLastDate_Archive 		DATETIME;
    DECLARE lv_Server 						VARCHAR(20);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Table;
	CREATE TEMPORARY TABLE Temp_Table (
			DB 			VARCHAR(64) NOT NULL
	    ,	TableName 	VARCHAR(64) NOT NULL
        ,	ServerName 	VARCHAR(20)
		,	Count_Read 	BIGINT UNSIGNED
        ,	Created		DATETIME
        ,	PRIMARY KEY (DB,TableName)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_PreTable;
	CREATE TEMPORARY TABLE Temp_PreTable (
			DB 			VARCHAR(64) NOT NULL
	    ,	TableName 	VARCHAR(64) NOT NULL
        ,	ServerName 	VARCHAR(20)
        ,	PRIMARY KEY (DB,TableName)
    );
    
    SELECT MAX(Created)
    INTO lv_LastDate_Master
    FROM MonDB.Monitor_TableMetric_Master58;
    
    SELECT MAX(Created)
    INTO lv_LastDate_Replica
    FROM MonDB.Monitor_TableMetric_Replica185;
    
    SELECT MAX(Created)
    INTO lv_LastDate_Archive
    FROM MonDB.Monitor_TableMetric_Archive59;
    
    IF lv_LastDate_Master < DATE_SUB(NOW(), INTERVAL 45 MINUTE) THEN
		SELECT NULL AS MessageAlert;
        LEAVE sp;
    END IF; 
	
    /*************************Master**************************/
    INSERT IGNORE INTO Temp_Table(DB,TableName,ServerName,Count_Read,Created)
	SELECT 	Object_Schema
		,	Object_Name
        ,	'Master(58)' AS ServerName
        ,	Count_Read
        ,	Created
    FROM MonDB.Monitor_TableMetric_Master58 
	WHERE Created = lv_LastDate_Master
		AND Count_Read >= 10000000;
	
    DELETE 
    FROM Temp_Table
    WHERE TIME(Created) >= '05:00:00'
		AND TIME(Created) <= '06:00:00'
        AND TableName = 'CTSCustomerClassification';
    
    SET lv_BeforeLastDate_Master = DATE_SUB(lv_LastDate_Master, INTERVAL 45 MINUTE);
    INSERT IGNORE INTO Temp_PreTable(DB,TableName,ServerName)
	SELECT 	Object_Schema
		,	Object_Name
        ,	'Master(58)' AS ServerName
    FROM MonDB.Monitor_TableMetric_Master58 
	WHERE Created > lv_BeforeLastDate_Master 
		AND Created < lv_LastDate_Master
		AND Count_Read >= 10000000;
    
    DELETE tbl
    FROM Temp_Table AS tbl
    WHERE EXISTS (SELECT 1 FROM Temp_PreTable AS pre WHERE pre.DB = tbl.DB AND pre.TableName = tbl.TableName AND pre.ServerName = 'Master(58)');
    
    
    /*************************Replica**************************/
    INSERT IGNORE INTO Temp_Table(DB,TableName,ServerName,Count_Read,Created)
	SELECT 	Object_Schema
		,	Object_Name
        ,	'Replica(58)' AS ServerName
        ,	Count_Read
        ,	Created
    FROM MonDB.Monitor_TableMetric_Replica185 
	WHERE Created = lv_LastDate_Replica
		AND Count_Read >= 10000000
        AND Object_Name NOT IN ('CTSCustomer', 'AssociationByDevice','CTSCustomerClassification');
     
	SET lv_BeforeLastDate_Replica = DATE_SUB(lv_LastDate_Replica, INTERVAL 45 MINUTE);
    INSERT IGNORE INTO Temp_PreTable(DB,TableName,ServerName)
	SELECT 	Object_Schema
		,	Object_Name
        ,	'Replica(58)' AS ServerName
    FROM MonDB.Monitor_TableMetric_Replica185 
	WHERE Created > lv_BeforeLastDate_Replica 
		AND Created < lv_LastDate_Replica
        AND Object_Name NOT IN ('CTSCustomer', 'AssociationByDevice','CTSCustomerClassification')
		AND Count_Read >= 10000000;
	
    DELETE tbl
    FROM Temp_Table AS tbl
    WHERE EXISTS (SELECT 1 FROM Temp_PreTable AS pre WHERE pre.DB = tbl.DB AND pre.TableName = tbl.TableName AND pre.ServerName = 'Replica(58)');
	
    /*************************Archive**************************/
    INSERT IGNORE INTO Temp_Table(DB,TableName,ServerName,Count_Read,Created)
	SELECT 	Object_Schema
		,	Object_Name
        ,	'Archive(59)' AS ServerName
        ,	Count_Read
        ,	Created
    FROM MonDB.Monitor_TableMetric_Archive59 
	WHERE Created = lv_LastDate_Archive
		AND Count_Read >= 10000000
        AND Object_Schema NOT IN ('MonDB');
     
	SET lv_BeforeLastDate_Archive = DATE_SUB(lv_LastDate_Archive, INTERVAL 45 MINUTE);
    INSERT IGNORE INTO Temp_PreTable(DB,TableName,ServerName)
	SELECT 	Object_Schema
		,	Object_Name
        ,	'Archive(59)' AS ServerName
    FROM MonDB.Monitor_TableMetric_Archive59 
	WHERE Created > lv_BeforeLastDate_Archive
		AND Created < lv_LastDate_Archive
        AND Object_Schema NOT IN ('MonDB')
		AND Count_Read >= 10000000;
	
    DELETE tbl
    FROM Temp_Table AS tbl
    WHERE EXISTS (SELECT 1 FROM Temp_PreTable AS pre WHERE pre.DB = tbl.DB AND pre.TableName = tbl.TableName AND pre.ServerName = 'Archive(59)');
    
    /*******************************************************/
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
