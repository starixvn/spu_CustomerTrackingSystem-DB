/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_GetAllByCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_GetAllByCategory`(IN ip_CategoryIDList 	VARCHAR(200))
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200924@Long.Luu	
		Task :		Get All Customers by Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200924@Long.Luu: Created [Redmine ID: #141755]
            - 20201202@Lex.Khuat: Hotfix remove sportgroup, no use sportgroup table [Redmine ID: #146819]
            
		Param's Explanation:
			- call CTS_DC_CustClassification_GetAllByCategory('3,5,205');
	*/ 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CategoryIDs;
    CREATE TEMPORARY TABLE Temp_CategoryIDs (
			CategoryID 		SMALLINT UNSIGNED PRIMARY KEY
    );  
    
    SET @sql = CONCAT("INSERT INTO Temp_CategoryIDs (CategoryID) VALUES ('", REPLACE(ip_CategoryIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
    SELECT DISTINCT c.CustID, c.SportGroupID, 'All Sports', c.CategoryID, a.CategoryName
    FROM Temp_CategoryIDs AS t
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON t.CategoryID = a.CategoryID
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS c ON t.CategoryID = c.CategoryID
    WHERE a.IsActive = 1
    ORDER BY c.CustID ASC; 
    
END$$
DELIMITER ;
