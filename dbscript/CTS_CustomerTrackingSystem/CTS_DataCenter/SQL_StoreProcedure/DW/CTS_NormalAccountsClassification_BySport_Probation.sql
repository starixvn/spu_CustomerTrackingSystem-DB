USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_Probation.sql]     Script Date: 9/13/2022 04:07:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_Probation]
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
		[CustId]				INT NOT NULL,
		[SportId]				INT NOT NULL,
		[IsSpecialSite]			BIT DEFAULT 0,
		[IsDeposit]				BIT DEFAULT 0,
		[SRecommend]			INT,
		[TurnoverRM]			MONEY NULL,
		[WinlossRM]				MONEY NULL,
		[Margin]				MONEY NULL,
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
	
	-- Parse customers info
	INSERT INTO #tmpCustomers(CustId, SportId, IsProbationLastDay)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportId', 'SMALLINT') AS SportId
		,	T.C.value('./@IsProbationLastDay', 'BIT') AS IsProbationLastDay
	FROM @CustomersXML.nodes('//ProbationModel') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- Check inactive customers
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	INSERT INTO #tmpActiveCustomers(CustId, IsActive)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	

	-- LOG INPUT DATA
	INSERT INTO dbo.CustomerClassification_InputLog(CustId, CreatedDate, CreatedTime, FunctionId, IsActive)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, IsActive
	FROM #tmpActiveCustomers WITH(NOLOCK );

	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN #tmpActiveCustomers AS a WITH(NOLOCK) ON a.CustId = r.CustId
	WHERE a.IsActive = 0;

	-- Get Customer's ID List
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	-- Get Customer's Accummulated data
	INSERT INTO #tmpRawData(CustId, SportId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
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
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	s.CustId
		,	SUM(s.TurnoverRM)
		,	SUM(s.WinlossRM)
		,	CASE WHEN SUM(s.TurnoverRM) = 0 THEN 0 ELSE SUM(s.WinlossRM) / SUM(s.TurnoverRM) * 100 END
		,	SUM(s.BetCount)
		,	MAX(s.ActiveDays)
	FROM #tmpRawData AS s WITH(NOLOCK)
	GROUP BY s.CustId;

	-- Get site info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET   a.SRecommend = c.srecommend
		, a.IsSpecialSite = CASE WHEN c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

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
			 WHERE 	(a.IsSpecialSite = 1 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)					-- NEW MEMBER	
					OR (a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)		-- GOOD
					OR (a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)												-- NORMAL
					OR (a.IsSpecialSite = 1 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)				-- NORMAL
					OR (a.IsDeposit = 0 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)					-- NORMAL
					OR (a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)				-- SMART
					OR (a.IsProbationLastDay = 1 AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM <= r.WinlossRM)			-- SMART
					--OR (a.IsProbationLastDay = 1 AND a.Margin <= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)				-- SMART
					OR (a.IsProbationLastDay = 1 AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)											-- RISKY
		) as b
	 WHERE b.RowNum = 1;

	DROP TABLE #tmpRawData;
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
END;