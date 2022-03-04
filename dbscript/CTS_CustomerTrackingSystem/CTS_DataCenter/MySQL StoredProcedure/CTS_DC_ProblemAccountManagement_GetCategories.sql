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
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DC_ProblemAccountManagement_GetCategories();
	*/
	SELECT 	DISTINCT cat.CategoryID, cat.CategoryName
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.SourceType = 'NAP' AND cat.ReasonID BETWEEN 102 AND 110; 
END$$
DELIMITER ;