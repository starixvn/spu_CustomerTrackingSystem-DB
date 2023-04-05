USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_RealTime]    Script Date: 10/11/2022 2:18:50 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_RealTime]
		@CustomersXML			XML
AS
/*
	Created: 20200901@Long.Luu
	Task : Classify Normal Customer Realtime Generally
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200901@Long.Luu: Created [Redmine ID: #137550]
		- 20201126@Long.Luu: Categorize for New Member in General-Realtime [Redmine ID: #145954]
		- 20210408@John.Ngo: Special rule for Haifa CC2 & Problem Agent Category (only member level) [Redmine ID: #152884]
		- 20210511@John.Ngo: Exclude Customer of Odd Feed Sites [Redmine ID: #154694]
		- 20210512@John.Ngo: Exclude Customer Class for Internal Account [Redmine ID: #154844]
		- 20210714@Long.Luu: Special rule for ManbetX CC2 [Redmine ID: #158465]
        - 20210802@Long.Luu: Rescan for customers that have no category in CTS [Redmine ID: #158465]
		- 20210803@Long.Luu: Log Input Data for Classification [Redmine ID: #157203]
		- 20210818@Long.Luu: Check Winloss on probation assessment [Redmine ID: #159709]
		- 20220222@Long.Luu: Remove 10k Probation rule for Credit [Redmine ID: #168988]
		- 20220325@Long.Luu: Update TicketCount rescan for Normal Member from 100 to 20 [Redmine ID: #170465]
		- 20221006@Jonas.Huynh: New Rule for General Customer Classifiation [Redmine ID: #178022]
		- 20221125@Jonas.Huynh: Combine Realtime Flow of General CC and By Sport [Redmine ID: #180805]
		- 20230403@Jonas.Huynh: Modify betcount schedule for Normal & Good Member [Redmine ID: #185633]

	Param's Explanation:
			@CustomersXML = N'<Root>
										<r CustId="4345542" CategoryId ="201"/>
										<r CustId="4345541" CategoryId ="201"/>
								 </Root>';
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @GENERAL_SPORTID		SMALLINT = 200;
	DECLARE @FUNCTIONID				SMALLINT = 1,
			@GeneralParameterId		SMALLINT = 6,
		    @MaxScannedId			BIGINT;

	DECLARE @CATEGORY_NORMALMEMBER	INT = 202
		,	@CATEGORY_GOODMEMBER	INT = 205

	DECLARE	@CurrentDateTime		DATETIME = GETDATE()
		,	@CurrentDate			DATE = GETDATE();


	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers(
			CustId				INT PRIMARY KEY
		,	CurrentCategoryId	SMALLINT
	);


	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT				NOT NULL,
		[IsSpecialSite]		BIT				DEFAULT 0,
		[IsDeposit]			BIT				DEFAULT 0,
		[SRecommend]		INT,
		[TurnoverRM]		DECIMAL(19, 4)	NULL,
		[WinlossRM]			DECIMAL(19, 4)	NULL,
		[Margin]			DECIMAL(19, 4)	NULL,
		[BetCount]			BIGINT			NULL,
		[ActiveDays]		INT				NULL,
		[CurrentCategoryId]	SMALLINT		NULL
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

	
	IF	OBJECT_ID('tempdb..#tmpResultData') IS NOT NULL
	DROP TABLE	#tmpResultData;

	CREATE TABLE #tmpResultData(
		[CustId]			INT			NOT NULL,
		[CategoryId]		SMALLINT	NOT NULL,
		PRIMARY KEY CLUSTERED ([CustId])
	);

	IF	OBJECT_ID('tempdb..#tmpBetCount') IS NOT NULL
	DROP TABLE	#tmpBetCount;

	CREATE TABLE #tmpBetCount(
		CustId				INT			NOT NULL,
		SportId				SMALLINT,
		CategoryId			SMALLINT	NOT NULL,
		BetCount			BIGINT		NULL
		PRIMARY KEY CLUSTERED (CustId)
	);

	-- #1: Filter Customers
	INSERT INTO #tmpCustomers(CustId, CurrentCategoryId)
	SELECT	T.C.value('./@CustId', 'INT')		   AS CustId
		,	T.C.value('./@CategoryId', 'SMALLINT') AS CurrentCategoryId
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));
	
	-- #2: Get MaxScannedId
	SELECT @MaxScannedId = CAST(a.Value AS BIGINT)
	FROM [dbo].CustomerClassification_Parameter AS a WITH(NOLOCK)
	WHERE a.DataId = @GeneralParameterId;
	
	-- #3: GetCustomer Accummulated data
	WITH cte_rawData AS  (  
					SELECT  *
					FROM (
							SELECT *, ROW_NUMBER() OVER(PARTITION BY a.CustId ORDER BY a.ID DESC) AS RowNum
							FROM [dbo].[CustomerClassification_LatestChanged] AS a WITH(NOLOCK)
							WHERE a.ID <= @MaxScannedId
						) AS b
					WHERE b.RowNum = 1
		) 
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, CurrentCategoryId, IsSpecialSite, SRecommend, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	c.CurrentCategoryId
		,	CASE WHEN cu.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
		,	cu.srecommend
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.Margin
		,	a.BetCount
		,	a.ActiveDays
	FROM cte_rawData AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.CustId
		LEFT JOIN bodb02.dbo.Customer AS cu WITH(NOLOCK) ON a.CustId = cu.custid;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;

	---- Log Data
	INSERT INTO dbo.CustomerClassification_InputLog(CustId, CreatedDate, CreatedTime, FunctionId, TurnoverRM, WinlossRM, BetCount, ActiveDays, CurrentCategoryId, IsActive)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, TurnoverRM, WinlossRM, BetCount, ActiveDays, CurrentCategoryId, 1
	FROM #tmpCustomerAccummulatedInfo;

	-- #4: Remove Accounts that settle ticket Count has not reach the schedule
	---- less than 100 settle tickets compared to last scan for Good Member
	---- less than 20 settle tickets compared to last scan for Normal Member
	DELETE a WITH(ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN dbo.CustomerClassification_BetCount AS b WITH(NOLOCK) ON a.CustId = b.CustId
	WHERE  (a.CurrentCategoryId = @CATEGORY_GOODMEMBER AND a.BetCount - b.BetCount < 100)
		OR (a.CurrentCategoryId = @CATEGORY_NORMALMEMBER AND a.BetCount - b.BetCount < 20);
	
	-- #5: Classify classification by general rule
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
					OR (r.RuleGroupId = 10 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin)												-- PROBATION
					OR (r.RuleGroupId = 11 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM >= r.WinlossRM)				-- PROBATION
					OR (r.RuleGroupId = 12 AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM > r.WinlossRM)					-- SMART
					OR (r.RuleGroupId = 16 AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM))												-- RISKY
		) as b
	 WHERE b.RowNum = 1;

	 --#6: Insert to CustomerClassification
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	OUTPUT INSERTED.CustId, @GENERAL_SPORTID, INSERTED.CategoryId, INSERTED.BetCount INTO #tmpBetCount  
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

	-- #7: Update last settle betcounts
	EXEC dbo.CTS_NormalAccountsClassification_BetCount_Update @CurrentDateTime = @CurrentDateTime, @IsGeneralFlow = 1;

	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpResultData;
	DROP TABLE #tmpBetCount;
END;