/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_DataGrowth_Metric`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_DataGrowth_Metric`()
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
			- CALL MonDB.DBA_Monitor_DataGrowth_Metric(); 
	*/
    DECLARE lv_FromDate 		DATETIME;
    DECLARE lv_ToDate 			DATETIME;
    DECLARE lv_FromDate_Compare DATETIME;
    DECLARE lv_ToDate_Compare 	DATETIME;
    
    DECLARE lv_TotalInsert 			INT;
    DECLARE lv_TotalInsert_Compare	INT;
    DECLARE lv_TotalUpdate			INT;
    DECLARE lv_TotalUpdate_Compare	INT;
    DECLARE lv_TotalDelete 			INT;
    DECLARE lv_TotalDelete_Compare	INT;
    DECLARE lv_TotalTable 			INT;
	DECLARE lv_ListTable 		 	LONGTEXT;
    DECLARE lv_IsMore 				BIT DEFAULT 0;
    DECLARE lv_DeleteRow 			INT;
    DECLARE lv_MessageMetric		LONGTEXT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LargeTable;
	CREATE TEMPORARY TABLE Temp_LargeTable (
			DBName 		VARCHAR(20) 
		,	TableName 	VARCHAR(100) 
        ,	PRIMARY KEY(TableName, DBName)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LargeTable_Result;
	CREATE TEMPORARY TABLE Temp_LargeTable_Result (
			DBName 				VARCHAR(20) 
		,	TableName 			VARCHAR(100) 
        ,	Count_DataChanged 	INT
        ,	PRIMARY KEY(TableName, DBName)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LargeTable_Count;
	CREATE TEMPORARY TABLE Temp_LargeTable_Count (
			DBName 					VARCHAR(20) 
		,	TableName 				VARCHAR(100) 
        ,	Count_Insert 			INT
        ,	Count_Insert_Growth 	INT
        ,	Count_Update 			INT
        ,	Count_Update_Growth 	INT
        ,	Count_Delete 			INT
        ,	Count_Delete_Growth 	INT
        ,	PRIMARY KEY(TableName, DBName)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LargeTable_Count_Compared;
	CREATE TEMPORARY TABLE Temp_LargeTable_Count_Compared (
			DBName 			VARCHAR(20) 
		,	TableName 		VARCHAR(100) 
        ,	Count_Insert 	INT
        ,	Count_Update 	INT
        ,	Count_Delete 	INT
        ,	PRIMARY KEY(TableName, DBName)
    );
    
    IF lv_FromDate IS NULL OR lv_ToDate IS NULL THEN
		SET lv_ToDate = NOW();
        SET lv_FromDate = DATE_SUB(lv_ToDate,INTERVAL 1 DAY); 
    END IF;
    SET lv_ToDate_Compare = lv_FromDate;
    SET lv_FromDate_Compare = DATE_SUB(lv_ToDate_Compare,INTERVAL 1 DAY); 
    
    SELECT 	SUM(Count_Insert)
		,	SUM(Count_Update)
		,	SUM(Count_Delete)
	INTO 	lv_TotalInsert
		,	lv_TotalUpdate
        ,	lv_TotalDelete
	FROM MonDB.DBA_Table_IO_Monitor
		WHERE Created BETWEEN lv_FromDate AND lv_ToDate;
    SET lv_TotalInsert = IFNULL(lv_TotalInsert,0);
    SET lv_TotalUpdate = IFNULL(lv_TotalUpdate,0);
    SET lv_TotalDelete = IFNULL(lv_TotalDelete,0);
    
    SELECT 	SUM(Count_Insert)
		,	SUM(Count_Update)
		,	SUM(Count_Delete)
	INTO 	lv_TotalInsert_Compare
		,	lv_TotalUpdate_Compare
        ,	lv_TotalDelete_Compare
	FROM MonDB.DBA_Table_IO_Monitor
		WHERE Created BETWEEN lv_FromDate_Compare AND lv_ToDate_Compare;
    SET lv_TotalInsert_Compare = IFNULL(lv_TotalInsert_Compare,1);
    SET lv_TotalUpdate_Compare = IFNULL(lv_TotalUpdate_Compare,1);
    SET lv_TotalDelete_Compare = IFNULL(lv_TotalDelete_Compare,1);
    
    SET lv_MessageMetric = CONCAT("Total Row Insert: ",FORMAT(lv_TotalInsert,0),'(', ROUND((((lv_TotalInsert/lv_TotalInsert_Compare)*100) - 100),0),"%)\\n",
			'Total Row Update: ',FORMAT(lv_TotalUpdate,0),'(', ROUND((((lv_TotalUpdate/lv_TotalUpdate_Compare)*100) - 100),0),"%)\\n",
            'Total Row Delete: ',FORMAT(lv_TotalDelete,0),'(', ROUND((((lv_TotalDelete/lv_TotalDelete_Compare)*100) - 100),0),"%)\\n"
        );
    INSERT IGNORE INTO Temp_LargeTable(DBName, TableName)
    SELECT 	TABLE_SCHEMA
		,	TABLE_NAME
	FROM information_schema.tables
	WHERE TABLE_SCHEMA NOT IN ('mysql','sys','information_schema','performance_schema', 'CTS_Adhoc','MonDB' )
		AND TABLE_ROWS > 1000000 ;

	INSERT IGNORE INTO Temp_LargeTable_Count(DBName, TableName, Count_Insert, Count_Update,	Count_Delete)
    SELECT 	tbl.`Database`
		,	tbl.TableName
        ,	SUM(tbl.Count_Insert)
        ,	SUM(tbl.Count_Update)
        ,	SUM(tbl.Count_Update)
    FROM MonDB.DBA_Table_IO_Monitor AS tbl
	WHERE Created BETWEEN lv_FromDate AND lv_ToDate
		AND EXISTS (SELECT 1 FROM Temp_LargeTable AS tmp WHERE tmp.DBName = tbl.`Database` AND tmp.TableName = tbl.TableName)
	GROUP BY tbl.`Database`
		,	 tbl.TableName;
	
    INSERT IGNORE INTO Temp_LargeTable_Count_Compared(DBName, TableName, Count_Insert, Count_Update,Count_Delete)
    SELECT 	tbl.`Database`
		,	tbl.TableName
        ,	SUM(tbl.Count_Insert)
        ,	SUM(tbl.Count_Update)
        ,	SUM(tbl.Count_Delete)
    FROM MonDB.DBA_Table_IO_Monitor AS tbl
	WHERE Created BETWEEN lv_FromDate_Compare AND lv_ToDate_Compare
		AND EXISTS (SELECT 1 FROM Temp_LargeTable AS tmp WHERE tmp.DBName = tbl.`Database` AND tmp.TableName = tbl.TableName)
	GROUP BY tbl.`Database`
		,	 tbl.TableName;  
    
    UPDATE Temp_LargeTable_Count AS tbl
		INNER JOIN Temp_LargeTable_Count_Compared AS com ON tbl.DBName = com.DBName AND tbl.TableName = com.TableName
	SET   tbl.Count_Insert_Growth = CASE WHEN tbl.Count_Insert > com.Count_Insert THEN tbl.Count_Insert - com.Count_Insert ELSE 0 END
		, tbl.Count_Update_Growth = CASE WHEN tbl.Count_Update > com.Count_Update THEN tbl.Count_Update - com.Count_Update ELSE 0 END 
        , tbl.Count_Delete_Growth = CASE WHEN tbl.Count_Delete > com.Count_Delete THEN tbl.Count_Delete - com.Count_Delete ELSE 0 END; 
    
    INSERT IGNORE INTO Temp_LargeTable_Result(DBName, TableName, Count_DataChanged)
    SELECT 	DBName
		, 	TableName
        ,   (Count_Insert_Growth + Count_Update_Growth + Count_Delete_Growth)
    FROM Temp_LargeTable_Count
    WHERE (Count_Insert_Growth + Count_Update_Growth + Count_Delete_Growth) > 1000000
    ORDER BY (Count_Insert_Growth + Count_Update_Growth + Count_Delete_Growth) DESC;
    
    SELECT COUNT(1)
    INTO lv_TotalTable
    FROM Temp_LargeTable_Result;
    
    IF lv_TotalTable > 5 THEN
		SET lv_IsMore = 1;
        SET lv_DeleteRow = lv_TotalTable - 5;
        
        DELETE 
		FROM Temp_LargeTable_Result
		LIMIT lv_DeleteRow;
    END IF;
    
	SELECT GROUP_CONCAT(CONCAT(TableName,': ', FORMAT(Count_DataChanged,0)) SEPARATOR " \\n")
    INTO lv_ListTable
	FROM Temp_LargeTable_Result;  
     
    IF lv_ListTable IS NOT NULL THEN
		 SET lv_MessageMetric = CONCAT(lv_MessageMetric, "\\n",lv_ListTable);
         
         IF lv_IsMore = 1 THEN
			SET lv_MessageMetric  = CONCAT(lv_MessageMetric, "\\n...");
         END IF;
    END IF;
    
    SELECT lv_MessageMetric AS MessageMetric;
END$$
DELIMITER ;
