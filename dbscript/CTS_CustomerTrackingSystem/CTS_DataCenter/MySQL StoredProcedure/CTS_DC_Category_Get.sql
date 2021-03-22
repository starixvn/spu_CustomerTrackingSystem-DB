/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Category_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Category_Get`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210315@Casey.Huynh
		Task:		Get Category List
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20210316@Casey.Huynh: Created [Redmine ID: #150457]
            
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DC_Category_Get();
	*/
	
	SELECT 	'Problem Account Category' AS CategoryGroup		    
		,	cat.CategoryName
		,	GROUP_CONCAT(cat.CategoryID SEPARATOR ',')  AS CategoryIDs  
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.CategoryGroup IN (52,53,54,55,56,58,59,60,61)
	GROUP BY cat.CategoryName 
			 , cat.CategoryGroup
	UNION ALL
	SELECT	'PA Associated Category'  AS CategoryGroup
		,	cat.CategoryName
		,	cat.CategoryID AS CategoryIDs
	FROM	CTS_DataCenter.CustomerCategory AS cat
		INNER JOIN CTS_DataCenter.TaggingToCategory AS ttc ON ttc.CategoryID = cat.CategoryID
	WHERE 	ttc.TaggingType = 1
	UNION ALL
	SELECT	'Normal Account Category'  AS CategoryGroup
		,	cat.CategoryName, cat.CategoryID AS CategoryIDs
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.CategoryID IN (201,202,203,204,205,206,210);
    
END$$
DELIMITER ;
