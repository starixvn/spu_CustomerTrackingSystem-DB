/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_Customer_GetNewCustSubInfo
		@QueryType		TINYINT = 1

	,	@LastCustSubId	INT = 0
	,	@rowSize		INT = 500

	,	@CustIdList		VARCHAR(MAX) = ''
AS
/*
	Creator:	20210115@CaseyHuynh
	Task:		Get customer - [Redmine: #148849]
	Database:	DBCTS.bodb02
	
	Revisions:
		- 20210115@Casey.Huynh: Created [Redmine ID: 148849]
		- 20220122@Long.Luu:	Support for case already known list of CustID [Redmine ID: 165607]
		- 20220616@Long.Luu:	Get Licensee Info [Redmine ID: 174136]
		- 20220707@Long.Luu:	Get Lic VIP & BA Info [Redmine ID: 174219]

	Param Explaination:
		- @QueryType: 1 (default) get by range, 2 get by list CustId

	Example:
		exec CTS_Customer_GetNewCustSubInfo @QueryType=2,@LastCustSubId=0,@rowSize=500,@CustIdList='8';
		
*/
BEGIN;
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#tmpCustomer') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomer;
	END;

	CREATE TABLE #tmpCustomer (
			CustId		INT NOT NULL PRIMARY KEY
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END;

	CREATE TABLE #tmpCustomers (
			CustID			INT	
		,	CustSubID		INT
		,	UserName		VARCHAR(30)
		,	UserName2		VARCHAR(50)
		,	SiteID			INT
		,	[Site]			VARCHAR(10)
		,	RoleID			TINYINT
		,	CurrencyID		TINYINT
		,	Currency		VARCHAR(50)
		,	SRecommend		INT
		,	MRecommend		INT
		,	Recommend		INT
		,	CreatedDate		DATETIME	
		,	IsLicensee		BIT		
		,	IsLicenseeVIP	BIT DEFAULT 0		
		,	IsLicenseeBA	BIT DEFAULT 0	
		,	PRIMARY KEY		(CustID,CustSubID)		
	);

	IF (@QueryType = 1)
		BEGIN
			INSERT INTO #tmpCustomers(CustID,CustSubID,UserName,UserName2,SiteID,[Site],RoleID,CurrencyID,Currency,SRecommend,MRecommend,Recommend,CreatedDate,IsLicensee)
			SELECT TOP (@rowSize) 
					sub.custid		AS CustID
				,	sub.subaccid	AS CustSubID
				,	sub.username	AS UserName
				,	sub.username2	AS UserName2
				,	st.siteid		AS SiteID
				,	cust.site		AS 'Site'
				,	cust.roleid		AS RoleID
				,	cust.currency	AS 'CurrencyID'
				,	ex.currency		AS Currency
				,	cust.srecommend AS SRecommend
				,	cust.mrecommend AS MRecommend
				,	cust.recommend	AS Recommend
				,	sub.createdate	AS CreatedDate				
				,	CASE WHEN cs.custid IS NULL THEN 0 ELSE 1 END AS IsLicensee
			FROM dbo.custSub sub WITH (NOLOCK)
				INNER JOIN dbo.Customer cust WITH (NOLOCK) ON sub.custid = cust.custid
				INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
				INNER JOIN dbo.Site st WITH (NOLOCK) ON cust.site = st.site
				LEFT JOIN dbo.Dep_CustSuper AS cs WITH(NOLOCK) ON cust.Srecommend = cs.custid
			WHERE sub.subaccid > @LastCustSubId
			ORDER BY sub.subaccid;
		END
	ELSE
		BEGIN
			INSERT	INTO #tmpCustomer (CustId)
			SELECT	val AS CustId
			FROM	bodb02.dbo.strSplit(@CustIdList, ',');

			INSERT INTO #tmpCustomers(CustID,CustSubID,UserName,UserName2,SiteID,[Site],RoleID,CurrencyID,Currency,SRecommend,MRecommend,Recommend,CreatedDate,IsLicensee)
			SELECT	sub.custid		AS CustID
				,	sub.subaccid	AS CustSubID
				,	sub.username	AS UserName
				,	sub.username2	AS UserName2
				,	st.siteid		AS SiteID
				,	cust.site		AS 'Site'
				,	cust.roleid		AS RoleID
				,	cust.currency	AS 'CurrencyID'
				,	ex.currency		AS Currency
				,	cust.srecommend AS SRecommend
				,	cust.mrecommend AS MRecommend
				,	cust.recommend	AS Recommend
				,	sub.createdate	AS CreatedDate
				,	CASE WHEN cs.custid IS NULL THEN 0 ELSE 1 END AS IsLicensee
			FROM #tmpCustomer AS t WITH(NOLOCK)
				INNER JOIN dbo.custSub sub WITH (NOLOCK) ON sub.custid = t.CustId
				INNER JOIN dbo.Customer cust WITH (NOLOCK) ON sub.custid = cust.custid
				INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
				INNER JOIN dbo.Site st WITH (NOLOCK) ON cust.site = st.site
				LEFT JOIN dbo.Dep_CustSuper AS cs WITH(NOLOCK) ON cust.Srecommend = cs.custid
			ORDER BY sub.subaccid;
		END;
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsLicenseeVIP = 1
	FROM #tmpCustomers AS a
		INNER JOIN DBCUST.custDB.dbo.Dep_CustVIP AS c WITH(NOLOCK) ON a.custid = c.CustID
	WHERE	a.IsLicensee = 1;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsLicenseeBA = 1
	FROM #tmpCustomers AS a
		INNER JOIN DBCUST.custDB.dbo.Dep_CustBAActive AS s WITH(NOLOCK) ON a.custid = s.custid
	WHERE	a.IsLicensee = 1;

	SELECT	t.CustID
		,	t.CustSubID
		,	t.UserName
		,	t.UserName2
		,	t.SiteID
		,	t.Site
		,	t.RoleID
		,	t.CurrencyID
		,	t.Currency
		,	t.SRecommend
		,	t.MRecommend
		,	t.Recommend
		,	t.CreatedDate				
		,	t.IsLicensee		
		,	t.IsLicenseeVIP	
		,	t.IsLicenseeBA
	FROM #tmpCustomers AS t;
END;

GO