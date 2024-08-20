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
			- 20240820@Long.Luu: Created [Redmine ID: #209403]
            
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
    
    
    SELECT b.CustID, b.CategoryID, c.CustomerClass, b.CreatedDate
    FROM Temp_InputCustomers AS a
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS b ON a.CustID = b.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS c ON b.CategoryID = c.CategoryID; 
   
END$$

DELIMITER ;
