USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_Probation.sql]     Script Date: 9/13/2022 04:07:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_Probation]
		@CustomersXML			XML
AS
/*
	Created: 20220831@Jonas.Huynh
	Task : Get new classification by sport
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200901@Jonas.Huynh: Created [Redmine ID: #176992]

	Param's Explanation:

	Example: 
		exec [dbo].[CTS_NormalAccountsClassification_BySport_Probation]
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @PARLAY_SPORTID		SMALLINT = -100

	DECLARE @FUNCTIONID			SMALLINT = 102;

	DECLARE @SPORT_SOCCER				SMALLINT = 1;
	DECLARE @SPORT_BASKETBALL			SMALLINT = 2;
	DECLARE @SPORT_ESPORT				SMALLINT = 43;
	DECLARE @SPORT_OTHERSPORT			SMALLINT = 99;

	DECLARE @CATEGORY_NEWMEMBER			INT = 201
		,	@CATEGORY_NORMALMEMBER		INT = 202
		,	@CATEGORY_SMARTPUNTER		INT = 203
		,	@CATEGORY_HIGHRISKPUNTER	INT = 204
		,	@CATEGORY_GOODMEMBER		INT = 205
		,	@CATEGORY_PROBATION			INT = 206

	DECLARE	@CustIdList			VARCHAR(MAX)	
		,	@CurrentDateTime	DATETIME = GETDATE()
		,	@CurrentDate		DATE	 = GETDATE()

	DECLARE	@ToDate				DATE	 = GETDATE();
	DECLARE	@From30Date			DATE	 = DATEADD(DAY, - 30, @ToDate);
	
	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
		[SportGroup]		VARCHAR(50) NOT NULL,
		[TurnoverRM]		DECIMAL(19, 4) NULL,
		[WinlossRM]			DECIMAL(19, 4) NULL,
		[TurnoverORG]		DECIMAL(19, 4) NULL,
		[WinlossORG]		DECIMAL(19, 4) NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
		PRIMARY KEY ([CustId],[SportId])
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]				INT NOT NULL,
		[SportId]				INT NOT NULL,
		[Site]					VARCHAR (10) NULL,
		[IsSpecialSite]			BIT DEFAULT 0,
		[IsDeposit]				BIT DEFAULT 0,
		[SRecommend]			INT,
		[TurnoverRM]			DECIMAL(19, 4) NULL,
		[WinlossRM]				DECIMAL(19, 4) NULL,
		[Margin]				DECIMAL(19, 4) NULL,
		[BetCount]				BIGINT NULL,
		[ActiveDays]			INT NULL,
		[IsProbationLastDay]	BIT DEFAULT 0
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
		[CustId]					INT PRIMARY KEY,
		[SportId]					SMALLINT,
		[IsProbationLastDay]		BIT DEFAULT 0
	);

	IF OBJECT_ID('tempdb..#tmpActiveCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpActiveCustomers;
	END
	
	CREATE TABLE #tmpActiveCustomers(
			CustId			INT PRIMARY KEY
		,	IsActive		BIT DEFAULT 0
	);
	
	INSERT INTO #tmpCustomers(CustId, SportId, IsProbationLastDay)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportId', 'SMALLINT') AS SportId
		,	T.C.value('./@IsProbationLastDay', 'BIT') AS IsProbationLastDay
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- #1: Filter Inactive Customers
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	INSERT INTO #tmpActiveCustomers(CustId, IsActive)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	

	-- Log Input Data
	INSERT INTO dbo.CustomerClassification_InputLog(CustId, CreatedDate, CreatedTime, FunctionId, IsActive)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, IsActive
	FROM #tmpActiveCustomers WITH(NOLOCK );

	-- #2: Remove account Closed & Disabled accounts & SMA account & Internal Account
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.[Enabled] = 0 OR c.roleid <> 1)
		OR c.srecommend IN (41430709)
		OR c.mrecommend IN (27899314,11656504,12146012)
		OR c.recommend IN (52466,5707545,29270764,134456)
		OR c.username LIKE '%CashOut';

	---- Remove Inactive accounts
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN #tmpActiveCustomers AS a WITH(NOLOCK) ON a.CustId = r.CustId
	WHERE a.IsActive = 0;

	-- #3: GetCustomer Accummulated data
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	INSERT INTO #tmpRawData(CustId, SportId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList;

	-- #4: Remove Parlay, Non-Sport
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
	WHERE SportGroup = 'NonSport' OR SportId = @PARLAY_SPORTID;

	-- #5: Update SportId for OtherSports
	UPDATE r WITH(ROWLOCK, UPDLOCK)
	SET r.SportId = @SPORT_OTHERSPORT
	FROM #tmpRawData AS r
	WHERE r.SportId NOT IN (@SPORT_SOCCER, @SPORT_BASKETBALL, @SPORT_ESPORT)

	-- #6: Sum data by custid, sportid
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, SportId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	a.SportId
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDays)
	FROM #tmpRawData AS a WITH(NOLOCK)
	GROUP BY a.CustId, a.SportId;

	-- Get site info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET   a.Site = c.site
	    , a.SRecommend = c.srecommend
		, a.IsSpecialSite = CASE WHEN c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

	-- Remove 'Odd Feed Sites'
	DELETE a
	FROM  #tmpCustomerAccummulatedInfo AS a WITH(ROWLOCK)
	WHERE (a.Site = 'NextBet' OR a.Site = '9wickets' OR a.Site = '9wsports');

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;	

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsProbationLastDay = c.IsProbationLastDay
	FROM #tmpCustomerAccummulatedInfo as a
		INNER JOIN #tmpCustomers as c WITH(NOLOCK) ON a.CustId = c.CustId AND a.SportId = c.SportId

	-- #7: Classify GOOD, NEW, NORMAL, PROBATION, SMART, RISKY MEMBER
	INSERT INTO dbo.CustomerClassification_BySport(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  CustId
		,	SportId
		,	CASE WHEN b.CategoryId = NULL THEN @CATEGORY_PROBATION ELSE b.CategoryId END
		,	@CurrentDate
		,	@CurrentDateTime
		,	TurnoverRM
		,	WinlossRM
		,	BetCount
		,	ActiveDays
	FROM (
			SELECT a.CustId
				,	a.SportId
				,   r.CategoryId
				,   r.Prioity
				,	a.TurnoverRM
				,	a.WinlossRM
				,	a.BetCount
				,	a.ActiveDays
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId, a.SportId, r.CategoryId ORDER BY r.Prioity ASC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
				LEFT JOIN dbo.CustomerClassification_BySport_Rule AS r WITH(NOLOCK) ON a.SportId = r.SportId 
			 WHERE 	   (r.RuleGroupId = 2 AND a.IsSpecialSite = 1 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)					-- NEW MEMBER	
					OR (r.RuleGroupId = 3 AND a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)			-- GOOD
					OR (r.RuleGroupId = 4 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)			-- NORMAL
					OR (r.RuleGroupId = 5 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND NOT (a.BetCount > r.BetCount2 AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays))	-- NORMAL									
					OR (r.RuleGroupId = 6 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)	-- NORMAL
					OR (r.RuleGroupId = 7 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)			-- NORMAL
					OR (r.RuleGroupId = 11 AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)				-- SMART
					OR (r.RuleGroupId = 12 AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM < r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)			-- SMART
					OR (r.RuleGroupId = 15 AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)											-- RISKY
		) as b
	 WHERE b.RowNum = 1;

	DROP TABLE #tmpRawData;
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
END;