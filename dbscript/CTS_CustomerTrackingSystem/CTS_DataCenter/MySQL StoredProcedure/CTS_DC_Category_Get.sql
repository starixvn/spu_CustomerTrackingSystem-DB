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
			- 20240425@Thomas.Nguyen: Classify Initial Group Betting - Add ParentID = 150 [Redmine ID: #200854]
			- 20240626@Thomas.Nguyen: Renovate CC phase 2 - Remove hardcode ParentID [Redmine ID: #205317]

		Param's Explanation (filtered by):
        Example:
				CALL CTS_DC_Category_Get();
	*/
	DECLARE CONST_BIZCATEGROUPID_PA				INT;
	DECLARE CONST_BIZCATEGROUPID_ASSOCIATEDPA	INT;
	DECLARE CONST_BIZCATEGROUPID_NORMAL			INT;
	DECLARE CONST_BIZCATEGROUPID_INACTIVE		INT;

	SET CONST_BIZCATEGROUPID_PA				= CTS_DC_CategoryTypeParent_Get ('CONST_BIZCATEGROUPID_PA');
	SET CONST_BIZCATEGROUPID_ASSOCIATEDPA	= CTS_DC_CategoryTypeParent_Get ('CONST_BIZCATEGROUPID_ASSOCIATEDPA');
	SET CONST_BIZCATEGROUPID_NORMAL			= CTS_DC_CategoryTypeParent_Get ('CONST_BIZCATEGROUPID_NORMAL');
	SET CONST_BIZCATEGROUPID_INACTIVE 		= CTS_DC_CategoryTypeParent_Get ('CONST_BIZCATEGROUPID_INACTIVE');

	DROP TEMPORARY TABLE IF EXISTS Temp_CategoryFilter;
	CREATE TEMPORARY TABLE Temp_CategoryFilter(
			ID 				SMALLINT
		,  	CategoryGroup 	TEXT
		,  	CategoryName 	TEXT
		,  	CategoryIDs 	LONGTEXT
	);

	INSERT IGNORE INTO Temp_CategoryFilter (ID, CategoryGroup, CategoryName, CategoryIDs)
	SELECT 	cat.BussinessCategoryGroupID AS ID
		,	'Problem Account Category' AS CategoryGroup		    
		,	cat.CategoryName
		,	GROUP_CONCAT(cat.CategoryID SEPARATOR ',')  AS CategoryIDs  
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.BussinessCategoryGroupID = CONST_BIZCATEGROUPID_PA
		AND cat.IsActive = 1
	GROUP BY cat.CategoryName, cat.BussinessCategoryGroupID
	UNION
	SELECT 	cat.BussinessCategoryGroupID AS ID
		,	'PA Associated Category' AS CategoryGroup		    
		,	cat.CategoryName
		,	cat.CategoryID AS CategoryIDs  
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.BussinessCategoryGroupID = CONST_BIZCATEGROUPID_ASSOCIATEDPA
		AND cat.IsActive = 1
	GROUP BY cat.CategoryName, cat.BussinessCategoryGroupID
	UNION
	SELECT	cat.BussinessCategoryGroupID AS ID
		,	'Normal Account Category' AS CategoryGroup
		,	cat.CategoryName
		,	cat.CategoryID AS CategoryIDs
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.BussinessCategoryGroupID = CONST_BIZCATEGROUPID_NORMAL
		AND cat.IsActive = 1
	GROUP BY cat.CategoryName, cat.BussinessCategoryGroupID
	UNION
	SELECT	cat.BussinessCategoryGroupID AS ID
		,	'Others' AS CategoryGroup
		,	cat.CategoryName
		,	cat.CategoryID AS CategoryIDs
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.BussinessCategoryGroupID = CONST_BIZCATEGROUPID_INACTIVE
		AND cat.IsActive = 1
	GROUP BY cat.CategoryName, cat.BussinessCategoryGroupID
	UNION
	SELECT CONST_BIZCATEGROUPID_INACTIVE AS ID
		,	'Others'  AS CategoryGroup
		,	'No Category' AS CategoryName
		, 	0 AS CategoryIDs;
/*
	UPDATE Temp_CategoryFilter
	SET ID = CASE WHEN CategoryGroup = 'Problem Account Category' THEN 1
				 WHEN CategoryGroup = 'PA Associated Category' THEN 2
				 WHEN CategoryGroup = 'Normal Account Category' THEN 3
				 ELSE 4
			END;
*/
	SELECT	CategoryGroup
		,	CategoryName
		,	CategoryIDs
	FROM Temp_CategoryFilter
	ORDER BY ID ASC, CategoryName ASC; 
END$$
DELIMITER ;