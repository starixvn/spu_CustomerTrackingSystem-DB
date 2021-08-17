/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="1"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_Customer_GetInfoByCustIdList
		@custIdList			VARCHAR(MAX) = ''
		, @sourceType			TINYINT	= 0
AS
/*
	Creator:	20191128@Harvey
	Task:		Get customer - [Redmine: #124592]
	Database:	DBCTS.bodb02
	
	Revisions:
		- 20181121@Harvey:		Initial - [Redmine: #124592]
		- 20200423@Harvey:		New way to get siteId, siteName - [Redmine: #132705]
		- 20202005@Harvey:		only get SMAP (roleid 4321) 	- [Redmine: #133934]
		- 20200623@Long.Luu:	Sync more Customer Info [Redmine: #136046]
		- 20200827@Long.Luu:	Fix CN88 account status checking condition [Redmine: #137647]
		- 20210112@Long.Luu:	Fix Customer Status Issue & Remove Robot checking [Redmine: #148541]
		- 20191128@Casey.Huynh:	Enhance CTSCustomerFlow [Redmine ID: 148849]
		- 20210205@Casey.Huynh:	Return  Customer Info [Redmine ID: 149941]
		- 20210423@Casey.Huynh:	Enhance Get Closed and Suspended Status of Credit Customer from table bodb02.dbo.CustProductStatus [Redmine ID: #152259]

	Developer's Notes:
		- @sourceType: 0- GET New Customer Info, 1- Get Info Customer table, 2-Get CustInfo table, 3 GET Info CustProductStatus table

	EXEC CTS_Customer_GetInfoByCustIdList '1,2,3', 0
		
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE @MBC_ACCOUNTSTATUS_OPEN INT = 1
		,	@MBC_ACCOUNTSTATUS_DISABLED INT = 2
		,	@MBC_ACCOUNTSTATUS_CLOSED INT = 3
		,	@MBC_ACCOUNTSTATUS_SUSPENDED INT = 4

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END;

	CREATE TABLE #tmpCustomers (
			CustId			INT NOT NULL PRIMARY KEY		
		,	CustStatusID	TINYINT NULL
		,	Danger1			TINYINT NULL
		,	Danger2			TINYINT NULL
		,	Danger3			TINYINT NULL
		,	Username		VARCHAR(30)
		,	Username2		VARCHAR(50)
		,	SiteId			INT
		,	Site			VARCHAR(10)
		,	RoleId			TINYINT
		,	CurrencyId		TINYINT
		,	Currency		VARCHAR(50)
		,	Srecommend		INT
		,	Mrecommend		INT
		,	Recommend		INT
		,	CreatedDate		DATETIME
		
	);

	INSERT INTO #tmpCustomers(CustId)
	SELECT	val AS CustId
	FROM	bodb02.dbo.strSplit(@custIdList, ',');


	IF (@sourceType IN (0,1,2))
	BEGIN
		UPDATE tmpCust 
		SET		Username = 	cust.username
			,	Username2 = cust.username2	
			,	SiteId = (CASE WHEN cust.roleid = 1 THEN st.siteid ELSE st2.siteid END)
			,	Site = (CASE WHEN cust.roleid = 1 THEN upl.site ELSE cust.site END)	
			,	RoleId = cust.roleid		
			,	CurrencyId = cust.currency
			,	Currency = ex.currency
			,	Srecommend = cust.srecommend
			,	Mrecommend = cust.mrecommend 
			,	Recommend = cust.recommend	
			,	CreatedDate = cust.creatdate	
		FROM dbo.Customer AS cust WITH (NOLOCK)
			INNER JOIN #tmpCustomers AS tmpCust ON cust.custid = tmpCust.CustId
			INNER JOIN dbo.Exchange AS ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
			LEFT JOIN dbo.Customer AS upl WITH (NOLOCK) ON cust.recommend = upl.custid
			LEFT JOIN dbo.Site AS st WITH (NOLOCK) ON upl.site = st.site
			LEFT JOIN dbo.Site AS st2 WITH (NOLOCK) ON cust.site = st2.site;
	END;

	IF (@sourceType IN(0,2))
	BEGIN
		-- Get MBC's Customer Status
		UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET a.CustStatusID = (CASE 
								WHEN c.[Enabled] <> 1 THEN @MBC_ACCOUNTSTATUS_DISABLED
								WHEN c.closed = 1 THEN @MBC_ACCOUNTSTATUS_CLOSED
								WHEN c.reject = 1 THEN @MBC_ACCOUNTSTATUS_SUSPENDED
								ELSE @MBC_ACCOUNTSTATUS_OPEN END)
			,	a.Danger1 = c.danger
			,	a.Danger2 = c.danger2
			,	a.Danger3 = c.danger3
		FROM #tmpCustomers AS a
			INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON a.custid = c.custid
			INNER JOIN bodb02.dbo.Dep_CustSuper AS cs WITH(NOLOCK) ON a.Srecommend = cs.custid;


		UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET a.CustStatusID = (CASE 
								WHEN c.[Enabled] <> 1 THEN @MBC_ACCOUNTSTATUS_DISABLED
								WHEN s.CloseInfo <> 0 THEN @MBC_ACCOUNTSTATUS_CLOSED
								WHEN s.SuspendInfo <> 0 THEN @MBC_ACCOUNTSTATUS_SUSPENDED
								ELSE @MBC_ACCOUNTSTATUS_OPEN END)
			,	a.Danger1 = c.danger
			,	a.Danger2 = c.danger2
			,	a.Danger3 = c.danger3
		FROM #tmpCustomers AS a
			INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON a.custid = c.custid
			INNER JOIN bodb02.dbo.CustProductStatus AS s WITH(NOLOCK) ON a.custid = s.custid
		WHERE	a.CustStatusID IS NULL;
	END;

	IF (@sourceType = 3)
	BEGIN

		UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET a.CustStatusID = (CASE 
								WHEN c.[Enabled] <> 1 THEN @MBC_ACCOUNTSTATUS_DISABLED
								WHEN s.CloseInfo <> 0 THEN @MBC_ACCOUNTSTATUS_CLOSED
								WHEN s.SuspendInfo <> 0 THEN @MBC_ACCOUNTSTATUS_SUSPENDED
								ELSE @MBC_ACCOUNTSTATUS_OPEN END)
		FROM #tmpCustomers AS a
			INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON a.custid = c.custid
			INNER JOIN bodb02.dbo.CustProductStatus AS s WITH(NOLOCK) ON a.custid = s.custid;

	END;

	IF (@sourceType = 0)
	BEGIN
		SELECT	a.CustId		AS CustID
		,	a.Username		AS UserName
		,	a.Username2		AS UserName2
		,	a.SiteId		AS SiteID
		,	a.Site			AS 'Site'
		,	a.RoleId		AS RoleID
		,	a.CurrencyId	AS CurrencyID
		,	a.Currency		AS Currency
		,	a.Srecommend	AS SRecommend
		,	a.Mrecommend	AS MRecommend
		,	a.Recommend		AS Recommend
        ,	a.CreatedDate	AS CreatedDate
        ,	a.CustStatusID	AS CustStatusID
		,	a.Danger1		AS Danger1
		,	a.Danger2		AS Danger2
		,	a.Danger3		AS Danger3
		FROM #tmpCustomers AS a WITH(NOLOCK);
	END;

	IF (@sourceType = 1)
	BEGIN
		SELECT	a.CustId		AS CustID
		,	a.Username		AS UserName
		,	a.Username2		AS UserName2
		,	a.SiteId		AS SiteID
		,	a.Site			AS 'Site'
		,	a.RoleId		AS RoleID
		,	a.CurrencyId	AS CurrencyID
		,	a.Currency		AS Currency
		,	a.Srecommend	AS SRecommend
		,	a.Mrecommend	AS MRecommend
		,	a.Recommend		AS Recommend
        ,	a.CreatedDate	AS CreatedDate
		FROM #tmpCustomers AS a WITH(NOLOCK)
	END;

	IF (@sourceType = 2)
	BEGIN
		SELECT
			a.CustID		AS CustID
        ,	a.CustStatusID	AS CustStatusID
		,	a.Danger1		AS Danger1
		,	a.Danger2		AS Danger2
		,	a.Danger3		AS Danger3
		FROM #tmpCustomers AS a WITH(NOLOCK);
	END;
	
	IF (@sourceType = 3)
	BEGIN
		SELECT
			a.CustID		AS CustID
        ,	a.CustStatusID	AS CustStatusID
		FROM #tmpCustomers AS a WITH(NOLOCK);
	END;
END;
GO