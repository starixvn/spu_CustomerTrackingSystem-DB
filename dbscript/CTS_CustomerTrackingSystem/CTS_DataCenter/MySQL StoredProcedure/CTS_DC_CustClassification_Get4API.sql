/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsAPI" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Get4API`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Get4API`(IN ip_CustIDs			VARCHAR(2000), IN ip_ParentCateIDs		VARCHAR(500))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200914@Harvey.Nguyen
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter.
		Original: 
		Revisions:
            - 20200910@Harvey.Nguyen: init sp [Redmine ID: #140971]
            - 20200929@Lex.Khuat: Support return problem account categories by [Redmine ID: #141962]
            - 20201130@Aries.Nguyen: Update metadata for goSQL. Remove transaction isolation level REPEATABLE READ and READ UNCOMMITTED. Remove logic detail category. [Redmine ID: #145954]

		Param's Explanation:
	*/ 
	DECLARE v_remark VARCHAR(50);
    
    DROP TEMPORARY TABLE IF EXISTS TempCustIDs;
    CREATE TEMPORARY TABLE TempCustIDs (
			CustID 			BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS TempParentIDs;
    CREATE TEMPORARY TABLE TempParentIDs (
			ParentID 		SMALLINT UNSIGNED PRIMARY KEY
    );
    
    IF IFNULL(ip_CustIDs, '') <> '' THEN
		SET @sql = CONCAT("INSERT INTO TempCustIDs (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
		PREPARE stmt1 FROM @sql;
		EXECUTE stmt1;
    END IF;
    
    IF IFNULL(ip_ParentCateIDs, '') <> '' THEN
		SET @sql = CONCAT("INSERT INTO TempParentIDs (ParentID) VALUES ('", REPLACE(ip_ParentCateIDs, ",", "'),('"),"');");
		PREPARE stmt2 FROM @sql;
		EXECUTE stmt2;
	END IF;

    DROP TEMPORARY TABLE IF EXISTS tempLatestRecordOfCategory;
    CREATE TEMPORARY TABLE tempLatestRecordOfCategory (
		CustID				BIGINT UNSIGNED
	,	CategoryID			SMALLINT UNSIGNED
	,	SportGroupID		SMALLINT UNSIGNED
	, 	Remark				VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    , 	LastModifiedDate	DATETIME
    ,	LastModifiedBy		INT UNSIGNED
    , 	LastScannedDate		DATETIME
	,   CategoryType        SMALLINT UNSIGNED DEFAULT 0 -- 0: ParentID = 1, 1: ParentID = 200, 2: ParentID = 50
    );
    
    SET v_remark = 'Auto tag customer classification';
    
    INSERT INTO tempLatestRecordOfCategory(CustID, CategoryID, SportGroupID, LastModifiedBy, LastModifiedDate, Remark, LastScannedDate, CategoryType)
    SELECT 		cla.CustID
				, cla.CategoryID
				, cla.SportGroupID
				, cla.LastModifiedBy
                , cla.LastModifiedDate
                , cla.Remark
                , cla.LastScannedDate
                 , CASE
					  -- WHEN b.CategoryID = 1 THEN 0
			          WHEN b.CategoryID = 200  THEN 1
					  WHEN b.CategoryID = 50  THEN 2
                  END AS CategoryType   
    FROM		CTS_DataCenter.CTSCustomerClassification AS cla
		INNER JOIN TempCustIDs AS cust ON cla.CustID = cust.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON cla.CategoryID = a.CategoryID
		INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID
    WHERE (IFNULL(ip_ParentCateIDs, '') = ''
			OR a.ParentID IN (SELECT ParentID FROM TempParentIDs));    

    SELECT 	c.CustID AS CustID
		,	b.CategoryID AS ParentCategoryID
		,	b.CategoryName AS ParentCategoryName
		,   c.CategoryType
        ,   a.CategoryID
		,	a.CategoryName
        , 	LEFT(GROUP_CONCAT(s.SportGroupID ORDER BY s.SportGroupID ASC SEPARATOR ', '), 255) AS SportGroupIDList
        , 	LEFT(GROUP_CONCAT(s.SportGroupName ORDER BY s.SportGroupID ASC SEPARATOR ', '), 255) AS SportGroupNameList
        ,	(CASE WHEN a.IsUsedManually = 0 THEN v_remark ELSE  c.Remark END ) AS Remark
        ,	u.UserName AS LastModifiedBy
        ,	MAX(c.LastModifiedDate) AS LastModifiedDate
        ,	DATE_ADD(MIN(c.LastScannedDate), INTERVAL a.ScanIntervalInSecond SECOND) AS NextScanFromDate
        , 	DATE_ADD(MAX(c.LastScannedDate), INTERVAL a.ScanIntervalInSecond SECOND) AS NextScanToDate
        ,	a.IsUsedManually AS IsEnabledDelete 
    FROM tempLatestRecordOfCategory AS c
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON c.CategoryID = a.CategoryID
        INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID
		LEFT JOIN CTS_DataCenter.SportGroup AS s ON c.SportGroupID = s.SportGroupID
        LEFT JOIN CTS_Admin.CTSUser AS u ON c.LastModifiedBy = u.UserID
	GROUP BY c.CustID
		,	b.CategoryID
		,	b.CategoryName
		,   c.CategoryType
        ,   a.CategoryID
		,	a.CategoryName
        ,	c.Remark
        ,	c.LastModifiedBy
        , 	u.Username
        ,	a.IsUsedManually
		,	a.ScanIntervalInSecond
    ORDER BY LastModifiedDate DESC;
   
	
	# Begin: Cleanup
	DROP TEMPORARY TABLE tempLatestRecordOfCategory;
	# End: Cleanup
END$$

DELIMITER ;