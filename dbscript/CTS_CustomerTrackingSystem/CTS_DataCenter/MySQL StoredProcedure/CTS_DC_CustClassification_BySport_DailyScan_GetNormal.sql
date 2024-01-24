/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_DailyScan_GetNormal`;

DELIMITER $$
CREATE PROCEDURE `CTS_DC_CustClassification_BySport_DailyScan_GetNormal`(
		OUT op_LastCategoryID 	INT 
	,	OUT op_LastCustID 		BIGINT UNSIGNED 

)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20220908@Harvey.Nguyen
		Task: Get cust for daily scan [Redmine ID: #176992]
		DB: CTS_DataCenter
        
		Original:
		Revisions:
			- 20220908@Harvey.Nguyen: Created [Redmine ID: #176992]
            - 20230707@Jonas.Huynh: Normal Renovation [Redmine ID: #189875]
			- 20240124@Jonas.Huynh: Exclude inactive customer within 30days [Redmine ID: #199632]
            
		Param's Explanation (filtered by):      
			- CALL CTS_DC_CustClassification_BySport_DailyScan_GetNormal (@op_LastCategoryID, @op_LastCustID);
	*/
    
	DECLARE	CONST_GROUP_NORMAL 			INT DEFAULT 200;
	DECLARE	CONST_CATEGORYID_PROBATION	INT DEFAULT 206;
	DECLARE	CONST_MINNORMALCATEGORY		INT DEFAULT 202;
    
	DECLARE lv_LastCategoryID 		INT;
	DECLARE lv_LastCustID 			BIGINT UNSIGNED;
    DECLARE lv_BatchSize 			BIGINT;
    DECLARE lv_ScanDateValid 		DATETIME;
    
    DECLARE lv_NextCategoryID 		INT;
    DECLARE lv_NextCustID 			BIGINT UNSIGNED;
    DECLARE lv_NextScanDateValid 	DATETIME;
    
    DECLARE lv_CurrentDate 			DATE DEFAULT CURRENT_DATE();
    DECLARE lv_From30Date 			DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 29 DAY);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Category;
	CREATE TEMPORARY TABLE Temp_Category(
			CategoryID		INT PRIMARY KEY
        ,	ScanDate		DATETIME
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Normal;
    CREATE TEMPORARY TABLE 	Temp_Normal (
            CustID					BIGINT UNSIGNED
		,	SportID					SMALLINT
        ,	PRIMARY KEY (CustID, SportID)
	);
    
    INSERT INTO Temp_Category(CategoryID, ScanDate)
	SELECT 	CategoryID
        , 	DATE_SUB(NOW(), INTERVAL ScanIntervalInSecond - 86400 SECOND)
	FROM CTS_DataCenter.CustomerCategory
	WHERE ParentID = CONST_GROUP_NORMAL 
		AND CategoryID < CONST_CATEGORYID_PROBATION
		AND IsActive = 1
		AND IsUsedManually = 0 
		AND ScanIntervalInSecond > 0; 
    
    SELECT ParameterValue 
    INTO lv_BatchSize
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 113; 
    
    SELECT ParameterValue 
    INTO lv_LastCategoryID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 114;
    
    SELECT ParameterValue 
    INTO lv_LastCustID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 115;
    
    IF lv_LastCategoryID IS NULL OR lv_LastCategoryID = 0 THEN
		SELECT CategoryID 
		INTO lv_LastCategoryID 
		FROM Temp_Category
		ORDER BY CategoryID ASC
        LIMIT 1;
	END IF;
    
    SELECT ScanDate 
    INTO lv_ScanDateValid 
    FROM Temp_Category
    WHERE CategoryID = lv_LastCategoryID;
  
    SET @sql = CONCAT("
		INSERT IGNORE INTO Temp_Normal (CustID, SportID)
		SELECT 	clss.CustID, clss.SportID
		FROM CTS_DataCenter.CTSCustomerClassification_BySport AS clss USE INDEX(IX_CTSCustomerClassification_BySport_CategoryID_CustID)
		WHERE clss.CustID > ", lv_LastCustID, " ","
			AND clss.CategoryID = ", lv_LastCategoryID, " ","
			AND clss.LastScannedDate <= '", lv_ScanDateValid, "' ","
			AND NOT EXISTS (SELECT 1 
							 FROM  CTS_DataCenter.ProbationAccountMonitor_BySport AS pro 
							 WHERE pro.CustID = clss.CustID AND pro.SportID = clss.SportID)
			AND EXISTS (SELECT 1
						FROM CTS_Archive.CTSCustomerAssociationStatus AS arc
                        WHERE arc.CustID = clss.CustID AND arc.LastTicketDate >= lv_From30Date)
		ORDER BY 	clss.CustID ASC
            , 		clss.SportID ASC
		LIMIT ", lv_BatchSize, ";");

    PREPARE stmt1 FROM @sql;
    EXECUTE stmt1; 
	DEALLOCATE PREPARE stmt1;
    
    IF NOT EXISTS (SELECT 1 FROM Temp_Normal) THEN
		SELECT 	cate.CategoryID
			,	cate.ScanDate
        INTO 	lv_NextCategoryID
			,	lv_NextScanDateValid
		FROM Temp_Category AS cate
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS clss ON cate.CategoryID = clss.CategoryID 
		WHERE cate.CategoryID > lv_LastCategoryID
			AND clss.LastScannedDate <= cate.ScanDate
			AND NOT EXISTS (SELECT 1 
							 FROM  CTS_DataCenter.ProbationAccountMonitor_BySport AS pro 
							 WHERE pro.CustID = clss.CustID AND pro.SportID = clss.SportID)
			AND EXISTS (SELECT 1
						FROM CTS_Archive.CTSCustomerAssociationStatus AS arc
                        WHERE arc.CustID = clss.CustID AND arc.LastTicketDate >= lv_From30Date)
		ORDER BY cate.CategoryID ASC
		LIMIT 1; 
    END IF;
    
    IF lv_NextCategoryID IS NOT NULL THEN
		SELECT ScanDate 
		INTO lv_ScanDateValid  
		FROM Temp_Category
		WHERE CategoryID = lv_NextCategoryID;
        
		SET @sql =  CONCAT("
		INSERT IGNORE INTO Temp_Normal (CustID, SportID)
		SELECT 	clss.CustID, clss.SportID
		FROM CTS_DataCenter.CTSCustomerClassification_BySport AS clss USE INDEX(IX_CTSCustomerClassification_BySport_CategoryID_CustID)
		WHERE clss.CustID > 0
			AND clss.CategoryID = ", lv_NextCategoryID," ","
			AND clss.LastScannedDate <= '", lv_NextScanDateValid,"' ","
			AND NOT EXISTS (SELECT 1 
							 FROM  CTS_DataCenter.ProbationAccountMonitor_BySport AS pro 
							 WHERE pro.CustID = clss.CustID AND pro.SportID = clss.SportID)
			AND EXISTS (SELECT 1
						FROM CTS_Archive.CTSCustomerAssociationStatus AS arc
						WHERE arc.CustID = clss.CustID AND arc.LastTicketDate >= lv_From30Date)
		ORDER BY clss.CustID ASC
            , 	 clss.SportID ASC
		LIMIT ", lv_BatchSize,";");
    
		PREPARE stmt1 FROM  @sql;
		EXECUTE stmt1; 
		DEALLOCATE PREPARE stmt1;        
	ELSE
		SET lv_NextCategoryID = lv_LastCategoryID;
	END IF;
    
    SELECT MAX(CustID)
    INTO lv_NextCustID
    FROM Temp_Normal;
    
    IF lv_NextCustID IS NOT NULL THEN
		IF ((SELECT COUNT(1) FROM Temp_Normal) = lv_BatchSize) THEN
			DELETE FROM Temp_Normal WHERE CustID = lv_NextCustID;
			
			SELECT MAX(CustID)
			INTO lv_NextCustID
			FROM Temp_Normal;	
		END IF;
        
        SET op_LastCategoryID = lv_NextCategoryID;
		SET op_LastCustID = lv_NextCustID;
	ELSE 
		SELECT CategoryID
        INTO lv_NextCategoryID
		FROM Temp_Category
		ORDER BY CategoryID ASC 
		LIMIT 1;
	
        SET op_LastCategoryID = CONST_MINNORMALCATEGORY;
        SET op_LastCustID = 0;
    END IF;
    
    SELECT 	CustID  AS CustId, 
			SportID AS SportGroup
    FROM Temp_Normal;

END$$
DELIMITER ;