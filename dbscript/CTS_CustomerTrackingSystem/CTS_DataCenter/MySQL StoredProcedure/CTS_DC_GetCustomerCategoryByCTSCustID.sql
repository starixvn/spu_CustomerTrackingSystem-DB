DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetCustomerCategoryByCTSCustID` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetCustomerCategoryByCTSCustID`(
	IN ip_CTSCustID 	BIGINT UNSIGNED
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Get Customer Category by CTSCustId
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            
		Param's Explanation:
	*/ 
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT DISTINCT a.CategoryID, a.CategoryName, a.ParentID, a.DisplayOrder
    FROM CTS_DataCenter.CustomerCategory AS a
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS b ON a.CategoryID = b.CategoryID AND b.CTSCustID = ip_CTSCustID
    WHERE a.IsUsedManually = 1
		AND b.CategoryID IS NULL
		AND a.IsActive = 1
		AND a.CategoryID < 50
    ORDER BY a.DisplayOrder ASC; 
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
    
END$$
DELIMITER ;
