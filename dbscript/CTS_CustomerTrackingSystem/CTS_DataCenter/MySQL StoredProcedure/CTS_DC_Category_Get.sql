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
			- 20210805@Irena.Vo: Update get Category filter [Redmine ID: #155956]
            - 20240318@Casey.Huynh: Classify Danger Score [Redmine ID: #201358]
			
		Param's Explanation (filtered by):
        Example:
				CALL CTS_DC_Category_Get();
	*/
	DECLARE	CONST_GROUPPRIORITY_DANGEROUS	SMALLINT UNSIGNED DEFAULT 5700;

	DROP TEMPORARY TABLE IF EXISTS Temp_CategoryFilter;
	CREATE TEMPORARY TABLE Temp_CategoryFilter(
			ID 				SMALLINT
		,  	CategoryGroup 	TEXT
		,  	CategoryName 	TEXT
		,  	CategoryIDs 	LONGTEXT
	);

	INSERT IGNORE INTO Temp_CategoryFilter (CategoryGroup, CategoryName, CategoryIDs)
	SELECT 	(CASE WHEN GroupPriority = CONST_GROUPPRIORITY_DANGEROUS THEN 'Normal Account Category' ELSE 'Problem Account Category' END) AS CategoryGroup		    
		,	cat.CategoryName
		,	GROUP_CONCAT(cat.CategoryID SEPARATOR ',')  AS CategoryIDs  
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.ParentID = 50
		AND cat.IsActive = 1
	GROUP BY cat.CategoryName, cat.CategoryGroup, GroupPriority
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
		AND cat.IsActive = 1
	UNION
	SELECT 'Others'  AS CategoryGroup
		,  'No Category' AS CategoryName
		, 	0 AS CategoryIDs;

	UPDATE Temp_CategoryFilter
	SET ID = CASE WHEN CategoryGroup = 'Problem Account Category' THEN 1
				 WHEN CategoryGroup = 'PA Associated Category' THEN 2
				 WHEN CategoryGroup = 'Normal Account Category' THEN 3
				 ELSE 4
			END;

	SELECT	CategoryGroup
		,	CategoryName
		,	CategoryIDs
	FROM Temp_CategoryFilter
	ORDER BY ID ASC, CategoryName ASC; 
END$$
DELIMITER ;