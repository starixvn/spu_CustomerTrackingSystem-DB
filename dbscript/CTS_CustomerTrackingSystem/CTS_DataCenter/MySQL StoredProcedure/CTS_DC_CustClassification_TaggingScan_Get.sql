/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_TaggingScan_Get`;

DELIMITER $$
CREATE PROCEDURE `CTS_DC_CustClassification_TaggingScan_Get`(
		OUT op_LastCategoryID 	INT 
	,	OUT op_LastCustID 		BIGINT UNSIGNED 
)

    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230804@Jonas.Huynh
        Task :		Get normal customer to scan tagging
		DB:			CTS_DataCenter  
		Original: 
		Revisions:
			- 20230804@Jonas.Huynh: Created [RedmineID: #191400]
            
        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_DailyScan_GetTagging();
	*/ 
    
    DECLARE	CONST_GROUP_NORMAL 	INT DEFAULT 200;
    
	DECLARE lv_LastCategoryID 	INT;
	DECLARE lv_LastCustID 		BIGINT UNSIGNED;
    DECLARE lv_BatchSize 		BIGINT;
    
    DECLARE lv_NextCategoryID 	INT;
    DECLARE lv_NextCustID 		BIGINT UNSIGNED;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Category;
	CREATE TEMPORARY TABLE Temp_Category(
			CategoryID	INT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID 	BIGINT UNSIGNED PRIMARY KEY
    );
          
    SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 143; 
    
    SELECT ParameterValue 
    INTO lv_LastCategoryID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 144;
    
    SELECT ParameterValue 
    INTO lv_LastCustID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 145;
   
	INSERT INTO Temp_Category(CategoryID)
	SELECT CategoryID
	FROM CTS_DataCenter.CustomerCategory
	WHERE ParentID = 200 
		AND IsActive = 1
		AND IsUsedManually = 0 
		AND ScanTaggingIntervalInSecond > 0; 
        
    IF lv_LastCategoryID IS NULL OR lv_LastCategoryID = 0 THEN
		SELECT CategoryID 
		INTO lv_LastCategoryID 
		FROM Temp_Category
		ORDER BY CategoryID ASC
        LIMIT 1;
	END IF;
    
	INSERT IGNORE INTO Temp_Cust (CustID)
	SELECT clss.CustID
	FROM CTS_DataCenter.CTSCustomerClassification AS clss
	WHERE clss.CustID > lv_LastCustID
		AND clss.CategoryID = lv_LastCategoryID
		AND clss.SportGroupID = CONST_GROUP_NORMAL
		AND NOT EXISTS (SELECT 1 
						 FROM  CTS_DataCenter.PinCustomerCategory AS pin 
						 WHERE pin.CTSCustID = clss.CTSCustID)
	ORDER BY clss.CategoryID ASC
		,	 clss.CustID ASC
	LIMIT lv_BatchSize;
    
    IF NOT EXISTS (SELECT 1 FROM Temp_Cust) THEN
		SELECT cate.CategoryID
        INTO   lv_NextCategoryID
		FROM Temp_Category AS cate
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON cate.CategoryID = clss.CategoryID 
		WHERE cate.CategoryID > lv_LastCategoryID
            AND NOT EXISTS (SELECT 1 
							 FROM CTS_DataCenter.PinCustomerCategory AS pin 
							 WHERE pin.CTSCustID = clss.CTSCustID)
		ORDER BY cate.CategoryID ASC
		LIMIT 1; 
    END IF;
    
    IF lv_NextCategoryID IS NOT NULL THEN
		INSERT IGNORE INTO Temp_Cust (CustID)
		SELECT clss.CustID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss
		WHERE clss.CustID > 0
			AND clss.CategoryID = lv_NextCategoryID
			AND clss.SportGroupID = CONST_GROUP_NORMAL
			AND NOT EXISTS (SELECT 1 
							 FROM  CTS_DataCenter.PinCustomerCategory AS pin 
							 WHERE pin.CTSCustID = clss.CTSCustID)
		ORDER BY clss.CategoryID ASC
			,	 clss.CustID ASC
		LIMIT lv_BatchSize;
	ELSE
		SET lv_NextCategoryID = lv_LastCategoryID;
	END IF;
    
    SELECT MAX(CustID)
    INTO lv_NextCustID
    FROM Temp_Cust;
    
    IF lv_NextCustID IS NOT NULL THEN
        SET op_LastCategoryID = lv_NextCategoryID;
		SET op_LastCustID = lv_NextCustID;
	ELSE 
		SELECT CategoryID
        INTO lv_NextCategoryID
		FROM Temp_Category
		ORDER BY CategoryID ASC 
		LIMIT 1;
	
        SET op_LastCategoryID = lv_NextCategoryID;
        SET op_LastCustID = 0;
    END IF;
    
    SELECT DISTINCT	tmp.CustID
    FROM Temp_Cust AS tmp;
    
END$$

DELIMITER ;