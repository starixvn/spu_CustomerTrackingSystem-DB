USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_Probation]    Script Date: 9/21/2022 6:08:33 PM ******/
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
		- 20221111@Jonas.Huynh: Adjust Eport Rules [Redmine ID: #179501]
		- 20221118@Jonas.Huynh: Support Non-Sport [Redmine ID: #179500]
		- 20230405@Jonas.Huynh: Modify betcount schedule for Normal & Good Member [Redmine ID: #185633]
		- 20230602@Long.Luu:	Add new agent as internal account [Redmine ID: #188554]

	Param's Explanation:

	Example: 
		exec [dbo].[CTS_NormalAccountsClassification_BySport_Probation]
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @FUNCTIONID					SMALLINT = 2;

	DECLARE @SPORT_SOCCER				SMALLINT = 1,
			@SPORT_BASKETBALL			SMALLINT = 2,
			@SPORT_ESPORT				SMALLINT = 43,
			@SPORT_OTHERSPORT			SMALLINT = 99,
			@SPORT_NONSPORT				SMALLINT = 229;

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
		CustId					INT				NOT NULL,
		SportId					INT				NOT NULL,
		TurnoverRM				DECIMAL(19, 4)  NULL,
		WinlossRM				DECIMAL(19, 4)  NULL,
		TurnoverORG				DECIMAL(19, 4)  NULL,
		WinlossORG				DECIMAL(19, 4)  NULL,
		BetCount				BIGINT			NULL,
		ActiveDaysCustID		INT				NOT NULL,
        ActiveDaysSportGroup	INT				NOT NULL,
        WindaysCustID			INT				NOT NULL,
        WinDaysSportGroup		INT				NOT NULL
	);

	CREATE CLUSTERED INDEX CIX_tmpRawData_CustId_SportId ON #tmpRawData(
		CustId, 
		SportId
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		CustId					INT				NOT NULL,
		SportId					INT				NOT NULL,
		CurrentCategoryId		SMALLINT		NULL,
		IsProbationLastDay		BIT				DEFAULT 0,
		[Site]					VARCHAR (10)	NULL,
		IsSpecialSite			BIT				DEFAULT 0,
		IsDeposit				BIT				DEFAULT 0,
		SRecommend				INT,
		TurnoverRM				DECIMAL(19, 4)	NULL,
		WinlossRM				DECIMAL(19, 4)	NULL,
		Margin					DECIMAL(19, 4)	NULL,
		BetCount				BIGINT			NULL,
		ActiveDays				INT				NULL,	
		WinDaysRate				DECIMAL(5,2)	NULL
	);

	CREATE CLUSTERED INDEX CIX_tmpCustomerAccummulatedInfo_CustId_SportId ON #tmpCustomerAccummulatedInfo(
		CustId, 
		SportId
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SportId_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		SportId,
		CurrentCategoryId,
		IsDeposit
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_Site ON #tmpCustomerAccummulatedInfo(
		[Site]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SRecommend ON #tmpCustomerAccummulatedInfo(
		SRecommend
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
		CustId					INT,
		SportId					SMALLINT,
		IsProbationLastDay		BIT DEFAULT 0,
		PRIMARY KEY CLUSTERED (CustId, SportId)
	);

	IF OBJECT_ID('tempdb..#tmpActiveMember') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpActiveMember;
	END
	
	CREATE TABLE #tmpActiveMember(
			CustId			INT PRIMARY KEY
		,	IsActive		BIT DEFAULT 0
	);

	CREATE NONCLUSTERED INDEX IX_tmpActiveMember_IsActive ON #tmpActiveMember(
		IsActive			ASC
	);

	IF	OBJECT_ID('tempdb..#tmpResultData') IS NOT NULL
		DROP TABLE	#tmpResultData;

	CREATE TABLE #tmpResultData(
		CustId			INT			NOT NULL,
		SportId			SMALLINT	NOT NULL,
		CategoryId		SMALLINT	NOT NULL,
		PRIMARY KEY CLUSTERED (CustId, SportId)
	);
	
	IF	OBJECT_ID('tempdb..#tmpBetCount') IS NOT NULL
	DROP TABLE	#tmpBetCount;

	CREATE TABLE #tmpBetCount(
		CustId					INT			NOT NULL,
		SportId					SMALLINT,
		CategoryId				SMALLINT	NOT NULL,
		BetCount				BIGINT		NULL
		PRIMARY KEY CLUSTERED (CustId, SportId)
	);
	
	CREATE NONCLUSTERED INDEX IX_tmpBetCount_CategoryId ON #tmpBetCount(
		CategoryId
	);

	INSERT INTO #tmpCustomers(CustId, SportId, IsProbationLastDay)
	SELECT	T.C.value('./@CustId', 'INT')			  AS CustId
		,	T.C.value('./@SportId', 'SMALLINT')		  AS SportId
		,	T.C.value('./@IsProbationLastDay', 'BIT') AS IsProbationLastDay
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- #1: Filter Active Customers
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	INSERT INTO #tmpActiveMember(CustId, IsActive)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	

	-- #2.1: Remove account Closed & Disabled accounts & SMA account & Internal Account
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.[Enabled] = 0 OR c.roleid <> 1)
		OR c.srecommend IN (41430709)
		OR c.mrecommend IN (27899314,11656504,12146012)
		OR c.recommend IN (52466,5707545,29270764,134456,27787409)
		OR c.username LIKE '%CashOut';

	-- #2.2: Remove Inactive accounts
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN #tmpActiveMember AS a WITH(NOLOCK) ON a.CustId = r.CustId
	WHERE a.IsActive = 0;

	-- #3: GetCustomer Accummulated data
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(15))
							  FROM #tmpCustomers
							  FOR XML PATH ('')), 1, 1, '');

	INSERT INTO #tmpRawData(CustId, SportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDaysCustID, ActiveDaysSportGroup, WindaysCustID, WinDaysSportGroup)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList, @ResultDataMode = 1;	

	-- #4: Sum data by custid, sportid
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, SportId, CurrentCategoryId, IsProbationLastDay, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays, WinDaysRate)
	SELECT	a.CustId
		,	a.SportId
		,   @CATEGORY_PROBATION
		,   c.IsProbationLastDay
		,	a.TurnoverRM
		,	a.WinlossRM
		,	CASE WHEN a.TurnoverRM = 0 THEN 0 ELSE a.WinlossRM / a.TurnoverRM * 100 END
		,	a.BetCount
		,	a.ActiveDaysSportGroup
		,	CASE WHEN a.ActiveDaysSportGroup = 0 THEN 0 ELSE ((a.WinDaysSportGroup * 1.0) / a.ActiveDaysSportGroup) * 100 END
	FROM #tmpRawData AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.CustId AND a.SportId = c.SportId;

	-- #5: Log Input Data
	INSERT INTO dbo.CustomerClassification_BySport_InputLog(CustId, SportId, CreatedDate, CreatedTime, FunctionId, TurnoverRM, WinlossRM, BetCount, CurrentCategoryId, ActiveDays, WinDaysRate)
	SELECT CustId, SportId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, TurnoverRM, WinlossRM, BetCount, CurrentCategoryId, ActiveDays, WinDaysRate
	FROM #tmpCustomerAccummulatedInfo;

	-- #6: Get site info and 
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET	  a.Site = c.Site
		, a.SRecommend = c.srecommend
		, a.IsSpecialSite = CASE
								WHEN a.SportId = @SPORT_NONSPORT THEN NULL
								WHEN a.SportId = @SPORT_ESPORT AND c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada', 'WINHX1') THEN 1
								WHEN a.SportId <> @SPORT_ESPORT AND c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1
								ELSE 0
							END		
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

	-- #7: Remove 'Odd Feed Sites'
	DELETE a
	FROM  #tmpCustomerAccummulatedInfo AS a WITH(ROWLOCK)
	WHERE (a.Site = 'NextBet' OR a.Site = '9wickets' OR a.Site = '9wsports');

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;	

	-- #8: Classify Probation Category
	INSERT INTO #tmpResultData(CustId, SportId, CategoryId)
	SELECT  CustId
		,	SportId
		,	CategoryId
	FROM (
			SELECT  a.CustId
				,	a.SportId
				,   r.CategoryId
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId, a.SportId ORDER BY r.Prioity ASC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
				INNER JOIN dbo.CustomerClassification_BySport_Rule AS r WITH(NOLOCK) ON a.SportId = r.SportId 
			 WHERE 	   (r.RuleGroupId = 2 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)																			-- NEW MEMBER	
					OR (r.RuleGroupId = 3 AND a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)																				-- GOOD
					OR (r.RuleGroupId = 4 AND (a.IsSpecialSite IS NULL OR a.IsSpecialSite = r.IsSpecialSite) AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)												-- NORMAL
					OR (r.RuleGroupId = 5 AND (a.IsSpecialSite IS NULL OR a.IsSpecialSite = r.IsSpecialSite) AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND NOT (a.BetCount > r.BetCount2 AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays))	-- NORMAL									
					OR (r.RuleGroupId = 6 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)																		-- NORMAL
					OR (r.RuleGroupId = 7 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)																				-- NORMAL
					OR (r.RuleGroupId = 12 AND r.CurrentCategory = a.CurrentCategoryId AND a.IsProbationLastDay = 1 AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)			-- SMART
					OR (r.RuleGroupId = 13 AND r.CurrentCategory = a.CurrentCategoryId AND a.IsProbationLastDay = 1 AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)		-- SMART
					OR (r.RuleGroupId = 17 AND r.CurrentCategory = a.CurrentCategoryId AND a.IsProbationLastDay = 1 AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)										-- RISKY
					OR (r.RuleGroupId = 20 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsProbationLastDay = 1 AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM AND a.WinDaysRate > r.WinDaysRate)		-- SMART
					OR (r.RuleGroupId = 22 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsProbationLastDay = 1 AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM AND a.WinDaysRate > r.WinDaysRate)									-- RISKY
		) as b
	 WHERE b.RowNum = 1;

	INSERT INTO dbo.CustomerClassification_BySport(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	OUTPUT INSERTED.CustId, INSERTED.SportId, INSERTED.CategoryId, INSERTED.BetCount INTO #tmpBetCount  
	SELECT  a.CustId
		,	a.SportId
		,	CASE WHEN r.CategoryId IS NULL THEN a.CurrentCategoryId ELSE r.CategoryId END
		,	@CurrentDate
		,	@CurrentDateTime
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.BetCount
		,	a.ActiveDays
	 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
	   LEFT JOIN #tmpResultData AS r WITH(NOLOCK) ON a.CustId = r.CustId AND a.SportId = r.SportId

	-- #9: Update last settle betcounts
	EXEC dbo.CTS_NormalAccountsClassification_BetCount_Update @CurrentDateTime = @CurrentDateTime, @IsGeneralFlow = 0;

	DROP TABLE #tmpRawData;
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpActiveMember;
	DROP TABLE #tmpResultData;
	DROP TABLE #tmpBetCount;
END;
GO 

GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_BySport_Probation] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_BySport_Probation] TO [bodbSPUNet]
GO