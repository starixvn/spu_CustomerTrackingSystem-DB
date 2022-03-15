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
		Param's Explanation (filtered by):   
        Example: 
			-CALL CTS_DC_ProblemAccountManagement_Get('2021-03-03 00:00:00', '2021-03-10 00:00:00', null,'KEONUS',0); 
	*/	
    DECLARE lv_IsAllSite 			BIT DEFAULT 0;
    DECLARE lv_CTSCustID 			BIGINT UNSIGNED DEFAULT 0;
    DECLARE lv_CustID 				BIGINT UNSIGNED DEFAULT 0;

    DROP TEMPORARY TABLE IF EXISTS Temp_SiteID;
    CREATE TEMPORARY TABLE 		Temp_SiteID (
			SiteID 		INT UNSIGNED
        , 	PRIMARY KEY (SiteID)
	);   
    
    IF ip_Sites IS NULL OR ip_Sites = '' THEN
		SET lv_IsAllSite = 1;
    END IF;
    
    IF lv_IsAllSite = 0 THEN 
		SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_SiteID (SiteID) VALUES ('", REPLACE(ip_Sites, ",", "'),('"),"');");
		PREPARE 	stmt1 FROM @sql;
		EXECUTE 	stmt1; 

		DELETE 
        FROM Temp_SiteID AS tmp
        WHERE EXISTS (SELECT 1 
					  FROM CTS_DataCenter.MappingSubscriberSite AS map 
					  WHERE  map.SiteID = tmp.SiteID
						 AND map.SubscriberStatus = -1);

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
        ,	GROUP_CONCAT(DISTINCT cate.CategoryName SEPARATOR ', ') AS CategoryName
		,	MIN(class.CreatedDate) AS CreatedDate
	FROM CTS_DataCenter.CTSCustomerClassification AS class
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON class.CTSCustID = cus.CTSCustID
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON class.CategoryID = cate.CategoryID
	WHERE    class.CreatedDate BETWEEN ip_FromDate AND ip_ToDate
		AND  class.SportGroupID = 0
		AND (lv_IsAllSite = 1 OR cus.SiteID IN (SELECT st.SiteID FROM Temp_SiteID AS st))
		AND (lv_CTSCustID = 0 OR cus.CTSCustID = lv_CTSCustID
							   OR (ip_HasDownline = 1 
									AND (cus.SRecommend = lv_CustID 
									OR cus.MRecommend = lv_CustID 
									OR cus.Recommend = lv_CustID)))
	GROUP BY cus.CTSCustID
		, 	 cus.CustID
		, 	 cus.UserName
		, 	 cus.UserName2
		, 	 cus.Site
		, 	 cus.SiteID
		,	 cus.Currency
		,	 cus.CurrencyID;
END$$
DELIMITER ;