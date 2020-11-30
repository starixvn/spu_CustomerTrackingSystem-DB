/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Probation_GetCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Probation_GetCategory`(
	IN ip_CategoryMode	TINYINT
)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200918@Lex.Khuat
		Task :		Return list of available categories to assign for each probation customer
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200918@Lex.Khuat: Created [Redmine ID: #141755]
			- 20201201@Aries.Nguyen: Update metadata for goSQL. Remove transaction isolation level REPEATABLE READ and READ UNCOMMITTED. Remove logic detail category. [Redmine ID: #145954]
            
		Param's Explanation:
            - ip_CategoryMode: 1 for General Category, 2 for Detailed Category

		Example:  
			- CALL CTS_DataCenter.CTS_DC_CustClassification_Probation_GetCategory(1);
	*/ 
    IF IFNULL(ip_CategoryMode, 0) = 1 THEN
		SELECT  a.CategoryID, a.CategoryName, a.DisplayOrder
		FROM CTS_DataCenter.CustomerCategory AS a
		WHERE a.IsActive = 1
		AND a.CategoryID in	(202, 203, 204, 205)
		ORDER BY a.DisplayOrder ASC;
        
   /* ELSEIF IFNULL(ip_CategoryMode, 0) = 2 THEN
		SELECT DISTINCT a.CategoryID, a.CategoryName, a.DisplayOrder
		FROM CTS_DataCenter.CustomerCategory AS a
		WHERE a.IsUsedManually = 0
		AND a.IsActive = 1
		AND a.CategoryID in	(4, 5, 6, 7)
		ORDER BY a.DisplayOrder ASC; */ 
	
	ELSE
		SELECT a.CategoryID, a.CategoryName, a.DisplayOrder
		FROM CTS_DataCenter.CustomerCategory AS a
		WHERE 1 = 0;
    END IF;
    
END$$

DELIMITER ;

