/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_GetLatestClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetLatestClassification`(IN ip_CustomerList VARCHAR(10000),IN ip_IsCustId TINYINT)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201207@Irena.Vo	
		Task :		Get Customers' latest Customer Class 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201207@Irena.Vo: Created [RedmineID: #145951]
            
		Param's Explanation:
			- From CustID: call CTS_DataCenter.CTS_DC_CustClassification_GetLatestClassification_xtest('1,2,1277,555555', 1);
            - From CTSCustID: call CTS_DataCenter.CTS_DC_CustClassification_GetLatestClassification_xtest('1,2770811,2771325,555555', 0);
	*/ 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerList;
    CREATE TEMPORARY TABLE Temp_CustomerList (
			CustomerID 			BIGINT UNSIGNED PRIMARY KEY
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory;
    CREATE TEMPORARY TABLE Temp_LatestRecordOfCategory (
        	CustomerID			BIGINT UNSIGNED
		,	SportGroupID		SMALLINT
		,	LastModifiedDate	DATETIME
        ,	PRIMARY KEY 		PK_Temp_LatestRecordOfCategory_CustomerID_SportGroupID(CustomerID,SportGroupID)
        ,	INDEX				IX_Temp_LatestRecordOfCategory_CustomerID_SportGroupID(CustomerID,SportGroupID)
    );    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LastestCustomerCategory;
    CREATE TEMPORARY TABLE Temp_LastestCustomerCategory (
        	CustID				BIGINT UNSIGNED
		,	CategoryID		    SMALLINT
        ,	LastModifiedDate	DATETIME
        ,	PRIMARY KEY         PK_Temp_LastestCustomerCategory_CustID(CustID)
        ,   INDEX               IX_Temp_LastestCustomerCategory_CategoryID(CategoryID)
    );     
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClass;
    CREATE TEMPORARY TABLE Temp_CustomerClass (
        	CustID				BIGINT UNSIGNED
		,   CustomerClass       SMALLINT
        ,	ScannedTime	        DATETIME
        ,	PRIMARY KEY 		PK_Temp_CustomerClass_CustID(CustID)
        ,	INDEX       		IX_Temp_CustomerClass_CustomerClass_ScannedTime(CustomerClass,ScannedTime)
    );    
    
    SET @sql = CONCAT("INSERT INTO Temp_CustomerList (CustomerID) VALUES ('", REPLACE(ip_CustomerList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
 
	IF (ip_IsCustId = 1) THEN
			INSERT INTO Temp_LatestRecordOfCategory(CustomerID, SportGroupID, LastModifiedDate)
			SELECT  t.CustomerID, 
					CASE WHEN c.CustID IS NULL THEN -1
						 ELSE c.SportGroupID
					END, 
					CASE WHEN c.CustID IS NULL THEN '1000-01-01 00:00:00'
						 ELSE MAX(c.LastModifiedDate)
					END
			FROM CTS_DataCenter.CTSCustomerClassification AS c
				RIGHT JOIN Temp_CustomerList AS t ON t.CustomerID = c.CustID
			WHERE c.CustID IS NULL OR (c.CategoryID > 50 AND c.CategoryID < 300)
			GROUP BY t.CustomerID, c.CustID, c.SportGroupID;
			
            INSERT INTO Temp_LastestCustomerCategory(CustID, CategoryID, LastModifiedDate)
			SELECT t.CustomerID AS CustID, 
				   CASE WHEN t.SportGroupID = -1 THEN -1 
						ELSE MAX(c.CategoryID) 
				   END,
				   t.LastModifiedDate
			FROM Temp_LatestRecordOfCategory AS t
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS c 
					ON t.CustomerID = c.CustID AND t.SportGroupID = c.SportGroupID
			WHERE t.SportGroupID = -1 OR t.LastModifiedDate = c.LastModifiedDate
			GROUP BY  t.CustomerID, t.SportGroupID, t.LastModifiedDate;
    ELSE
		    INSERT INTO Temp_LatestRecordOfCategory(CustomerID, SportGroupID, LastModifiedDate)
			SELECT  t.CustomerID, 
					CASE WHEN c.CTSCustID IS NULL THEN -1
						 ELSE c.SportGroupID
					END, 
					CASE WHEN c.CTSCustID IS NULL THEN '1000-01-01 00:00:00'
						 ELSE MAX(c.LastModifiedDate)
					END
			FROM CTS_DataCenter.CTSCustomerClassification AS c
				RIGHT JOIN Temp_CustomerList AS t ON t.CustomerID = c.CTSCustID
			WHERE c.CTSCustID IS NULL OR (c.CategoryID > 50 AND c.CategoryID < 300)
			GROUP BY t.CustomerID, c.CTSCustID, c.SportGroupID;
			
            INSERT INTO Temp_LastestCustomerCategory(CustID, CategoryID, LastModifiedDate)
			SELECT cust.CustID, 
				   CASE WHEN t.SportGroupID = -1 THEN -1 
						ELSE MAX(c.CategoryID) 
				   END,
                   t.LastModifiedDate
			FROM Temp_LatestRecordOfCategory AS t
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS c 
					ON t.CustomerID = c.CTSCustID AND t.SportGroupID = c.SportGroupID
                INNER JOIN CTS_DataCenter.CTSCustomer AS cust on cust.CTSCustID = t.CustomerID
			WHERE t.SportGroupID = -1 OR t.LastModifiedDate = c.LastModifiedDate
			GROUP BY  cust.CustID, t.SportGroupID, t.LastModifiedDate;
    END IF;
    
    -- REMOVE SPECIAL CUSTOMER CLASS
    DELETE cc
    FROM Temp_LastestCustomerCategory AS cc
    INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = cc.CustID;

    -- MAPPING CategoryID to CustomerClass in mainDB
    INSERT INTO Temp_CustomerClass(CustID,CustomerClass,ScannedTime)
    SELECT DISTINCT lastest.CustID
		   ,  CASE  WHEN map.CategoryID IS NOT NULL THEN map.CustomerClass
                    WHEN lastest.CategoryID = -1 THEN -1
                    ELSE -99
			  END AS CustomerClass
			, lastest.LastModifiedDate 
    FROM Temp_LastestCustomerCategory AS lastest
    LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = lastest.CategoryID;
     
    -- GET LATEST CC
    SELECT DISTINCT CustId, CustomerClass, ScannedTime from Temp_CustomerClass WHERE CustomerClass <> -99;
  
END$$

DELIMITER ;