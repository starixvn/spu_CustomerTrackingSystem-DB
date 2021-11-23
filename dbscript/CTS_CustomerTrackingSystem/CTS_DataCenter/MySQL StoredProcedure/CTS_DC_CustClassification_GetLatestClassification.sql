use CTS_DataCenter;
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
			- 20211115@Irena.Vo: Re-priortize Robot and other PA categories  [Redmine ID: #164344]
        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetLatestClassification('1,2,1277,555555');
	*/ 
	DECLARE	CONST_GROUP_NORMAL 		INT DEFAULT 200;
    DECLARE	CONST_GROUP_PROBLEM 	INT DEFAULT 0;
    DECLARE	CONST_GROUP_ROBOTUSER 	INT DEFAULT 61;
    
    DECLARE lv_CurrentDateTime		DATETIME DEFAULT CURRENT_TIMESTAMP();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_InputCustomers;
    CREATE TEMPORARY TABLE 		Temp_InputCustomers (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedSpecialCC;
    CREATE TEMPORARY TABLE 		Temp_ExistedSpecialCC (
			CustID              BIGINT UNSIGNED PRIMARY KEY auto_increment        
		,	ScannedTime			DATETIME
        ,   CustomerClass       SMALLINT
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;
    CREATE TEMPORARY TABLE 		Temp_ProblemAccounts (
        	CustID			    BIGINT UNSIGNED
		,	ScannedTime			DATETIME
		,	CategoryID			SMALLINT
        ,	PRIMARY KEY 		PK(CustID,CategoryID)
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CategoryList;
    CREATE TEMPORARY TABLE 		Temp_CategoryList (
        	CustID			    BIGINT UNSIGNED
		,	ScannedTime			DATETIME
        ,	SportGroupID		SMALLINT
        ,	CategoryID			SMALLINT
		,	PRIMARY KEY 		PK(CustID,CategoryID)
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedLatestCategory;
    CREATE TEMPORARY TABLE 		Temp_ExistedLatestCategory (
        	CustID			    BIGINT UNSIGNED PRIMARY KEY 
		,	ScannedTime			DATETIME
		,	SportGroupID		SMALLINT
		,	CategoryID			SMALLINT
    );    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_LatestClassification;
    CREATE TEMPORARY TABLE 		Temp_LatestClassification (
        	CustID				BIGINT UNSIGNED PRIMARY KEY 
		,	ScannedTime			DATETIME
		,   CustomerClass       SMALLINT DEFAULT -1 -- -1: No data, <> -1: Has data
		,	CategoryGroup		SMALLINT DEFAULT -1 -- -1: No data, <> -1: Has data
    );    
    
    /* 1. Insert CustIDs */
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_InputCustomers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
    
	/* 2. Insert Existed Special CC */
	INSERT IGNORE INTO Temp_ExistedSpecialCC (CustID, ScannedTime, CustomerClass)
    SELECT c.CustID, sp.LastModifiedDate, sp.CustomerClass
    FROM Temp_InputCustomers AS c
		INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = c.CustID;
    
    /* 3. Get Problem Account */
	INSERT IGNORE INTO Temp_ProblemAccounts(CustID, ScannedTime, CategoryID)
    SELECT cate.CustID, cate.LastModifiedDate, cate.CategoryID
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_InputCustomers AS c ON c.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PROBLEM;
	
    /* 4. Insert Category List */
    /* 4.1 From Normal Category */
    INSERT IGNORE INTO Temp_CategoryList (CustID, ScannedTime, SportGroupID, CategoryID)
    SELECT cate.CustID, cate.LastModifiedDate, CONST_GROUP_NORMAL, cate.CategoryID
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_InputCustomers AS c ON c.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_NORMAL 
    WHERE NOT EXISTS (SELECT 1 FROM Temp_ProblemAccounts AS p WHERE p.CustID = cate.CustID);
    
    /* 4.2 From Problem Category */
    DELETE p
    FROM Temp_ProblemAccounts AS p
		INNER JOIN  CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = p.CategoryID AND cc.CategoryGroup = CONST_GROUP_ROBOTUSER; /** Clean Robot User. Only get PA */
    
	INSERT IGNORE INTO Temp_CategoryList (CustID, ScannedTime, SportGroupID, CategoryID)
    SELECT CustID, ScannedTime, CONST_GROUP_PROBLEM, CategoryID 
    FROM Temp_ProblemAccounts;
    
    /* 4.3 From Robot User */
    INSERT IGNORE INTO Temp_CategoryList (CustID, ScannedTime, SportGroupID, CategoryID)
    SELECT cate.CustID, cate.LastModifiedDate, CONST_GROUP_PROBLEM, cate.CategoryID
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_InputCustomers AS c ON c.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PROBLEM
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID AND cc.Categorygroup = CONST_GROUP_ROBOTUSER
    WHERE NOT EXISTS (SELECT 1 FROM Temp_ProblemAccounts AS p WHERE p.CustID = cate.CustID);
    
    /* 5. Insert Existed Lastest Category */
	INSERT IGNORE INTO Temp_ExistedLatestCategory(CustID, ScannedTime)
    SELECT CustID, MAX(ScannedTime) AS ScannedTime
    FROM Temp_CategoryList GROUP BY CustID;
    
    UPDATE Temp_ExistedLatestCategory AS ec,
		LATERAL (SELECT CustID, ScannedTime, SportGroupID, MAX(CategoryID) AS CategoryID 
				FROM Temp_CategoryList 
                GROUP BY CustID, ScannedTime, SportGroupID) AS c
	SET 	ec.SportGroupID = c.SportGroupID
		, 	ec.CategoryID = c.CategoryID
	WHERE ec.CustID = c.CustID AND ec.ScannedTime = c.ScannedTime;
    
    /* 6. Update ScannedTime to back Special CC */
    UPDATE Temp_ExistedSpecialCC AS es
		INNER JOIN Temp_ExistedLatestCategory AS ec ON ec.CustID = es.CustID
    SET es.ScannedTime = GREATEST(es.ScannedTime, ec.ScannedTime);
    
    DELETE ec
    FROM Temp_ExistedLatestCategory AS ec  
		INNER JOIN Temp_ExistedSpecialCC AS es ON es.CustID = ec.CustID;
    
    /* 7. Mapping case: Not existed category */
	INSERT IGNORE INTO Temp_LatestClassification (CustID, ScannedTime)
    SELECT temp.CustID, lv_CurrentDateTime AS ScannedTime
    FROM Temp_InputCustomers AS temp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID = temp.CustID AND cust.CustSubID = 0
	WHERE NOT EXISTS (SELECT 1 FROM Temp_ExistedSpecialCC AS es WHERE es.CustID = temp.CustID) /* Not existed Special CC */
		 AND NOT EXISTS (SELECT 1 FROM Temp_ExistedLatestCategory AS ec WHERE ec.CustID = temp.CustID); /* Not existed Category */
    
    /* 8. Mapping case: Existed Special CC */
    INSERT IGNORE INTO Temp_LatestClassification (CustID, ScannedTime, CustomerClass)
    SELECT es.CustID, es.ScannedTime,  es.CustomerClass 
    FROM Temp_ExistedSpecialCC AS es;
    
    /* 9. Mapping case: Existed Category */
	INSERT IGNORE INTO Temp_LatestClassification (CustID, ScannedTime, CustomerClass, CategoryGroup)
	SELECT 	ec.CustID, ec.ScannedTime,  map.CustomerClass
		,	CASE WHEN ec.SportGroupID = CONST_GROUP_NORMAL THEN -1 ELSE cc.CategoryGroup END AS CategoryGroup
	FROM Temp_ExistedLatestCategory AS ec 
		INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = ec.CategoryID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = ec.CategoryID;
    
    /* 10. Get Latest Classification to push */
    SELECT DISTINCT	c.CustID, c.CustomerClass, c.CategoryGroup AS Category, c.ScannedTime 
    FROM Temp_LatestClassification AS c;
END$$
DELIMITER ;