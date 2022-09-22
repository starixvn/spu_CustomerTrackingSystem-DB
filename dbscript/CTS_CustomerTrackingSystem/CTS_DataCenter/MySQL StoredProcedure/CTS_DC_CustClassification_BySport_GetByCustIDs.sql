/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_GetByCustIDs`;

DELIMITER $$
CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_GetByCustIDs`(
	  IN ip_CustSport      	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20220907@Harvey.Nguyen
		Task:  Return the auto tag customer list by ip_category
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20220907@Harvey.Nguyen: Initial [RedmineID: #177434]
		Param's Explanation (filtered by):    
	*/  
	
    DECLARE	CONST_CATEGORY_NEWMEMBER 	INT DEFAULT 201;
	DECLARE	CONST_CATEGORY_NORMALMEMBER INT DEFAULT 202;
    DECLARE	CONST_CATEGORY_GOOD			INT DEFAULT 205;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RealtimeCustomers;
	CREATE TEMPORARY TABLE Temp_RealtimeCustomers(
			CustID				BIGINT UNSIGNED
		,	SportID				SMALLINT
        ,	PRIMARY KEY (CustID, SportID)
	);

	INSERT INTO Temp_RealtimeCustomers(CustID, SportID)
	SELECT 	temp.CustID, temp.SportID
	FROM JSON_TABLE(ip_CustSport,
		 "$[*]" COLUMNS(
			CustID 		BIGINT UNSIGNED		PATH "$.CustId"
		, 	SportID		SMALLINT UNSIGNED	PATH "$.SportId"	
		 )) AS temp;       
         
	SELECT 		temp.CustID
			, 	temp.SportID
			, 	cate.CategoryID
	FROM Temp_RealtimeCustomers AS temp
		LEFT JOIN 	CTS_DataCenter.CTSCustomerClassification_BySport AS cate ON cate.CustID = temp.CustID AND cate.SportID = temp.SportID
	WHERE	cate.CategoryID IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER, CONST_CATEGORY_GOOD)
			OR cate.CustID IS NULL;
END$$
DELIMITER ;