/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_ProblemAccount_FilterByB2C`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_ProblemAccount_FilterByB2C`(
	IN ip_CustIDs LONGTEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20211130@Aries.Nguyen
		Task:		Scan PA to update info AFC
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20211130@Aries.Nguyen: Created [Redmine: #164079]
        
		Param's Explanation (filtered by):   
        
        Example: 
			-CALL CTS_DC_CustClassification_ProblemAccount_FilterByB2C("8,9,10");
	*/	
    DECLARE	CONST_GROUP_PROBLEM 	INT DEFAULT 0;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Cust;    
	CREATE TEMPORARY TABLE Temp_Cust( 	  
			CustID		INT UNSIGNED	
        ,	PRIMARY	KEY (CustID)
	);
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Cust (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
    WITH CTS_Cust AS (
		SELECT 	DISTINCT
				cust.CustID
			,	cate.AFCFraudID
			,	clss.SportGroupID
		FROM Temp_Cust AS cust
			INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON clss.CustID = cust.CustID
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID 
		WHERE clss.SubscriberID IN (SELECT ItemID 
									FROM CTS_DataCenter.StaticList 
									WHERE ListID = 15)
	)
	SELECT 	CustID
		,	CASE WHEN SportGroupID = CONST_GROUP_PROBLEM THEN JSON_ARRAYAGG(AFCFraudID)
			ELSE NULL END AS FraudID
	FROM CTS_Cust
	GROUP BY CustID, SportGroupID;
END$$
DELIMITER ;