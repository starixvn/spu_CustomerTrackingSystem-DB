/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_GetCurrentCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_GetCurrentCategory`(
		IN ip_CustSport     JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230703@Jonas.Huynh
		Task :		Get Existing Category (Normal BySport Flow)
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20230703@Jonas.Huynh: Created [Redmine ID: #189875]
			- 20240318@Jonas.Huynh: Config Probation Days [Redmine ID: #201359]
            
		Param's Explanation:
        
		Example:
			- call CTS_DataCenter.CTS_DC_CustClassification_BySport_GetCurrentCategory('[{"CustId": 5941, "SportGroup": 10}]');
            
	 */ 	
    DECLARE	CONST_GROUP_NORMAL 			INT DEFAULT 200;
	DECLARE	CATEGORY_GROUP_PROBATION	INT DEFAULT 206;
	DECLARE lv_CurrentTime 				DATETIME DEFAULT CURRENT_TIMESTAMP();
	DECLARE lv_CurrentDate 				DATE DEFAULT CURRENT_DATE();
       
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID				BIGINT UNSIGNED
		,	SportGroup			SMALLINT
        ,	PRIMARY KEY (CustID, SportGroup)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InvalidCust;
    CREATE TEMPORARY TABLE Temp_InvalidCust(
			CustID				BIGINT UNSIGNED
        ,	PRIMARY KEY (CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;
    CREATE TEMPORARY TABLE Temp_CustCategory (
			CustID 				BIGINT UNSIGNED
        ,	SportGroup			SMALLINT
        ,	CategoryID			INT
        ,	CategoryGroup		SMALLINT
        ,	IsProbationLastDay	BIT DEFAULT(0)
        ,   PRIMARY KEY (CustID, SportGroup)
		,	INDEX IX_Temp_CustCategory_CategoryGroup(CategoryGroup)
    );
    
    #1. Get valid customers
    IF ip_CustSport IS NOT NULL THEN        
       
        INSERT INTO Temp_Cust(CustID, SportGroup)
		SELECT 	temp.CustID, temp.SportGroup
		FROM JSON_TABLE(ip_CustSport,
			 "$[*]" COLUMNS(
				CustID 		BIGINT UNSIGNED		PATH "$.CustId"
			, 	SportGroup	SMALLINT UNSIGNED	PATH "$.SportGroup"	
			 )) AS temp;
		
		INSERT INTO Temp_InvalidCust(CustID)
		SELECT tmp.CustID
        FROM (SELECT DISTINCT CustID FROM Temp_Cust) AS tmp
			LEFT JOIN CTS_DataCenter.CTSCustomer AS c ON c.CustID = tmp.CustID AND c.CustSubID = 0
        WHERE c.CustID IS NULL;
        
		DELETE c
		FROM Temp_Cust AS c
			INNER JOIN Temp_InvalidCust AS r ON r.CustID = c.CustID;

	END IF;	

	#2. Get latest normal category
	INSERT INTO Temp_CustCategory(CustID, SportGroup, CategoryID, CategoryGroup)
	SELECT 	tmpIc.CustID
		,	tmpIc.SportGroup
		,	cls.CategoryID
		,	cc.CategoryGroup
	FROM Temp_Cust AS tmpIc
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS cls ON cls.CustID = tmpIc.CustID AND cls.SportID = tmpIc.SportGroup
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID;
	
	#3. Get Probation info    
	UPDATE Temp_CustCategory AS tmpCc
		INNER JOIN CTS_DataCenter.ProbationAccountMonitor_BySport AS pro ON pro.CustID = tmpCc.CustID
        INNER JOIN CTS_DataCenter.StaticList AS s ON s.ListID = 23 AND s.ItemID = tmpCc.SportGroup 
	SET IsProbationLastDay = (CASE WHEN pro.CreatedDate <= DATE_SUB(lv_CurrentDate, INTERVAL CAST(s.ItemValue AS UNSIGNED) DAY) THEN 1 /*Up to Smart, Risky*/ ELSE 0 END)
	WHERE tmpCc.CategoryGroup = CATEGORY_GROUP_PROBATION;
    
    #4. Return data set
	SELECT	DISTINCT tmpCust.CustID
		,	tmpCust.SportGroup
		,	CASE WHEN tmpCc.CategoryGroup IS NULL THEN 0 ELSE tmpCc.CategoryGroup END AS CategoryID
        ,	CASE WHEN tmpCc.IsProbationLastDay IS NULL THEN 0 ELSE tmpCc.IsProbationLastDay END AS IsProbationLastDay
	FROM Temp_Cust AS tmpCust
		LEFT JOIN Temp_CustCategory AS tmpCc ON tmpCc.CustID = tmpCust.CustID AND tmpCc.SportGroup = tmpCust.SportGroup;
END$$
DELIMITER ;