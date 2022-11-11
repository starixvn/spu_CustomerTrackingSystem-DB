/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Normal_GetExisting`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Normal_GetExisting`(
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
           
		Param's Explanation:
        
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_Normal_GetExisting('5941,5942,100,7681925');
	 */ 	
    DECLARE	CONST_GROUP_NORMAL 	INT DEFAULT 200;
	
    DROP TEMPORARY TABLE IF EXISTS Temp_InputCust;
    CREATE TEMPORARY TABLE Temp_InputCust(
			CustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;
    CREATE TEMPORARY TABLE Temp_CustCategory (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
        ,	CTSCustID 		BIGINT UNSIGNED
        ,	CategoryID		INT
        ,	SportGroupID	INT 	
	
		,	INDEX IX_Temp_CustCategory_CTSCustID(CTSCustID)
    );
    
    IF ip_CustIDList IS NOT NULL THEN        

		SET @sql = CONCAT("INSERT INTO Temp_InputCust(CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
		
        INSERT INTO Temp_Cust(CustID)
		SELECT tmpIc.CustID 
        FROM Temp_InputCust AS tmpIc
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpIc.CustID = cus.CustID AND cus.CustSubID = 0
			LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin ON pin.CTSCustID = cus.CTSCustID
		WHERE pin.CTSCustID IS NULL;

    END IF;	
	
    #===========GET LASTEST EXISTING CATEGORY====================================
	INSERT INTO Temp_CustCategory(CustID, CategoryID, SportGroupID)
	SELECT 	cls.CustID
		,	cls.CategoryID
        ,	cls.SportGroupID
	FROM Temp_Cust AS tmpIc
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls  ON cls.CustID = tmpIc.CustID
	WHERE cls.SportGroupID = CONST_GROUP_NORMAL;

    INSERT IGNORE INTO Temp_CustCategory(CustID, CategoryID, SportGroupID)
	SELECT 	tmpIc.CustID
		, 	IFNULL(cls.CategoryID, 0) 
        ,	cls.SportGroupID
	FROM Temp_Cust AS tmpIc
		LEFT JOIN CTS_DataCenter.CTSCustomerClassificationOldCategory  AS cls ON cls.CustID = tmpIc.CustID
	ORDER BY cls.CreatedDate DESC;

    #=========RETURN CUST IF LASTEST Category is Normal OR Not Existing any Category
	SELECT	DISTINCT tmpCc.CustID
		,	cc.CategoryGroup AS CategoryID
	FROM Temp_CustCategory AS tmpCc
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON tmpCc.CategoryID = cc.CategoryID
    WHERE tmpCc.SportGroupID = CONST_GROUP_NORMAL OR tmpCc.SportGroupID IS NULL;
END$$
DELIMITER ;