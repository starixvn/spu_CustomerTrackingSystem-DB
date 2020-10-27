USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_Probation_Finalize]    Script Date: 9/29/2020 5:12:53 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_Probation_Finalize]
		@CustomersXML			XML
AS
/*
	Created: 20200918@Long.Luu
	Task : Check the level of probation accounts after finishing probation duration
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200918@Long.Luu: Created [Redmine ID: #141755]
        - 20200924@Irena.Vo: Updated [Redmine ID: #141755]
		- 20201026@Long.Luu: Allow to move from Probation back to Normal, VIP [Redmine ID: #142546]
        
	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @PARLAY_SPORTID		SMALLINT = -100
		,	@OTHERS_SPORTID		SMALLINT = -99
		,	@GENERAL_SPORTID	SMALLINT = 200;
	DECLARE @GENERALCATEGORY_NORMALMEMBER		INT = 202
		,	@GENERALCATEGORY_SMARTPUNTER		INT = 203
		,	@GENERALCATEGORY_HIGHRISKPUNTER		INT = 204
		,	@GENERALCATEGORY_VIP				INT = 205
		,	@DETAILEDCATEGORY_NORMALMEMBER		INT = 4
		,	@DETAILEDCATEGORY_VIP				INT = 5
		,	@DETAILEDCATEGORY_SMARTPUNTER		INT = 6
		,	@DETAILEDCATEGORY_HIGHRISKPUNTER	INT = 7;

	DECLARE	@RptToDate			DATE = DATEADD(DAY, -1, GETDATE())
	DECLARE	@RptFromDate		DATE = DATEADD(DAY, -60, @RptToDate)
		,	@Last30Days			DATE = DATEADD(DAY, -30, @RptToDate)
		,	@CustIdList			VARCHAR(MAX)	
		,	@CurrentDateTime	DATETIME = GETDATE()
		,	@CurrentDate		DATE = GETDATE();
	
	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[TurnoverORG]		MONEY NULL,
		[WinlossORG]		MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[Margin]			MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL
	);

	IF	OBJECT_ID('tempdb..#tmpRawDailyData') IS NOT NULL
		DROP TABLE	#tmpRawDailyData;

	CREATE TABLE #tmpRawDailyData(
		[RptDate]			DATE NOT NULL,
		[CustId]			BIGINT NOT NULL,
		[SportId]			SMALLINT NOT NULL,
		[BettypeId]			SMALLINT NOT NULL,
		[Turnover]			MONEY NULL,
		[Winloss]			MONEY NULL,
		[BetCount]			BIGINT NULL
		PRIMARY KEY (RptDate, CustId, SportId, BettypeId)
	);

	IF	OBJECT_ID('tempdb..#tmpSportDailyData') IS NOT NULL
		DROP TABLE	#tmpSportDailyData;

	CREATE TABLE #tmpSportDailyData(
		[RptDate]			DATE NOT NULL,
		[CustId]			BIGINT NOT NULL,
		[SportId]			SMALLINT NOT NULL,
		[Turnover]			MONEY,
		[Winloss]			MONEY,
		[IsLast30Days]		BIT DEFAULT 0
		PRIMARY KEY (RptDate, CustId, SportId)
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
		[CustId]			INT,
		[SportId]			SMALLINT,
		[TargetCategoryId]	SMALLINT,
		[IsPassed]			BIT DEFAULT 0,
		PRIMARY KEY (CustId, SportId)
	);
	
	IF OBJECT_ID('tempdb..#tmpFilteredCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFilteredCustomers;
	END
	
	CREATE TABLE #tmpFilteredCustomers(
		[CustId]			INT,
		[SportId]			SMALLINT,
		[TargetCategoryId]	SMALLINT,
		PRIMARY KEY (CustId, SportId)
	);


	IF	OBJECT_ID('tempdb..#tmpSportGroups') IS NOT NULL
		DROP TABLE	#tmpSportGroups;

	CREATE TABLE #tmpSportGroups(
		[SportId]			INT NOT NULL, --1 soccer, 2 basketball, 3 othersports, 4 esports, 5 nonsports
		[MainDBSportId]		INT NOT NULL,
		PRIMARY KEY (SportId, MainDBSportId)
	);

	-- Init sportgroups
	INSERT INTO #tmpSportGroups(SportId, MainDBSportId)
	VALUES (1,1), (2,2), (4,43), (6,-100);

	INSERT INTO #tmpSportGroups(SportId, MainDBSportId)
	SELECT DISTINCT 3, s.SportType
	FROM bodb02.dbo.SportBettypeMatrix AS s WITH(NOLOCK)
	WHERE s.ProductID = 1
		AND s.SportType NOT IN (1,2,43);

	-- Parse customers info
	INSERT INTO #tmpCustomers(CustId, SportId, TargetCategoryId)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportGroupId', 'SMALLINT') AS SportId
		,	T.C.value('./@CategoryId', 'SMALLINT') AS CategoryId
	FROM @CustomersXML.nodes('//ProbationModel') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- FILTER BY MARGIN AND BETCOUNT
	-- Get Customer's ID List
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	-- Get Customer's Accummulated data
	INSERT INTO #tmpRawData(CustId, SportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList;

	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, SportId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDays)
	FROM #tmpRawData AS a WITH(NOLOCK)
		LEFT JOIN #tmpSportGroups AS s WITH(NOLOCK) ON a.SportId = s.MainDBSportId
	GROUP BY a.CustId, CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END
	UNION
	SELECT	s.CustId
		,	@GENERAL_SPORTID
		,	SUM(s.TurnoverRM)
		,	SUM(s.WinlossRM)
		,	CASE WHEN SUM(s.TurnoverRM) = 0 THEN 0 ELSE SUM(s.WinlossRM) / SUM(s.TurnoverRM) * 100 END
		,	SUM(s.BetCount)
		,	MAX(s.ActiveDays)
	FROM #tmpRawData AS s WITH(NOLOCK)
	GROUP BY s.CustId;

	-- Assign level for customers with margin <0
	UPDATE c WITH(ROWLOCK, UPDLOCK)
	SET c.IsPassed = 1,
		c.TargetCategoryId = CASE 
								WHEN (s.Margin <= -2 AND s.TurnoverRM > 150000 AND s.BetCount > 300 AND s.ActiveDays >= 8) THEN 
									CASE WHEN c.TargetCategoryId > 200 THEN @GENERALCATEGORY_VIP
									ELSE @DETAILEDCATEGORY_VIP END
								ELSE
									CASE WHEN c.TargetCategoryId > 200 THEN @GENERALCATEGORY_NORMALMEMBER
									ELSE @DETAILEDCATEGORY_NORMALMEMBER END
							 END
	FROM #tmpCustomers AS c
		INNER JOIN #tmpCustomerAccummulatedInfo AS s ON c.CustId = s.CustId AND c.SportId = s.SportId
	WHERE s.Margin < 0;
    
	-- Filter customers by: Bet count >= 60 tickets (count from beginning) & Margin >= 0
	INSERT INTO #tmpFilteredCustomers(CustId, SportId, TargetCategoryId)
	SELECT c.CustId, c.SportId, c.TargetCategoryId
	FROM #tmpCustomers AS c
		INNER JOIN #tmpCustomerAccummulatedInfo AS s ON c.CustId = s.CustId AND c.SportId = s.SportId
	WHERE s.BetCount >= 60
		OR s.Margin >= 0;

	-- FILTER BY WINNING COUNT
	-- Get daily raw data for all sports
	INSERT INTO #tmpRawDailyData(RptDate, CustId, SportId, BettypeId, Turnover, Winloss, BetCount)
	SELECT	s.RptFromDate
		,	s.CustId
		,	s.SportType
		,	s.BetType
		,	SUM(s.MemberTurnover)
		,	SUM(s.MemberWinloss)
		,	SUM(s.BetCount)
	FROM bodb_Account.dbo.[FactCustProductStatsDetail] AS s WITH(NOLOCK)
		INNER JOIN #tmpFilteredCustomers AS t ON s.CustID = t.CustId
	WHERE s.RptFromDate >= @RptFromDate AND s.RptFromDate <= @RptToDate
	GROUP BY s.RptFromDate, s.CustId, s.SportType, s.BetType;

	-- Sum all for General Sport
	INSERT INTO #tmpSportDailyData(RptDate, CustId, SportId, Turnover, Winloss, IsLast30Days)
	SELECT	s.RptDate
		,	s.CustId
		,	@GENERAL_SPORTID
		,	SUM(s.Turnover)
		,	SUM(s.Winloss)
		,	CASE WHEN s.RptDate >= @Last30Days THEN 1 ELSE 0 END
	FROM #tmpRawDailyData AS s WITH(NOLOCK)
	GROUP BY s.RptDate, s.CustId;

	-- Sum data for Parlay
	INSERT INTO #tmpSportDailyData(RptDate, CustId, SportId, Turnover, Winloss, IsLast30Days)
	SELECT	s.RptDate
		,	s.CustId
		,	@PARLAY_SPORTID
		,	SUM(s.Turnover)
		,	SUM(s.Winloss)
		,	CASE WHEN s.RptDate >= @Last30Days THEN 1 ELSE 0 END
	FROM #tmpRawDailyData AS s WITH(NOLOCK)
	WHERE s.BettypeId IN (9, 29)
	GROUP BY s.RptDate, s.CustId;

	-- Sum data for all sports except Parlay, General Sport
	INSERT INTO #tmpSportDailyData(RptDate, CustId, SportId, Turnover, Winloss, IsLast30Days)
	SELECT	t.RptDate
		,	t.CustId
		,	t.SportId
		,	t.Turnover
		,	t.Winloss
		,	CASE WHEN t.RptDate >= @Last30Days THEN 1 ELSE 0 END
	FROM (
			SELECT	a.RptDate
				,	a.CustId
				,	CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END AS SportId
				,	SUM(a.Turnover) AS Turnover
				,	SUM(a.Winloss) AS Winloss
			FROM #tmpRawDailyData AS a WITH(NOLOCK)
				LEFT JOIN #tmpSportGroups AS s WITH(NOLOCK) ON a.SportId = s.MainDBSportId
			WHERE a.BettypeId NOT IN (9, 29) 
			GROUP BY a.RptDate, a.CustId, CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END
		) AS t;
	
	-- Filter customer by: Last 30 days' margin >= 0%
	WITH CTE_CustLoseInLast30Days(CustId, SportId)
	AS(
		SELECT	a.CustId
			,	a.SportId
		FROM #tmpSportDailyData AS a WITH(NOLOCK)
		WHERE a.IsLast30Days = 1
		GROUP BY a.CustId, a.SportId
		HAVING SUM(a.Winloss) < 0
	)
	DELETE c WITH(ROWLOCK)
	FROM #tmpFilteredCustomers AS c
		INNER JOIN CTE_CustLoseInLast30Days AS a ON c.CustId = a.CustId AND c.SportId = a.SportId;
			
	-- Filter customer by: At least 40/60 days with margin > 0%
	WITH CTE_CustWinCounterInLast60Days(CustId, SportId, DayWinCount)
	AS(
		SELECT	a.CustId
			,	a.SportId
			,	COUNT(1)
		FROM #tmpSportDailyData AS a WITH(NOLOCK)
			INNER JOIN #tmpFilteredCustomers AS c ON c.CustId = a.CustId AND c.SportId = a.SportId
		WHERE a.Winloss > 0
		GROUP BY a.CustId, a.SportId
	)
	DELETE c WITH(ROWLOCK)
	FROM #tmpFilteredCustomers AS c
		INNER JOIN CTE_CustWinCounterInLast60Days AS a ON c.CustId = a.CustId AND c.SportId = a.SportId
	WHERE a.DayWinCount < 40;

	UPDATE c WITH(ROWLOCK, UPDLOCK)
	SET c.IsPassed = 1,
		c.TargetCategoryId = CASE 
								WHEN t.Margin <= 1 THEN 
									CASE WHEN c.TargetCategoryId > 200 THEN @GENERALCATEGORY_SMARTPUNTER
									ELSE @DETAILEDCATEGORY_SMARTPUNTER END
								ELSE
									CASE WHEN c.TargetCategoryId > 200 THEN @GENERALCATEGORY_HIGHRISKPUNTER
									ELSE @DETAILEDCATEGORY_HIGHRISKPUNTER END
							 END
	FROM #tmpCustomers AS c
		INNER JOIN	(
						SELECT f.CustId, f.SportId, 
							CASE WHEN SUM(d.Turnover) = 0 THEN 0 ELSE (SUM(d.Winloss) / SUM(d.Turnover) * 100) END AS Margin
						FROM #tmpFilteredCustomers AS f WITH(NOLOCK)
							INNER JOIN #tmpSportDailyData AS d WITH(NOLOCK) ON f.CustId = d.CustId AND d.SportId = f.SportId
						GROUP BY f.CustId, f.SportId
					) AS t ON c.CustId = t.CustId AND c.SportId = t.SportId;
	
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	a.SportId
		,	a.TargetCategoryId
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	t.TurnoverRM
		,	t.WinlossRM
		,	t.BetCount
		,	t.ActiveDays
	FROM #tmpCustomers AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomerAccummulatedInfo AS t WITH(NOLOCK) ON a.CustId = t.CustId AND a.SportId = t.SportId -- 
	WHERE a.IsPassed = 1;
	
	-- Return results
	SELECT	CustId
		,	SportId AS 'SportGroupId'
		,	TargetCategoryId
		,	IsPassed
	FROM #tmpCustomers WITH(NOLOCK);
END;