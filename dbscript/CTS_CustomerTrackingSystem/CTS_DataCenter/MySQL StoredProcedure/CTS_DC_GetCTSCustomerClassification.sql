USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_GetCTSCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetCTSCustomerClassification`(
	IN ip_CustIDs 			VARCHAR(2000),
    IN ip_ParentCateID		SMALLINT
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter.
		Original: 
		Revisions:
			- 20200423@Long.Luu [Redmine ID: #132623]: Created
            - 20200608@Casey.Huynh: Enhance SP
            - [20200701@Casey.Huynh][135324]: Chagne Flow and Store more Info
					+ Remove rule "hide VIP IF has SmartPunter/Highrisk
            - 20200820@Roger.Le [Redmine ID: #139969]: New Column "Next Scan Date" for Customer Category
            - 20200903@Long.Luu [Redmine ID: #137550]: Get for both General & Detailed Categories
			- 20200903@Irena.Vo: Update for Internal/External category [137550]
		Param's Explanation:
	*/ 
	DECLARE v_remark VARCHAR(50);
    
    DROP TEMPORARY TABLE IF EXISTS TempCustIDs;
    CREATE TEMPORARY TABLE TempCustIDs (
			CustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO TempCustIDs (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

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
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    INSERT INTO tempLatestRecordOfCategory(CustID, CategoryID, SportGroupID, LastModifiedBy, LastModifiedDate, Remark, LastScannedDate, CategoryType)
    SELECT 		cla.CustID
				, cla.CategoryID
				, cla.SportGroupID
				, cla.LastModifiedBy
                , cla.LastModifiedDate
                , cla.Remark
                , cla.LastScannedDate
                 , CASE
					  WHEN b.CategoryID = 1 THEN 0
			          WHEN b.CategoryID = 200  THEN 1
					  WHEN b.CategoryID = 50  THEN 2
                  END AS CategoryType   
    FROM		CTS_DataCenter.CTSCustomerClassification AS cla
		INNER JOIN TempCustIDs AS cust ON cla.CustID = cust.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON cla.CategoryID = a.CategoryID
		INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID
    WHERE (ip_ParentCateID = -1
			OR a.ParentID IN (ip_ParentCateID,50));    

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
   
   SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	
	# Begin: Cleanup
	DROP TEMPORARY TABLE tempLatestRecordOfCategory;
	# End: Cleanup
END$$

DELIMITER ;