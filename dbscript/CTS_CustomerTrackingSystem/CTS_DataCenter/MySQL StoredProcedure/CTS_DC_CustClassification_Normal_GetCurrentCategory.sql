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
            
		Param's Explanation:
        
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_Normal_GetCurrentCategory('5941,5942,100,7681925');
	 */ 	
    DECLARE	CONST_GROUP_NORMAL 		INT DEFAULT 200;
    DECLARE	CONST_GROUP_INACTIVE 	INT DEFAULT 1000;
	DECLARE lv_CurrentTime 			DATETIME DEFAULT CURRENT_TIMESTAMP();
    
    DROP TEMPORARY TABLE IF EXISTS Temp_InputCust;
    CREATE TEMPORARY TABLE Temp_InputCust(
			CustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID 			BIGINT UNSIGNED PRIMARY KEY
		,	CreatedDate		DATETIME
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;
    CREATE TEMPORARY TABLE Temp_CustCategory (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
        ,	CTSCustID 		BIGINT UNSIGNED
        ,	CategoryID		INT
        ,	SportGroupID	INT
        ,	CreatedDate		DATETIME
	
		,	INDEX IX_Temp_CustCategory_CTSCustID(CTSCustID)
    );
    
    IF ip_CustIDList IS NOT NULL THEN        

		SET @sql = CONCAT("INSERT INTO Temp_InputCust(CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
		
        INSERT INTO Temp_Cust(CustID, CreatedDate)
		SELECT tmpIc.CustID, cus.CreatedDate
        FROM Temp_InputCust AS tmpIc
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpIc.CustID = cus.CustID AND cus.CustSubID = 0
			LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin ON pin.CTSCustID = cus.CTSCustID
		WHERE pin.CTSCustID IS NULL;

    END IF;	
	
    #===========GET LASTEST EXISTING CATEGORY====================================
	INSERT INTO Temp_CustCategory(CustID, CategoryID, SportGroupID, CreatedDate)
	SELECT 	tmpIc.CustID
		,	cls.CategoryID
        ,	cls.SportGroupID
        ,   tmIc.CreatedDate
	FROM Temp_Cust AS tmpIc
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls  ON cls.CustID = tmpIc.CustID
	WHERE cls.SportGroupID = CONST_GROUP_NORMAL;

    INSERT IGNORE INTO Temp_CustCategory(CustID, CategoryID, SportGroupID, CreatedDate)
	SELECT 	tmpIc.CustID
		, 	IFNULL(cls.CategoryID, 0) 
        ,	cls.SportGroupID
        ,	tmIc.CreatedDate
	FROM Temp_Cust AS tmpIc
		LEFT JOIN CTS_DataCenter.CTSCustomerClassificationOldCategory  AS cls ON cls.CustID = tmpIc.CustID
	ORDER BY cls.CreatedDate DESC;

    #=========RETURN CUST IF LASTEST Category is Normal OR Not Existing any Category
	SELECT	DISTINCT tmpCc.CustID
		,	CASE
				WHEN cc.CategoryGroup IS NULL THEN 0
                WHEN cc.CategoryGroup = CONST_GROUP_INACTIVE THEN cc.CategoryID
                ELSE cc.CategoryGroup
			END AS CategoryID
		,   CASE WHEN tmpCc.CreatedDate >= DATE_SUB(lv_CurrentTime, INTERVAL 29 DAY) THEN 1 ELSE 0 END AS IsNewCreated
	FROM Temp_CustCategory AS tmpCc
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON tmpCc.CategoryID = cc.CategoryID
    WHERE tmpCc.SportGroupID = CONST_GROUP_NORMAL OR cc.CategoryID IS NULL;
END$$
DELIMITER ;