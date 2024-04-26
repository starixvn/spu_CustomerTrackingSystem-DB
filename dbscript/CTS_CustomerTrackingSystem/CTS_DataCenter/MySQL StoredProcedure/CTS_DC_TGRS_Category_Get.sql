/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="tgrWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_TGRS_Category_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_TGRS_Category_Get`()
    SQL SECURITY INVOKER
BEGIN
/*
	Created:	20230608@Victoria.Le
	Task:		Get Category List - TGRS
	DB:			CTS_DataCenter
	Original:
	Revisions:
		- 20230608@Victoria.Le:		Initial Writing [Redmine ID: #187083]
		- 20240410@Long.Luu:		Add special rule for CC2800/2801: considered as Normal by User but has been arranged as a PA in DB [Redmine ID: #201358]
		- 20240426@Thomas.Nguyen:	Classify Initial Group Betting - Add ParentID = 150 [Redmine ID: #200854]

	Param's Explanation (filtered by):
	Example:
		- CALL CTS_DC_TGRS_Category_Get();
*/
	DECLARE CONST_CATEGORYGROUP_NORMAL 	SMALLINT DEFAULT 200;
	DECLARE CONST_CATEGORYGROUP_PA 		SMALLINT DEFAULT 50;
	DECLARE	CONST_CATEGORYGROUP_POTENTIALPA		SMALLINT DEFAULT 150;

	DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
    CREATE TEMPORARY TABLE Temp_CustomerCategory(
			CustomerClass 			SMALLINT UNSIGNED PRIMARY KEY
        ,  	CategoryName 			VARCHAR(50)
        ,	CustomerClassGroupID	SMALLINT
    );
    
	DROP TEMPORARY TABLE IF EXISTS Temp_SpecialCustomerClass;
    CREATE TEMPORARY TABLE Temp_SpecialCustomerClass(
			CustomerClass 			SMALLINT UNSIGNED PRIMARY KEY
		,	CategoryName			VARCHAR(50)
    );

	INSERT INTO Temp_CustomerCategory (CustomerClassGroupID,CustomerClass,CategoryName)
	WITH CTE_CC AS
	(	SELECT 	cc.ParentID
			,	cc.CustomerClass
            ,	cc.CategoryName
            ,	cc.TaggingType
            ,	CategoryGroup
            ,	ROW_NUMBER() OVER (PARTITION BY cc.CustomerClass ORDER BY cc.CategoryID) AS RowNumber
		FROM CTS_DataCenter.CustomerCategory AS cc
		WHERE cc.CustomerClass IS NOT NULL
			AND cc.IsActive = 1
	)
	SELECT 	CASE WHEN (c.ParentID = CONST_CATEGORYGROUP_NORMAL AND TaggingType  = 0 AND CategoryGroup <> 1000) OR (c.ParentID = CONST_CATEGORYGROUP_POTENTIALPA) THEN 1 -- Normal
				 WHEN c.ParentID = CONST_CATEGORYGROUP_NORMAL AND TaggingType <> 0  THEN 2 -- Normal linked Problem
				 WHEN c.ParentID = CONST_CATEGORYGROUP_PA THEN 3  -- Problem Account
				 ELSE 4 -- Other
			END AS CustomerClassGroupID
		,	c.CustomerClass
		,	c.CategoryName
	FROM CTE_CC AS c
	WHERE c.RowNumber = 1;
    
    INSERT INTO Temp_SpecialCustomerClass (CustomerClass, CategoryName)
    WITH CTE_Special AS
    (
		SELECT DISTINCT s.CustomerClass
        FROM CTS_DataCenter.SpecialCustomerClass AS s
			INNER JOIN CTS_DataCenter.CTSCustomer AS c ON s.CTSCustID = c.CTSCustID
		WHERE c.CurrencyID NOT IN (20,27,28) 
			AND IFNULL(s.CustomerClass,0) <> 0
			AND c.Site NOT IN ('Athena000')
    )
    SELECT 	s.CustomerClass
		,	CASE WHEN s.CustomerClass = 951 THEN 'Under / Underdog Group'
				 WHEN s.CustomerClass = 952 THEN 'Price Difference Group'
                 WHEN s.CustomerClass = 953 THEN 'Long Term Winning'
                 ELSE 'N/A'
			END AS CategoryName
    FROM CTE_Special AS s
    ;
    
    INSERT IGNORE Temp_CustomerCategory (CustomerClassGroupID,CustomerClass,CategoryName)
    SELECT 	4 AS CustomerClassGroupID
		,	s.CustomerClass
        ,	s.CategoryName
    FROM Temp_SpecialCustomerClass AS s
    ;
    
    SELECT 	CustomerClassGroupID
		,	CASE WHEN CustomerClassGroupID = 1 THEN 'Normal'
				 WHEN CustomerClassGroupID = 2 THEN 'Normal Linked Problem'
                 WHEN CustomerClassGroupID = 3 THEN 'Problem Account'
                 WHEN CustomerClassGroupID = 4 THEN 'Others'
			END AS CustomerClassGroupName
		,	CustomerClass
        ,	CategoryName
    FROM Temp_CustomerCategory
    ORDER BY CustomerClassGroupID,CAST(CustomerClass AS CHAR(8));

END$$
DELIMITER ;