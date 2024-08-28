/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_GetCategoryByCustIDs`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetCategoryByCustIDs`(
	IN ip_CustIDs TEXT
)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20240820@Long.Luu	
		Task :		Get Customer Category by List CustID
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20240820@Long.Luu: 			Created [Redmine ID: #209403]
			- 20240822@Victoria.Le: 		Renovate CC phase 2 [Redmine ID: #205317]
            
		Param's Explanation:

		Example:  
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetCategoryByCustIDs("1,2,3");
	*/ 
	DROP TEMPORARY TABLE IF EXISTS Temp_InputCustomers;
    CREATE TEMPORARY TABLE 		Temp_InputCustomers (
			CustID              BIGINT UNSIGNED PRIMARY KEY 
    );  
    
    /* 1. Insert CustIDs */
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_InputCustomers (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;    
    
    
    SELECT b.CustID, c.OldCategoryID AS CategoryID, c.CustomerClass, b.CreatedDate
    FROM Temp_InputCustomers AS a
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS b ON a.CustID = b.CustID
		INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = b.CategoryID
        INNER JOIN CTS_DataCenter.CustomerCategory AS c ON b.CategoryID = c.CategoryID AND c.IsActive = 1 AND c.CustomerClass IS NOT NULL
		,	LATERAL (
				SELECT cs.ParentID, cs.IsParallelParentID
				FROM CTS_DataCenter.CTSCustomerClassification AS cls
					INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID 
																			AND cat.IsActive = 1 AND cat.CustomerClass IS NOT NULL
					INNER JOIN CTS_DataCenter.CustomerCategorySettings AS cs ON cs.CategoryID = cat.CategoryID
				WHERE cls.CTSCustID = b.CTSCustID
				ORDER BY cat.CategoryPriority ASC, cls.LastModifiedDate DESC
				LIMIT 1
			) AS ltr
	WHERE (ltr.IsParallelParentID = 0 AND c.ParentID = ltr.ParentID) OR (ltr.IsParallelParentID = 1 AND cs.IsMultiCateIDSameParentID = 1);
   
END$$

DELIMITER ;
