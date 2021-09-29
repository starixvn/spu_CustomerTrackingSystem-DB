/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_GetLatestClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetLatestClassification`(
	IN ip_CustIDs TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201214@Irena.Vo	
		Task :		Get Customers' latest Customer Class 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201214@Irena.Vo: Created [RedmineID: #145951]
            - 20210413@Irena.Vo: Get Reason. Ignore sub account for case CC = -1 [RedmineID: #141931]
			- 20210419@Irena.Vo: Get Category more [RedmineID: #153617]
			- 20210625@Long.Luu: Refactor  [Redmine ID: #157203]
			- 20210811@Irena.Vo: Fix issue get PA Category incorrectly [Redmine ID: 160071]
            - 20210910@Irena.Vo: Additional IGNORE for insert table Temp_CustomerClass [Redmine ID: 161232]
		Param's Explanation:
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetLatestClassification('1,2,1277,555555');
	*/ 
    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
    CREATE TEMPORARY TABLE 		Temp_Customers (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedSpecialCC;
    CREATE TEMPORARY TABLE 		Temp_ExistedSpecialCC (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
        ,   CustomerClass       SMALLINT
        ,	ScannedTime			DATETIME
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedLastestCategory;
    CREATE TEMPORARY TABLE 		Temp_ExistedLastestCategory (
        	CustID			    BIGINT UNSIGNED PRIMARY KEY 
		,	CategoryID			SMALLINT
        ,	SportGroupID		SMALLINT
		,	ScannedTime			DATETIME
    );    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClass;
    CREATE TEMPORARY TABLE 		Temp_CustomerClass (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,   CustomerClass       SMALLINT	
        ,	CategoryGroup		SMALLINT
        ,	ScannedTime			DATETIME
    );    
    
    /* 1. Insert CustIDs */
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
    
	/* 2. Insert Existed Special CC */
	INSERT INTO Temp_ExistedSpecialCC (CustID, ScannedTime, CustomerClass)
    SELECT c.CustID, sp.LastModifiedDate, sp.CustomerClass
    FROM Temp_Customers AS c
		INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = c.CustID;
    
    /* 3. Insert Existed Lastest Category */
	INSERT IGNORE INTO Temp_ExistedLastestCategory(CustID, ScannedTime, SportGroupID, CategoryID)
    SELECT t1.CustID, t2.ScannedTime, t1.SportGroupID, MAX(t1.CategoryID) AS CategoryID
    FROM CTS_DataCenter.CTSCustomerClassification AS t1,
		LATERAL (SELECT cate.CustID, MAX(cate.LastModifiedDate) AS ScannedTime 
				FROM CTS_DataCenter.CTSCustomerClassification AS cate 
					INNER JOIN Temp_Customers AS c ON c.CustID = cate.CustID
				GROUP BY cate.CustID) AS t2
	WHERE t1.CustID = t2.CustID AND t1.LastModifiedDate = t2.ScannedTime
    GROUP BY t1.CustID, t2.ScannedTime, t1.SportGroupID;
    
    /* 4. Update ScannedTime to back Special CC */
    UPDATE Temp_ExistedSpecialCC AS es
		INNER JOIN Temp_ExistedLastestCategory AS ec ON ec.CustID = es.CustID
    SET 	es.ScannedTime = GREATEST(es.ScannedTime, ec.ScannedTime);
    
    DELETE ec
    FROM Temp_ExistedLastestCategory AS ec 
		INNER JOIN Temp_ExistedSpecialCC AS es ON es.CustID = ec.CustID;
    
    /* 5. Mapping case: Not existed category */
	INSERT IGNORE INTO Temp_CustomerClass (CustID, CustomerClass, ScannedTime, CategoryGroup)
    SELECT temp.CustID, -1	AS CustomerClass, CURRENT_TIME() AS ScannedTime, -1 AS CategoryGroup
    FROM Temp_Customers AS temp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
		LEFT JOIN Temp_ExistedSpecialCC AS es ON es.CustID = temp.CustID /* Not existed Special CC */
		LEFT JOIN Temp_ExistedLastestCategory AS ec ON ec.CustID = temp.CustID /* Not existed Category */
    WHERE es.CustID IS NULL AND ec.CustID IS NULL;
    
    /* 6. Mapping case: Existed Special CC */
    INSERT IGNORE INTO Temp_CustomerClass (CustID, CustomerClass, ScannedTime, CategoryGroup)
    SELECT 	es.CustID,  es.CustomerClass, es.ScannedTime, -1 AS CategoryGroup
	FROM Temp_ExistedSpecialCC AS es;
    
    /* 7. Mapping case: Existed Category */
	INSERT IGNORE INTO Temp_CustomerClass (CustID, CustomerClass, ScannedTime, CategoryGroup)
	SELECT 	ec.CustID,  map.CustomerClass, ec.ScannedTime
		,	CASE WHEN ec.SportGroupID = 200  THEN -1 ELSE cc.CategoryGroup END AS CategoryGroup
	FROM Temp_ExistedLastestCategory AS ec 
		INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = ec.CategoryID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ec.CategoryID;
    
    /* 8. Get Latest Customer Class & Category */
    SELECT DISTINCT	c.CustID, c.CustomerClass, c.CategoryGroup AS Category, c.ScannedTime FROM Temp_CustomerClass AS c;
END$$
DELIMITER ;