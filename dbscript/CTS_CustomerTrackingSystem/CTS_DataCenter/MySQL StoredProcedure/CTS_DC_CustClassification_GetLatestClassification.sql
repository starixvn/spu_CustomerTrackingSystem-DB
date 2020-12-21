/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_GetLatestClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetLatestClassification`(IN ip_CustomerCategorizes JSON)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201214@Irena.Vo	
		Task :		Get Customers' latest Customer Class 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201214@Irena.Vo: Created [RedmineID: #145951]
            - 20201221@Irena.Vo: Update Input & Output params. Enhance logic get data CC [RedmineID: #145951]
            
		Param's Explanation:
			call CTS_DataCenter.CTS_DC_CustClassification_GetLatestClassification('1,2,1277,555555');
	*/ 
    DECLARE lv_CurrentDateTime DATETIME DEFAULT CURRENT_TIME();
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
    CREATE TEMPORARY TABLE 		Temp_Customers (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
        ,   IsExistedCC         BIT
        ,   IsExistedCate       BIT
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecords;
    CREATE TEMPORARY TABLE 		Temp_LatestRecords (
        	CustID			    BIGINT UNSIGNED PRIMARY KEY 
		,	LastModifiedDate	DATETIME
        ,	INDEX				IX_Temp_LatestRecords_LastModifiedDate(LastModifiedDate)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LastestCategories;
    CREATE TEMPORARY TABLE 		Temp_LastestCategories (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,	CategoryID		    SMALLINT
        ,   INDEX               IX_Temp_LastestCategories_CategoryID(CategoryID)
    );     
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClass;
    CREATE TEMPORARY TABLE 		Temp_CustomerClass (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,   CustomerClass       SMALLINT
    );    
    
    -- Insert CustIDs
	SET @sql = 	CONCAT("INSERT INTO Temp_Customers (CustID) VALUES ('", REPLACE(ip_CustomerIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
   
    -- Update CustIDs if Input = CTSCustIDs
    UPDATE 		Temp_Customers AS temp
    INNER JOIN  CTS_DataCenter.CTSCustomer AS cust on cust.CTSCustID = temp.CustID
    SET 		temp.CustID 	= 	cust.CustID;
   
    -- Update info: IsExistedCC & IsExistedCate
	UPDATE 		Temp_Customers AS temp
	LEFT JOIN 	CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
	LEFT JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
	SET			temp.IsExistedCC = 	CASE WHEN sp.CustID IS NOT NULL THEN 1
										 ELSE 0
									END
			,	temp.IsExistedCate = CASE WHEN cate.CustID IS NOT NULL THEN 1
										 ELSE 0
									 END;
   
    -- Ignore Customer List existed CC
    DELETE 	temp
    FROM 	Temp_Customers AS temp
    WHERE 	temp.IsExistedCC = 1;
   
	-- Insert lastest of records
	INSERT INTO Temp_LatestRecords(CustID, LastModifiedDate)
	SELECT  DISTINCT temp.CustID,	MAX(cate.LastModifiedDate)
	FROM 		CTS_DataCenter.CTSCustomerClassification AS cate
	INNER JOIN 	Temp_Customers AS temp ON temp.CustID = cate.CustID
	WHERE 		temp.IsExistedCate = 1 AND cate.SportGroupID IN (0, 200) -- PA & Normal
	GROUP BY 	temp.CustID;
	
    -- Insert lastest customer category
	INSERT INTO Temp_LastestCategories(CustID, CategoryID)
	SELECT 	DISTINCT temp.CustID,	MAX(cate.CategoryID) 
	FROM 		Temp_LatestRecords AS temp
	INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID
	WHERE 		temp.LastModifiedDate = cate.LastModifiedDate
	GROUP BY  	temp.CustID;
    
    -- Insert Customer Class
    INSERT INTO Temp_CustomerClass (CustID, CustomerClass)
    SELECT DISTINCT	temp.CustID,	-1	AS CustomerClass
    FROM 			Temp_Customers AS temp
    WHERE 			temp.IsExistedCate = 0 -- CC = -1
    UNION ALL
    SELECT DISTINCT temp.CustID,  map.CustomerClass
    FROM 			Temp_LastestCategories AS temp
    INNER JOIN 		CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.CategoryID; -- CC <> -1
    
    -- Get Lastest Customer Class to sync in mainDB
    SELECT DISTINCT	cc.CustId, cc.CustomerClass, lv_CurrentDateTime AS ScannedTime
    FROM 			Temp_CustomerClass AS cc;
  
END$$

DELIMITER ;