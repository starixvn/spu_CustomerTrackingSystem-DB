USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_Metaverse]    Script Date: 1/31/2023 2:55:00 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_Metaverse]
	@CustomersXML			XML
AS
/*
	Created: 20220118@Long.Luu
	Task : Classify Normal Customer Generally -  Metaverse (Support rescan normal for null/wrong customer category)
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20220118@Long.Luu: Created [Redmine ID: #0000]
		- 20230203@Jonas.Huynh: Update logic [Redmine ID: #0000]

	Param's Explanation:
				@CustomersXML = N'<Root>
										<r CustId="4345542" CategoryId ="201"/>
										<r CustId="4345541" CategoryId ="201"/>
								 </Root>';
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @FUNCTIONID					SMALLINT = 0; -- From metaverse
	DECLARE @CATEGORY_NORMALINACTIVE	INT		 = 1001
	   	,   @CATEGORY_SMARTINACTIVE		INT		 = 1002
		,	@CATEGORY_SMARTPUNTER		INT		 = 203
		,	@CATEGORY_RISKY				INT		 = 204
		,	@CATEGORY_PROBATION			INT		 = 206
		,	@CATEGORY_NEWMEMBER			INT		 = 201;
	
	DECLARE @GENERAL_SPORTID			SMALLINT = 200;
	DECLARE @CurrentDateTime			DATETIME = GETDATE()
	    ,   @CurrentDate				DATE	 = GETDATE()
	    ,	@ToDate						DATE	 = GETDATE();
	DECLARE @From30Date					DATE	 = DATEADD(DAY, - 30, @ToDate);
	DECLARE @ListCustIds				VARCHAR(MAX);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers(
			CustId					INT PRIMARY KEY
		,	CurrentCategoryId		SMALLINT
		,	SiteName				VARCHAR (10)	NULL
		,	IsSpecialSite			BIT				DEFAULT 0
		,	SRecommend				INT
		,	IsActive				BIT				DEFAULT 0
		,	IsCreatedWithin30Days	BIT				DEFAULT 0
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomers_SiteName ON #tmpCustomers(
		SiteName
	);

	IF OBJECT_ID('tempdb..#tmpActiveMember') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpActiveMember;
	END
	
	CREATE TABLE #tmpActiveMember(
		CustId					INT PRIMARY KEY,
		IsActive				BIT DEFAULT 0
	);

	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		CustId					INT				NOT NULL,
		SportId					INT				NOT NULL,
		TurnoverRM				DECIMAL(19, 4)	NULL,
		WinlossRM				DECIMAL(19, 4)	NULL,
		TurnoverORG				DECIMAL(19, 4)	NULL,
		WinlossORG				DECIMAL(19, 4)	NULL,
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
		CustId				INT				NOT NULL,		
		IsActive			BIT				DEFAULT 0,
		CurrentCategoryId	SMALLINT		NULL,
		NewCategoryId		SMALLINT		NULL,
		SiteName			VARCHAR (10)	NULL,
		IsSpecialSite		BIT				DEFAULT 0,
		IsDeposit			BIT				DEFAULT 0,
		SRecommend			INT,
		TurnoverRM			DECIMAL(19, 4)	NULL,
		WinlossRM			DECIMAL(19, 4)	NULL,
		Margin				DECIMAL(19, 4)	NULL,
		BetCount			BIGINT			NULL,
		ActiveDays			INT				NULL	
	);

	CREATE CLUSTERED INDEX CIX_tmpCustomerAccummulatedInfo_CustId ON #tmpCustomerAccummulatedInfo(
		[CustId]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_Site ON #tmpCustomerAccummulatedInfo(
		SiteName	ASC
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		[CurrentCategoryId]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SRecommend ON #tmpCustomerAccummulatedInfo(
		[SRecommend]
	);
	
	-- #1: Filter Customers
	INSERT INTO #tmpCustomers(CustId, CurrentCategoryId)
	SELECT	T.C.value('./@CustId', 'INT')		   AS CustId
		,	T.C.value('./@CategoryId', 'SMALLINT') AS CurrentCategoryId
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	--#2: Remove closed & disabled accounts, SMA account, Internal Account
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.[Enabled] = 0 OR c.roleid <> 1)
		OR c.srecommend IN (41430709)
		OR c.mrecommend IN (27899314,11656504,12146012)
		OR c.recommend IN (52466,5707545,29270764,134456)
		OR c.username LIKE '%CashOut';
	
	-- #3: Get relevant info
	UPDATE m WITH(ROWLOCK, UPDLOCK)
	SET m.IsCreatedWithin30Days = CASE WHEN DATEDIFF(DAY, c.creatdate, GETDATE()) <= 30 THEN 1 ELSE 0 END,
		m.SiteName = c.site,
		m.SRecommend = c.SRecommend,
		m.IsSpecialSite = CASE WHEN c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
	FROM #tmpCustomers AS m
		INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON m.CustId = c.custid;

	-- #4: Remove oddsfeed site
	DELETE r WITH(ROWLOCK)
	FROM  #tmpCustomers AS r WITH(ROWLOCK)
	WHERE (r.SiteName = 'NextBet' OR r.SiteName = '9wickets' OR r.SiteName = '9wsports');

	--#5: Check inactive customers
	SELECT @ListCustIds = STUFF((	SELECT DISTINCT ',', CONVERT(VARCHAR(15), CustId) 
									FROM #tmpCustomers WITH (NOLOCK)
									FOR XML PATH('')), 1, 1, '');

	INSERT INTO #tmpActiveMember(CustId, IsActive)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	

	UPDATE c WITH(ROWLOCK, UPDLOCK)
	SET c.IsActive = a.IsActive
	FROM #tmpCustomers AS c
		INNER JOIN #tmpActiveMember AS a WITH(NOLOCK) ON c.CustId = a.custid;

	-- #6: Get Customer's Accummulated data
	-- get more performance for null customer classification (over 30days & in 30days)
	INSERT INTO #tmpRawData(CustId, SportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDaysCustID, ActiveDaysSportGroup, WindaysCustID, WinDaysSportGroup)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 1;	
	
	-- #7: Sum data by custid
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDaysCustID)
	FROM #tmpRawData AS a WITH(NOLOCK)
	GROUP BY a.CustId;
	
	--#8: Update customer info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.CurrentCategoryId = c.CurrentCategoryId,
		a.IsActive = c.IsActive,
		a.SiteName = c.SiteName,
		a.SRecommend = c.SRecommend,
		a.IsSpecialSite = c.IsSpecialSite
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.custid;	
	
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;

	--#9: Log Data
	INSERT INTO dbo.CustomerClassification_InputLog(CustId, CreatedDate, CreatedTime, FunctionId, TurnoverRM, WinlossRM, BetCount, ActiveDays, CurrentCategoryId, IsActive)
	SELECT t.CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, ISNULL(TurnoverRM,0), ISNULL(WinlossRM,0), ISNULL(BetCount,0), ISNULL(ActiveDays,0), ISNULL(t.CurrentCategoryId,0), t.IsActive
	FROM #tmpCustomers AS t
		LEFT JOIN #tmpCustomerAccummulatedInfo AS c ON t.CustId = c.CustId;

	--#10: Insert for newly customer
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	t.CustId
		,	@GENERAL_SPORTID
		,	CASE WHEN t.IsCreatedWithin30Days = 1 THEN @CATEGORY_NEWMEMBER ELSE @CATEGORY_NORMALINACTIVE END
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	0
		,	0
		,	0
		,	0
	FROM #tmpCustomers AS t
		LEFT JOIN #tmpCustomerAccummulatedInfo AS c ON t.CustId = c.CustId
	WHERE c.CustId IS NULL;	
	
	--#11: Classify classification by general rule
	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET t.NewCategoryId = b.CategoryId,
		t.CurrentCategoryId = ISNULL(t.CurrentCategoryId,b.CategoryId)
	FROM (
			SELECT  a.CustId
				,   r.CategoryId
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId ORDER BY r.Prioity ASC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK) 
				 INNER JOIN dbo.CustomerClassification_Rule AS r WITH(NOLOCK) ON a.CurrentCategoryId = r.CurrentCategory 
			 WHERE 	   (r.RuleGroupId = 1 AND a.BetCount < r.BetCount
					OR (r.RuleGroupId = 2 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)			-- NEW MEMBER	
					OR (r.RuleGroupId = 3 AND a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)				-- GOOD
					OR (r.RuleGroupId = 4 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)				-- NORMAL
					OR (r.RuleGroupId = 5 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND NOT (a.BetCount > r.BetCount2 AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays))	-- NORMAL
					OR (r.RuleGroupId = 6 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)		-- NORMAL
					OR (r.RuleGroupId = 7 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)				-- NORMAL
					OR (r.RuleGroupId = 8 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM <= r.WinlossRM)					-- PROBATION
					OR (r.RuleGroupId = 9 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM <= r.WinlossRM)					-- PROBATION
					OR (r.RuleGroupId = 10 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin)												-- PROBATION
					OR (r.RuleGroupId = 11 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM >= r.WinlossRM)				-- PROBATION
					OR (r.RuleGroupId = 12 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM > r.WinlossRM)					-- SMART
					OR (r.RuleGroupId = 13 AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)				-- SMART
					OR (r.RuleGroupId = 14 AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)											-- SMART
					OR (r.RuleGroupId = 15 AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM > r.WinlossRM)												-- SMART
					OR (r.RuleGroupId = 16 AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM)												-- RISKY
					OR (r.RuleGroupId = 17 AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM))																			-- RISKY
		) AS b
		INNER JOIN #tmpCustomerAccummulatedInfo AS t ON b.CustId = t.CustId
	 WHERE b.RowNum = 1;

	 --#12: Insert to CustomerClassification
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	@GENERAL_SPORTID
		,	CASE WHEN a.NewCategoryId IS NULL THEN a.CurrentCategoryId ELSE a.NewCategoryId END
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.BetCount
		,	a.ActiveDays
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
	WHERE a.IsActive = 1;

	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	@GENERAL_SPORTID
		,	CASE WHEN a.CurrentCategoryId IN (@CATEGORY_SMARTPUNTER, @CATEGORY_RISKY, @CATEGORY_PROBATION) THEN @CATEGORY_SMARTINACTIVE ELSE @CATEGORY_NORMALINACTIVE END AS CategoryId
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	0
		,	0
		,	0
		,	0
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
	WHERE a.IsActive = 0
	
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpRawData;
	DROP TABLE #tmpActiveMember;
END;
GO
GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_Metaverse] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_Metaverse] TO [bodbSPUNet]
GO
