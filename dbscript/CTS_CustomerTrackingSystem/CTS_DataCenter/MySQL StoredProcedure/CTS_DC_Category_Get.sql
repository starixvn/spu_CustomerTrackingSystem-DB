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
            - 20210727@Irena.Vo: Enhance Category filter [Redmine ID: #159142]
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DC_Category_Get();
	*/
	SELECT 	'Problem Account Category' AS CategoryGroup		    
		,	cat.CategoryName
		,	GROUP_CONCAT(cat.CategoryID SEPARATOR ',')  AS CategoryIDs  
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.ParentID = 50
	GROUP BY cat.CategoryName, cat.CategoryGroup
	UNION
	SELECT	CASE WHEN ttc.TaggingType = 1 THEN 'PA Associated Category' 
				 WHEN cat.CategoryGroup = 1000 THEN 'Others' 
                 ELSE 'Normal Account Category' 
			END AS CategoryGroup
		,	cat.CategoryName
		,	cat.CategoryID AS CategoryIDs
	FROM	CTS_DataCenter.CustomerCategory AS cat
		LEFT JOIN CTS_DataCenter.TaggingToCategory AS ttc ON ttc.CategoryID = cat.CategoryID	
	WHERE 	cat.ParentID = 200
    UNION
	SELECT 'Others'  AS CategoryGroup
		,	'No Category' AS CategoryName
        , 	0 AS CategoryIDs;
END$$
DELIMITER ;