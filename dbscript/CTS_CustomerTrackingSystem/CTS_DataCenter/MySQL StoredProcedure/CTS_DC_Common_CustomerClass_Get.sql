/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Common_CustomerClass_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Common_CustomerClass_Get`(
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230912@Casey.Huynh
		Task:		Get Customer List
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20230912@Casey.Huynh: Created [Redmine ID: #193029]
            - 20240318@Casey.Huynh: Classify Danger Score [Redmine ID: #201358]
			- 20240425@Thomas.Nguyen: Classify Initial Group Betting - Add ParentID = 150 [Redmine ID: #200854]
			- 20240628@Thomas.Nguyen: Renovate CC phase 2 - Remove hardcode ParentID [Redmine ID: #205317]

		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DC_Common_CustomerClass_Get();
	*/
    DECLARE	CONST_GROUPNAME_PA 				VARCHAR(100) DEFAULT 'PA';
	DECLARE	CONST_GROUPNAME_NORMAL 			VARCHAR(100) DEFAULT 'Normal';
	DECLARE	CONST_GROUPNAME_ASSOCIATEDPA 	VARCHAR(100) DEFAULT 'Associated PA';
	DECLARE	CONST_GROUPNAME_OTHERS			VARCHAR(100) DEFAULT 'Others';
    
	DECLARE	CONST_PARENTID_PA 					INT;
	DECLARE	CONST_PARENTID_POTENTIALPA 			INT;
	DECLARE	CONST_PARENTID_NORMAL 				INT;
	DECLARE CONST_CATEGROUPID_INACTIVE			INT;

	SET CONST_PARENTID_PA 				    = CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
    SET CONST_PARENTID_POTENTIALPA 			= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_POTENTIALPA');
	SET CONST_PARENTID_NORMAL 				= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_NORMAL');
	SET CONST_CATEGROUPID_INACTIVE 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEGROUPID_INACTIVE');

    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerClass;
    CREATE TEMPORARY TABLE Temp_CustomerClass(
		  	CustomerClass 		SMALLINT UNSIGNED
        ,  	CustomerClassGroup 	VARCHAR(50)
        ,	CategoryIDs			TEXT
        ,  	OrderID 			SMALLINT DEFAULT 0
        
        ,	PRIMARY KEY PK_Temp_CustomerClass(CustomerClassGroup ASC , CustomerClass ASC)
        ,	INDEX IX_Temp_CustomerClass_OrderID( CustomerClass, OrderID)
    );
    
    INSERT IGNORE INTO Temp_CustomerClass (CustomerClassGroup, CustomerClass, CategoryIDs)
    SELECT 	CONST_GROUPNAME_PA AS CustomerClassGroup		    
		,	cat.CustomerClass
		,	GROUP_CONCAT(cat.CategoryID SEPARATOR ',')  AS CategoryIDs  
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.ParentID = CONST_PARENTID_PA
		AND cat.IsActive = 1
        AND cat.CustomerClass IS NOT NULL
	GROUP BY cat.CustomerClass, cat.CategoryGroupID;
    
	INSERT IGNORE INTO Temp_CustomerClass (CustomerClassGroup, CustomerClass, CategoryIDs)
    SELECT 	CONST_GROUPNAME_NORMAL AS CustomerClassGroup		    
		,	cat.CustomerClass
		,	GROUP_CONCAT(cat.CategoryID SEPARATOR ',')  AS CategoryIDs  
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.ParentID = CONST_PARENTID_POTENTIALPA
		AND cat.IsActive = 1
        AND cat.CustomerClass IS NOT NULL
	GROUP BY cat.CustomerClass, cat.CategoryGroupID;

	INSERT IGNORE INTO Temp_CustomerClass (CustomerClassGroup, CustomerClass, CategoryIDs)
	SELECT	(CASE WHEN cat.TaggingType =1 THEN CONST_GROUPNAME_ASSOCIATEDPA 
				 WHEN cat.CategoryGroupID = CONST_CATEGROUPID_INACTIVE THEN CONST_GROUPNAME_OTHERS 
                 ELSE CONST_GROUPNAME_NORMAL 
			END) AS CustomerClassGroup
		,	cat.CustomerClass
		,	cat.CategoryID AS CategoryIDs
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.ParentID = CONST_PARENTID_NORMAL
		AND cat.IsActive = 1
        AND cat.CustomerClass IS NOT NULL;

   UPDATE Temp_CustomerClass
   SET OrderID = CASE WHEN CustomerClassGroup = CONST_GROUPNAME_PA THEN 1
                 WHEN CustomerClassGroup = CONST_GROUPNAME_ASSOCIATEDPA THEN 2
                 WHEN CustomerClassGroup = CONST_GROUPNAME_NORMAL THEN 3
                 ELSE 4
			END;
	
   SELECT	OrderID
		,	CustomerClassGroup
        ,	CustomerClass
        ,	CategoryIDs 
   FROM Temp_CustomerClass 
   ORDER BY OrderID ASC, CustomerClass ASC; 

END$$
DELIMITER ;