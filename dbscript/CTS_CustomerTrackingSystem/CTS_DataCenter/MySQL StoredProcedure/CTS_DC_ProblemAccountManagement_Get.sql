/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_ProblemAccountManagement_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemAccountManagement_Get`(
		IN ip_FromDate		DATETIME
    ,	IN ip_ToDate		DATETIME
    ,	IN ip_Sites			LONGTEXT
    ,	IN ip_CategoryIDs	TEXT
    ,	IN ip_UserName		VARCHAR(50)
    ,	IN ip_HasDownline	SMALLINT
)
    SQL SECURITY INVOKER
sp :BEGIN
	/*
		Created:	20220307@Aries.Nguyen
		Task:		Mark Problem Account
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20211130@Aries.Nguyen: 	Created [Redmine: #164079]
			- 20220408@Casey.Huynh: 	Return CreatedBy [Redmine: #171223]
			- 20220426@Casey.Huynh: 	Add CreatedBy [Redmine ID: #171512]
			- 20220913@Casey.Huynh: 	Add CategoryID Filter  [Redmine ID: #176976]
			- 20230404@Victoria.Le		TVS Abnormal Bet and Abnormal Account - Add IsParlay,SportType,IssueTypeId [Redmine ID: #185319] 

		Param's Explanation (filtered by):   
        Example: 
			CALL CTS_DC_ProblemAccountManagement_Get('2022-01-10 00:00:00', '2022-05-10 00:00:00', null,null,null,0); 
            CALL CTS_DC_ProblemAccountManagement_Get('2022-01-10 00:00:00', '2022-05-10 00:00:00', null,'52,92,63',null,0); 
	*/	
    DECLARE lv_CTSCustID 			BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_CustID 				BIGINT UNSIGNED DEFAULT 0;

    DROP TEMPORARY TABLE IF EXISTS Temp_SiteID;
    CREATE TEMPORARY TABLE 		Temp_SiteID (
			SiteID 		INT UNSIGNED
        , 	PRIMARY KEY (SiteID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CategoryID;
    CREATE TEMPORARY TABLE 		Temp_CategoryID(
			CategoryID 		SMALLINT UNSIGNED
        , 	PRIMARY KEY (CategoryID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
    CREATE TEMPORARY TABLE 		Temp_CustomerCategory (
			CategoryID 		SMALLINT UNSIGNED
        ,   CategoryName	VARCHAR(50)
        , 	PRIMARY KEY (CategoryID)
	);
    
    IF ip_Sites IS NULL OR ip_Sites = '' THEN
		INSERT IGNORE INTO Temp_SiteID(SiteID)
        SELECT map.SiteID 
		FROM CTS_DataCenter.MappingSubscriberSite AS map 
		WHERE map.SubscriberStatus <> -1;
	ELSE 
		SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_SiteID (SiteID) VALUES ('", REPLACE(ip_Sites, ",", "'),('"),"');");
		PREPARE 	stmt1 FROM @sql;
		EXECUTE 	stmt1;
    END IF; 
    
    IF ip_CategoryIDs IS NULL OR ip_CategoryIDs = '' THEN
		INSERT IGNORE INTO Temp_CustomerCategory(CategoryID, CategoryName)
        SELECT 	cate.CategoryID
			,	cate.CategoryName
		FROM CTS_DataCenter.CustomerCategory AS cate 
		WHERE cate.ParentID = 50;        
	ELSE 
		SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CategoryID (CategoryID) VALUES ('", REPLACE(ip_CategoryIDs, ",", "'),('"),"');");
		PREPARE 	stmt1 FROM @sql;
		EXECUTE 	stmt1;
        
        INSERT IGNORE INTO Temp_CustomerCategory(CategoryID, CategoryName)
        SELECT	cate.CategoryID
			,	cate.CategoryName
        FROM CTS_DataCenter.CustomerCategory AS cate
			INNER JOIN Temp_CategoryID AS tmp ON tmp.CategoryID = cate.CategoryID;
    END IF; 
    
     IF ip_UserName IS NOT NULL AND  ip_UserName != '' THEN 
		SELECT  CTSCustID
			,	CustID
        INTO 	lv_CTSCustID
			,	lv_CustID
        FROM CTS_DataCenter.CTSCustomer
        WHERE  UserName = ip_UserName
			OR RegisterName = ip_UserName
		LIMIT 1;

		IF  lv_CTSCustID IS NULL OR lv_CTSCustID = 0 THEN
			LEAVE sp;
		END IF;
     END IF;
	
	SELECT 	cus.CTSCustID
	, 	cus.CustID
	, 	cus.UserName
	, 	cus.Site
	, 	cus.SiteID
	,	cus.Currency
	,	cus.CurrencyID
	,	GROUP_CONCAT(DISTINCT tmpCat.CategoryName SEPARATOR ', ') AS CategoryName
	,	MIN(class.CreatedDate) AS CreatedDate
	,	SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(us.UserName, class.CreatedBy) ORDER BY class.CreatedDate ASC,class.CategoryID ASC SEPARATOR ', '),',',1) AS CreatedBy
	,	SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(class.Remark,'') ORDER BY class.CreatedDate ASC,class.CategoryID ASC SEPARATOR ', '),',',1) AS Remark
	,	CAST(SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(class.IsFromTVS,0) ORDER BY class.CreatedDate ASC,class.CategoryID ASC SEPARATOR ', '),',',1) AS UNSIGNED) AS IsFromTVS
	,	SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(class.TVSRequestID,0) ORDER BY class.CreatedDate ASC,class.CategoryID ASC SEPARATOR ', '),',',1) AS TVSRequestID
	,	CAST(SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(class.IsParlay,0) ORDER BY class.CreatedDate ASC,class.CategoryID ASC SEPARATOR ', '),',',1) AS UNSIGNED) AS IsParlay
	,	SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(class.SportType,0) ORDER BY class.CreatedDate ASC,class.CategoryID ASC SEPARATOR ', '),',',1) AS SportType
	,	SUBSTRING_INDEX(GROUP_CONCAT(IFNULL(class.IssueTypeID,0) ORDER BY class.CreatedDate ASC,class.CategoryID ASC SEPARATOR ', '),',',1) AS IssueTypeID
	FROM CTS_DataCenter.CTSCustomerClassification AS class
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON class.CTSCustID = cus.CTSCustID
        STRAIGHT_JOIN CTS_DataCenter.Temp_CustomerCategory AS tmpCat ON class.CategoryID = tmpCat.CategoryID
        LEFT JOIN CTS_Admin.CTSUser AS us ON class.CreatedBy = us.UserID
	WHERE    class.CreatedDate BETWEEN ip_FromDate AND ip_ToDate
		AND  class.SportGroupID = 0
		AND  cus.SiteID IN (SELECT st.SiteID FROM Temp_SiteID AS st)
		AND  (lv_CTSCustID = 0 OR cus.CTSCustID = lv_CTSCustID
							   OR (ip_HasDownline = 1 
									AND (cus.SRecommend = lv_CustID 
										OR cus.MRecommend = lv_CustID 
										OR cus.Recommend = lv_CustID)))
	GROUP BY cus.CTSCustID
		, 	cus.CustID
		, 	cus.UserName
		, 	cus.Site
		, 	cus.SiteID
		,	cus.Currency
		,	cus.CurrencyID;
	
END$$
DELIMITER ;