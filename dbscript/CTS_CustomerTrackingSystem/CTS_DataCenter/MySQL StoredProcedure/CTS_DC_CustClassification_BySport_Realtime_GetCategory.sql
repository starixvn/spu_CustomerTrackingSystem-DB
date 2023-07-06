/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_Realtime_GetCategory`;

DELIMITER $$
CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_Realtime_GetCategory`(
	  IN ip_CustSport      	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created: 20230706@Jonas.Huynh
		Task:  Return category for realtime bysport
		DB: CTS_DataCenter
		Original:
		Revisions:
			- 20230706@Jonas.Huynh: Initial [RedmineID: #189875]
		Param's Explanation (filtered by):    
			call CTS_DataCenter.CTS_DC_CustClassification_BySport_Realtime_GetCategory('[{"CustId": "4345542", "SportGroup":1}]');
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
		, 	SportID		SMALLINT UNSIGNED	PATH "$.SportGroup"	
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