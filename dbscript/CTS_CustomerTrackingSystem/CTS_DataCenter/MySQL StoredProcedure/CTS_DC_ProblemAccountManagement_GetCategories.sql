/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_ProblemAccountManagement_GetCategories`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_ProblemAccountManagement_GetCategories`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220307@Irena.Vo
		Task:		Get Category Filter for ProblemAccount Management page
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20220307@Irena.Vo: Created [Redmine ID: #159014]
			- 20220407@Irena.Vo: Change logic get [Redmine ID: #170135]
            - 20220519@Casey.Huynh: Renovate PA Process [Redmine ID: #172061]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DC_ProblemAccountManagement_GetCategories();
	*/ 
	SELECT 	DISTINCT cat.CategoryName, cat.CategoryGroup, cat.CategoryGroup AS CategoryID # cat.CategoryID
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.SourceType = 'NAP' AND cat.CategoryID BETWEEN 52 AND 62 AND cat.CategoryID NOT IN (56,60,61); 
    
END$$
DELIMITER ;