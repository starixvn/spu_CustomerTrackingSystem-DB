/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_RowAffectedSP_Metric`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_RowAffectedSP_Metric`()
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
			- CALL MonDB.DBA_Monitor_RowAffectedSP_Metric(); 
	*/
    DECLARE lv_FromDate 		DATETIME;
    DECLARE lv_ToDate 			DATETIME;
    DECLARE lv_FromDate_Compare DATETIME;
    DECLARE lv_ToDate_Compare 	DATETIME;
    
    DECLARE lv_Total 			INT;
    DECLARE lv_Total_Compare	INT;
    DECLARE lv_TotalSP 			INT;
	DECLARE lv_ListSP 		 	LONGTEXT;
    DECLARE lv_IsMore 			BIT DEFAULT 0;
    DECLARE lv_DeleteRow 		INT;
    DECLARE lv_MessageMetric	LONGTEXT;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_SPName;
	CREATE TEMPORARY TABLE Temp_SPName (
			SPName 		VARCHAR(100) PRIMARY KEY
    );
    
    IF lv_FromDate IS NULL OR lv_ToDate IS NULL THEN
		SET lv_ToDate = NOW();
        SET lv_FromDate = DATE_SUB(lv_ToDate,INTERVAL 1 DAY); 
    END IF;
    SET lv_ToDate_Compare = lv_FromDate;
    SET lv_FromDate_Compare = DATE_SUB(lv_ToDate_Compare,INTERVAL 1 DAY); 
    
    SELECT SUM(Sum_Rows_Affected) 
    INTO lv_Total
	FROM MonDB.DBA_SPMonitor 
	WHERE Created BETWEEN lv_FromDate AND lv_ToDate;
    SET lv_Total = IFNULL(lv_Total,0);
    
    SELECT SUM(Sum_Rows_Affected) 
    INTO lv_Total_Compare
	FROM MonDB.DBA_SPMonitor 
	WHERE Created BETWEEN lv_FromDate_Compare AND lv_ToDate_Compare;
    SET lv_Total_Compare = IFNULL(lv_Total_Compare,0);
	
    IF lv_Total = 0 THEN
		SELECT "Total: 0" AS MessageMetric;
        LEAVE sp;
    END IF;
    
    INSERT IGNORE INTO Temp_SPName(SPName)
    SELECT Name
    FROM MonDB.DBA_SPMonitor 
    WHERE Created BETWEEN lv_FromDate AND lv_ToDate
		AND Sum_Rows_Affected > 5000000;
    
    SELECT COUNT(1)
    INTO lv_TotalSP
    FROM Temp_SPName;
    
    IF lv_TotalSP > 5 THEN
		SET lv_IsMore = 1;
        SET lv_DeleteRow = lv_TotalSP - 5;
        
        DELETE 
		FROM Temp_SPName
		LIMIT lv_DeleteRow;
    END IF;
    
	SELECT GROUP_CONCAT(SPName  SEPARATOR " \\n")
    INTO lv_ListSP
	FROM Temp_SPName;  
     
    SET lv_MessageMetric = CONCAT("Total: ",FORMAT(lv_Total,0),'(', ROUND((((lv_Total/lv_ToDate_Compare)*100) - 100),0),"%)");
    
    IF lv_ListSP IS NOT NULL THEN
		 SET lv_MessageMetric = CONCAT(lv_MessageMetric, "\\n",lv_ListSP);
         
         IF lv_IsMore = 1 THEN
			SET lv_MessageMetric  = CONCAT(lv_MessageMetric, "\\n...");
         END IF;
    END IF;
    
    SELECT lv_MessageMetric AS MessageMetric;
END$$
DELIMITER ;
