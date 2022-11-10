/*<info serverAlias="CTSMain-MonDB" databaseType="2" executers="ctsMonitor" isFunction="0" isNested="0"></info>*/
USE MonDB;
DROP PROCEDURE IF EXISTS `DBA_Monitor_ErrorQuery_Metric`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Monitor_ErrorQuery_Metric`()
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
			- CALL MonDB.DBA_Monitor_ErrorQuery_Metric(); 
	*/
    DECLARE lv_FromDate 		DATETIME;
    DECLARE lv_ToDate 			DATETIME;
    DECLARE lv_Total 			INT;
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
    
    SELECT SUM(Sum_Errors) 
	INTO lv_Total
	FROM MonDB.DBA_SPMonitor 
    WHERE Created BETWEEN lv_FromDate AND lv_ToDate
		AND Sum_Errors > 0;
	
    IF lv_Total IS NULL THEN
		SELECT "Total: 0 \\nTotal SP: 0" AS MessageMetric;
        LEAVE sp;
    END IF;
    
    INSERT IGNORE INTO Temp_SPName(SPName)
    SELECT Name
    FROM MonDB.DBA_SPMonitor 
    WHERE Created BETWEEN lv_FromDate AND lv_ToDate
		AND Sum_Errors > 0;
    
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
     
    SET lv_MessageMetric = CONCAT("Total: ", lv_Total, "\\nTotal SP: ",lv_TotalSP);
    
    IF lv_ListSP IS NOT NULL THEN
		 SET lv_MessageMetric = CONCAT(lv_MessageMetric, "\\n",lv_ListSP);
         
         IF lv_IsMore = 1 THEN
			SET lv_MessageMetric  = CONCAT(lv_MessageMetric, "\\n...");
         END IF;
    END IF;
    
    SELECT lv_MessageMetric AS MessageMetric;
END$$
DELIMITER ;
