DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetCTSCustomerClassification` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetCTSCustomerClassification`(
	IN ip_CTSCustID 	BIGINT UNSIGNED
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            
		Param's Explanation:
	*/ 
    
    DROP TEMPORARY TABLE IF EXISTS tempResults;
    CREATE TEMPORARY TABLE tempResults (
			CategoryID 			SMALLINT UNSIGNED
        ,	CategoryName 		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	SportGroupIDList 	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	SportGroupNameList 	VARCHAR(200) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	Remark 				VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	LastModifiedBy		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	LastModifiedDate 	DATETIME
    );
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    INSERT INTO tempResults(CategoryID, CategoryName, SportGroupIDList, SportGroupNameList, Remark, LastModifiedBy, LastModifiedDate)
    SELECT 	a.CategoryID
		,	a.CategoryName
        , 	LEFT(GROUP_CONCAT(s.SportGroupID,','),255) AS SportGroupIDList
        , 	LEFT(GROUP_CONCAT(s.SportGroupName,','),255) AS SportGroupNameList
        ,	c.Remark
        ,	CASE
				WHEN c.LastModifiedBy = 0 THEN "System"
				ELSE u.UserName
			END AS LastModifiedBy
        ,	MAX(c.LastModifiedDate) AS LastModifiedDate
    FROM CTS_DataCenter.CTSCustomerClassification AS c
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON c.CategoryID = a.CategoryID
		INNER JOIN CTS_DataCenter.SportGroup AS s ON c.SportGroupID = s.SportGroupID
        INNER JOIN CTS_Admin.CTSUser AS u ON c.LastModifiedBy = 0 OR c.LastModifiedBy = u.UserID
    WHERE c.CTSCustID = ip_CTSCustID
    GROUP BY a.CategoryID
		,	a.CategoryName
        ,	c.Remark
        ,	c.LastModifiedBy, u.Username
    ORDER BY a.CategoryID ASC; 
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
    
    SELECT	CategoryID
		, 	CategoryName
        , 	REPLACE(TRIM(BOTH ',' FROM SportGroupIDList), ',,',',') AS SportGroupIDList
        , 	REPLACE(TRIM(BOTH ',' FROM SportGroupNameList), ',,',',') AS SportGroupNameList
		, 	Remark
        , 	LastModifiedBy
        , 	LastModifiedDate
    FROM tempResults;
    
END$$
DELIMITER ;
