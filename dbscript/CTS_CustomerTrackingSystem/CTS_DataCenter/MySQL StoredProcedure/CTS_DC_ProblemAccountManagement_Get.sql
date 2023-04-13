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
	
	WITH CTE_CategoryName AS
	(
		SELECT 	cus.CTSCustID
			, 	cus.CustID
			, 	cus.UserName
			, 	cus.Site
			, 	cus.SiteID
			,	cus.Currency
			,	cus.CurrencyID
			,	GROUP_CONCAT(DISTINCT tmpCat.CategoryName SEPARATOR ', ') AS CategoryName
			,	MIN(class.CreatedDate) AS CreatedDate
		FROM CTS_DataCenter.CTSCustomerClassification AS class
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON class.CTSCustID = cus.CTSCustID
			STRAIGHT_JOIN CTS_DataCenter.Temp_CustomerCategory AS tmpCat ON class.CategoryID = tmpCat.CategoryID
		WHERE    class.CreatedDate BETWEEN ip_FromDate AND ip_ToDate
			AND  class.SportGroupID = 0
			AND  cus.SiteID IN (SELECT st.SiteID FROM Temp_SiteID AS st)
			AND  (lv_CTSCustID = 0 OR cus.CTSCustID = lv_CTSCustID
								   OR (ip_HasDownline = 1 
										AND (cus.SRecommend = lv_CustID 
											OR cus.MRecommend = lv_CustID 
											OR cus.Recommend = lv_CustID)))
		GROUP BY 	cus.CTSCustID
				, 	cus.CustID
				, 	cus.UserName
				, 	cus.Site
				, 	cus.SiteID
				,	cus.Currency
				,	cus.CurrencyID
	), CTE_First AS
    (
		SELECT 	cus.CTSCustID
			, 	cus.CustID
			,	class.CategoryID
			,	tmp.ID AS HistoryID
			,	ROW_NUMBER() OVER (PARTITION BY cus.CTSCustID, cus.CustID ORDER BY tmp.ID) AS RowNumber
        FROM CTS_DataCenter.CTSCustomerClassification AS class
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON class.CTSCustID = cus.CTSCustID,
            LATERAL (	SELECT h.ID
						FROM CTS_DataCenter.CTSCustomerClassification_History AS h
                        WHERE h.CTSCustID = class.CTSCustID
							AND h.CustID = class.CustID
                            AND h.CategoryID = class.CategoryID
                            AND h.IsDataChanged = 1
                            ORDER BY h.ID ASC
                            LIMIT 1) AS tmp
		WHERE    class.CreatedDate BETWEEN ip_FromDate AND ip_ToDate
			AND  class.SportGroupID = 0
			AND  (lv_CTSCustID = 0 OR cus.CTSCustID = lv_CTSCustID
								   OR (ip_HasDownline = 1 
										AND (cus.SRecommend = lv_CustID 
											OR cus.MRecommend = lv_CustID 
											OR cus.Recommend = lv_CustID)))
		GROUP BY 	cus.CTSCustID
				, 	cus.CustID
				,	class.CategoryID
				,	tmp.ID
            
    )
    SELECT 	DISTINCT 
				tmp1.CTSCustID
			, 	tmp1.CustID
			, 	tmp1.UserName
			, 	tmp1.Site
			, 	tmp1.SiteID
			,	tmp1.Currency
			,	tmp1.CurrencyID
			,	tmp1.CategoryName
			,	tmp1.CreatedDate
			,	IFNULL(us.UserName, class.CreatedBy) AS CreatedBy
			,	class.IsFromTVS
			,	class.Remark
			,	class.TVSRequestID
			,	class.IsParlay
			,	class.SportType
			,	class.IssueTypeID
			,	tmp2.HistoryID
    FROM CTE_CategoryName AS tmp1
		INNER JOIN CTE_First AS tmp2 ON tmp2.CTSCustID = tmp1.CTSCustID AND tmp2.CustID = tmp1.CustID
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification AS class ON class.CTSCustID = tmp1.CTSCustID AND class.CustID = tmp1.CustID AND class.CategoryID = tmp2.CategoryID
		LEFT JOIN CTS_Admin.CTSUser AS us ON class.CreatedBy = us.UserID
	WHERE tmp2.RowNumber = 1;
	
END$$
DELIMITER ;