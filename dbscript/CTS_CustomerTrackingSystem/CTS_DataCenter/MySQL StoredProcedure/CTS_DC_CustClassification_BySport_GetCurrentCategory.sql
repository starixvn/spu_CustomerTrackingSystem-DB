/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_GetCurrentCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_GetCurrentCategory`(
		IN ip_CustSport     JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221110@Jonas.Huynh
		Task :		Get Existing Category (Normal BySport Flow)
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20230703@Jonas.Huynh [Redmine ID: #189875]: Created 
            
		Param's Explanation:
        
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_GetCurrentCategory('5941,5942,100,7681925');
	 */ 	
    DECLARE	CONST_GROUP_NORMAL 			INT DEFAULT 200;
	DECLARE	CATEGORY_GROUP_PROBATION	INT DEFAULT 206;
	DECLARE lv_CurrentTime 				DATETIME DEFAULT CURRENT_TIMESTAMP();
	DECLARE lv_CurrentDate 				DATE DEFAULT CURRENT_DATE();
    DECLARE lv_LastDayProbation 		DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 14 DAY); /*Up to 15 Last Day*/
       
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID				BIGINT UNSIGNED
		,	SportID				SMALLINT
        ,	PRIMARY KEY (CustID, SportID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;
    CREATE TEMPORARY TABLE Temp_CustCategory (
			CustID 				BIGINT UNSIGNED PRIMARY KEY
        ,	CategoryID			INT
        ,	CategoryGroup		SMALLINT
        ,	IsProbationLastDay	BIT DEFAULT(0)
		,	INDEX IX_Temp_CustCategory_CategoryGroup(CategoryGroup)
    );
    
    #1. Get valid customers
    IF ip_CustIDList IS NOT NULL THEN        
       
        INSERT INTO Temp_Cust(CustID, SportID)
		SELECT 	temp.CustID, temp.SportID
		FROM JSON_TABLE(ip_CustSport,
			 "$[*]" COLUMNS(
				CustID 		BIGINT UNSIGNED		PATH "$.CustId"
			, 	SportID		SMALLINT UNSIGNED	PATH "$.SportId"	
			 )) AS temp;       
		
        DELETE r
        FROM Temp_InputCust AS tmpIc
			LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpIc.CustID = cus.CustID AND cus.CustSubID = 0
		WHERE cus IS NULL;
        
    END IF;	
	
    #2. Get latest normal category
	INSERT INTO Temp_CustCategory(CustID, CategoryID, CategoryGroup)
	SELECT 	tmpIc.CustID
		,	cls.CategoryID
        ,	cc.CategoryGroup
	FROM Temp_Cust AS tmpIc
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS cls ON cls.CustID = tmpIc.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID
	WHERE cls.SportGroupID = CONST_GROUP_NORMAL;
    
    #3. Get Probation info
    UPDATE Temp_CustCategory AS tmpCc
		INNER JOIN CTS_DataCenter.ProbationAccountMonitor_BySport AS pro ON pro.CustID = tmpCc.CustID
	SET IsProbationLastDay = (CASE WHEN pro.CreatedDate <= lv_LastDayProbation THEN 1 /*Up to Smart, Risky*/ ELSE 0 END)
	WHERE tmpCc.CategoryGroup = CATEGORY_GROUP_PROBATION;
    
    #4. Return data set
	SELECT	DISTINCT tmpCust.CustID
		,	CASE
				WHEN tmpCc.CategoryGroup IS NULL THEN 0 ELSE tmpCc.CategoryGroup
			END AS CategoryID
        ,	tmpCc.IsProbationLastDay AS IsProbationLastDay
	FROM Temp_Cust AS tmpCust
		LEFT JOIN Temp_CustCategory AS tmpCc ON tmpCc.CustID = tmpCust.CustID;
END$$
DELIMITER ;