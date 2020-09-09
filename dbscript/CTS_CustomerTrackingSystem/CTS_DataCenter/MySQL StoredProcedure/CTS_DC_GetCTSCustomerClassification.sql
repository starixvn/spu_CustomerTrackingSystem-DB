USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_GetCTSCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetCTSCustomerClassification`(
	IN ip_CustID 	BIGINT UNSIGNED
)
BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Get CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu [Redmine ID: #132623]: Created
            - 20200608@Casey.Huynh: Enhance SP
            - [20200701@Casey.Huynh][135324]: Chagne Flow and Store more Info
					+ Remove rule "hide VIP IF has SmartPunter/Highrisk
            - 20200820@Roger.Le [Redmine ID: #139969]: New Column "Next Scan Date" for Customer Category
            - 20200903@Long.Luu [Redmine ID: #137550]: Get for both General & Detailed Categories
            - 20200908@Irena.Vo [Redmine ID: #141020]: Get for VVIP. VVIP -> PA -> Detailed & General
            
		Param's Explanation:
	*/ 
	DECLARE lv_Remark VARCHAR(50);

    DROP TEMPORARY TABLE IF EXISTS Temp_LatestRecordOfCategory;
    CREATE TEMPORARY TABLE Temp_LatestRecordOfCategory (
	 	CategoryID			SMALLINT UNSIGNED
	,	SportGroupID		SMALLINT UNSIGNED
	, 	Remark				VARCHAR(500) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    , 	LastModifiedDate	DATETIME
    ,	LastModifiedBy		INT UNSIGNED
    , 	LastScannedDate		DATETIME
	,   CategoryType        SMALLINT UNSIGNED DEFAULT 0 -- 0: ParentID = 1, 1: ParentID = 200, 2: ParentID = 50 OR CategoryID = 3
    );
    
    SET lv_Remark = 'Auto tag customer classification';
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
   INSERT INTO Temp_LatestRecordOfCategory (CategoryID, SportGroupID, LastModifiedBy, LastModifiedDate, Remark, LastScannedDate, CategoryType)
   SELECT 	  cate.CategoryID
			, cate.SportGroupID
			, cate.LastModifiedBy
			, cate.LastModifiedDate
			, cate.Remark
			, cate.LastScannedDate
			, CASE
                  WHEN a.CategoryID = 3 THEN 2 -- For VVIP 
				  WHEN b.CategoryID = 50 THEN 2
				  WHEN b.CategoryID = 1 THEN 0
				  WHEN b.CategoryID = 200  THEN 1
			  END AS CategoryType   
	FROM		CTS_DataCenter.CTSCustomerClassification AS cate
	INNER JOIN CTS_DataCenter.CustomerCategory AS a ON cate.CategoryID = a.CategoryID
	INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID
	WHERE		cate.CustID = ip_CustID;    

    SELECT 	b.CategoryID AS ParentCategoryID
		,   c.CategoryType
        ,   a.CategoryID
		,	a.CategoryName
        , 	LEFT(GROUP_CONCAT(s.SportGroupID ORDER BY s.SportGroupID ASC SEPARATOR ', '),255) AS SportGroupIDList
        , 	LEFT(GROUP_CONCAT(s.SportGroupName ORDER BY s.SportGroupID ASC SEPARATOR ', '),255) AS SportGroupNameList
        ,	(CASE WHEN a.IsUsedManually = 0 THEN lv_Remark ELSE  c.Remark END ) AS Remark
        ,	u.UserName AS LastModifiedBy
        ,	MAX(c.LastModifiedDate) AS LastModifiedDate
        ,   CASE WHEN ip_CustID IN (SELECT CustID FROM CTS_DataCenter.SpecialCustomerClass WHERE CreatedFromFunction = 21) THEN '-'
				 ELSE DATE_ADD(MIN(c.LastScannedDate), INTERVAL a.ScanIntervalInSecond SECOND) 
			END AS NextScanFromDate
        , 	 CASE WHEN ip_CustID IN (SELECT CustID FROM CTS_DataCenter.SpecialCustomerClass WHERE CreatedFromFunction = 21) THEN '-'
				 ELSE DATE_ADD(MAX(c.LastScannedDate), INTERVAL a.ScanIntervalInSecond SECOND) 
			END AS NextScanToDate
        ,	1 AS IsEnabledDelete-- all category will be delete
    FROM Temp_LatestRecordOfCategory AS c
		INNER JOIN CTS_DataCenter.CustomerCategory AS a ON c.CategoryID = a.CategoryID
        INNER JOIN CTS_DataCenter.CustomerCategory AS b ON a.ParentID = b.CategoryID
		LEFT JOIN CTS_DataCenter.SportGroup AS s ON c.SportGroupID = s.SportGroupID
        LEFT JOIN CTS_Admin.CTSUser AS u ON c.LastModifiedBy = u.UserID
	GROUP BY b.CategoryID
		,   c.CategoryType
        ,   a.CategoryID
		,	a.CategoryName
        ,	c.Remark
        ,	c.LastModifiedBy
        , 	u.Username
        ,	a.IsUsedManually
		,	a.ScanIntervalInSecond
    ORDER BY LastModifiedDate DESC;
   
    -- Return isPinCategory for customer
   SELECT CASE WHEN ip_CustID IN (SELECT CustID FROM CTS_DataCenter.SpecialCustomerClass WHERE CreatedFromFunction = 21) THEN 1
               ELSE 0
		  END AS isPinCategory;
          
   SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
	
	# Begin: Cleanup
	DROP TEMPORARY TABLE Temp_LatestRecordOfCategory;
	# End: Cleanup
END$$

DELIMITER ;