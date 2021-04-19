/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_GetLatestClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_GetLatestClassification`(
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
        ,	CategoryID			SMALLINT
        ,	ScannedTime			DATETIME
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedLastestCategory;
    CREATE TEMPORARY TABLE 		Temp_ExistedLastestCategory (
        	CustID			    BIGINT UNSIGNED PRIMARY KEY 
		,	CategoryID			SMALLINT
		,	ScannedTime			DATETIME
    );    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClass;
    CREATE TEMPORARY TABLE 		Temp_CustomerClass (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,   CustomerClass       SMALLINT	
        ,	Category			TEXT
        ,	ScannedTime			DATETIME
    );    
    
    -- Insert CustIDs
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Customers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
    
	/* Insert Existed Special CC */
	INSERT INTO Temp_ExistedSpecialCC (CustID, CustomerClass, ScannedTime)
    SELECT 		c.CustID,	sp.CustomerClass, sp.LastModifiedDate
    FROM 		Temp_Customers AS c
		INNER JOIN 	CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = c.CustID;
    
    /* Insert Existed Lastest Category */
	INSERT INTO Temp_ExistedLastestCategory(CustID, ScannedTime, CategoryID)
    SELECT 		t1.CustID, t2.ScannedTime, MAX(t1.CategoryID)
    FROM 		CTS_DataCenter.CTSCustomerClassification AS t1,
    LATERAL (	SELECT cate.CustID, MAX(cate.LastModifiedDate) AS ScannedTime 
				FROM CTS_DataCenter.CTSCustomerClassification AS cate 
					INNER JOIN Temp_Customers AS c ON c.CustID = cate.CustID AND cate.SportGroupID IN (0,200)
				GROUP BY cate.CustID	) AS t2
	WHERE 		t1.CustID = t2.CustID  AND t1.SportGroupID IN (0,200) AND t1.LastModifiedDate = t2.ScannedTime 
    GROUP BY 	t1.CustID, t2.ScannedTime;
    
    /* Update ScannedTime & CategoryGroup for Special CC */
    UPDATE    	Temp_ExistedSpecialCC AS es
		INNER JOIN 	Temp_ExistedLastestCategory AS ec ON ec.CustID = es.CustID
    SET 	   		es.ScannedTime = GREATEST(es.ScannedTime,ec.ScannedTime)
				,	es.CategoryID = ec.CategoryID;
    
    DELETE 		ec
    FROM 		Temp_ExistedLastestCategory AS ec 
    INNER JOIN  Temp_ExistedSpecialCC AS es ON es.CustID = ec.CustID;
    
    /* Mapping Customer Class */
    INSERT INTO Temp_CustomerClass (CustID, CustomerClass, Category, ScannedTime)
    SELECT a.CustID, a.CustomerClass, cc.CategoryGroup, a.ScannedTime
	FROM (	SELECT es.CustID,  es.CustomerClass, es.CategoryID, es.ScannedTime
			FROM Temp_ExistedSpecialCC AS es
			UNION ALL
			SELECT ec.CustID,  map.CustomerClass, ec.CategoryID, ec.ScannedTime
			FROM Temp_ExistedLastestCategory AS ec 
				INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = ec.CategoryID) AS a
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = a.CategoryID;
    
    /* Insert Customer Class = -1 */
	INSERT INTO Temp_CustomerClass (CustID, CustomerClass, Category, ScannedTime)
    SELECT 		temp.CustID, -1	AS CustomerClass, -1 AS Category, CURRENT_TIME()
    FROM 		Temp_Customers AS temp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0 -- Existed CustID
		LEFT JOIN Temp_ExistedSpecialCC AS es ON es.CustID = temp.CustID -- Not existed Special CC
		LEFT JOIN Temp_ExistedLastestCategory AS ec ON ec.CustID = temp.CustID -- Not existed Category
    WHERE 		es.CustID IS NULL AND ec.CustID IS NULL;
    
    /* Get Lastest Customer Class to sync in mainDB */
    SELECT DISTINCT	c.CustID, c.CustomerClass, c.Category, c.ScannedTime FROM Temp_CustomerClass AS c;
END$$
DELIMITER ;