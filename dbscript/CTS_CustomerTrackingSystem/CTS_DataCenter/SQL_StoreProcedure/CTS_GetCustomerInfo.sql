/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_GetCustomerInfo
		@maxCustId			INT = 0
	,	@rowSize			INT = 500
	,	@numberOfBatch		INT = 1
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
		- 20200107@Casey.Huynh:	Remove Code Isdangerous [Redmine: #145951]

	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	exec CTS_GetCustomerInfo 0,500,2
		
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE @totalRow			INT = @rowSize * @numberOfBatch
		,	@currentBatch		TINYINT = 1;

	DECLARE @MBC_ACCOUNTSTATUS_OPEN INT = 1
		,	@MBC_ACCOUNTSTATUS_DISABLED INT = 2
		,	@MBC_ACCOUNTSTATUS_CLOSED INT = 3
		,	@MBC_ACCOUNTSTATUS_SUSPENDED INT = 4

		,	@CN88_ACCOUNTSTATUS_ACTIVE INT = 11
		,	@CN88_ACCOUNTSTATUS_INACTIVE INT = 12
		,	@CN88_ACCOUNTSTATUS_VIEWONLY INT = 13
		,	@CN88_ACCOUNTSTATUS_SUSPENDED INT = 14;

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END;

	CREATE TABLE #tmpCustomers (
			RowNo			INT IDENTITY
		,	CustId			INT NOT NULL PRIMARY KEY
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

	INSERT INTO #tmpCustomers
	(	 
			CustId		
		,	Username	
		,	Username2	
		,	SiteId
		,	Site		
		,	RoleId		
		,	CurrencyId 
		,	Currency	
		,	Srecommend 
		,	Mrecommend 
		,	Recommend	
		,	CreatedDate
	)
	SELECT TOP (@totalRow) cust.custid
		,	cust.username
		,	cust.username2
		,	CASE WHEN cust.roleid = 1 THEN st.siteid ELSE st2.siteid END 'siteid'
		,	CASE WHEN cust.roleid = 1 THEN upl.site ELSE cust.site END 'site'
		,	cust.roleid
		,	cust.currency 'currencyid'
		,	ex.currency
		,	cust.srecommend
		,	cust.mrecommend
		,	cust.recommend
		,	cust.creatdate
	FROM dbo.Customer AS cust WITH (NOLOCK)
		INNER JOIN dbo.Exchange AS ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
		LEFT JOIN dbo.Customer AS upl WITH (NOLOCK) ON cust.recommend = upl.custid
		LEFT JOIN dbo.Site AS st WITH (NOLOCK) ON upl.site = st.site
		LEFT JOIN dbo.Site AS st2 WITH (NOLOCK) ON cust.site = st2.site
	WHERE cust.custid > @maxCustId
		AND cust.roleid BETWEEN 1 AND 4
	ORDER BY cust.custid;

	-- Get MBC's Customer Status
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.CustStatusID = (CASE 
							WHEN c.[Enabled] <> 1 THEN @MBC_ACCOUNTSTATUS_DISABLED
							WHEN c.closed = 1 THEN @MBC_ACCOUNTSTATUS_CLOSED
							WHEN c.reject = 1 THEN @MBC_ACCOUNTSTATUS_SUSPENDED
							WHEN c.reject <> 1 THEN @MBC_ACCOUNTSTATUS_OPEN END)
		,	a.Danger1 = c.danger
		,	a.Danger2 = c.danger2
		,	a.Danger3 = c.danger3
	FROM #tmpCustomers AS a
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON a.CustId = c.custid;

	-- Get CN88's Customer Status
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.CustStatusID = (CASE 
							WHEN c.InactiveInfo > 0 THEN @CN88_ACCOUNTSTATUS_INACTIVE
							WHEN (c.InactiveInfo = 0 AND c.SuspendedInfo > 0) THEN @CN88_ACCOUNTSTATUS_SUSPENDED
							WHEN (c.InactiveInfo = 0 AND c.SuspendedInfo = 0 AND c.ViewOnlyInfo > 0) THEN @CN88_ACCOUNTSTATUS_VIEWONLY
							ELSE @CN88_ACCOUNTSTATUS_ACTIVE END)/*WHEN (c.InactiveInfo = 0 AND c.SuspendedInfo = 0 AND c.ViewOnlyInfo = 0)*/ 
	FROM #tmpCustomers AS a
		INNER JOIN bodb02.dbo.CS_CustomerStatus AS c WITH(NOLOCK) ON a.CustId = c.custid;


	SELECT	(RowNo/(@rowSize+1)) AS 'BatchId'
		,	a.CustId
		,	a.CustStatusID
		,	a.Danger1
		,	a.Danger2
		,	a.Danger3
		,	a.Username
		,	a.Username2
		,	a.SiteId
		,	a.Site
		,	a.RoleId
		,	a.CurrencyId
		,	a.Currency
		,	a.Srecommend
		,	a.Mrecommend
		,	a.Recommend
		,	a.CreatedDate
	FROM #tmpCustomers AS a WITH(NOLOCK);
END;
GO