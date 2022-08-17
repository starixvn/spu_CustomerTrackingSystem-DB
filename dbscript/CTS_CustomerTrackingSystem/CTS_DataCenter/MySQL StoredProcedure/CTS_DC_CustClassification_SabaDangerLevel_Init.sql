/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_SabaDangerLevel_Init`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_SabaDangerLevel_Init`(
		OUT op_LastCategoryID 	BIGINT UNSIGNED
	,	OUT op_LastCustID 		BIGINT UNSIGNED
)
    SQL SECURITY INVOKER
BEGIN
	/* 
		Created:	20220818@Aries.Nguyen
		Task :		Customer Class - Update Saba Danger Level
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
			- 20220818@Aries.Nguyen: Created [Redmine ID: #176224] 
            
        Param's Explanation: 

		Example:
			-CALL CTS_DataCenter.CTS_DC_CustClassification_SabaDangerLevel_Init(@op_LastCategoryID,@op_LastCustID);

	*/
    DECLARE lv_LastCategoryID 		INT;
	DECLARE lv_LastCustID 			BIGINT UNSIGNED;
    DECLARE lv_BatchSize 			BIGINT;
    
    DECLARE lv_NextCategoryID 		INT;
    DECLARE lv_NextCustID 			BIGINT UNSIGNED;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Category;
	CREATE TEMPORARY TABLE Temp_Category(
			CategoryID				INT PRIMARY KEY 	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_PA;
    CREATE TEMPORARY TABLE 	Temp_PA (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
	);
	INSERT INTO Temp_Category(CategoryID)
	SELECT CategoryID
	FROM CustomerCategory 
	WHERE SabaSportType IS NOT NULL; 
    
    SELECT ParameterValue 
    INTO lv_LastCategoryID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 103;
    
    SELECT ParameterValue 
    INTO lv_LastCustID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 104;
    
	SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 106;
    
    SET @sql = 	CONCAT("
		INSERT IGNORE INTO Temp_PA (CustID)
		SELECT 	clss.CustID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss USE INDEX(IX_CTSCustomerClassification_CategoryID_CustID)
		WHERE clss.CustID > ",lv_LastCustID," ","
			AND clss.CategoryID = ",lv_LastCategoryID," ","
		ORDER BY clss.CategoryID ASC
			,	 clss.CustID ASC
		LIMIT ",lv_BatchSize,";");
    
    IF NOT EXISTS (SELECT 1 FROM Temp_PA) THEN
		SELECT 	cate.CategoryID
        INTO 	lv_NextCategoryID
		FROM Temp_Category  AS cate
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON cate.CategoryID = clss.CategoryID 
		WHERE cate.CategoryID > lv_LastCategoryID
		ORDER BY cate.CategoryID ASC
		LIMIT 1; 
    END IF;
    
    IF lv_NextCategoryID IS NOT NULL THEN
		SET @sql = 	CONCAT("
		INSERT IGNORE INTO Temp_PA (CustID)
		SELECT 	clss.CustID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss  USE INDEX(IX_CTSCustomerClassification_CategoryID_CustID)
		WHERE clss.CustID > 0
			AND clss.CategoryID = ", lv_NextCategoryID," ","
		ORDER BY clss.CategoryID ASC
			,	 clss.CustID ASC
		LIMIT ",lv_BatchSize,";");

		PREPARE stmt1 FROM  @sql;
		EXECUTE stmt1; 
		DEALLOCATE PREPARE stmt1; 
	ELSE
		SET lv_NextCategoryID = lv_LastCategoryID;
	END IF;
    
    SELECT MAX(CustID)
    INTO lv_NextCustID
    FROM Temp_PA;
    
    IF lv_NextCustID IS NOT NULL THEN
		SET op_LastCategoryID = lv_NextCategoryID;
		SET op_LastCustID = lv_NextCustID;
        
	ELSE         
		SET op_LastCategoryID = -1;
		SET op_LastCustID = -1;
    END IF;
    
	SELECT 	CustID
    FROM Temp_PA;
    
    WITH CTE_SportType AS (
		SELECT tbl.SportType
		FROM CTS_DataCenter.CustomerCategory AS cate
		INNER JOIN JSON_TABLE(cate.SabaSportType, 
						'$[*]' COLUMNS (SportType BIGINT UNSIGNED PATH '$')
		) tbl
	WHERE cate.CategoryID = lv_NextCategoryID
    )
    SELECT 	pa.CustID
		,	st.SportType
        ,	1 AS ActionType
	FROM Temp_PA AS pa
		JOIN CTE_SportType AS st;
END$$
DELIMITER ;