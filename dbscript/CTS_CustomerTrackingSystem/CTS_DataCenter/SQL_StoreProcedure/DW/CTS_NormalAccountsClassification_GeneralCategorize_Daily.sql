USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_Daily_xtest]    Script Date: 10/06/2022 14:24:2022 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_Daily]
	@CustomersXML			XML,
	@FunctionId				SMALLINT = -1
AS
/*
	Created: 20200901@Long.Luu
	Task : Classify Customer Generally -  Daily
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200901@Long.Luu: Created [Redmine ID: #137550]
        - 20201224@Long.Luu: Update insert data [Redmine ID: #145951]
		- 20210408@John.Ngo: Special rule for Haifa CC2 & Problem Agent Category (only member level) [Redmine ID: #152884]
		- 20210511@John.Ngo: Exclude Customer of Odd Feed Sites [Redmine ID: #154694]
		- 20210512@John.Ngo: Exclude Customer Class for Internal Account [Redmine ID: #154844]
        - 20210607@Long.Luu: Check Inactive Accounts [Redmine ID: #156465]
		- 20210714@Long.Luu: Special rule for ManbetX CC2 [Redmine ID: #158465]
		- 20210730@John.Ngo: [CTS] New way to store Closed Status [Redmine ID: #152259]		
		- 20210811@Long.Luu: Change way to check Customers' Inactive status [Redmine ID: #159543]		
		- 20210818@Long.Luu: Check Winloss on probation assessment [Redmine ID: #159709]	
		- 20220222@Long.Luu: Remove 10k Probation rule for Credit [Redmine ID: #168988]
		- 20280628@Long.Luu: Exclude more Internal Accounts [Redmine ID: #174430]
		- 20221006@Jonas.Huynh: New Rule for General Customer Classifiation [Redmine ID: #178022]
		- 20221118@Jonas.Huynh: Update parameter of DW SP GetCustAccumulatedInfo [Redmine ID: #179500]

	Param's Explanation:
				@CustomersXML = N'<Root>
										<r CustId="4345542" SportId="2" CategoryId ="201"/>
										<r CustId="4345542" SportId="1" CategoryId ="201"/>
								 </Root>';
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @CATEGORY_NORMALINACTIVE	INT = 1001
	   	,   @CATEGORY_SMARTINACTIVE		INT = 1002
		,	@CATEGORY_SMARTPUNTER		INT = 203
		,	@CATEGORY_RISKY				INT = 204
		,	@CATEGORY_PROBATION			INT = 206
		,	@CATEGORY_NEWMEMBER			INT = 201;
	
	DECLARE @FUNCTION_NEWCUSTOMER_WITHOUT30DAYS		INT = 0
		,	@FUNCTION_NEWCUSTOMER_WITHIN30DAYS		INT = 4;

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
			CustId				INT PRIMARY KEY
		,	CurrentCategoryId	SMALLINT
	);

	IF OBJECT_ID('tempdb..#tmpActiveMember') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpActiveMember;
	END
	
	CREATE TABLE #tmpActiveMember(
		CustId				INT,
		IsActive			BIT DEFAULT 0
		PRIMARY KEY CLUSTERED (CustId)
	);

	CREATE NONCLUSTERED INDEX IX_tmpActiveMember_IsActive ON #tmpActiveMember(
		IsActive			ASC
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
		CurrentCategoryId	SMALLINT		NULL,
		[Site]				VARCHAR (10)	NULL,
		IsSpecialSite		BIT DEFAULT 0,
		IsDeposit			BIT DEFAULT 0,
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
		[Site]	ASC
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		[CurrentCategoryId]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SRecommend ON #tmpCustomerAccummulatedInfo(
		[SRecommend]
	);


	IF	OBJECT_ID('tempdb..#tmpResultData') IS NOT NULL
	DROP TABLE	#tmpResultData;

	CREATE TABLE #tmpResultData(
		[CustId]			INT NOT NULL,
		[CategoryId]		SMALLINT NOT NULL,
		PRIMARY KEY CLUSTERED ([CustId])
	);
	
	-- #1: Filter Customers
	INSERT INTO #tmpCustomers(CustId, CurrentCategoryId)
	SELECT	T.C.value('./@CustId', 'INT')		   AS CustId
		,	T.C.value('./@CategoryId', 'SMALLINT') AS CurrentCategoryId
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	--#2: Check inactive customers
	IF (@FunctionId = @FUNCTION_NEWCUSTOMER_WITHIN30DAYS) 
		BEGIN
			INSERT INTO #tmpActiveMember(CustId, IsActive)
			SELECT CustId, 1
			FROM #tmpCustomers
		END
	ELSE
		BEGIN
			SELECT @ListCustIds = STUFF((SELECT DISTINCT ',', CONVERT(VARCHAR(15), CustId) 
						FROM #tmpCustomers WITH (NOLOCK)
						FOR XML PATH('')), 1, 1, '');

			INSERT INTO #tmpActiveMember(CustId, IsActive)
			EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	
		END;

	--#3: Remove closed & disabled accounts, SMA account, Internal Account
	DELETE r WITH(ROWLOCK)
	FROM #tmpActiveMember AS r
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.[Enabled] = 0 OR c.roleid <> 1)
		OR c.srecommend IN (41430709)
		OR c.mrecommend IN (27899314,11656504,12146012)
		OR c.recommend IN (52466,5707545,29270764,134456)
		OR c.username LIKE '%CashOut';

	-- #4: Get Customer's Accummulated data
	SELECT @ListCustIds = STUFF((SELECT DISTINCT ',', CONVERT(VARCHAR(15), CustId) 
								FROM #tmpActiveMember WITH (NOLOCK)
								WHERE IsActive = 1
								FOR XML PATH('')), 1, 1, '');

	INSERT INTO #tmpRawData(CustId, SportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDaysCustID, ActiveDaysSportGroup, WindaysCustID, WinDaysSportGroup)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 1;	
	
	-- #5: Sum data by custid
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDaysCustID)
	FROM #tmpRawData AS a WITH(NOLOCK)
	GROUP BY a.CustId;
	
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.CurrentCategoryId = c.CurrentCategoryId
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.custid;

	IF (@FunctionId = @FUNCTION_NEWCUSTOMER_WITHIN30DAYS OR @FunctionId = @FUNCTION_NEWCUSTOMER_WITHOUT30DAYS) 
		BEGIN
			INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
			SELECT	t.CustId
				,	@GENERAL_SPORTID
				,	@CATEGORY_NEWMEMBER
				,	@CurrentDate AS CreatedDate
				,	@CurrentDateTime AS CreatedTime
				,	0
				,	0
				,	0
				,	0
			FROM #tmpCustomers AS t
				LEFT JOIN #tmpCustomerAccummulatedInfo AS c ON t.CustId = c.CustId
			WHERE c.CustId IS NULL;
		END;
	

	---- Log Data
	INSERT INTO dbo.CustomerClassification_InputLog(CustId, CreatedDate, CreatedTime, FunctionId, TurnoverRM, WinlossRM, BetCount, ActiveDays, CurrentCategoryId, IsActive)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, TurnoverRM, WinlossRM, BetCount, ActiveDays, CurrentCategoryId, 1
	FROM #tmpCustomerAccummulatedInfo;

	INSERT INTO dbo.CustomerClassification_InputLog(CustId, CreatedDate, CreatedTime, FunctionId, TurnoverRM, WinlossRM, BetCount, ActiveDays, CurrentCategoryId, IsActive)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, NULL, NULL, NULL, NULL, NULL, 0
	FROM #tmpActiveMember
	WHERE IsActive = 0;

	--#6 Get cust info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET	   a.site = c.site
	   ,   a.SRecommend = c.srecommend
	   ,   a.IsSpecialSite = CASE WHEN c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;
		
	DELETE a
	FROM  #tmpCustomerAccummulatedInfo AS a WITH(ROWLOCK)
	WHERE (a.Site = 'NextBet' OR a.Site = '9wickets' OR a.Site = '9wsports');

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;
	
	--#7: Classify classification by general rule
	INSERT INTO #tmpResultData(CustId, CategoryId)
	SELECT  CustId
		,	CategoryId
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
		) as b
	 WHERE b.RowNum = 1;

	 --#8: Insert to CustomerClassification
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	@GENERAL_SPORTID
		,	CASE WHEN r.CategoryId IS NULL THEN a.CurrentCategoryId ELSE r.CategoryId END
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.BetCount
		,	a.ActiveDays
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
	    LEFT JOIN #tmpResultData AS r WITH(NOLOCK) ON a.CustId = r.CustId

	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	c.CustId
		,	@GENERAL_SPORTID
		,	CASE WHEN c.CurrentCategoryId IN (@CATEGORY_SMARTPUNTER, @CATEGORY_RISKY, @CATEGORY_PROBATION) THEN @CATEGORY_SMARTINACTIVE ELSE @CATEGORY_NORMALINACTIVE END AS CategoryId
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	0
		,	0
		,	0
		,	0
	FROM #tmpActiveMember AS a WITH(NOLOCK)
			INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.custid
	WHERE a.IsActive = 0
	

	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpRawData;
	DROP TABLE #tmpActiveMember;
	DROP TABLE #tmpResultData;
		

	-- #7: Delete old data
/*	WHILE(1 = 1)
	BEGIN
		DELETE TOP (5000)
		FROM dbo.CustomerClassification WITH(ROWLOCK)
		WHERE CreatedDate < @Back3DaysFromToday
			AND IsApplied = 1;

	IF (@@ROWCOUNT = 0)
		BREAK;
	END;
*/
END;
