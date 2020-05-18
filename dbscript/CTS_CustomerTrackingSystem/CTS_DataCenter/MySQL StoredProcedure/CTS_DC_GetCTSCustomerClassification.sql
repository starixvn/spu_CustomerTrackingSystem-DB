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
	 	CategoryID			SMALLINT UNSIGNED
    ,	SportGroupID		SMALLINT UNSIGNED
	, 	PRIMARY KEY			PK_tempResults_CategoryIDSportGroupID(CategoryID,SportGroupID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS tempLatestRecordOfCategory;
    CREATE TEMPORARY TABLE tempLatestRecordOfCategory (
	 	CategoryID			SMALLINT UNSIGNED
	,	SportGroupID		SMALLINT UNSIGNED
	, 	Remark				VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    , 	LastModifiedDate	DATETIME
    ,	LastModifiedBy		INT UNSIGNED
	, 	PRIMARY KEY			PK_tempLatestRecordOfCategory_CategoryID(CategoryID)
    );
    
    SET SQL_SAFE_UPDATES = 0;
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    INSERT INTO tempResults(CategoryID, SportGroupID)    
	SELECT DISTINCT d.CategoryID, d.SportGroupID
	FROM
	 (SELECT c.SportGroupID, MAX(c.LastModifiedDate) AS MaxLastModified
	   FROM CTS_DataCenter.CTSCustomerClassification AS c
       WHERE c.CTSCustID = ip_CTSCustID 
       GROUP BY c.SportGroupID
	 ) AS r
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS d ON r.SportGroupID = d.SportGroupID AND d.LastModifiedDate = r.MaxLastModified
	WHERE d.CTSCustID = ip_CTSCustID;
    
    INSERT INTO tempLatestRecordOfCategory(CategoryID, LastModifiedBy, LastModifiedDate, Remark)    
	SELECT DISTINCT d.CategoryID, d.LastModifiedBy, d.LastModifiedDate, d.Remark
	FROM
	 (SELECT c.CategoryID, MAX(c.LastModifiedDate) AS MaxLastModified
	   FROM CTS_DataCenter.CTSCustomerClassification AS c
       WHERE c.CTSCustID = ip_CTSCustID 
       GROUP BY c.CategoryID
	 ) AS r
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS d ON r.CategoryID = d.CategoryID AND d.LastModifiedDate = r.MaxLastModified
	WHERE d.CTSCustID = ip_CTSCustID;
    
    IF (SELECT COUNT(DISTINCT CategoryID) FROM tempResults) > 1 THEN
		DELETE t
		FROM tempLatestRecordOfCategory AS t
		WHERE t.CategoryID = 2;
    END IF;
    
    IF (SELECT COUNT(1) FROM tempResults WHERE CategoryID IN (6,7)) >= 1 THEN
		DELETE t
		FROM tempLatestRecordOfCategory AS t
		WHERE t.CategoryID IN (3,5);
    END IF;
    
    SELECT 	a.CategoryID
		,	a.CategoryName
        ,	b.CategoryID AS ParentCategoryID
		,	b.CategoryName AS ParentCategoryName
        , 	LEFT(GROUP_CONCAT(s.SportGroupID ORDER BY s.SportGroupID ASC SEPARATOR ', '),255) AS SportGroupIDList
        , 	LEFT(GROUP_CONCAT(s.SportGroupName ORDER BY s.SportGroupID ASC SEPARATOR ', '),255) AS SportGroupNameList
        ,	c.Remark
        ,	CASE
				WHEN MAX(c.LastModifiedBy) = 0 THEN "System"
				ELSE u.UserName
			END AS LastModifiedBy
        ,	MAX(c.LastModifiedDate) AS LastModifiedDate
        ,	a.IsUsedManually AS IsEnabledDelete 
    FROM tempLatestRecordOfCategory AS c
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON c.CategoryID = a.CategoryID
        INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID
        INNER JOIN tempResults AS cc ON c.CategoryID = cc.CategoryID
		INNER JOIN CTS_DataCenter.SportGroup AS s ON cc.SportGroupID = s.SportGroupID
        INNER JOIN CTS_Admin.CTSUser AS u ON c.LastModifiedBy = 0 OR c.LastModifiedBy = u.UserID
	GROUP BY a.CategoryID
		,	a.CategoryName
        ,	b.CategoryID
		,	b.CategoryName
        ,	c.Remark
        ,	c.LastModifiedBy
        , 	u.Username
        ,	a.IsUsedManually
    ORDER BY LastModifiedDate DESC;
    
END$$
DELIMITER ;
