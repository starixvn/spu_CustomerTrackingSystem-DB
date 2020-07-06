USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_GetAllCustomerCategories`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetAllCustomerCategories`()
BEGIN
	/*
		Created:	20200622@Lex.Khuat
		Task :		Get all customer categories
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200622@Lex.Khuat: Created [Redmine ID: #133934]
            
		Param's Explanation:
	*/ 
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT cc.CategoryID, cc.CategoryName, cc.ParentID, cc.DisplayOrder, cc.IsActive
    FROM CTS_DataCenter.CustomerCategory AS cc
    WHERE cc.IsActive = 1
		AND cc.ParentID is not null
    ORDER BY cc.DisplayOrder ASC;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  

END$$

DELIMITER ;

