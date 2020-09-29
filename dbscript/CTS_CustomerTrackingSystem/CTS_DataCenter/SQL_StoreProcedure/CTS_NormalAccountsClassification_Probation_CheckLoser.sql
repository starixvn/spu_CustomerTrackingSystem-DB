USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_Probation_CheckLoser]    Script Date: 9/28/2020 10:33:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_Probation_CheckLoser]
		@CustomersXML			XML
AS
/*
	Created: 20200918@Long.Luu
	Task : Check whether probation accounts are loser
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200918@Long.Luu: Created [Redmine ID: #141755]
        - 20200924@Irena.Vo: Updated [Redmine ID: #141755]
         
	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @PARLAY_SPORTID		SMALLINT = -100;
	DECLARE @OTHERS_SPORTID		SMALLINT = -99;
	DECLARE @GENERAL_SPORTID	SMALLINT = 200;
	DECLARE	@RptDate			DATE = DATEADD(DAY, -1, GETDATE());
	
	
	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		[CustId]			BIGINT NOT NULL,
		[SportId]			SMALLINT NOT NULL,
		[BettypeId]			SMALLINT NOT NULL,
		[Turnover]			MONEY NULL,
		[Winloss]			MONEY NULL,
		[BetCount]			BIGINT NULL
		PRIMARY KEY (CustId, SportId, BettypeId)
	);

	IF	OBJECT_ID('tempdb..#tmpSportDailyData') IS NOT NULL
		DROP TABLE	#tmpSportDailyData;

	CREATE TABLE #tmpSportDailyData(
		[CustId]			BIGINT NOT NULL,
		[SportId]			SMALLINT NOT NULL,
		[Turnover]			MONEY NULL,
		[Winloss]			MONEY NULL,
		[BetCount]			BIGINT NULL
		PRIMARY KEY (CustId, SportId)
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
			CustId			INT
		,	SportId			SMALLINT
		,	CategoryId		SMALLINT
		,	PRIMARY KEY (CustId, SportId)
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
	INSERT INTO #tmpCustomers(CustId, SportId)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportGroupId', 'SMALLINT') AS SportId
	FROM @CustomersXML.nodes('//ProbationModel') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- Get raw data for all sports
	INSERT INTO #tmpRawData(CustId, SportId, BettypeId, Turnover, Winloss, BetCount)
	SELECT	s.CustId
		,	s.SportType
		,	s.BetType
		,	SUM(s.MemberTurnover)
		,	SUM(s.MemberWinloss)
		,	SUM(s.BetCount)
	FROM bodb_Account.dbo.[FactCustProductStatsDetail] AS s WITH(NOLOCK)
		INNER JOIN #tmpCustomers AS t ON s.CustID = t.CustId
	WHERE s.RptFromDate = @RptDate
	GROUP BY s.CustId, s.SportType, s.BetType;

	-- Sum all for General Sport
	INSERT INTO #tmpSportDailyData(CustId, SportId, Turnover, Winloss, BetCount)
	SELECT	s.CustId
		,	@GENERAL_SPORTID
		,	SUM(s.Turnover)
		,	SUM(s.Winloss)
		,	SUM(s.BetCount)
	FROM #tmpRawData AS s WITH(NOLOCK)
	GROUP BY s.CustId;

	-- Sum data for Parlay
	INSERT INTO #tmpSportDailyData(CustId, SportId, Turnover, Winloss, BetCount)
	SELECT	s.CustId
		,	@PARLAY_SPORTID
		,	SUM(s.Turnover)
		,	SUM(s.Winloss)
		,	SUM(s.BetCount)
	FROM #tmpRawData AS s WITH(NOLOCK)
	WHERE s.BettypeId IN (9, 29)
	GROUP BY s.CustId;

	-- Sum data for all sports except Parlay, General Sport
	WITH CTE_CustSportGroups(CustId, SportId, Turnover, Winloss, BetCount)
	AS(
		SELECT	a.CustId
			,	CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END
			,	SUM(a.Turnover)
			,	SUM(a.Winloss)
			,	SUM(a.BetCount)
		FROM #tmpRawData AS a WITH(NOLOCK)
			LEFT JOIN #tmpSportGroups AS s WITH(NOLOCK) ON a.SportId = s.MainDBSportId
		WHERE a.BettypeId NOT IN (9, 29)
		GROUP BY a.CustId, CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END
	)
	INSERT INTO #tmpSportDailyData(CustId, SportId, Turnover, Winloss, BetCount)
	SELECT	CustId
		,	SportId
		,	Turnover
		,	Winloss
		,	BetCount
	FROM CTE_CustSportGroups;
						
	-- Return results
	SELECT	s.CustId
		,	s.SportId AS 'SportGroupId'
	FROM #tmpSportDailyData AS s WITH(NOLOCK)
		INNER JOIN #tmpCustomers AS a WITH(NOLOCK) ON s.CustId = a.CustId AND s.SportId = a.SportId
	WHERE s.Winloss < 0;
END;