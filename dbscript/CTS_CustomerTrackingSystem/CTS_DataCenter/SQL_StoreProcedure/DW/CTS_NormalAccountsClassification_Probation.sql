ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_Probation]
		@CustomersXML			XML
AS
/*
	Created: 20201111@Long.Luu
	Task : Daily scan for Probation accounts
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20201111@Long.Luu: Created [Redmine ID: #145028]
		- 20201224@Long.Luu: Return more data [Redmine ID: #145951]
		- 20210408@John.Ngo: Special rule for Haifa CC2 & Problem Agent Category (only member level) [Redmine ID: #152884]
        
	Param's Explanation:

	Example:
		EXEC [dbo].[CTS_NormalAccountsClassification_Probation] @CustomersXML='<root> <ProbationModel CustId="123" SportGroupId="200" IsProbationLastDay="2" /> </root>';
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @PARLAY_SPORTID		SMALLINT = -100
		,	@GENERAL_SPORTID	SMALLINT = 200;

	DECLARE	@PROBATION_FULLPERIOD				SMALLINT = 20
		,	@PROBATION_MINDAYSWINTOPASS			SMALLINT = 14
		,	@PROBATION_LATESTDAYSWINTOPASS		SMALLINT = 7
		,	@PROBATION_MINBETSTOPASS			SMALLINT = 30;

	DECLARE @GENERALCATEGORY_NORMALMEMBER		INT = 202
		,	@GENERALCATEGORY_SMARTPUNTER		INT = 203
		,	@GENERALCATEGORY_HIGHRISKPUNTER		INT = 204
		,	@GENERALCATEGORY_VIP				INT = 205
		,	@GENERALCATEGORY_PROBATION			INT = 206;

	DECLARE	@RptToDate			DATE = DATEADD(DAY, -1, GETDATE())
	DECLARE	@RptFromDate		DATE = DATEADD(DAY, -(@PROBATION_FULLPERIOD), @RptToDate)
		,	@LastXDays			DATE = DATEADD(DAY, -(@PROBATION_LATESTDAYSWINTOPASS), @RptToDate)
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
		[ActiveDays]		INT NULL,
		PRIMARY KEY ([CustId],[SportId])
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT NOT NULL PRIMARY KEY,
		[Site]				VARCHAR (10) NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[Margin]			MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_Site ON #tmpCustomerAccummulatedInfo(
		[Site]				ASC
	);

	IF	OBJECT_ID('tempdb..#tmpRawDailyData') IS NOT NULL
		DROP TABLE	#tmpRawDailyData;

	CREATE TABLE #tmpRawDailyData(
		[RptDate]			DATE NOT NULL,
		[CustId]			BIGINT NOT NULL,
		[Turnover]			MONEY NULL,
		[Winloss]			MONEY NULL,
		[BetCount]			BIGINT NULL,
		[IsLastXDays]		BIT,
		PRIMARY KEY (RptDate, CustId)
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
		[CustId]					INT PRIMARY KEY,
		[CategoryId]				SMALLINT,
		[IsProbationLastDay]		BIT DEFAULT 0,
		[IsPassed]					BIT DEFAULT 0,
		[LastXDaysMargin]			MONEY,
		[ProbationPeriodWinloss]	MONEY
	);
	
	IF OBJECT_ID('tempdb..#tmpFilteredCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpFilteredCustomers;
	END
	
	CREATE TABLE #tmpFilteredCustomers(
		[CustId]			INT PRIMARY KEY
	);
	
	-- Parse customers info
	INSERT INTO #tmpCustomers(CustId, IsProbationLastDay)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@IsProbationLastDay', 'BIT') AS IsProbationLastDay
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

	-- Remove Parlay
	DELETE FROM #tmpRawData
	WHERE SportId = @PARLAY_SPORTID;

	-- Remove SMA account
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
		LEFT JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE c.roleid <> 1;

	-- Sum data by sport
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, Site, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	s.CustId
		,	c.site
		,	SUM(s.TurnoverRM)
		,	SUM(s.WinlossRM)
		,	CASE WHEN SUM(s.TurnoverRM) = 0 THEN 0 ELSE SUM(s.WinlossRM) / SUM(s.TurnoverRM) * 100 END
		,	SUM(s.BetCount)
		,	MAX(s.ActiveDays)
	FROM #tmpRawData AS s WITH(NOLOCK)
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON s.CustId = c.custid
	GROUP BY s.CustId, c.site;

	-- Assign level for customers with margin <0 (to Normal or VIP)
	UPDATE c WITH(ROWLOCK, UPDLOCK)
	SET c.IsPassed = 1,
		c.CategoryId = CASE 
							WHEN (s.Margin <= -2 AND s.TurnoverRM > 150000 AND s.BetCount > 300 AND s.ActiveDays >= 8) THEN 
								@GENERALCATEGORY_VIP
							WHEN (s.Site <> 'haifa') THEN @GENERALCATEGORY_NORMALMEMBER
							WHEN (s.Site = 'haifa' AND s.WinlossRM >= -20000) THEN @GENERALCATEGORY_NORMALMEMBER
							ELSE
								@GENERALCATEGORY_PROBATION
						END,
		c.LastXDaysMargin = s.Margin,
		c.ProbationPeriodWinloss = s.WinlossRM
	FROM #tmpCustomers AS c
		INNER JOIN #tmpCustomerAccummulatedInfo AS s ON c.CustId = s.CustId
	WHERE s.Margin < 0;
    
	-- Filter customers by: Bet count >= @PROBATION_MINBETSTOPASS tickets (count from beginning) & Margin >= 0
	INSERT INTO #tmpFilteredCustomers(CustId)
	SELECT c.CustId
	FROM #tmpCustomers AS c
		INNER JOIN #tmpCustomerAccummulatedInfo AS s ON c.CustId = s.CustId
	WHERE	c.IsProbationLastDay = 1
		AND s.BetCount >= @PROBATION_MINBETSTOPASS
		AND s.Margin >= 0;

	-- FILTER BY WINNING COUNT
	-- Get daily raw data for all sports (exclude Parlay)
	INSERT INTO #tmpRawDailyData(RptDate, CustId, Turnover, Winloss, BetCount, IsLastXDays)
	SELECT	s.RptFromDate
		,	s.CustId
		,	SUM(s.MemberTurnover)
		,	SUM(s.MemberWinloss)
		,	SUM(s.BetCount)		
		,	CASE WHEN s.RptFromDate >= @LastXDays THEN 1 ELSE 0 END
	FROM bodb_Account.dbo.[FactCustProductStatsDetail] AS s WITH(NOLOCK)
		INNER JOIN #tmpFilteredCustomers AS t ON s.CustID = t.CustId
	WHERE s.RptFromDate >= @RptFromDate AND s.RptFromDate <= @RptToDate
		AND s.BetType NOT IN (9, 29)
	GROUP BY s.RptFromDate
		,	s.CustId
		,	CASE WHEN s.RptFromDate >= @LastXDays THEN 1 ELSE 0 END;

	-- Filter customer by: At least @PROBATION_MINDAYSWINTOPASS/@PROBATION_FULLPERIOD days with margin > 0%
	WITH CTE_CustWinCounterInProbationFullPeriod(CustId, DayWinCount)
	AS(
		SELECT	a.CustId
			,	SUM(CASE WHEN a.Winloss > 0 THEN 1 ELSE 0 END)
		FROM #tmpRawDailyData AS a WITH(NOLOCK)
			RIGHT JOIN #tmpFilteredCustomers AS c ON c.CustId = a.CustId
		GROUP BY a.CustId
	)
	DELETE c WITH(ROWLOCK)
	FROM #tmpFilteredCustomers AS c
		INNER JOIN CTE_CustWinCounterInProbationFullPeriod AS a ON c.CustId = a.CustId
	WHERE a.DayWinCount < @PROBATION_MINDAYSWINTOPASS;
	
	UPDATE c WITH(ROWLOCK, UPDLOCK)
	SET c.IsPassed = 1,
		c.CategoryId = CASE 
								WHEN (a.Margin <= 1 AND (t.TotalWinlossLastXDays >= 0 OR t.TotalWinloss > 10000)) THEN 
									@GENERALCATEGORY_SMARTPUNTER
								WHEN (a.Margin > 1 AND (t.TotalWinlossLastXDays >= 0 OR t.TotalWinloss > 20000)) THEN
									@GENERALCATEGORY_HIGHRISKPUNTER
								ELSE @GENERALCATEGORY_PROBATION
							 END,
		c.LastXDaysMargin = CASE WHEN t.TotalTurnoverLastXDays <> 0 THEN t.TotalWinlossLastXDays/t.TotalTurnoverLastXDays*100 ELSE 0 END,
		c.ProbationPeriodWinloss = t.TotalWinloss
	FROM #tmpCustomers AS c
		INNER JOIN #tmpCustomerAccummulatedInfo AS a ON c.CustId = a.CustId
		INNER JOIN	(
						SELECT	f.CustId
							,	SUM(d.Winloss) AS TotalWinloss
							,	SUM(CASE WHEN d.IsLastXDays = 1 THEN d.Winloss ELSE 0 END) AS TotalWinlossLastXDays
							,	SUM(CASE WHEN d.IsLastXDays = 1 THEN d.Turnover ELSE 0 END) AS TotalTurnoverLastXDays
						FROM #tmpFilteredCustomers AS f WITH(NOLOCK)
							INNER JOIN #tmpRawDailyData AS d WITH(NOLOCK) ON f.CustId = d.CustId
						GROUP BY f.CustId
					) AS t ON c.CustId = t.CustId
	WHERE a.Margin >= 0;
	
	UPDATE c WITH(ROWLOCK, UPDLOCK)
	SET c.IsPassed = 0
	FROM #tmpCustomers AS c
	WHERE c.CategoryId = @GENERALCATEGORY_PROBATION;
	
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, LastXDaysMargin, ProbationPeriodWinloss)
	SELECT  a.CustId
		,  @GENERAL_SPORTID
		,  a.CategoryId
		,  @CurrentDate AS CreatedDate
		,  @CurrentDateTime AS CreatedTime
		,  t.TurnoverRM
		,  t.WinlossRM
		,  t.BetCount
		,  t.ActiveDays
		,  a.LastXDaysMargin
		,  a.ProbationPeriodWinloss
	FROM #tmpCustomers AS a WITH(NOLOCK)
	INNER JOIN #tmpCustomerAccummulatedInfo AS t WITH(NOLOCK) ON a.CustId = t.CustId
	WHERE a.IsPassed = 1;

	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	@GENERAL_SPORTID
		,	@GENERALCATEGORY_PROBATION
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	t.TurnoverRM
		,	t.WinlossRM
		,	t.BetCount
		,	t.ActiveDays
	FROM #tmpCustomers AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomerAccummulatedInfo AS t WITH(NOLOCK) ON a.CustId = t.CustId
	WHERE a.IsPassed = 0;
	
	-- Return results
	SELECT	CustId
		,	@GENERAL_SPORTID AS 'SportGroupId'
		,	IsProbationLastDay
		,	CategoryId
		,	LastXDaysMargin
		,	ProbationPeriodWinloss
		,	IsPassed
	FROM #tmpCustomers WITH(NOLOCK);

	DROP TABLE #tmpRawData;
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpRawDailyData;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpFilteredCustomers;
END;