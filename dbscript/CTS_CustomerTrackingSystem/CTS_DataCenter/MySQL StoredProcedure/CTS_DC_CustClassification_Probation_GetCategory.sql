USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_GetCategory`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_GetCategory`(
	IN ip_CategoryMode	TINYINT
)
BEGIN
	/*
		Created:	20200918@Lex.Khuat
		Task :		Return list of available categories to assign for each probation customer
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200918@Lex.Khuat [Redmine ID: #141755]: Created
            
		Param's Explanation:
			Sample: call CTS_DataCenter.CTS_DC_CustClassification_Probation_GetCategory(1);
            - ip_CategoryMode: 1 for General Category, 2 for Detailed Category
	*/ 
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    IF IFNULL(ip_CategoryMode, 0) = 1 THEN
		SELECT DISTINCT a.CategoryID, a.CategoryName, a.DisplayOrder
		FROM CTS_DataCenter.CustomerCategory AS a
		WHERE a.IsActive = 1
		AND a.CategoryID in	(202, 203, 204, 205)
		ORDER BY a.DisplayOrder ASC;
        
    ELSEIF IFNULL(ip_CategoryMode, 0) = 2 THEN
		SELECT DISTINCT a.CategoryID, a.CategoryName, a.DisplayOrder
		FROM CTS_DataCenter.CustomerCategory AS a
		WHERE a.IsUsedManually = 0
		AND a.IsActive = 1
		AND a.CategoryID in	(4, 5, 6, 7)
		ORDER BY a.DisplayOrder ASC;
	
	ELSE
		SELECT DISTINCT a.CategoryID, a.CategoryName, a.DisplayOrder
		FROM CTS_DataCenter.CustomerCategory AS a
		WHERE 1 = 0;
    
    END IF;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
    
END$$

DELIMITER ;

