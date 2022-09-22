USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_Daily]    Script Date: 9/21/2022 6:07:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_Daily]
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
				@CustomersXML = N'<Root>
										<r CustId="4345542" SportId="2" CategoryId ="201"/>
										<r CustId="4345542" SportId="1" CategoryId ="201"/>
								 </Root>';
	Example: 
		exec [dbo].[CTS_NormalAccountsClassification_BySport_Daily]
*/
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @SPORT_SOCCER				SMALLINT = 1;
	DECLARE @SPORT_BASKETBALL			SMALLINT = 2;
	DECLARE @SPORT_ESPORT				SMALLINT = 43;
	DECLARE @SPORT_OTHERSPORT			SMALLINT = 99;

	DECLARE @CurrentDateTime		DATETIME = GETDATE();
	DECLARE @CurrentDate			DATE	 = GETDATE();
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
		[TurnoverRM]		DECIMAL(19, 4) NULL,
		[WinlossRM]			DECIMAL(19, 4) NULL,
		[TurnoverORG]		DECIMAL(19, 4) NULL,
		[WinlossORG]		DECIMAL(19, 4) NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
	);

	CREATE CLUSTERED INDEX IX_tmpRawData_CustId_SportId ON #tmpRawData(
	   [CustId],
	   [SportId]
	);

	CREATE NONCLUSTERED INDEX IX_tmpRawData_SportId ON #tmpRawData(
	   [SportId]
	);

	CREATE NONCLUSTERED INDEX IX_tmpRawData_SportGroup ON #tmpRawData(
	   [SportGroup]
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
		[TurnoverRM]		DECIMAL(19, 4) NULL,
		[WinlossRM]			DECIMAL(19, 4) NULL,
		[Margin]			DECIMAL(19, 4) NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
		[CurrentCategoryId]	SMALLINT NULL
	);

	CREATE CLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_CustId_SportId_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		[CustId],
		[SportId]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SportId_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		[SportId],
		[CurrentCategoryId],
		[IsDeposit]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_Site ON #tmpCustomerAccummulatedInfo(
		[Site]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SRecommend ON #tmpCustomerAccummulatedInfo(
		[SRecommend]
	);

	IF OBJECT_ID('tempdb..#tmpActiveMember') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpActiveMember;
	END
	
	CREATE TABLE #tmpActiveMember(
			CustId				INT
		,	IsActive			BIT DEFAULT 0
		,	PRIMARY KEY CLUSTERED(CustId)
	);

	CREATE NONCLUSTERED INDEX IX_tmpActiveMember_IsActive ON #tmpActiveMember(
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
		,	PRIMARY KEY CLUSTERED (CustId, SportId)
	);

	INSERT INTO #tmpCustomers(CustId, SportId, CurrentCategoryId)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportId', 'SMALLINT') AS SportId
		,	T.C.value('./@CategoryId', 'SMALLINT') AS CurrentCategoryId
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- #1: Filter Active Customers
	SELECT @ListCustIds = STUFF((SELECT DISTINCT ',', CONVERT(VARCHAR(15), CustId) 
							FROM #tmpCustomers WITH (NOLOCK)
							FOR XML PATH('')), 1, 1, '');

	INSERT INTO #tmpActiveMember(CustId, IsActive)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	
	
	-- #2: Remove account Closed & Disabled accounts & SMA account & Internal Account
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.[Enabled] = 0 OR c.roleid <> 1)
		OR c.srecommend IN (41430709)
		OR c.mrecommend IN (27899314,11656504,12146012)
		OR c.recommend IN (52466,5707545,29270764,134456)
		OR c.username LIKE '%CashOut';

	---- Remove InActive accounts
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN #tmpActiveMember As a WITH(NOLOCK) ON r.CustId = a.CustId
	WHERE a.IsActive = 0;

	-- #3: GetCustomer Accummulated data
	SELECT @ListCustIds = STUFF((SELECT DISTINCT ',', CONVERT(VARCHAR(15), CustId) 
								FROM #tmpCustomers WITH (NOLOCK)
								FOR XML PATH('')), 1, 1, '');

	INSERT INTO #tmpRawData(CustId, SportId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 1;	
	
	-- #4: Remove Non-Sport
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
	WHERE SportGroup = 'NonSport'

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

	-- Log Input Data
	INSERT INTO dbo.CustomerClassification_BySport_InputLog(CustId, SportId, CreatedDate, CreatedTime, FunctionId, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT CustId, SportId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, TurnoverRM, WinlossRM, BetCount, ActiveDays
	FROM #tmpCustomerAccummulatedInfo;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.CurrentCategoryId = c.CurrentCategoryId
	FROM #tmpCustomerAccummulatedInfo as a
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.CustId AND a.SportId = c.SportId 
	
	-- Get site info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET	  a.Site = c.Site
		, a.SRecommend = c.srecommend
		, a.IsSpecialSite = CASE WHEN c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;

	-- Remove 'Odd Feed Sites'
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
				,	a.TurnoverRM
				,	a.WinlossRM
				,	a.BetCount
				,	a.ActiveDays
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId, a.SportId ORDER BY r.Prioity ASC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
				INNER JOIN dbo.CustomerClassification_BySport_Rule AS r WITH(NOLOCK) ON a.SportId = r.SportId 
			 WHERE 	   (r.RuleGroupId = 2 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)											-- NEW MEMBER	
					OR (r.RuleGroupId = 3 AND a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)												-- GOOD
					OR (r.RuleGroupId = 4 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)												-- NORMAL
					OR (r.RuleGroupId = 5 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND NOT (a.BetCount > r.BetCount2 AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays))			-- NORMAL
					OR (r.RuleGroupId = 6 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)										-- NORMAL
					OR (r.RuleGroupId = 7 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)												-- NORMAL
					OR (r.RuleGroupId = 8 AND a.CurrentCategoryId = r.CurrentCategory AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM <= r.WinlossRM)		-- PROBATION
					OR (r.RuleGroupId = 9 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin)									-- PROBATION
					OR (r.RuleGroupId = 10 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM >= r.WinlossRM)	-- PROBATION
					OR (r.RuleGroupId = 11 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)		-- SMART
					OR (r.RuleGroupId = 12 AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)												-- SMART
					OR (r.RuleGroupId = 13 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)	-- SMART
					OR (r.RuleGroupId = 14 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM > r.WinlossRM)									-- SMART
					OR (r.RuleGroupId = 15 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)									-- RISKY
					OR (r.RuleGroupId = 16 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM)																-- RISKY
		) as b
	 WHERE b.RowNum = 1;

	
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpRawData;
	DROP TABLE #tmpActiveMember;
END;

GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_BySport_Daily] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_BySport_Daily] TO [bodbSPUNet]
GO