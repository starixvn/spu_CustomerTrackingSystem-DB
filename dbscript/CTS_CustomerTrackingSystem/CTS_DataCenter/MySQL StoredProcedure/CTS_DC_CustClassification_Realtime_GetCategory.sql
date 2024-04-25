/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Realtime_GetCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_Realtime_GetCategory`(
	  IN ip_CustIDs      	TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20200612@Casey.Huynh
		Task:  Return the auto tag customer list by ip_category
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20200701@Casey.Huynh: Chagne Flow and Store more Info [RedmineID: #135324]
            - 20200826@Casey.Huynh: Add Trace Performance [RedmineID: #137693]
            - 202012121@Irena.Vo: Enhance logic ignore Pin category & Probation List  [RedmineID: #145951]
            - 20210510@Aries.Nguyen: Remove insert log zzTracePerformance [Redmine ID: #154792]
			- 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [Redmine ID: 152965]
            - 20210608@Casey.Huynh: Return Category Group AND Hardcode RealTime CategoryGroup List [Redmine ID: 156465]
			- 20210722@Irena.Vo: Refactor SP [Redmine ID: 157203]  
            - 20220826@Long.Luu: Fix issue leaving blank for should-not-be-classified customer [Redmine ID: 176782]  
            - 20221007@Harvey.Nguyen: Return CurrentCategoryID [Redmine ID: #178022]
			- 20230120@Long.Luu: Support special case for Inactive (return CategoryID instead of CategoryGroup)  [Redmine ID: #182997]
            - 20230120@Long.Luu: Support special case for Inactive (return CategoryID instead of CategoryGroup)  [Redmine ID: #182997]
            - 20230313@Jonas.Huynh: Get PA category for daily scan PA [Redmine ID: #184772]
            - 20230915@Jonas.Huynh: HF Wrong Inactive Category for New and Realtime flow exclude S/R/P with not latest category [Redmine ID: #193050]
            - 20240425@Thomas.Nguyen: Classify Initial Group Betting - Add SportGroupID = 150 [Redmine ID: #200854]

		Param's Explanation (filtered by):    
			CALL CTS_DC_CustClassification_Realtime_GetCategory('761925')
	*/  
    DECLARE	CONST_GROUP_NORMAL 			INT DEFAULT 200;
	DECLARE	CONST_GROUP_PA 				INT DEFAULT 0;
	DECLARE	CONST_GROUP_POTENTIALPA 	INT DEFAULT 150;

    DECLARE	CONST_CATEGORY_NEWMEMBER 	INT DEFAULT 201;
	DECLARE	CONST_CATEGORY_NORMALMEMBER INT DEFAULT 202;
	DECLARE	CONST_CATEGORY_GOODMEMBER	INT DEFAULT 205;
    DECLARE CONST_CATEGORY_INACTIVE		INT DEFAULT 1000;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Customers;
	CREATE TEMPORARY TABLE Temp_Customers(
			CustID					BIGINT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
	CREATE TEMPORARY TABLE Temp_CustomerCategory(
			CustID					BIGINT UNSIGNED NOT NULL
		,   CTSCustID				BIGINT UNSIGNED NOT NULL
		,	SportGroupID			INT
        ,	CategoryID 				INT
        ,	CategoryGroup 			SMALLINT UNSIGNED
        ,	RelevantCategoryID 		SMALLINT UNSIGNED
        ,	IsOldCategory	 		BOOLEAN DEFAULT FALSE
        , 	INDEX IX_Temp_CustomerCategory_CustID(CustID)
	);      
	
    INSERT INTO Temp_Customers (CustID)
    SELECT DISTINCT temp.CustID
    FROM JSON_TABLE(CONCAT('[',ip_CustIDs,']'),
			'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (
				CustID 		BIGINT UNSIGNED PATH '$'
			))) AS temp;
	
    -- #1: Get customer category
	INSERT INTO Temp_CustomerCategory(CustID, CTSCustID, SportGroupID, CategoryID, CategoryGroup, RelevantCategoryID, IsOldCategory)
	SELECT 		temp.CustID
			,	cate.CTSCustID
			, 	cate.SportGroupID
            ,	cate.CategoryID
            ,	cc.CategoryGroup
            ,	cc.RelevantCategoryID
            ,	FALSE
	FROM Temp_Customers AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE cate.SportGroupID in (CONST_GROUP_NORMAL, CONST_GROUP_PA, CONST_GROUP_POTENTIALPA);

	INSERT INTO Temp_CustomerCategory(CustID, CTSCustID, SportGroupID, CategoryID, CategoryGroup, RelevantCategoryID, IsOldCategory)
	SELECT 		temp.CustID
			,	cate.CTSCustID
			, 	cate.SportGroupID
			, 	cate.CategoryID
            ,	cc.CategoryGroup
            ,	cc.RelevantCategoryID
            , 	TRUE
	FROM Temp_Customers AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationOldCategory AS cate ON cate.CustID = temp.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID;
	
    -- #2: Return customer category for realtime classification
    SELECT 	DISTINCT temp.CustID AS CustID
	FROM Temp_Customers AS temp
		LEFT JOIN Temp_CustomerCategory AS cate ON cate.CustID = temp.CustID
        LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin ON pin.CTSCustID = cate.CTSCustID
	WHERE  pin.CTSCustID IS NULL
		AND (cate.CategoryID IS NULL OR (cate.CategoryID IS NOT NULL AND cate.SportGroupID = CONST_GROUP_NORMAL));
	
    -- #3: Return customer with problem category for PA daily scan
	SELECT DISTINCT CustID
    FROM Temp_CustomerCategory 
    WHERE SportGroupID IN (CONST_GROUP_PA, CONST_GROUP_POTENTIALPA)
		AND RelevantCategoryID IS NOT NULL
        AND IsOldCategory = FALSE;
	
END$$
DELIMITER ;