/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Normal_GetCurrentCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Normal_GetCurrentCategory`(
		IN ip_CustIDList	TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221110@Casey.Huynh	
		Task :		Get Existing Category (Normal Flow)
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Casey.Huynh [Redmine ID: #178022]: Created 
			- 20230120@Long.Luu [Redmine ID: #182997]: Support special case for Inactive (return CategoryID instead of CategoryGroup) 
            - 20230427@Jonas.Huynh [Redmine ID: #186678]: Renovate normal classification
            - 20230605@Jonas.Huynh [Redmine ID: #186684]: Renovate normal classification (phase2)
            - 20230915@Jonas.Huynh [Redmine ID: #193050]: HF Wrong Inactive Category for New and Realtime flow exclude S/R/P with not latest category 
            
		Param's Explanation:
        
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_Normal_GetCurrentCategory('5941,5942,100,7681925');
	 */ 	
    DECLARE	CONST_GROUP_NORMAL 			INT DEFAULT 200;
    DECLARE	CONST_GROUP_INACTIVE 		INT DEFAULT 1000;
	DECLARE lv_CurrentTime 				DATETIME DEFAULT CURRENT_TIMESTAMP();
	DECLARE lv_CurrentDate 				DATE DEFAULT CURRENT_DATE();
    
    DECLARE	CATEGORY_GROUP_PROBATION	INT DEFAULT 206;
    DECLARE lv_LastDayProbation 		DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 14 DAY); /*Up to 15 Last Day*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputCust;
    CREATE TEMPORARY TABLE Temp_InputCust(
			CustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID 			BIGINT UNSIGNED PRIMARY KEY
		,	CreatedDate		DATETIME
        ,	InsertedTime    DATETIME
        ,   IsReactived		BIT DEFAULT(0)
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

		SET @sql = CONCAT("INSERT INTO Temp_InputCust(CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
		
        INSERT INTO Temp_Cust(CustID, CreatedDate, InsertedTime)
		SELECT tmpIc.CustID, cus.CreatedDate, cus.InsertedTime
        FROM Temp_InputCust AS tmpIc
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpIc.CustID = cus.CustID AND cus.CustSubID = 0
			LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin ON pin.CTSCustID = cus.CTSCustID
		WHERE pin.CTSCustID IS NULL;
        
		UPDATE Temp_Cust AS tmpCust
		INNER JOIN CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arc ON arc.CustID = tmpCust.CustID AND arc.CustSubID = 0
		SET tmpCust.IsReactived = 1
        WHERE arc.ProcessedDate IS NOT NULL;
	        
    END IF;	
	
    #2. Get latest normal category
	INSERT INTO Temp_CustCategory(CustID, CategoryID, CategoryGroup)
	SELECT 	tmpIc.CustID
		,	cls.CategoryID
        ,	cc.CategoryGroup
	FROM Temp_Cust AS tmpIc
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls  ON cls.CustID = tmpIc.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID
	WHERE cls.SportGroupID = CONST_GROUP_NORMAL;

    INSERT INTO Temp_CustCategory(CustID, CategoryID, CategoryGroup)
	SELECT 	tmpIc.CustID
		, 	cls.CategoryID
		,	cc.CategoryGroup
	FROM Temp_Cust AS tmpIc
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationOldCategory  AS cls ON cls.CustID = tmpIc.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID
	WHERE cls.SportGroupID = CONST_GROUP_NORMAL;
    
    #3. Get Probation info
    UPDATE Temp_CustCategory AS tmpCc
		INNER JOIN CTS_DataCenter.ProbationAccountMonitor AS pro ON pro.CustID = tmpCc.CustID
	SET IsProbationLastDay = (CASE WHEN pro.CreatedDate <= lv_LastDayProbation THEN 1 /*Up to Smart, Risky*/ ELSE 0 END)
	WHERE tmpCc.CategoryGroup = CATEGORY_GROUP_PROBATION;
           
    #4. Return data set
	SELECT	DISTINCT tmpCust.CustID
		,	CASE
				WHEN tmpCc.CategoryGroup IS NULL THEN 0
                WHEN tmpCc.CategoryGroup = CONST_GROUP_INACTIVE THEN tmpCc.CategoryID
                ELSE tmpCc.CategoryGroup
			END AS CategoryID
		,   CASE 
				WHEN tmpCust.CreatedDate >= DATE_SUB(lv_CurrentTime, INTERVAL 29 DAY) THEN 1 
                WHEN tmpCust.InsertedTime >= DATE_SUB(lv_CurrentTime, INTERVAL 29 DAY) AND tmpCust.IsReactived = 1 THEN 1 
                ELSE 0 
			END AS IsNewCreated
        ,	tmpCc.IsProbationLastDay AS IsProbationLastDay
	FROM Temp_Cust AS tmpCust
		LEFT JOIN Temp_CustCategory AS tmpCc ON tmpCc.CustID = tmpCust.CustID;
END$$
DELIMITER ;