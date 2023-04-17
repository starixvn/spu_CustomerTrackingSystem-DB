USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_RealTime]    Script Date: 9/21/2022 6:10:00 PM ******/
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
		- 20220831@Jonas.Huynh: Created [Redmine ID: #176992]
		- 20221017@Jonas.Huynh: Fix issue ineligible customer classification
		- 20221111@Jonas.Huynh: Adjust Eport Rules [Redmine ID: #179501]
		- 20221125@Jonas.Huynh: Combine Realtime Flow of General CC and By Sport [Redmine ID: #180805]
		- 20221213@Jonas.Huynh: Support Non-Sport [Redmine ID: #179500]
		- 20230405@Jonas.Huynh: Modify betcount schedule for Normal & Good Member [Redmine ID: #185633]
	
	Param's Explanation:
				@CustomersXML = N'<Root>
										<r CustId="4345542" SportId="2" CategoryId ="201"/>
										<r CustId="4345542" SportId="1" CategoryId ="201"/>
								 </Root>';
	Example: 
		exec [dbo].[CTS_NormalAccountsClassification_BySport_RealTime]
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @SPORT_ESPORT				SMALLINT = 43,
			@SPORT_NONSPORT				SMALLINT = 229;

	DECLARE	@FUNCTIONID					SMALLINT = 1,
			@BySportParameterId			SMALLINT = 7,
		    @MaxScannedId				BIGINT;

	DECLARE @CATEGORY_NEWMEMBER			INT		 = 201
		,	@CATEGORY_NORMALMEMBER		INT		 = 202
		,	@CATEGORY_SMARTPUNTER		INT		 = 203
		,	@CATEGORY_HIGHRISKPUNTER	INT		 = 204
		,	@CATEGORY_GOODMEMBER		INT		 = 205
		,	@CATEGORY_PROBATION			INT		 = 206

	DECLARE	@CurrentDateTime			DATETIME = GETDATE()
		,	@CurrentDate				DATE	 = GETDATE();

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		CustId					INT				NOT NULL,
		SportId					INT				NOT NULL,
		CurrentCategoryId		SMALLINT		NULL,
		IsSpecialSite			BIT				DEFAULT 0,
		IsDeposit				BIT				DEFAULT 0,
		SRecommend				INT,
		TurnoverRM				DECIMAL(19, 4)	NULL,
		WinlossRM				DECIMAL(19, 4)	NULL,
		Margin					DECIMAL(19, 4)	NULL,
		BetCount				BIGINT			NULL,
		ActiveDays				INT				NULL,
		WinDaysRate				DECIMAL(5,2)	NULL
	);

	CREATE CLUSTERED INDEX CIX_tmpCustomerAccummulatedInfo_CustId_SportId_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		[CustId]			ASC,
		[SportId]			ASC,
		[CurrentCategoryId]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SportId_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		[SportId],
		[CurrentCategoryId],
		[IsDeposit]
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SRecommend ON #tmpCustomerAccummulatedInfo(
		[SRecommend]
	);
	
	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
			CustId				INT
		,	SportId				SMALLINT
		,	CurrentCategoryId	SMALLINT
		,	PRIMARY KEY CLUSTERED (CustId, SportId)
	);

	IF	OBJECT_ID('tempdb..#tmpResultData') IS NOT NULL
	DROP TABLE	#tmpResultData;

	CREATE TABLE #tmpResultData(
		CustId			INT		  NOT NULL,
		SportId			SMALLINT  NOT NULL,
		CategoryId		SMALLINT  NOT NULL,
		PRIMARY KEY CLUSTERED (CustId, SportId)
	);

	IF	OBJECT_ID('tempdb..#tmpBetCount') IS NOT NULL
	DROP TABLE	#tmpBetCount;

	CREATE TABLE #tmpBetCount(
		CustId			INT			NOT NULL,
		SportId			SMALLINT,
		CategoryId		SMALLINT	NOT NULL,
		BetCount		BIGINT		NULL
		PRIMARY KEY CLUSTERED (CustId, SportId)
	);

	CREATE NONCLUSTERED INDEX IX_tmpBetCount_CategoryId ON #tmpBetCount(
		CategoryId
	);

	INSERT INTO #tmpCustomers(CustId, SportId, CurrentCategoryId)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportId', 'SMALLINT') AS SportId
		,	T.C.value('./@CategoryId', 'SMALLINT') AS CurrentCategoryId
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));
	
	-- START	
	-- #1: Get MaxScannedId
	SELECT @MaxScannedId = CAST(a.Value AS BIGINT)
	FROM [dbo].CustomerClassification_Parameter AS a WITH(NOLOCK)
	WHERE a.DataId = @BySportParameterId;

	-- #2: GetCustomer Accummulated data  
	WITH cte_rawData AS  (  
					SELECT  *
					FROM (
							SELECT *, ROW_NUMBER() OVER(PARTITION BY a.CustId, a.SportId ORDER BY a.ID DESC) AS RowNum
							FROM [dbo].[CustomerClassification_BySport_LatestChanged] AS a WITH(NOLOCK)
							WHERE a.ID <= @MaxScannedId
						) as b
					WHERE b.RowNum = 1
		)  
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, SportId, CurrentCategoryId, IsSpecialSite, SRecommend, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays, WinDaysRate)
	SELECT	a.CustId
		,	a.SportId
		,	c.CurrentCategoryId
		,	CASE
				WHEN a.SportId = @SPORT_NONSPORT THEN NULL
				WHEN a.SportId = @SPORT_ESPORT AND cu.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada', 'WINHX1') THEN 1
				WHEN a.SportId <> @SPORT_ESPORT AND cu.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1
				ELSE 0
			END		
		,	cu.srecommend
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.Margin
		,	a.BetCount
		,	a.ActiveDays
		,	a.WinDaysRate
	FROM cte_rawData AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.CustId AND a.SportId = c.SportId
		LEFT JOIN bodb02.dbo.Customer AS cu WITH(NOLOCK) ON a.CustId = cu.custid;

	-- #3: Log Input Data
	INSERT INTO dbo.CustomerClassification_BySport_InputLog(CustId, SportId, CreatedDate, CreatedTime, FunctionId, TurnoverRM, WinlossRM, BetCount, CurrentCategoryId, ActiveDays, WinDaysRate)
	SELECT CustId, SportId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, TurnoverRM, WinlossRM, BetCount, CurrentCategoryId, ActiveDays, WinDaysRate
	FROM #tmpCustomerAccummulatedInfo;

	-- #4: Get Cust Info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;

	-- #5: Remove Accounts that settle ticket Count has not reach the schedule
	---- less than 100 settle tickets compared to last scan for Good Member
	---- less than 20 settle tickets compared to last scan for Normal Member
	DELETE a WITH(ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN dbo.CustomerClassification_BySport_BetCount AS b WITH(NOLOCK) ON a.CustId = b.CustId AND a.SportId = b.SportId
	WHERE  (a.CurrentCategoryId = @CATEGORY_GOODMEMBER AND a.BetCount - b.BetCount < 100)
		OR (a.CurrentCategoryId = @CATEGORY_NORMALMEMBER AND a.BetCount - b.BetCount < 20);

	-- #6: Classify NULL, GOOD, NEW, NORMAL Category
	INSERT INTO #tmpResultData(CustId, SportId, CategoryId)
	SELECT  CustId
		,	SportId
		,	CategoryId
	FROM (
			SELECT a.CustId
				,	a.SportId
				,   r.CategoryId
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId, a.SportId ORDER BY r.Prioity ASC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
				INNER JOIN dbo.CustomerClassification_BySport_Rule AS r WITH(NOLOCK) ON a.SportId = r.SportId 
			 WHERE     (r.RuleGroupId = 1 AND a.CurrentCategoryId = r.CurrentCategory AND a.BetCount < r.BetCount)																								-- NEW MEMBER			
					OR (r.RuleGroupId = 2 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)												-- NEW MEMBER	
					OR (r.RuleGroupId = 3 AND a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)													-- GOOD
					OR (r.RuleGroupId = 4 AND (a.IsSpecialSite IS NULL OR a.IsSpecialSite = r.IsSpecialSite) AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)					-- NORMAL
					OR (r.RuleGroupId = 5 AND (a.IsSpecialSite IS NULL OR a.IsSpecialSite = r.IsSpecialSite) AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND NOT (a.BetCount > r.BetCount2 AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays))	-- NORMAL
					OR (r.RuleGroupId = 6 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)											-- NORMAL
					OR (r.RuleGroupId = 7 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)													-- NORMAL
					OR (r.RuleGroupId = 10 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin)										-- PROBATION
					OR (r.RuleGroupId = 11 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM >= r.WinlossRM)		-- PROBATION
					OR (r.RuleGroupId = 12 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)			-- SMART
					OR (r.RuleGroupId = 13 AND a.CurrentCategoryId = r.CurrentCategory AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)		-- SMART
					OR (r.RuleGroupId = 17 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)										-- RISKY
					OR (r.RuleGroupId = 19 AND a.CurrentCategoryId = r.CurrentCategory AND a.BetCount > r.BetCount AND a.Margin > r.Margin)																		-- PROBATION
					OR (r.RuleGroupId = 20 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM AND a.WinDaysRate > r.WinDaysRate)		-- SMART
					OR (r.RuleGroupId = 22 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM AND a.WinDaysRate > r.WinDaysRate)								-- RISKY
		) as b
	 WHERE b.RowNum = 1;

	INSERT INTO dbo.CustomerClassification_BySport(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	OUTPUT INSERTED.CustId, INSERTED.SportId, INSERTED.CategoryId, INSERTED.BetCount INTO #tmpBetCount  
	SELECT  a.CustId
		,	a.SportId
		,	CASE WHEN r.CategoryId IS NULL THEN a.CurrentCategoryId ELSE r.CategoryId END
		,	@CurrentDate
		,	@CurrentDateTime
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.BetCount
		,	a.ActiveDays
	 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
	   LEFT JOIN #tmpResultData AS r WITH(NOLOCK) ON a.CustId = r.CustId AND a.SportId = r.SportId

	-- #7: Update last settle betcounts
	EXEC dbo.CTS_NormalAccountsClassification_BetCount_Update @CurrentDateTime = @CurrentDateTime, @IsGeneralFlow = 0;

	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpResultData;
	DROP TABLE #tmpBetCount;
END;

GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_BySport_RealTime] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_BySport_RealTime] TO [bodbSPUNet]
GO