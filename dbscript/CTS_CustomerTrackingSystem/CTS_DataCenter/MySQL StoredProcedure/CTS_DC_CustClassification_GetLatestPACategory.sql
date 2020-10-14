DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_GetLatestCategory` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_GetLatestCategory`(
	IN ip_CTSCustIDList 				VARCHAR(8000),
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
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustIDs;
    CREATE TEMPORARY TABLE Temp_CTSCustIDs (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustLastCategory;
    CREATE TEMPORARY TABLE Temp_CustLastCategory (
        	CTSCustID			BIGINT UNSIGNED
		,	SportGroupID		SMALLINT UNSIGNED
		,	LastModifiedTime	DATETIME
        ,	PRIMARY KEY PK_Temp_CustLastCategory(CTSCustID,SportGroupID,LastModifiedTime)
    );     
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;
    CREATE TEMPORARY TABLE Temp_CustCategory (
        	CTSCustID			BIGINT UNSIGNED
		,	CategoryID			SMALLINT UNSIGNED
        ,	PRIMARY KEY PK_Temp_CustCategory(CTSCustID,CategoryID)
    );     
    
    SET @sql = CONCAT("INSERT INTO Temp_CTSCustIDs (CTSCustID) VALUES ('", REPLACE('1,2,3', ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
    
    INSERT INTO Temp_CustLastCategory(CTSCustID, SportGroupID, LastModifiedTime)
    SELECT c.CTSCustID, c.SportGroupID, MAX(c.LastModifiedDate)
	FROM CTS_DataCenter.CTSCustomerClassification AS c
		INNER JOIN Temp_CTSCustIDs AS t ON c.CTSCustID = t.CTSCustID
    WHERE (ip_IsExcludedDetailedCategory = 0 OR (c.CategoryID > 50 AND c.CategoryID < 300))
	GROUP BY c.CTSCustID, c.SportGroupID;
    
    INSERT INTO Temp_CustCategory(CTSCustID, CategoryID)
	SELECT t.CTSCustID, c.CategoryID
    FROM Temp_CustLastCategory AS t
        INNER JOIN CTS_DataCenter.CTSCustomerClassification AS c 
			ON t.CTSCustID = c.CTSCustID AND t.SportGroupID = c.SportGroupID
	WHERE t.LastModifiedDate = c.LastModifiedDate;
    
    WITH CTE_Ordered AS (
		SELECT 	CTSCustID
			, 	CategoryID
			, 	ROW_NUMBER() OVER (PARTITION BY CTSCustID) AS Row_Num
		FROM Temp_CustCategory
   )
    SELECT t.CTSCustID, t.CategoryID
    FROM CTE_Ordered AS t
	WHERE t.Row_Num = 1;
    
END$$
DELIMITER ;
