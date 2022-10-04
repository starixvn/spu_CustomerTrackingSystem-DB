USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_GetAccummulatedInfo]    Script Date: 9/6/2022 11:08:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_GetAccummulatedInfo]
		@CustomersXML			XML
AS
/*
	Created: 20200918@Long.Luu
	Task : Get customer's accummulated info
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200918@Long.Luu: Created [Redmine ID: #141755]
        - 20200924@Irena.Vo: Updated [Redmine ID: #141755]		
		- 20201006@Long.Luu: Return more valus [Redmine ID: #142546]
        
	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @PARLAY_SPORTID		SMALLINT = -100;
	DECLARE @OTHERS_SPORTID		SMALLINT = -99;
	DECLARE @GENERAL_SPORTID	SMALLINT = 200;
	DECLARE @CustIdList			VARCHAR(MAX);
	
	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
		[SportGroup]		VARCHAR(50) NOT NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[TurnoverORG]		MONEY NULL,
		[WinlossORG]		MONEY NULL,
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

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
		[CustId]			INT,
		[SportId]			SMALLINT,
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
	INSERT INTO #tmpCustomers(CustId, SportId)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportGroupId', 'SMALLINT') AS SportId
	FROM @CustomersXML.nodes('//ProbationModel') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- FILTER BY MARGIN AND BETCOUNT
	-- Get Customer's ID List
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	-- Get Customer's Accummulated data
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, SportId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList;

	-- Filter customers by: Bet count >= 60 tickets (count from beginning) & Margin >= 0
	WITH CTE_CustSportGroups(CustId, SportId, Turnover, Winloss, Margin, BetCount, ActiveDays)
	AS(
		SELECT	a.CustId
			,	CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END
			,	SUM(a.TurnoverRM)
			,	SUM(a.WinlossRM)
			,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
			,	SUM(a.BetCount)
			,	MAX(a.ActiveDays)
		FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
			LEFT JOIN #tmpSportGroups AS s WITH(NOLOCK) ON a.SportId = s.MainDBSportId
		GROUP BY a.CustId, CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END
		UNION
		SELECT	s.CustId
			,	@GENERAL_SPORTID
			,	SUM(s.TurnoverRM)
			,	SUM(s.WinlossRM)
			,	CASE WHEN SUM(s.TurnoverRM) = 0 THEN 0 ELSE SUM(s.WinlossRM)/SUM(s.TurnoverRM)*100 END
			,	SUM(s.BetCount)
			,	MAX(s.ActiveDays)
		FROM #tmpCustomerAccummulatedInfo AS s WITH(NOLOCK)
		GROUP BY s.CustId
	)
	SELECT	s.CustId
		,	s.SportId
		,	s.Turnover
		,	s.Winloss
		,	s.Margin
		,	s.BetCount
		,	s.ActiveDays
	FROM #tmpCustomers AS c
		INNER JOIN CTE_CustSportGroups AS s ON c.CustId = s.CustId AND c.SportId = s.SportId;
END;



