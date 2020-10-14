DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_GetLatestCategory` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_GetLatestCategory`(
	IN ip_CustIDList 					VARCHAR(8000),
	IN ip_IsUsingCustID					BOOL,
    IN ip_IsExcludedDetailedCategory	BOOL
)
BEGIN
	/*
		Created:	20201013@Long.Luu	
		Task :		Get Customers' latest Customer Class
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201013@Long.Luu [Redmine ID: #141756]: Created 
            
		Param's Explanation:
			- call CTS_DC_CustClassification_GetLatestCategory('3,5,205');
	*/ 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustIDs;
    CREATE TEMPORARY TABLE Temp_CustIDs (
			CustID 		BIGINT UNSIGNED PRIMARY KEY
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustLastCategory;
    CREATE TEMPORARY TABLE Temp_CustLastCategory (
        	CustID				BIGINT UNSIGNED
		,	SportGroupID		SMALLINT UNSIGNED
		,	LastModifiedDate	DATETIME
        ,	PRIMARY KEY PK_Temp_CustLastCategory(CustID,SportGroupID,LastModifiedDate)
    );     
    
    SET @sql = CONCAT("INSERT INTO Temp_CustIDs (CustID) VALUES ('", REPLACE(ip_CTSCustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
    
    IF (ip_IsUsingCustID = 1) THEN
		INSERT INTO Temp_CustLastCategory(CustID, SportGroupID, LastModifiedDate)
		SELECT c.CustID, c.SportGroupID, MAX(c.LastModifiedDate)
		FROM CTS_DataCenter.CTSCustomerClassification AS c
			RIGHT JOIN Temp_CustIDs AS t ON c.CustID = t.CustID
		WHERE (ip_IsExcludedDetailedCategory = 0 OR (c.CategoryID > 50 AND c.CategoryID < 300))
		GROUP BY c.CustID, c.SportGroupID;
		
		SELECT t.CustID, t.SportGroupID, CASE WHEN MAX(c.CategoryID) IS NULL THEN -1 ELSE MAX(c.CategoryID) END AS CategoryID
		FROM Temp_CustLastCategory AS t
			LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS c 
				ON t.CustID = c.CustID AND t.SportGroupID = c.SportGroupID
		WHERE t.LastModifiedDate = c.LastModifiedDate
		GROUP BY t.CustID, t.SportGroupID;
    ELSE
		INSERT INTO Temp_CustLastCategory(CustID, SportGroupID, LastModifiedDate)
		SELECT c.CustID, c.SportGroupID, MAX(c.LastModifiedDate)
		FROM CTS_DataCenter.CTSCustomerClassification AS c
			RIGHT JOIN Temp_CustIDs AS t ON c.CTSCustID = t.CustID
		WHERE (ip_IsExcludedDetailedCategory = 0 OR (c.CategoryID > 50 AND c.CategoryID < 300))
		GROUP BY c.CustID, c.SportGroupID;
		
		SELECT t.CustID, t.SportGroupID, CASE WHEN MAX(c.CategoryID) IS NULL THEN -1 ELSE MAX(c.CategoryID) END AS CategoryID
		FROM Temp_CustLastCategory AS t
			LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS c 
				ON t.CustID = c.CustID AND t.SportGroupID = c.SportGroupID
		WHERE t.LastModifiedDate = c.LastModifiedDate
		GROUP BY t.CustID, t.SportGroupID;
    END IF;
    
END$$
DELIMITER ;
