DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetCTSCustomerClassification` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetCTSCustomerClassification`(
	IN ip_CustID 	BIGINT UNSIGNED
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu: Created [Redmine ID: #132623]
            - 20200608@Casey.Huynh: Enhance SP
            
		Param's Explanation:
	*/ 
	DECLARE v_remark VARCHAR(50);

    DROP TEMPORARY TABLE IF EXISTS tempLatestRecordOfCategory;
    CREATE TEMPORARY TABLE tempLatestRecordOfCategory (
	 	CategoryID			SMALLINT UNSIGNED
	,	SportGroupID		SMALLINT UNSIGNED
	, 	Remark				VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    , 	LastModifiedDate	DATETIME
    ,	LastModifiedBy		INT UNSIGNED
	#, 	PRIMARY KEY			PK_tempLatestRecordOfCategory_CategoryID(CategoryID)
    );
    
    SET v_remark = 'Auto tag customer classification';
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    INSERT INTO tempLatestRecordOfCategory(CategoryID, SportGroupID, LastModifiedBy, LastModifiedDate, Remark)
    SELECT 		cla.CategoryID
				, cla.SportGroupID
				, cla.LastModifiedBy
                , cla.LastModifiedDate
                , cla.Remark
    FROM		CTS_DataCenter.CTSCustomerClassification AS cla
    WHERE		cla.CustID = ip_CustID;
    
    IF (SELECT COUNT(1) FROM tempLatestRecordOfCategory WHERE CategoryID IN (6,7)) >= 1 THEN
		DELETE t
		FROM tempLatestRecordOfCategory AS t
		WHERE t.CategoryID IN (5);
    END IF;

    SELECT 	a.CategoryID
		,	a.CategoryName
        ,	b.CategoryID AS ParentCategoryID
		,	b.CategoryName AS ParentCategoryName
        , 	LEFT(GROUP_CONCAT(s.SportGroupID ORDER BY s.SportGroupID ASC SEPARATOR ', '),255) AS SportGroupIDList
        , 	LEFT(GROUP_CONCAT(s.SportGroupName ORDER BY s.SportGroupID ASC SEPARATOR ', '),255) AS SportGroupNameList
        ,	(CASE WHEN a.IsUsedManually = 0 THEN v_remark ELSE  c.Remark END ) AS Remark
        ,	u.UserName AS LastModifiedBy
        ,	MAX(c.LastModifiedDate) AS LastModifiedDate
        ,	a.IsUsedManually AS IsEnabledDelete 
    FROM tempLatestRecordOfCategory AS c
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON c.CategoryID = a.CategoryID
        INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID
		LEFT JOIN CTS_DataCenter.SportGroup AS s ON c.SportGroupID = s.SportGroupID
        LEFT JOIN CTS_Admin.CTSUser AS u ON c.LastModifiedBy = u.UserID
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
