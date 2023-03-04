/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_Monitoring_GetCategoryByCustIDs`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_Monitoring_GetCategoryByCustIDs`(
	  IN ip_CustIDs TEXT
) 
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20230227@Jonas.Huynh
		Task:  Return customer categories
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20230227@Jonas.Huynh: Created SP to get customer category [RedmineID: #183278]
            
		Param's Explanation (filtered by):    
			CALL CTS_DC_Monitoring_GetCategoryByCustIDs('123,456')
	*/  
    DECLARE CONST_CATEGORY_INACTIVE		INT DEFAULT 1000;

    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
	CREATE TEMPORARY TABLE Temp_Customers(
			CustID				BIGINT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
	CREATE TEMPORARY TABLE Temp_CustomerCategory(
			CustID				BIGINT UNSIGNED
		,	SportGroupID		INT
        ,	CurrentCategoryID 	INT
	);

    INSERT INTO Temp_Customers (CustID)
    SELECT DISTINCT temp.CustID
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),
			'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (
				CustID 		BIGINT UNSIGNED PATH '$'
			))) AS temp;
         
	INSERT IGNORE INTO Temp_CustomerCategory(CustID, SportGroupID, CurrentCategoryID)
	SELECT 		cate.CustID AS CustID
			, 	cate.SportGroupID AS SportGroupID  
			, 	CASE 
					WHEN cc.CategoryGroup IN (CONST_CATEGORY_INACTIVE) THEN cc.CategoryID
                    ELSE cc.CategoryGroup
				END AS CurrentCategoryID
	FROM Temp_Customers AS temp
		INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
		INNER JOIN	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID;
        
    SELECT 	cust.CustID AS CustID
		,	cate.SportGroupID AS SportGroupID
        ,	cate.CurrentCategoryID AS CurrentCategoryID
	FROM Temp_Customers as cust
		LEFT JOIN Temp_CustomerCategory AS cate ON cust.CustID = cate.CustID;   
	
END$$
DELIMITER ;