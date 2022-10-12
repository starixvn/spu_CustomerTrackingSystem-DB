USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_Probation]    Script Date: 9/6/2022 11:08:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_Probation_xtest]
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
		- 20210531@John.Ngo: Exclude non-real Saba Sport on Customer Classification [Redmine ID: #155976]
		- 20210607@Long.Luu: Change probation rules [Redmine ID: #156466]
        - 20210611@Long.Luu: Check Inactive Accounts [Redmine ID: #156465] 
		- 20210714@Long.Luu: Special rule for ManbetX CC2 [Redmine ID: #158465]
		- 20210811@Long.Luu: Change way to check Customers' Inactive status [Redmine ID: #159543]
		- 20210818@Long.Luu: Check Winloss on probation assessment [Redmine ID: #159709]
		- 20220222@Long.Luu: Remove 10k Probation rule for Credit [Redmine ID: #168988]
        - 20221006@Jonas.Huynh: New Rule for General Customer Classifiation [Redmine ID: #178022]

	Param's Explanation:

	Example:
		EXEC [dbo].[CTS_NormalAccountsClassification_Probation] @CustomersXML='<root> <ProbationModel CustId="123" SportGroupId="200" IsProbationLastDay="2" /> </root>';
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @PARLAY_SPORTID		SMALLINT = -100
		,	@GENERAL_SPORTID	SMALLINT = 200;

	DECLARE @FUNCTIONID			SMALLINT = 2;

	DECLARE @CATEGORY_PROBATION			INT = 206,
			@CATEGORY_SMARTINACTIVE		INT = 1002;

	DECLARE	@CustIdList			VARCHAR(MAX)	
		,	@CurrentDateTime	DATETIME = GETDATE()
		,	@CurrentDate		DATE	 = GETDATE()
		,	@ToDate				DATE	 = GETDATE();
	
	DECLARE	@From30Date			DATE	 = DATEADD(DAY, - 30, @ToDate);
	
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
		PRIMARY KEY ([CustId],[SportId])
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
	DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]				INT NOT NULL,
		[Site]					VARCHAR (10) NULL,
		[IsSpecialSite]			BIT DEFAULT 0,
		[IsDeposit]				BIT DEFAULT 0,
		[SRecommend]			INT,
		[TurnoverRM]			DECIMAL(19, 4) NULL,
		[WinlossRM]				DECIMAL(19, 4) NULL,
		[Margin]				DECIMAL(19, 4) NULL,
		[BetCount]				BIGINT NULL,
		[ActiveDays]			INT NULL,
		[CurrentCategoryId]	    SMALLINT NULL,
		[IsProbationLastDay]	BIT DEFAULT 0,
	);
	
	CREATE CLUSTERED INDEX CIX_tmpCustomerAccummulatedInfo_CustId ON #tmpCustomerAccummulatedInfo(
		[CustId]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		[CurrentCategoryId]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SRecommend ON #tmpCustomerAccummulatedInfo(
		[SRecommend]
	);

	IF OBJECT_ID('tempdb..#tmpCustomer') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomer;
	END

	CREATE TABLE #tmpCustomer(
		[CustId]				INT PRIMARY KEY,
		[IsProbationLastDay]	BIT DEFAULT 0,
	);

	IF OBJECT_ID('tempdb..#tmpActiveCustomer') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpActiveCustomer;
	END
	
	CREATE TABLE #tmpActiveCustomer(
		[CustId]		INT PRIMARY KEY,
		[IsActive]		BIT DEFAULT 0
	);

	IF	OBJECT_ID('tempdb..#tmpResultData') IS NOT NULL
	DROP TABLE	#tmpResultData;

	CREATE TABLE #tmpResultData(
		[CustId]				INT NOT NULL,
		[CategoryId]			SMALLINT NOT NULL,
		[IsProbationLastDay]	BIT DEFAULT 0,
		[IsPassed]				BIT DEFAULT 0
		PRIMARY KEY CLUSTERED ([CustId])
	);

	--#1: Filter customers info
	INSERT INTO #tmpCustomer(CustId, IsProbationLastDay)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@IsProbationLastDay', 'BIT') AS IsProbationLastDay
	FROM @CustomersXML.nodes('//ProbationModel') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	--#2: Check inactive customers
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomer
			  FOR XML PATH ('')), 1, 1, '');

	INSERT INTO #tmpActiveCustomer(CustId, IsActive)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	

	--#3: Remove disable account
	DELETE r WITH(ROWLOCK)
	FROM #tmpActiveCustomer AS r
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE c.[Enabled] = 0
	
	--#4: Get Customer's Accummulated data
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpActiveCustomer WITH (NOLOCK)
			  WHERE IsActive = 1
			  FOR XML PATH ('')), 1, 1, '');

	INSERT INTO #tmpRawData(CustId, SportId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList;

	DELETE FROM #tmpRawData
	WHERE SportId = @PARLAY_SPORTID;

	--#5: Sum Data
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, CurrentCategoryId, IsProbationLastDay, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	r.CustId
	    ,	@CATEGORY_PROBATION
		,	c.IsProbationLastDay
		,	SUM(r.TurnoverRM)
		,	SUM(r.WinlossRM)
		,	CASE WHEN SUM(r.TurnoverRM) = 0 THEN 0 ELSE SUM(r.WinlossRM) / SUM(r.TurnoverRM) * 100 END
		,	SUM(r.BetCount)
		,	MAX(r.ActiveDays)
	FROM #tmpRawData AS r WITH(NOLOCK)
		INNER JOIN #tmpCustomer AS c WITH(NOLOCK) ON r.CustId = c.CustId
	GROUP BY r.CustId;

	---- Log Data
	INSERT INTO dbo.CustomerClassification_InputLog(CustId, CreatedDate, CreatedTime, FunctionId, TurnoverRM, WinlossRM, BetCount, ActiveDays, CurrentCategoryId)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, TurnoverRM, WinlossRM, BetCount, ActiveDays, CurrentCategoryId
	FROM #tmpCustomerAccummulatedInfo;

	INSERT INTO dbo.CustomerClassification_InputLog(CustId, CreatedDate, CreatedTime, FunctionId, TurnoverRM, WinlossRM, BetCount, ActiveDays, CurrentCategoryId)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, 0, 0, 0, 0, @CATEGORY_SMARTINACTIVE
	FROM #tmpActiveCustomer 
	WHERE IsActive = 0;

	--#6 Get cust info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET    a.site = c.site
	   ,   a.SRecommend = c.srecommend
	   ,   a.IsSpecialSite = CASE WHEN c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;		

	--#7: Classify classification by general rule
	INSERT INTO #tmpResultData(CustId, CategoryId, IsProbationLastDay, IsPassed)
	SELECT  CustId
		,	CategoryId
		,	IsProbationLastDay
		,   1
	FROM (
			SELECT  a.CustId
				,   r.CategoryId
				,   a.IsProbationLastDay
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId ORDER BY r.Prioity ASC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK) 
				 INNER JOIN dbo.CustomerClassification_Rule AS r WITH(NOLOCK) ON a.CurrentCategoryId = r.CurrentCategory 
			 WHERE 	   (r.RuleGroupId = 2 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)						-- NEW MEMBER	
					OR (r.RuleGroupId = 3 AND a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)							-- GOOD
					OR (r.RuleGroupId = 4 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)							-- NORMAL
					OR (r.RuleGroupId = 5 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND NOT (a.BetCount > r.BetCount2 AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays))	-- NORMAL
					OR (r.RuleGroupId = 6 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)					-- NORMAL
					OR (r.RuleGroupId = 7 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)							-- NORMAL	
					OR (r.RuleGroupId = 12 AND a.IsProbationLastDay = 1 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM > r.WinlossRM)	-- SMART
					OR (r.RuleGroupId = 16 AND a.IsProbationLastDay = 1 AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM)								-- RISKY
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

	---- Insert inactive customers
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  CustId
		,  @GENERAL_SPORTID
	   ,   @CATEGORY_SMARTINACTIVE
		,  @CurrentDate AS CreatedDate
		,  @CurrentDateTime AS CreatedTime
		,  0
		,  0
		,  0
		,  0
	FROM #tmpActiveCustomer
	WHERE IsActive = 0;
	
	--#9: Return results
	SELECT	c.CustId	AS 'CustId'
		,	CASE WHEN (r.CategoryId IS NOT NULL) THEN 1 ELSE 0 END	AS 'IsPassed'
	FROM #tmpCustomer as c WITH(NOLOCK)
		 LEFT JOIN #tmpResultData AS r WITH(NOLOCK) ON r.CustId = r.CustId

	DROP TABLE #tmpRawData;
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomer;
	DROP TABLE #tmpResultData;
	DROP TABLE #tmpActiveCustomer;
END;