/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="" isFunction="" isNested="0"></info>*/
DROP VIEW IF EXISTS CTS_DC_vw_CTSCustomerInfo_Member_Get;
CREATE VIEW `CTS_DC_vw_CTSCustomerInfo_Member_Get` AS
/*
		Created:	20250403@Victoria.Le
		Task:		Create a View to minimize the team's effort required to retrieve essential customer information.
		DB:			CTS_DataCenter
			
		Param's Expanation:
		
		Example:
			set @lv_CustID := 187910812;
			select * from CTS_DC_vw_CTSCustomerInfo_Member_Get where CustID = @lv_CustID;
			
		Revisions: 
			- 20250403@Victoria.Le: 		Initial Writing - Member [Redmine ID: #222767]
*/
SELECT cust.CTSCustID
,	cust.CustID
,	cust.UserName
,	cust.UserName2
,	cust.RegisterName
, 	cust.RoleID
,	cust.Site
,	mss.SubscriberName
,	cust.Currency
,	cust.CurrencyID
,	cust.CreatedDate
,	dcs.AccountID
,	cust.LastLoginTime
,	lt.LastTicketDate
,	sta.ItemName AS CustomerStatus
,	cust.SRecommend
,	cust.MRecommend
,	cust.Recommend
,	cust.IsInternal
,	cust.IsLicensee
,	cust.IsLicenseeVIP
,	cust.IsLicenseeBA
,	cust.Danger1 AS DS_Ori
,	cust.Danger2 AS DS_ABI
,	cust.Danger3 AS DS_OtherSports
,	cust.Danger4 AS DS_Basketball
,	cust.Danger5 AS DS_ESport
, 	CASE WHEN (cust.IsLicensee = 0 AND cust.SiteID = 16) or (cust.IsLicensee = 0 AND cust.CurrencyID IN(6,13)) THEN 1 ELSE 0 END AS IsRobotException
, 	CASE WHEN sp.CustomerClass IS NOT NULL THEN 1 ELSE 0 END AS IsExistSpecialCC
, 	CASE WHEN sp.CustomerClass IS NOT NULL AND cust.IsLicensee = 1 THEN sp.CustomerClass
		 WHEN sp.CustomerClass IS NOT NULL AND cust.IsLicensee = 0 THEN
			CASE WHEN cl.CustomerClass = (SELECT CTS_DataCenter.CTS_DC_CategoryTypeParent_Get('CONST_CC_VVIP')) THEN cl.CustomerClass
				 ELSE sp.CustomerClass END
		 ELSE cl.CustomerClass END AS CustomerClass
 ,	cate.CategoryName AS CategoryNames
 ,	cate.CategoryID AS CategoryIDs
FROM CTS_DataCenter.CTSCustomer AS cust
	STRAIGHT_JOIN CTS_DataCenter.MappingSubscriberSite AS mss ON mss.SubscriberID = cust.SubscriberID AND mss.SiteID = cust.SiteID
	STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS lt ON lt.CustID = cust.CustID AND lt.CTSCustID = cust.CTSCustID
	STRAIGHT_JOIN CTS_DataCenter.StaticList AS sta ON sta.ListID = 1 AND sta.ItemID = cust.CustStatusID
	LEFT JOIN CTS_DataCenter.CustDCSAccount AS dcs ON dcs.CTSCustID = cust.CTSCustID AND dcs.SubscriberID = cust.SubscriberID
	LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = cust.CustID AND sp.CTSCustID = cust.CTSCustID
    , LATERAL (
		SELECT 	cate.CustomerClass,cate.ParentID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.IsActive = 1
		WHERE clss.CustID = cust.CustID  AND clss.CTSCustID = cust.CTSCustID
		ORDER BY  cate.CustomerClassPriority ASC  
				, clss.CreatedDate ASC
				, clss.LastModifiedDate DESC
		LIMIT 1
    ) AS cl
    , LATERAL (
		SELECT 	clss.ParentID
		FROM CTS_DataCenter.CTSCustomerClassification AS clss
			INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.IsActive = 1
		WHERE clss.CustID = cust.CustID AND clss.CTSCustID = cust.CTSCustID
			AND clss.ParentID <> (SELECT CTS_DataCenter.CTS_DC_CategoryTypeParent_Get('CONST_PARENTID_WRAPPER'))
		ORDER BY  cate.CustomerClassPriority ASC  
				, clss.CreatedDate ASC
				, clss.LastModifiedDate DESC
		LIMIT 1
    ) AS clP
	, LATERAL (
		SELECT GROUP_CONCAT(ca.CategoryName) AS CategoryName, GROUP_CONCAT(ca.CategoryID) AS CategoryID
        FROM CTS_DataCenter.CustomerCategory AS ca
			INNER JOIN (SELECT DISTINCT
								(CASE WHEN clss.ParentID = (SELECT CTS_DataCenter.CTS_DC_CategoryTypeParent_Get('CONST_PARENTID_PA')) THEN cate.CategoryGroupID
									  ELSE cate.CategoryID END) AS CategoryID
							FROM CTS_DataCenter.CTSCustomerClassification AS clss
								INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.IsActive = 1
							WHERE clss.CustID = cust.CustID AND clss.CTSCustID = cust.CTSCustID
								AND clss.ParentID = clP.ParentID
							) AS subca ON ca.CategoryID = subca.CategoryID
    ) AS cate
;