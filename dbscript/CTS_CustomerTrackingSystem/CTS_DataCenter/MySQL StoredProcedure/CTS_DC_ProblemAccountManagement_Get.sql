/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_ProblemAccountManagement_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_ProblemAccountManagement_Get`(
		IN ip_FromDate		DATETIME
    ,	IN ip_ToDate		DATETIME
    ,	IN ip_Sites			LONGTEXT
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
			- 20211130@Aries.Nguyen: Created [Redmine: #164079]
            - 20220408@Casey.Huynh: Return CreatedBy [Redmine: #171223]
            - 20220426@Casey.Huynh: Add CreatedBy [Redmine ID: #171512]
		Param's Explanation (filtered by):   
        Example: 
			-CALL CTS_DC_ProblemAccountManagement_Get('2022-01-10 00:00:00', '2022-05-10 00:00:00', null,null,0); 
            CALL CTS_DC_ProblemAccountManagement_Get_New('2022-01-10 00:00:00', '2022-05-10 00:00:00', null,null,0); 
            
            
	*/	
    DECLARE lv_CTSCustID 			BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_CustID 				BIGINT UNSIGNED DEFAULT 0;

    DROP TEMPORARY TABLE IF EXISTS Temp_SiteID;
    CREATE TEMPORARY TABLE 		Temp_SiteID (
			SiteID 		INT UNSIGNED
        , 	PRIMARY KEY (SiteID)
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
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustPA;
	CREATE TEMPORARY TABLE Temp_CustPA(
			CTSCustID		BIGINT UNSIGNED
        ,	CustID			INT UNSIGNED
        ,	SRecommend		INT UNSIGNED
        ,	MRecommend		INT UNSIGNED
        ,	Recommend		INT UNSIGNED
        ,	UserName		VARCHAR(50)
        ,	Site			VARCHAR(50)
        ,	SiteID			INT
        ,	Currency		VARCHAR(10)
        ,	CurrencyID		INT
        ,	CategoryName	VARCHAR(50)
        ,	CreatedDate		DATETIME
        ,	CreatedBy		INT UNSIGNED
        
        ,	PRIMARY KEY IX_Temp_CustPA(CTSCustID,CategoryName)
        ,	INDEX IX_Temp_CustPA_CTSCustIDCreatedDate(CTSCustID,CreatedDate)
	);   
    
    
	DROP TEMPORARY TABLE IF EXISTS Temp_FirstPA;
	CREATE TEMPORARY TABLE Temp_FirstPA(
			CTSCustID		BIGINT UNSIGNED
		,	MinCreatedDate	DATETIME
        ,	FirstCreatedBy	VARCHAR(50)
        
        ,	PRIMARY KEY IX_Temp_FirstCreatedBy(CTSCustID)
	); 

    INSERT IGNORE INTO Temp_CustPA(CTSCustID, CustID, UserName, Site, SiteID, Currency, CurrencyID, CategoryName, CreatedDate, CreatedBy)
    SELECT 	cus.CTSCustID
		, 	cus.CustID
		, 	cus.UserName
		, 	cus.Site
		, 	cus.SiteID
		,	cus.Currency
		,	cus.CurrencyID
        ,	cate.CategoryName
		,	class.CreatedDate
        ,	class.CreatedBy
	FROM CTS_DataCenter.CTSCustomerClassification AS class
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON class.CTSCustID = cus.CTSCustID
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON class.CategoryID = cate.CategoryID
	WHERE    class.CreatedDate BETWEEN ip_FromDate AND ip_ToDate
		AND  class.SportGroupID = 0
		AND  cus.SiteID IN (SELECT st.SiteID FROM Temp_SiteID AS st)
		AND  (lv_CTSCustID = 0 OR cus.CTSCustID = lv_CTSCustID
							   OR (ip_HasDownline = 1 
									AND (cus.SRecommend = lv_CustID 
										OR cus.MRecommend = lv_CustID 
										OR cus.Recommend = lv_CustID)));
                             
	INSERT IGNORE INTO Temp_FirstPA(CTSCustID, MinCreatedDate, FirstCreatedBy)
    SELECT	tmpPA.CTSCustID
		,	tmpPA.CreatedDate
        ,	tmpPA.CreatedBy
	FROM Temp_CustPA AS tmpPA
    ORDER BY tmpPA.CTSCustID, tmpPA.CreatedDate;

    SELECT 	tmpPA.CTSCustID
		, 	tmpPA.CustID
		, 	tmpPA.UserName
		, 	tmpPA.Site
		, 	tmpPA.SiteID
		,	tmpPA.Currency
		,	tmpPA.CurrencyID
        ,	GROUP_CONCAT(DISTINCT tmpPA.CategoryName SEPARATOR ', ') AS CategoryName
		,	tmpF.MinCreatedDate AS CreatedDate
        ,	us.UserName AS CreatedBy
	FROM Temp_CustPA AS tmpPA
		LEFT JOIN Temp_FirstPA AS tmpF ON tmpPA.CTSCustID = tmpF.CTSCustID 
        LEFT JOIN CTS_Admin.CTSUser AS us ON tmpF.FirstCreatedBy = us.UserID
	GROUP BY tmpPA.CTSCustID
		, 	tmpPA.CustID
		, 	tmpPA.UserName
		, 	tmpPA.Site
		, 	tmpPA.SiteID
		,	tmpPA.Currency
		,	tmpPA.CurrencyID
        ,	tmpF.MinCreatedDate
        ,	us.UserName;
END$$
DELIMITER ;