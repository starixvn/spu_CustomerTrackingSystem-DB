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
			
		Param's Explanation (filtered by):
        Example:
			- CALL CTS_DC_Common_CustomerClass_Get();
	*/
    
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
    SELECT 	'PA' AS CustomerClassGroup		    
		,	cat.CustomerClass
		,	GROUP_CONCAT(cat.CategoryID SEPARATOR ',')  AS CategoryIDs  
	FROM	CTS_DataCenter.CustomerCategory AS cat
	WHERE 	cat.ParentID = 50
		AND cat.IsActive = 1
        AND cat.CustomerClass IS NOT NULL
	GROUP BY cat.CustomerClass, cat.CategoryGroup;
    
	INSERT IGNORE INTO Temp_CustomerClass (CustomerClassGroup, CustomerClass, CategoryIDs)
	SELECT	CASE WHEN ttc.TaggingType =1 THEN 'Associated PA' 
				 WHEN cat.CategoryGroup = 1000 THEN 'Others' 
                 ELSE 'Normal' 
			END AS CustomerClassGroup
		,	cat.CustomerClass
		,	cat.CategoryID AS CategoryIDs
	FROM	CTS_DataCenter.CustomerCategory AS cat
		LEFT JOIN CTS_DataCenter.TaggingToCategory AS ttc ON ttc.CategoryID = cat.CategoryID	
	WHERE 	cat.ParentID = 200
		AND cat.IsActive = 1
        AND cat.CustomerClass IS NOT NULL;

   UPDATE Temp_CustomerClass
   SET OrderID = CASE WHEN CustomerClassGroup = 'PA' THEN 1
                 WHEN CustomerClassGroup = 'Associated PA' THEN 2
                 WHEN CustomerClassGroup = 'Normal' THEN 3
                 ELSE 4
			END;
	
   SELECT OrderID, CustomerClassGroup, CustomerClass, CategoryIDs FROM Temp_CustomerClass ORDER BY OrderID ASC, CustomerClass ASC; 

END$$
DELIMITER ;