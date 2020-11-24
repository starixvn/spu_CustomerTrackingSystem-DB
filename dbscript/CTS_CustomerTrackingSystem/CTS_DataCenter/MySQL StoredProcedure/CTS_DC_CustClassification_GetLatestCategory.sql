/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_GetLatestCategory`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetLatestCategory`(IN ip_CustIDList VARCHAR(8000),IN ip_IsUsingCustID tinyint,IN ip_IsExcludedDetailedCategory tinyint)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201013@Long.Luu	
		Task :		Get Customers' latest Customer Class 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201013@Long.Luu [Redmine ID: #141756]: Created 
            - 20201014@Irena.Vo [Redmine ID: #141756]: Updated logic SP. 
            
		Param's Explanation:
			- From CTSCustID & exclude Detail Category: call CTS_DataCenter.CTS_DC_CustClassification_GetLatestCategory('221882500', 0, 1);
            - From CTSCustID & no exclude Detail Category: call CTS_DataCenter.CTS_DC_CustClassification_GetLatestCategory('221882500', 0, 0);
            - From CustID & exclude Detail Category: call CTS_DataCenter.CTS_DC_CustClassification_GetLatestCategory('43600693', 1, 1);
            - From CustID & no exclude Detail Category: call CTS_DataCenter.CTS_DC_CustClassification_GetLatestCategory('43600693', 1, 0);
	*/ 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustIDs;
    CREATE TEMPORARY TABLE Temp_CustIDs (
			CustID 		BIGINT UNSIGNED PRIMARY KEY
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustLastCategory;
    CREATE TEMPORARY TABLE Temp_CustLastCategory (
        	CustID				BIGINT UNSIGNED
		,	SportGroupID		SMALLINT
		,	LastModifiedDate	DATETIME
        ,	PRIMARY KEY PK_Temp_CustLastCategory(CustID,SportGroupID,LastModifiedDate)
    );     
    
    SET @sql = CONCAT("INSERT INTO Temp_CustIDs (CustID) VALUES ('", REPLACE(ip_CustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    
    IF (ip_IsUsingCustID = 1) THEN
			INSERT INTO Temp_CustLastCategory(CustID, SportGroupID, LastModifiedDate)
			SELECT  t.CustID, 
					CASE WHEN c.CustID IS NULL THEN -1
						 ELSE c.SportGroupID
					END AS SportGroupID, 
					CASE WHEN c.CustID IS NULL THEN '1000-01-01 00:00:00'
						 ELSE MAX(c.LastModifiedDate)
					END AS LastModifiedDate
			FROM CTS_DataCenter.CTSCustomerClassification AS c
				RIGHT JOIN Temp_CustIDs AS t ON c.CustID = t.CustID
			WHERE c.CustID IS NULL OR (ip_IsExcludedDetailedCategory = 0 OR (c.CategoryID > 50 AND c.CategoryID < 300))
			GROUP BY t.CustID, c.CustID, c.SportGroupID;
			
			SELECT t.CustID AS CustId, 
				   t.SportGroupID, 
				   CASE WHEN t.SportGroupID = -1 THEN -1 
						ELSE MAX(c.CategoryID) 
				   END AS CategoryId
			FROM Temp_CustLastCategory AS t
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS c 
					ON t.CustID = c.CustID AND t.SportGroupID = c.SportGroupID
			WHERE t.SportGroupID = -1 OR t.LastModifiedDate = c.LastModifiedDate
			GROUP BY  t.CustID, t.SportGroupID;
    ELSE
		    INSERT INTO Temp_CustLastCategory(CustID, SportGroupID, LastModifiedDate)
			SELECT  t.CustID AS CTSCustID, 
					CASE WHEN c.CTSCustID IS NULL THEN -1
						 ELSE c.SportGroupID
					END AS SportGroupID, 
					CASE WHEN c.CTSCustID IS NULL THEN '1000-01-01 00:00:00'
						 ELSE MAX(c.LastModifiedDate)
					END AS LastModifiedDate
			FROM CTS_DataCenter.CTSCustomerClassification AS c
				RIGHT JOIN Temp_CustIDs AS t ON c.CTSCustID = t.CustID
			WHERE c.CTSCustID IS NULL OR (ip_IsExcludedDetailedCategory = 0 OR (c.CategoryID > 50 AND c.CategoryID < 300))
			GROUP BY t.CustID, c.CTSCustID, c.SportGroupID;
			
			SELECT cust.CustID AS CustId, 
				   t.SportGroupID, 
				   CASE WHEN t.SportGroupID = -1 THEN -1 
						ELSE MAX(c.CategoryID) 
				   END AS CategoryId
			FROM Temp_CustLastCategory AS t
				LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS c 
					ON t.CustID = c.CTSCustID AND t.SportGroupID = c.SportGroupID
                INNER JOIN CTS_DataCenter.CTSCustomer AS cust on cust.CTSCustID = t.CustID
			WHERE t.SportGroupID = -1 OR t.LastModifiedDate = c.LastModifiedDate
			GROUP BY  cust.CustID, t.SportGroupID;
    END IF;
      
    DROP TEMPORARY TABLE IF EXISTS Temp_CustLastCategory;
    DROP TEMPORARY TABLE IF EXISTS Temp_CustIDs;
    
END$$

DELIMITER ;