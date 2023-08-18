/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_TaggingScan_CheckChanges`;

DELIMITER $$
CREATE PROCEDURE `CTS_DC_CustClassification_TaggingScan_CheckChanges`(
		IN ip_TaggingCust JSON
)

    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20230817@Jonas.Huynh
        Task :		Check tagging changes 
		DB:			CTS_DataCenter  
		Original: 
		Revisions:
			- 20230817@Jonas.Huynh: Created [RedmineID: #191400]
            
        Param's Explanation:     
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_TaggingScan_CheckChanges('');
	*/ 
    
    DECLARE	CONST_GROUP_NORMAL 	INT DEFAULT 200;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_TaggingCust;
    CREATE TEMPORARY TABLE Temp_TaggingCust(
			CustID			BIGINT UNSIGNED PRIMARY KEY,
            TaggingID		SMALLINT,
            TaggingType		SMALLINT
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;
    CREATE TEMPORARY TABLE Temp_CustCategory(
			CustID				BIGINT UNSIGNED PRIMARY KEY,
            CategoryID			SMALLINT,
            CategoryGroup		SMALLINT,
            CurrentTaggingID	SMALLINT,
            CurrentTaggingType	SMALLINT
    );
          
	INSERT IGNORE INTO Temp_TaggingCust(CustID,TaggingID,TaggingType)
	SELECT DISTINCT temp.CustID
                ,	IFNULL(temp.TaggingID, -99)
                , 	temp.TaggingType
	 FROM JSON_TABLE(ip_TaggingCust,
		"$[*]" COLUMNS(
				CustID 					BIGINT UNSIGNED		PATH "$.CustID"
            , 	TaggingID				SMALLINT			PATH "$.TaggingID"
            , 	TaggingType				SMALLINT			PATH "$.TaggingType"
		 )) AS 	temp;
    
    INSERT IGNORE INTO Temp_CustCategory(CustID, CurrentTaggingID, CurrentTaggingType)
    SELECT t.CustID, c.CategoryID, cate.CategoryGroup, cate.TaggingID, cate.TaggingType
    FROM Temp_TaggingCust AS t
		INNER JOIN CTSCustomerClassification AS c ON c.CustID = t.CustId AND c.SportGroupID = CONST_GROUP_NORMAL
		INNER JOIN CustomerCategory AS cate ON cate.CategoryID = c.CategoryID
    WHERE cate.ParentID = 200 
		AND cate.IsActive = 1
		AND cate.IsUsedManually = 0
        AND cate.TaggingID IS NOT NULL;
        
	SELECT DISTINCT t.CustID AS CustID
    FROM Temp_TaggingCust AS t
		INNER JOIN Temp_CustCategory AS c ON c.CustID = t.CustID
	WHERE t.TaggingID <> c.CurrentTaggingID;
    
END$$

DELIMITER ;