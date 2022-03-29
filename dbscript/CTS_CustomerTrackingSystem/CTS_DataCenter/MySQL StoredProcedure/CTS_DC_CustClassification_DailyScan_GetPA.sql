/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_DailyScan_GetPA`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_DailyScan_GetPA`(
		OUT op_LastCategoryID 	INT 
	,	OUT op_LastCustID 		BIGINT UNSIGNED 
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20220328@Aries.Nguyen
		Task: Add new category/class for PA Probation [Redmine ID: #170468]
		DB: CTS_DataCenter
        
		Original:
		Revisions:
			- 20220328@Aries.Nguyen: Created [Redmine ID: #170468]

		Param's Explanation (filtered by):      
			- CALL CTS_DC_CustClassification_DailyScan_GetPA (@op_LastCategoryID, @op_LastCustID);
	*/
    
    DECLARE lv_LastCategoryID 		INT;
	DECLARE lv_LastCustID 			BIGINT UNSIGNED;
    DECLARE lv_BatchSize 			BIGINT;
    DECLARE lv_ScanDateValid 		DATETIME;
    
    DECLARE lv_NextCategoryID 		INT;
    DECLARE lv_NextCustID 			BIGINT UNSIGNED;

    DROP TEMPORARY TABLE IF EXISTS Temp_Category;
	CREATE TEMPORARY TABLE Temp_Category(
			CategoryID				INT PRIMARY KEY 	
        ,	ScanDate				DATETIME
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_PA;
    CREATE TEMPORARY TABLE 	Temp_PA (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
	);
    
    INSERT INTO Temp_Category(CategoryID)
	SELECT CategoryID
	FROM CustomerCategory 
	WHERE RelationshipCategoryID IS NOT NULL; 
    
    SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 87;
    
    SELECT ParameterValue 
    INTO lv_LastCategoryID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 88;
    
    SELECT ParameterValue 
    INTO lv_LastCustID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 89;

    INSERT IGNORE INTO Temp_PA (CustID)
	SELECT 	clss.CustID
	FROM CTS_DataCenter.CTSCustomerClassification AS clss
	WHERE clss.CustID > lv_LastCustID
		AND clss.CategoryID = lv_LastCategoryID
	ORDER BY clss.CustID ASC
	LIMIT lv_BatchSize;
    
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
		INSERT IGNORE INTO Temp_PA (CustID)
		SELECT 	clss.CustID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss
		WHERE clss.CustID > 0
			AND clss.CategoryID = lv_NextCategoryID
		ORDER BY clss.CustID ASC
		LIMIT lv_BatchSize;
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
		SELECT CategoryID
        INTO lv_NextCategoryID
		FROM Temp_Category
		ORDER BY CategoryID ASC 
		LIMIT 1;
        
		SET op_LastCategoryID = lv_NextCategoryID;
		SET op_LastCustID = 0;
    END IF;
    
    SELECT 	CustID
    FROM Temp_PA;
END$$
DELIMITER ;