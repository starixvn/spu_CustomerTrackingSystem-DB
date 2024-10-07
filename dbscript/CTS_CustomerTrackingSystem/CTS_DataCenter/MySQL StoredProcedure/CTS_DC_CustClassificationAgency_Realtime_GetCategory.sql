/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassificationAgency_Realtime_GetCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassificationAgency_Realtime_GetCategory`(
	  IN ip_CustIDs      	TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20241003@Jonas.Huynh
		Task:  Return customer to classify realtime
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20241003@Jonas.Huynh: Created [Redmine ID: #185799]
            
		Param's Explanation (filtered by):    
			CALL CTS_DC_CustClassificationAgency_Realtime_GetCategory('761925')
	*/  
    DECLARE	CONST_PARENTID_NORMAL 		INT;
	DECLARE	CONST_PARENTID_PA 			INT;
	DECLARE	CONST_PARENTID_POTENTIALPA	INT;
   	DECLARE CONST_PARENTID_WRAPPER		INT;
    DECLARE	CONST_CATEGROUPID_NEW 		INT;
    
    SET CONST_PARENTID_NORMAL 			= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
    SET CONST_PARENTID_PA 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
    SET CONST_PARENTID_POTENTIALPA 		= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_POTENTIALPA');
   	SET CONST_PARENTID_WRAPPER 			= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_WRAPPER');
	SET CONST_CATEGROUPID_NEW 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_NEW');
       
    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
	CREATE TEMPORARY TABLE Temp_Customers(
			CustID					BIGINT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
	CREATE TEMPORARY TABLE Temp_CustomerCategory(
			CustID					BIGINT UNSIGNED NOT NULL
		,   CTSCustID				BIGINT UNSIGNED NOT NULL
		,	ParentID				INT
        ,	CategoryID 				INT
        , 	INDEX IX_Temp_CustomerCategory_CustID(CustID)
	);      
	
    INSERT INTO Temp_Customers (CustID)
    SELECT DISTINCT temp.CustID
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),
			'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (
				CustID 		BIGINT UNSIGNED PATH '$'
			))) AS temp;
	
    -- #1: Get customer category
	INSERT INTO Temp_CustomerCategory(CustID, CTSCustID, ParentID, CategoryID)
	SELECT 		tmplc.CustID
			,	tmplc.CTSCustID
			, 	tmplc.ParentID
            ,	tmplc.CategoryID
	FROM Temp_Customers AS temp
    	, LATERAL	
			(	SELECT cc.CustID, cc.CTSCustID, cc.CategoryID, ca.ParentID
				FROM CTS_DataCenter.CTSCustomerClassificationAgency AS cc 
					INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS ca ON ca.CategoryID = cc.CategoryID
				WHERE temp.CustID = cc.CustID 
					AND ca.IsActive = 1
                    AND ca.ParentID <> CONST_PARENTID_WRAPPER
				ORDER BY ca.CategoryPriority ASC, cc.LastModifiedDate DESC
                LIMIT 1
		   ) tmplc;
	
    -- #2: Return customer category for realtime classification
    SELECT DISTINCT temp.CustID AS CustID
	FROM Temp_Customers AS temp
		LEFT JOIN Temp_CustomerCategory AS cate ON cate.CustID = temp.CustID
	WHERE cate.CategoryID IS NULL 
		OR cate.CategoryID = CONST_CATEGROUPID_NEW;	
END$$
DELIMITER ;