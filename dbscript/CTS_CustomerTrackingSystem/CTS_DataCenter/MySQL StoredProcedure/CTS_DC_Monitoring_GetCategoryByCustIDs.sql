/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_Monitoring_GetCategoryByCustIDs`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_Monitoring_GetCategoryByCustIDs`(
	  IN ip_CustIDs 		TEXT,
      IN ip_IsCheckInternal BOOLEAN
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
            - 20230523@Jonas.Huynh: Realtime Inactive Enhancement [RedmineID: #188509]
            
		Param's Explanation (filtered by):    
			CALL CTS_DC_Monitoring_GetCategoryByCustIDs('123,456', false)
	*/  
    
    DECLARE CONST_CATEGORY_INACTIVE		INT DEFAULT 1000;
    
    DECLARE	CONST_VALID_CATEGORY		TINYINT DEFAULT 0;
	DECLARE	CONST_INVALID_INACTIVE 		TINYINT DEFAULT 2;
    DECLARE	CONST_INVALID_NULL			TINYINT DEFAULT 3;
    
	DECLARE lv_ScanDateValid 			DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 29 DAY);
        
    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
	CREATE TEMPORARY TABLE Temp_Customers(
			CustID				BIGINT UNSIGNED PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
	CREATE TEMPORARY TABLE Temp_CustomerCategory(
			CustID				BIGINT UNSIGNED
        ,	CurrentCategoryID 	INT
        ,	INDEX IX_Temp_CustomerCategory_CustID(CustID)
	);

    INSERT INTO Temp_Customers (CustID)
    SELECT DISTINCT temp.CustID
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),
			'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (
				CustID 		BIGINT UNSIGNED PATH '$'
			))) AS temp;

	IF ip_IsCheckInternal THEN
		DELETE temp
		FROM Temp_Customers AS temp
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
		WHERE IsInternal = 1;
    END IF;

	INSERT IGNORE INTO Temp_CustomerCategory(CustID, CurrentCategoryID)
	SELECT 		cate.CustID AS CustID
			, 	cc.CategoryGroup AS CurrentCategoryID
	FROM Temp_Customers AS temp
		INNER JOIN	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
		INNER JOIN	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID;
        
    SELECT 	cust.CustID AS CustID
		,	cate.CurrentCategoryID AS CurrentCategoryID
        ,	CASE 
				WHEN cate.CurrentCategoryID = CONST_CATEGORY_INACTIVE AND ass.LastTicketDate >= lv_ScanDateValid THEN CONST_INVALID_INACTIVE
                WHEN cate.CurrentCategoryID IS NULL THEN CONST_INVALID_NULL
				ELSE CONST_VALID_CATEGORY
			END AS TypeID
	FROM Temp_Customers as cust
		LEFT JOIN Temp_CustomerCategory AS cate ON cust.CustID = cate.CustID
		LEFT JOIN CTS_Archive.CTSCustomerAssociationStatus AS ass ON ass.CustID = cust.CustID;

END$$
DELIMITER ;