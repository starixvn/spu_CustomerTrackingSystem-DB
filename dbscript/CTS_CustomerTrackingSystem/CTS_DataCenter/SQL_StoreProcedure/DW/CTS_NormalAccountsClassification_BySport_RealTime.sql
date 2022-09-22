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
		- 20200901@Jonas.Huynh: Created [Redmine ID: #176992]

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
		[TurnoverRM]		DECIMAL(19, 4) NULL,
		[WinlossRM]			DECIMAL(19, 4) NULL,
		[Margin]			DECIMAL(19, 4) NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
		[CurrentCategoryId]	SMALLINT NULL
	);

	CREATE CLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_CustId_SportId ON #tmpCustomerAccummulatedInfo(
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
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId, a.SportId ORDER BY r.Prioity ASC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
				INNER JOIN dbo.CustomerClassification_BySport_Rule AS r WITH(NOLOCK) ON a.SportId = r.SportId 
			 WHERE     (r.RuleGroupId = 1 AND a.CurrentCategoryId = r.CurrentCategory AND a.BetCount < r.BetCount)																								-- NEW MEMBER			
					OR (r.RuleGroupId = 2 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)												-- NEW MEMBER	
					OR (r.RuleGroupId = 3 AND a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)													-- GOOD
					OR (r.RuleGroupId = 4 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)													-- NORMAL
					OR (r.RuleGroupId = 5 AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND NOT (a.BetCount > r.BetCount2 AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays))				-- NORMAL
					OR (r.RuleGroupId = 6 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)											-- NORMAL
					OR (r.RuleGroupId = 7 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)													-- NORMAL
					OR (r.RuleGroupId = 9 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin)										-- PROBATION
					OR (r.RuleGroupId = 10 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM >= r.WinlossRM)		-- PROBATION
					OR (r.RuleGroupId = 11 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)			-- SMART
					OR (r.RuleGroupId = 12 AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)													-- SMART
					OR (r.RuleGroupId = 15 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)										-- RISKY					
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

GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_BySport_RealTime] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_BySport_RealTime] TO [bodbSPUNet]
GO