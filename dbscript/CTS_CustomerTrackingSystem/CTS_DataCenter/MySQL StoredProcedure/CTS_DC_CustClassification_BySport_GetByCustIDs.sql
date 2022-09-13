/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_GetByCustIDs`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_GetByCustIDs`(
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
			CustID 				BIGINT UNSIGNED		PATH "$.CustID"
		, 	SportID				SMALLINT UNSIGNED	PATH "$.SportID"	
		 )) AS temp;       
         
	SELECT 		cate.CustID AS CustID
			, 	cate.SportID
			, 	cc.CategoryGroup AS CategoryID
	FROM Temp_RealtimeCustomers AS temp
		INNER JOIN 	CTS_DataCenter.CTSCustomerClassification_BySport AS cate ON cate.CustID = temp.CustID AND cate.SportID = temp.SportID
		INNER JOIN	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE	cc.CategoryGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER)
			AND NOT EXISTS (SELECT 1 
							 FROM  CTS_DataCenter.ProbationAccountMonitor_BySport AS pro 
							 WHERE pro.CustID = temp.CustID AND pro.SportID = temp.SportID);
END$$
DELIMITER ;