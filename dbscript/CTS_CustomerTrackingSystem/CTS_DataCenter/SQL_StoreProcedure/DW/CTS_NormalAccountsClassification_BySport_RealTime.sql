USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_RealTime]    Script Date: 9/6/2022 5:07:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_RealTime]
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
		exec [dbo].[CTS_NormalAccountsClassification_BySport_RealTime]
*/
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @SPORT_SOCCER			SMALLINT = 1;
	DECLARE @SPORT_BASKETBALL		SMALLINT = 2;
	DECLARE @SPORT_ESPORT			SMALLINT = 43;
	DECLARE @SPORT_OTHERSPORT		SMALLINT = 99;
	DECLARE @FUNCTIONID				SMALLINT = 100;

	DECLARE @CATEGORY_NEWMEMBER			INT = 201
		,	@CATEGORY_NORMALMEMBER		INT = 202
		,	@CATEGORY_SMARTPUNTER		INT = 203
		,	@CATEGORY_HIGHRISKPUNTER	INT = 204
		,	@CATEGORY_GOODMEMBER		INT = 205
		,	@CATEGORY_PROBATION			INT = 206

	DECLARE	@CurrentDateTime			DATETIME = GETDATE()
		,	@CurrentDate				DATE = GETDATE();

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
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

	CREATE CLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_Margin ON #tmpCustomerAccummulatedInfo(
		Margin				ASC,
		TurnoverRM			ASC
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_ActiveDaysBetCount ON #tmpCustomerAccummulatedInfo(
		ActiveDays			ASC,
		BetCount			ASC
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
	
	-- LOG INPUT DATA
	INSERT INTO dbo.CustomerClassification_InputLog(CustId,CreatedDate,CreatedTime,FunctionId)
	SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID
	FROM #tmpCustomers;	
	
	-- START	
	-- #1: GetCustomer Accummulated data  
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, SportId, CurrentCategoryId, IsSpecialSite, SRecommend, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	a.SportId
		,	c.CurrentCategoryId
		,	CASE WHEN cu.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
		,	cu.srecommend
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.Margin
		,	a.BetCount
		,	a.ActiveDays
	FROM dbo.CustomerClassification_BySport_LatestChanged AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.CustId AND a.SportId = c.SportId
		LEFT JOIN bodb02.dbo.Customer AS cu WITH(NOLOCK) ON a.CustId = cu.custid;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;

	-- #2: Insert Accounts's BetCount
	INSERT INTO dbo.CustomerClassification_BySport_BetCount(CustId, SportId, BetCount)
	SELECT c.CustId, c.SportId, 0
	FROM #tmpCustomers AS c WITH(NOLOCK)
		LEFT JOIN dbo.CustomerClassification_BySport_BetCount AS v WITH(NOLOCK) ON c.CustId = v.CustId AND c.SportId = v.SportId
	WHERE c.CurrentCategoryId IN (@CATEGORY_NORMALMEMBER, @CATEGORY_GOODMEMBER) 
		AND v.CustId IS NULL;
		
	-- #3: Remove Accounts that Ticket Count has not reach the schedule
	-- Remove Accounts less than 100 tickets compared to last scan for GOODMEMBER
	DELETE a WITH(ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN dbo.CustomerClassification_BySport_BetCount AS v WITH(NOLOCK) ON a.CustId = v.CustId AND a.SportId = v.SportId
	WHERE a.CurrentCategoryId IN (@CATEGORY_GOODMEMBER)
		AND (v.CustId IS NOT NULL AND (a.BetCount - v.BetCount < 100));

	-- Remove Accounts less than 20 tickets compared to last scan for Normal Member
	DELETE a WITH(ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN dbo.CustomerClassification_BySport_BetCount AS v WITH(NOLOCK) ON a.CustId = v.CustId AND a.SportId = v.SportId
	WHERE a.CurrentCategoryId IN (@CATEGORY_NORMALMEMBER)
		AND (v.CustId IS NOT NULL AND (a.BetCount - v.BetCount < 20));

	-- #4: Classify GOOD, NEW, NORMAL, PROBATION MEMBER
	INSERT INTO dbo.CustomerClassification_BySport(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT CustId
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
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId, a.SportId, r.CategorId ORDER BY r.Prioity DESC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
				INNER JOIN dbo.CustomerClassification_BySport_Rule AS r WITH(NOLOCK) ON a.SportId = r.SportId 
			 WHERE a.BetCount < r.BetCount																										-- NEW MEMBER			
					OR (a.IsSpecialSite = 1 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)					-- NEW MEMBER	
					OR (a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)		-- GOOD
					OR (a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)												-- NORMAL
					OR (a.BetCount >= r.BetCount AND a.Margin < r.Margin AND (a.TurnoverRM <= r.TurnoverRM OR a.ActiveDays < r.ActiveDays))		-- NORMAL
					OR (a.IsSpecialSite = 1 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)				-- NORMAL
					OR (a.IsDeposit = 0 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)					-- NORMAL
					OR (a.IsDeposit = 0 AND a.Margin >= r.Margin AND a.WinlossRM >= r.WinlossRM)												-- PROBATION
					OR (a.IsDeposit = 1 AND a.Margin >= r.Margin)																			    -- PROBATION
		) as b
	 WHERE b.RowNum = 1;

	-- #8: Update last scanned ticket count back to dbo.CustomerClassification_BetCount
	UPDATE v WITH(ROWLOCK, UPDLOCK)
	SET v.BetCount = CASE 
						WHEN a.CurrentCategoryId IN (@CATEGORY_GOODMEMBER) 
							THEN (a.BetCount - (a.BetCount % 100))
						WHEN a.CurrentCategoryId IN (@CATEGORY_NORMALMEMBER) 
							THEN (a.BetCount - (a.BetCount % 20))
					END
		,	v.LastScannedDate = @CurrentDateTime
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
		INNER JOIN dbo.CustomerClassification_BySport_BetCount AS v ON a.CustId = v.CustId AND a.SportId = v.SportId;
	
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
END;