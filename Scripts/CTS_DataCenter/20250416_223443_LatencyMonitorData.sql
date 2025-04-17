/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
Creator:	20250417@Casey.Huynh	
Task:	 	Script Monitor Data Latency
Server:  	Master
DBName:		CTS_DataCenter

Revisions: 
		- 20250417@Casey.Huynh: Created [Redmine ID: #223443]
Reviewer:
*/
/***********************************************************************************************
************************ListA-CTS_DataCenter: Thomas Run ***************************************
*************************************************************************************************/
SET @FromCTSCustID = 301977224; # GET This Value when Deploy Time (service Stop)
SET @DiffCheckSecond = 120;
SET @FromDate = '2025-04-16'; #yyyy-mm-dd"
SET @ToDate = '2025-04-16'; #yyyy-mm-dd"

SET @NextToDate = DATE_ADD(@ToDate, INTERVAL 1 DAY);

SELECT cus.CTSCustID 
INTO @NextToCTSCustID
FROM CTS_DataCenter.CTSCustomer AS cus
WHERE cus.InsertedTime < @NextToDate
ORDER BY cus.CTSCustID DESC
LIMIT 1;
    
SELECT @FromDate CheckFromDate, @ToDate, NOW() AS GetTime, @FromCTSCustID AS FromCTSCustID, @ToCTSCustID AS ToCTSCustID;

SELECT  'InsertNewCust' AS Flow
	,	TIMESTAMPDIFF(SECOND, cus.CreatedDate, cls.CreatedDate) AS DiffTimeCusMainVsClass
    ,	TIMESTAMPDIFF(SECOND, cus.CreatedDate, cus.InsertedTime) AS DiffTimeCustMainVsCTS
	,	TIMESTAMPDIFF(SECOND, cus.InsertedTime, cls.CreatedDate) AS DiffTimeCusCTSVsClass	
    ,	'----' AS 'Table_CTSCustomer', cus.CTSCustID, cus.CustID, cus.Username, cus.UserName2, cus.Site, cus.IsLicensee, cus.CreatedDate , cus.InsertedTime , cus.Currency , CurrencyID
    ,	'----' AS 'Table_CTSCustomerClassification', cls.CreatedDate 
    ,   '----' AS 'Table_ArchiveCustomer_CTSCustomer',arc.ReactivateDate
    ,	'----' AS 'Table_CTSCustomerLatencyQueue_Archive', lat.LatencyType, lat.InsertedTime, lat.ArchivedDate    
    ,	'----' AS 'Table_Subscriber', sub.SubscriberID, sub.SubscriberName, sub.SubscriberType, sub.SubscriberPrefix
FROM CTS_DataCenter.CTSCustomer AS cus	
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON cls.CustID = cus.CustID AND CategoryID = 40100
    LEFT JOIN CTS_DataCenter.ArchiveCustomer_CTSCustomer AS arc ON arc.CustID = cus.CustiD AND arc.IsReactivated = 1
    LEFT JOIN CTS_DataCenter.CTSCustomerLatencyQueue_Archive AS lat ON lat.CustID = cus.CustID
    LEFT JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = cus.SubscriberID
WHERE cus.CTSCustID > @FromCTSCustID AND cus.CTSCustID < @NextToCTSCustID 
	AND cus.CustSubID = 0
    AND TIMESTAMPDIFF(SECOND, cus.CreatedDate,cls.CreatedDate) > @DiffCheckSecond
    AND arc.CustID IS NULL
UNION
SELECT	'InsertReactiveCust' AS Flow
	,	TIMESTAMPDIFF(SECOND, arc.ReactivateDate, cls.CreatedDate) AS DiffTimeCusMainVsClass
    ,	TIMESTAMPDIFF(SECOND, arc.ReactivateDate, cus.InsertedTime) AS DiffTimeCustMainVsCTS
	,	TIMESTAMPDIFF(SECOND, cus.InsertedTime, cls.CreatedDate) AS DiffTimeCusCTSVsClass	
    ,	'----' AS 'Table_CTSCustomer', cus.CTSCustID, cus.CustID, cus.Username, cus.UserName2, cus.Site, cus.IsLicensee, cus.CreatedDate , cus.InsertedTime , cus.Currency , CurrencyID
    ,	'----' AS 'Table_CTSCustomerClassification', cls.CreatedDate 
    ,   '----' AS 'Table_ArchiveCustomer_CTSCustomer',arc.ReactivateDate
    ,	'----' AS 'Table_CTSCustomerLatencyQueue_Archive', lat.LatencyType, lat.InsertedTime, lat.ArchivedDate    
    ,	'----' AS 'Table_Subscriber', sub.SubscriberID, sub.SubscriberName, sub.SubscriberType, sub.SubscriberPrefix
FROM CTS_DataCenter.CTSCustomer AS cus
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON cls.CustID = cus.CustID AND CategoryID = 40100
    INNER JOIN ArchiveCustomer_CTSCustomer AS arc ON arc.CustID = cus.CustiD AND arc.IsReactivated = 1
    LEFT JOIN CTS_DataCenter.CTSCustomerLatencyQueue_Archive AS lat ON lat.CustID = cus.CustID
    LEFT JOIN CTS_Admin.Subscriber AS sub ON sub.SubscriberID = cus.SubscriberID
WHERE cus.CTSCustID > @FromCTSCustID AND cus.CTSCustID < @NextToCTSCustID
	AND cus.CustSubID = 0
    AND TIMESTAMPDIFF(SECOND, cus.CreatedDate,cls.CreatedDate) > @DiffCheckSecond;
    
/***********************************************************************************************
************************ListB-MAIN DB: nhờ anh Long chạy trên remote server by @ListA****************************
*************************************************************************************************/
SELECT cust.Custid, cust.username, cust.creatdate, cust.RepUpdateTime
, '--CustInfo--', ci.RepUpdateTime AS CustInfo_RepUpdateTime
, '--Site--', st.RepUpdateTime AS Site_RepUpdateTime
, '--Dep_CustSuper--', cs.CustId, cs.RepUpdateTime AS Dep_CustSuper_RepUpdateTime
, '--CustProductStatus--', ps.CustId, ps.RepUpdateTime AS CustProductStatus_RepUpdateTime
FROM bodb02.dbo.Customer AS cust
	LEFT JOIN bodb02.dbo.CustInfo AS ci WITH (NOLOCK) on ci.custid = cust.custid
	LEFT JOIN bodb02.dbo.[Site] AS st WITH (NOLOCK) ON st.[site] = cust.[site]
	LEFT JOIN bodb02.dbo.Dep_CustSuper AS cs WITH(NOLOCK) ON cs.custid = cust.Srecommend 
	LEFT JOIN bodb02.dbo.CustProductStatus AS ps WITH(NOLOCK) ON ps.custid = cust.custid
WHERE cust.CustID IN (@ListA);