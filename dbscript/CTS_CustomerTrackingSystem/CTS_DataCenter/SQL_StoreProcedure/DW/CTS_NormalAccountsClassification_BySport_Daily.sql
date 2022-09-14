USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_Daily]    Script Date: 9/12/2022 5:07:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_Daily]
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
		exec [dbo].[CTS_NormalAccountsClassification_BySport_Daily]
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @GENERALCATEGORY_NEWMEMBER			INT = 201
		,	@GENERALCATEGORY_NORMALMEMBER		INT = 202
		,	@GENERALCATEGORY_SMARTPUNTER		INT = 203
		,	@GENERALCATEGORY_HIGHRISKPUNTER		INT = 204
		,	@GENERALCATEGORY_VIP				INT = 205
		,	@GENERALCATEGORY_PROBATION			INT = 206
		,	@GENERALCATEGORY_INACTIVE			INT = 1000;

	DECLARE @SPORT_SOCCER				SMALLINT = 1;
	DECLARE @SPORT_BASKETBALL			SMALLINT = 2;
	DECLARE @SPORT_ESPORT				SMALLINT = 43;
	DECLARE @SPORT_OTHERSPORT			SMALLINT = 99;

	DECLARE @CurrentDateTime		DATETIME = GETDATE();
	DECLARE @CurrentDate			DATE	 = GETDATE();
	DECLARE @Back3DaysFromToday		DATE	 = DATEADD(DAY, -3, @CurrentDate);	
	DECLARE	@ToDate					DATE	 = GETDATE();
	DECLARE	@From30Date				DATE	 = DATEADD(DAY, - 30, @ToDate);

	DECLARE @FUNCTIONID				SMALLINT = 101;
	DECLARE @ListCustIds			VARCHAR(MAX)

	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
		[SportGroup]		VARCHAR(50) NOT NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[TurnoverORG]		MONEY NULL,
		[WinlossORG]		MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
		PRIMARY KEY (CustId, SportId)
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
		[Site]				VARCHAR (10) NULL,
		[IsSpecialSite]		BIT DEFAULT 0,
		[IsDeposit]			BIT DEFAULT 0,
		[SRecommend]		INT,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[Margin]			MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
		[CurrentCategoryId]	SMALLINT NULL
	);

	IF OBJECT_ID('tempdb..#tmpInactiveMember') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpInactiveMember;
	END
	
	CREATE TABLE #tmpInactiveMember(
			CustId				INT
		,	IsActive			BIT DEFAULT 0
		,	PRIMARY KEY (CustId, IsActive)
	);

	CREATE NONCLUSTERED INDEX IX_tmpInactiveMember_IsActive ON #tmpInactiveMember(
		IsActive			ASC
	);
	

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
			CustId				INT
		,	SportId				SMALLINT
		,	CurrentCategoryId	SMALLINT
		,	PRIMARY KEY (CustId, SportId)
	);

	INSERT INTO #tmpCustomers(CustId, SportId, CurrentCategoryId)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportId', 'SMALLINT') AS SportId
		,	T.C.value('./@CategoryId', 'SMALLINT') AS CurrentCategoryId
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- #1: Filter Customers
	SELECT @ListCustIds = STUFF((SELECT ',', CONVERT(VARCHAR(15), CustId) 
							FROM #tmpCustomers WITH (NOLOCK)
							FOR XML PATH('')), 1, 1, '');

	INSERT INTO #tmpInactiveMember(CustId, IsActive)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	

	-- Log Input Data
	INSERT INTO dbo.CustomerClassification_InputLog(CustId,CreatedDate,CreatedTime,FunctionId,IsActive)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FunctionId, IsActive
	FROM #tmpInactiveMember;
	
	-- Remove closed & disabled accounts & SMA account & Internal Account
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.[Enabled] = 0 OR c.roleid <> 1)
		OR c.srecommend IN (41430709)
		OR c.mrecommend IN (27899314,11656504,12146012)
		OR c.recommend IN (52466,5707545,29270764,134456)
		OR c.username LIKE '%CashOut';

	-- Remove inactive accounts
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN #tmpInactiveMember As a WITH(NOLOCK) ON r.CustId = a.CustId
	WHERE a.IsActive = 0;

	-- #2: GetCustomer Accummulated data
	SELECT @ListCustIds = STUFF((SELECT ',', CONVERT(VARCHAR(15), CustId) 
								FROM #tmpCustomers WITH (NOLOCK)
								FOR XML PATH('')), 1, 1, '');

	INSERT INTO #tmpRawData(CustId, SportId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 1;	
	
	-- #3: Remove Non-Sport
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
	WHERE SportGroup = 'NonSport'

	-- #4: Update SportId for OtherSports
	UPDATE r WITH(ROWLOCK, UPDLOCK)
	SET r.SportId = @SPORT_OTHERSPORT
	FROM #tmpRawData AS r
	WHERE r.SportId NOT IN (@SPORT_SOCCER, @SPORT_BASKETBALL, @SPORT_ESPORT)

	-- #5: Sum data by custid, sportid
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, SportId, CurrentCategoryId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	a.SportId
		,   c.CurrentCategoryId
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDays)
	FROM #tmpRawData AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.CustId AND a.SportId = c.SportId
	GROUP BY a.CustId, a.SportId;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET	a.Site = c.Site
		, a.SRecommend = c.srecommend
		, a.IsSpecialSite = CASE WHEN c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;

	-- #6: Remove 'Odd Feed Sites'
	DELETE a
	FROM  #tmpCustomerAccummulatedInfo AS a WITH(ROWLOCK)
	WHERE (a.Site = 'NextBet' OR a.Site = '9wickets' OR a.Site = '9wsports');

	-- #7: Classify GOOD, NEW, NORMAL, PROBATION, SMART, RISKY MEMBER
	INSERT INTO dbo.CustomerClassification_BySport(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  CustId
		,	SportId
		,	CategoryId
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
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId, a.SportId, r.CategorId ORDER BY r.Prioity ASC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
				INNER JOIN dbo.CustomerClassification_BySport_Rule AS r WITH(NOLOCK) ON a.SportId = r.SportId 
			 WHERE a.BetCount < r.BetCount																										-- NEW MEMBER			
					OR (a.IsSpecialSite = 1 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)					-- NEW MEMBER	
					OR (a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)		-- GOOD
					OR (a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)												-- NORMAL
					OR (a.BetCount >= r.BetCount AND a.Margin < r.Margin AND (a.TurnoverRM <= r.TurnoverRM OR a.ActiveDays < r.ActiveDays))		-- NORMAL
					OR (a.IsSpecialSite = 1 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)				-- NORMAL
					OR (a.IsDeposit = 0 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)					-- NORMAL
					OR (a.IsDeposit = 0 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM >= r.WinlossRM)					-- PROBATION
					OR (a.IsDeposit = 1 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin)													-- PROBATION
					OR (a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM <= r.WinlossRM)				-- PROBATION
					OR (a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)				-- SMART
					OR (a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM <= r.WinlossRM)										-- SMART
					OR (r.CurrentCategory != NULL AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin <= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM) -- SMART
					OR (a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)											-- RISKY
					OR (r.CurrentCategory != NULL AND r.CurrentCategory = a.CurrentCategoryId AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)			-- RISKY
		) as b
	 WHERE b.RowNum = 1;

	
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpRawData;
	DROP TABLE #tmpInactiveMember;
END;
