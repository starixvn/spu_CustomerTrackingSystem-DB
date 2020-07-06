USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_RPT_CustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_RPT_CustomerClassification`(
	IN ip_Categories TEXT,
    IN ip_SiteIDs TEXT,
	IN ip_PageSize INT,
    IN ip_PageNumber INT
)
proc_label: BEGIN
	/*
		Created:	20200622@Lex.Khuat
		Task :		Generate customer classification report with filters and paging
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200622@Lex.Khuat: Created [Redmine ID: #133934]
            
		Param's Explanation:
			- ip_Categories: string list of categoryIDs separated by ','
            - ip_SiteIDs: string list of siteIDs separated by ','			
            Example: call CTS_DC_RPT_CustomerClassification('1,2,3,4', '1, 3', 100, 0);
	*/
    
    DECLARE	vr_seperator VARCHAR(1) DEFAULT ',';

    DROP TEMPORARY TABLE IF EXISTS tmp_category;
    CREATE TEMPORARY TABLE tmp_category (
		CategoryID		SMALLINT UNSIGNED
    ,	DisplayOrder	TINYINT UNSIGNED
    ,	IsActive		BIT(1)
    );

	DROP TEMPORARY TABLE IF EXISTS tmp_sites;
    CREATE TEMPORARY TABLE tmp_sites (
	 	SiteID		INT
	);

    DROP TEMPORARY TABLE IF EXISTS tmp_subscriber_mapping;
    CREATE TEMPORARY TABLE tmp_subscriber_mapping (
	 	SubscriberID		INT
	,	SiteID				INT
	,	SiteName			VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
	,	IsTest				TINYINT
    ,	SubscriberStatus	TINYINT
    ,	IsGroupActive		BIT(1)
    ,	GroupDisplayOrder	TINYINT UNSIGNED
    ,	INDEX TMP_IDX_SubscriberID (SubscriberID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS tmp_rpt;
    CREATE TEMPORARY TABLE tmp_rpt (
	 	CTSCustID			BIGINT UNSIGNED
	,	UserName			VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
	,	LoginID				VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
    ,	Site				VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
	,	Status				VARCHAR(10)
    ,	SportGroupNameList	VARCHAR(1000)
    ,	LastModifiedDate	DATETIME
    );

    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    # ====== Parse filter by category ======
    SET @CategoriesStr = CONCAT("INSERT INTO tmp_category(CategoryID) VALUES ('", REPLACE(ip_Categories, vr_seperator, "'),('"),"');");
	PREPARE categoriesCmd FROM @CategoriesStr;
	EXECUTE categoriesCmd;

    SET @SiteIDStr = CONCAT("INSERT INTO tmp_sites(SiteID) VALUES ('", REPLACE(ip_SiteIDs, vr_seperator, "'),('"),"');");
	PREPARE siteIDsCmd FROM @SiteIDStr;
	EXECUTE siteIDsCmd;
    
    # ====== Update more category infos ======
    SET SQL_SAFE_UPDATES = 0;

    UPDATE tmp_category AS c
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON c.CategoryID = cc.CategoryID
    SET c.DisplayOrder = cc.DisplayOrder, c.IsActive = cc.IsActive;
 
	SET SQL_SAFE_UPDATES = 1;
    
	# ====== Handle return for performance ======
	IF NOT EXISTS (SELECT 1 FROM tmp_category LIMIT 1) THEN
		SELECT *
		FROM tmp_rpt
		ORDER BY LastModifiedDate DESC;
    
		leave proc_label;
    END IF;
    
	# ====== Fill site infos ======
    INSERT INTO tmp_subscriber_mapping (SubscriberID, SiteID, SiteName, IsTest, SubscriberStatus, IsGroupActive, GroupDisplayOrder)
    SELECT	ms.SubscriberID
        ,	ms.SiteID
        ,	ms.SiteName
        ,	s.IsTest
        ,	s.SubscriberStatus
        ,	sg.IsActive as IsGroupActive
        ,	sg.DisplayOrder as GroupDisplayOrder
    FROM CTS_DataCenter.MappingSubscriberSite AS ms
		INNER JOIN tmp_sites AS ts ON ms.SiteID = ts.SiteID
		INNER JOIN CTS_Admin.Subscriber AS s ON ms.SubscriberID = s.SubscriberID
		INNER JOIN CTS_DataCenter.SubscriberGroup AS sg ON ms.SubscriberGroupID = sg.SubscriberGroupID;

	# ====== Handle return for performance ======
	IF NOT EXISTS (SELECT 1 FROM tmp_subscriber_mapping LIMIT 1) THEN
		SELECT *
		FROM tmp_rpt
		ORDER BY LastModifiedDate DESC;
    
		leave proc_label;
    END IF;
    
    # ====== Build Report Data ======
    INSERT INTO tmp_rpt(CTSCustID, UserName, LoginID, Site, SportGroupNameList, LastModifiedDate)
    SELECT	cc.CTSCustID
		,	c.UserName
        ,	c.RegisterName as LoginID
        ,	tmp_ms.SiteName as Site
        ,	LEFT(GROUP_CONCAT(s.SportGroupName ORDER BY s.SportGroupID ASC SEPARATOR ', '), 255) AS SportGroupNameList        
        ,	cc.LastModifiedDate
    FROM CTS_DataCenter.CTSCustomerClassification AS cc
		INNER JOIN tmp_category AS tmp_c ON cc.CategoryID = tmp_c.CategoryID
		INNER JOIN tmp_subscriber_mapping AS tmp_ms ON cc.SubscriberID = tmp_ms.SubscriberID
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON cc.CTSCustID = c.CTSCustID AND c.CustSubID = 0
		LEFT JOIN CTS_DataCenter.SportGroup AS s ON cc.SportGroupID = s.SportGroupID
	GROUP BY
			cc.CTSCustID
		,	c.UserName
        ,	c.RegisterName
        ,	tmp_ms.SiteName
        ,	cc.LastModifiedDate
    LIMIT ip_PageNumber, ip_PageSize;
    
    SELECT *
    FROM tmp_rpt
    ORDER BY LastModifiedDate DESC;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  

END$$

DELIMITER ;

