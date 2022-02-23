/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_GetDangerLevel`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_GetDangerLevel`(
		IN ip_CustIDs 	TEXT
    ,	IN ip_TypeID 	SMALLINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210401@Irena.Vo
		Task:		Get Danger Level for customers
		DB:			CTS_DataCenter 
		Original:
		Revisions:
			- 20210401@Irena.Vo: Created [Redmine ID: #152249]
			- 20210524@Aries.Nguyen: Enhance performance  [Redmine ID: #155693]
			- 20210625@Long.Luu: Refactor  [Redmine ID: #157203]
			- 20211115@Irena.Vo: Re-priortize Robot and other PA categories  [Redmine ID: #164344]
			- 20211116@Casey.Huynh: Sync Robot User Categories to Dangerous Setting [Redmine ID: #161665]
            - 20220210@Irena.Vo: Adjust logic for Update ABI Danger Level [#167746]
		Param's Explanation (filtered by):
			- ip_CustIDs ; ip_TypeID: 1(Original) / 2(ABI) / 3(Other)
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetDangerLevel('36266996,27852979,2324948',1);
	*/
	DECLARE	CONST_GROUP_PROBLEM 	INT DEFAULT 0;
    DECLARE	CONST_GROUP_ROBOTUSER 	INT DEFAULT 61;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputCustomers;
    CREATE TEMPORARY TABLE Temp_InputCustomers (
			CustID 				BIGINT UNSIGNED PRIMARY KEY
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;
    CREATE TEMPORARY TABLE 		Temp_ProblemAccounts (
        	CustID			    BIGINT UNSIGNED
		,	ScannedTime			DATETIME
        ,	CategoryID			SMALLINT
        ,	PRIMARY KEY 		PK(CustID,CategoryID)
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDangerLevels;
    CREATE TEMPORARY TABLE 		Temp_CustDangerLevels (
        	CustID			    BIGINT UNSIGNED
		,	ScannedTime			DATETIME
        ,	SportGroupID		SMALLINT
        ,	CategoryID			SMALLINT
        ,	PRIMARY KEY 		PK(CustID,CategoryID)
    ); 
	
    /* Insert CustIDs */
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_InputCustomers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
    
	/*  Get Problem Account List */
	INSERT IGNORE INTO Temp_ProblemAccounts(CustID, ScannedTime, CategoryID)
    SELECT cate.CustID, cate.LastModifiedDate, cate.CategoryID
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_InputCustomers AS c ON c.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PROBLEM;
    
     /* Get Danger Level to push */
    IF (ip_TypeID = 1) THEN -- Original Danger
		INSERT IGNORE INTO Temp_CustDangerLevels (CustID, ScannedTime, SportGroupID, CategoryID)
        SELECT cate.CustID, cate.LastModifiedDate, cate.SportGroupID, cate.CategoryID
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_InputCustomers AS c ON c.CustID = cate.CustID
			INNER JOIN CTS_DataCenter.CategoryToDangerLevel AS d ON d.CategoryID = cate.CategoryID AND d.TypeID = 1
		WHERE NOT EXISTS (SELECT 1 FROM Temp_ProblemAccounts AS p WHERE p.CustID = cate.CustID);
    
        SELECT DISTINCT his.CustID, his.LastModifiedDate AS ScannedTime, his.TargetDangerLevel1 AS DangerLevel
        FROM CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_CustDangerLevels AS cd ON cd.CustID = his.CustID AND cd.SportGroupID = his.SportGroupID AND cd.CategoryID = his.CategoryID AND cd.ScannedTime = his.LastModifiedDate 
		WHERE his.TargetDangerLevel1 IS NOT NULL AND his.ToCategoryID <> IFNULL(his.FromCategoryID, 0);
	END IF;
    
    IF (ip_TypeID = 2) THEN -- ABI Danger
		DELETE p
        FROM Temp_ProblemAccounts AS p
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = p.CategoryID AND cc.CategoryGroup = CONST_GROUP_ROBOTUSER;
    
		/*ABI for PA*/
        INSERT IGNORE INTO Temp_CustDangerLevels(CustID, ScannedTime)
		SELECT c.CustID, MAX(c.ScannedTime) AS ScannedTime
		FROM Temp_ProblemAccounts AS c
		GROUP BY c.CustID;
		
		UPDATE Temp_CustDangerLevels AS ec,
			LATERAL (SELECT CustID, ScannedTime, MAX(CategoryID) AS CategoryID 
					FROM Temp_ProblemAccounts 
					GROUP BY CustID, ScannedTime) AS c
		SET 	ec.SportGroupID = CONST_GROUP_PROBLEM
			, 	ec.CategoryID = c.CategoryID
		WHERE ec.CustID = c.CustID AND ec.ScannedTime = c.ScannedTime;
        
	    DELETE c
        FROM Temp_CustDangerLevels AS c
        WHERE NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CategoryToDangerLevel AS d WHERE d.CategoryID = c.CategoryID AND d.TypeID = 2); /*Ignore PA have not ABI Danger Setting*/
    
        /*ABI for Robot User*/
		INSERT IGNORE INTO Temp_CustDangerLevels (CustID, ScannedTime, SportGroupID, CategoryID)
        SELECT cate.CustID, cate.LastModifiedDate, cate.SportGroupID, cate.CategoryID
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID AND cc.CategoryGroup = CONST_GROUP_ROBOTUSER
			INNER JOIN Temp_InputCustomers AS c ON c.CustID = cate.CustID
			INNER JOIN CTS_DataCenter.CategoryToDangerLevel AS d ON d.CategoryID = cate.CategoryID AND d.TypeID = 2
		WHERE NOT EXISTS (SELECT 1 FROM Temp_ProblemAccounts AS p WHERE p.CustID = cate.CustID);
        
        SELECT DISTINCT his.CustID, his.LastModifiedDate AS ScannedTime, his.TargetDangerLevel1 AS DangerLevel
        FROM CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_CustDangerLevels AS cd ON cd.CustID = his.CustID AND cd.SportGroupID = his.SportGroupID AND cd.CategoryID = his.CategoryID AND cd.ScannedTime = his.LastModifiedDate 
		WHERE his.TargetDangerLevel1 IS NOT NULL;
	END IF;
END$$
DELIMITER ;