USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_GeneralNormalClassification_NormalPool_Classify]    Script Date: 21/04/2023 11:17:2022 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_GeneralNormalClassification_NormalPool_Classify]
		@CustomersXML	XML
AS
/*
	Created: 20230421@Jonas.Huynh
	Task : Insert customers to normal pool for classification
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230421@Jonas.Huynh: Created [Redmine ID: #186678]

	Param's Explanation:
		@CustomersXML	 : This parameter is used to classify customer perf which bases on currentCategory

    Script:
        EXEC bodb_VR2Model.dbo.CTS_GeneralNormalClassification_NormalPool_Classify 
			@CustomersXML = N'<Root>
								<r CustId="4345542" CategoryId ="0" IsNewCreated="1" IsCheckBetCount = "1"/>
								<r CustId="4345541" CategoryId ="201" IsNewCreated="0" IsCheckBetCount = "0"/>
							</Root>';
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @GENERAL_SPORTID		 SMALLINT = 200;
	DECLARE @CurrentDateTime		 DATETIME = GETDATE();
	DECLARE @CurrentDate			 DATE	  = GETDATE();
	DECLARE	@ToDate					 DATE	  = GETDATE();
	DECLARE @From30Date				 DATE	  = DATEADD(DAY, - 30, @ToDate);

	DECLARE @CATEGORY_NORMALINACTIVE SMALLINT = 1001,
	   	    @CATEGORY_SMARTINACTIVE	 SMALLINT = 1002,
			@CATEGORY_NEWMEMBER		 SMALLINT = 201,
			@CATEGORY_NORMALMEMBER	 SMALLINT = 202,
			@CATEGORY_SMARTPUNTER	 SMALLINT = 203,
			@CATEGORY_RISKY			 SMALLINT = 204,
			@CATEGORY_GOODMEMBER	 SMALLINT = 205,
			@CATEGORY_PROBATION		 SMALLINT = 206;

	DECLARE @ListCustIds			 VARCHAR(MAX);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers(
		CustId				  INT PRIMARY KEY,
		CurrentCategoryId	  SMALLINT			NOT NULL,
		IsCreatedWithin30Days BIT				DEFAULT 0,
		IsCheckBetCount		  BIT				DEFAULT 0
	);

	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		CustId				 INT			NOT NULL,
		SportGroup			 INT			NOT NULL,
		TurnoverRM			 DECIMAL(19, 4)	NOT NULL,
		WinlossRM			 DECIMAL(19, 4)	NOT NULL,
		TurnoverORG			 DECIMAL(19, 4)	NOT NULL,
		WinlossORG			 DECIMAL(19, 4)	NOT NULL,
		BetCount			 BIGINT			NOT NULL,
		ActiveDaysCustID	 INT			NOT NULL,
        ActiveDaysSportGroup INT			NOT NULL,
        WindaysCustID		 INT			NOT NULL,
        WinDaysSportGroup	 INT			NOT NULL,
		ProcessedTime        DATETIME       NOT NULL
	);

	CREATE CLUSTERED INDEX CIX_tmpRawData_CustId_SportId ON #tmpRawData(
		CustId, 
		SportGroup
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		CustId				   INT			  NOT NULL,
		CurrentCategoryId	   SMALLINT		  NOT NULL,
		NewCategoryId		   SMALLINT		  NOT NULL,
		IsPlaceBetWithin30Days BIT			  DEFAULT 0,
		IsCheckBetCount		   BIT			  DEFAULT 0,
		IsSpecialSite		   BIT			  DEFAULT 0,
		IsDeposit			   BIT			  DEFAULT 0,
		SRecommend			   INT,
		TurnoverRM			   DECIMAL(19, 4) NOT NULL,
		WinlossRM			   DECIMAL(19, 4) NOT NULL,
		Margin				   DECIMAL(19, 4) NOT NULL,
		BetCount			   BIGINT		  NOT NULL,
		ActiveDays			   INT			  NOT NULL,
		PerformanceTime        DATETIME       NOT NULL
	);

	CREATE CLUSTERED INDEX CIX_tmpCustomerAccummulatedInfo_CustId ON #tmpCustomerAccummulatedInfo(
		CustId
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		CurrentCategoryId
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_SRecommend ON #tmpCustomerAccummulatedInfo(
		SRecommend
	);

	IF	OBJECT_ID('tempdb..#tmpBetCount') IS NOT NULL
	DROP TABLE	#tmpBetCount;

	CREATE TABLE #tmpBetCount(
		CustId					INT			NOT NULL,
		SportId					SMALLINT,
		CategoryId				SMALLINT	NOT NULL,
		BetCount				BIGINT		NULL
		PRIMARY KEY CLUSTERED (CustId)
	);

	CREATE NONCLUSTERED INDEX IX_tmpBetCount_CategoryId ON #tmpBetCount(
		CategoryId
	);

	IF	OBJECT_ID('tempdb..#tmpRemoveCust') IS NOT NULL
	DROP TABLE	#tmpRemoveCust;

	CREATE TABLE #tmpRemoveCust(
		CustId INT PRIMARY KEY
	);

	-- #1: Get list customers
	INSERT INTO #tmpCustomers(CustId, CurrentCategoryId, IsCreatedWithin30Days, IsCheckBetCount)
	SELECT	T.C.value('./@CustId', 'INT')		   AS CustId
		,	T.C.value('./@CategoryId', 'SMALLINT') AS CurrentCategoryId
		,	T.C.value('./@IsNewCreated', 'BIT')	   AS IsCreatedWithin30Days
		,	T.C.value('./@IsCheckBetCount', 'BIT') AS IsCheckBetCount
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));
	
	SELECT @ListCustIds = STUFF(( SELECT DISTINCT ',', CONVERT(VARCHAR(15), CustId) 
								  FROM #tmpCustomers WITH (NOLOCK)
								  FOR XML PATH('')), 1, 1, '');

	-- #2: Get accummulated performance
	INSERT INTO #tmpRawData(CustId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDaysCustID, ActiveDaysSportGroup, WindaysCustID, WinDaysSportGroup, ProcessedTime)
	EXEC bodb_dwrs.dbo.Acc_Rpt_CTS_GetCustAccumulatedInfo @ListCustID = @ListCustIds;

	-- #3: Pre-process customer accumulated performance data
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays, PerformanceTime)
	SELECT a.CustId,
		   SUM(a.TurnoverRM),
		   SUM(a.WinlossRM),
		   CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END,
		   SUM(a.BetCount),
		   MAX(a.ActiveDaysCustID),
		   MAX(a.ProcessedTime)
	FROM #tmpRawData AS a
	GROUP BY a.CustId;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.CurrentCategoryId = c.CurrentCategoryId,
		a.IsCheckBetCount = c.IsCheckBetCount
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN #tmpCustomers AS c ON a.CustId = c.custid;

	-- #4: Remove accounts with settle bet count has not reach the schedule (FOR REALTIME ONLY)
	---- less than 100 settle tickets compared to last scan for Good Member
	---- less than 20 settle tickets compared to last scan for Normal Member
	INSERT INTO #tmpRemoveCust(CustId)
	SELECT a.CustId
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN dbo.CustomerClassification_BetCount AS b WITH(NOLOCK) ON a.CustId = b.CustId
	WHERE a.IsCheckBetCount = 1 
		  AND ((a.CurrentCategoryId = @CATEGORY_GOODMEMBER AND a.BetCount - b.BetCount < 100)
		  OR (a.CurrentCategoryId = @CATEGORY_NORMALMEMBER AND a.BetCount - b.BetCount < 20));
	
	DELETE a WITH (ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN #tmpRemoveCust AS b ON a.CustId = b.CustId

	DELETE a WITH (ROWLOCK)
	FROM #tmpCustomers AS a
		INNER JOIN #tmpRemoveCust AS b ON a.CustId = b.CustId

	-- #5: Insert scanned cust daily
	INSERT INTO dbo.CustomerClassification_ScannedDailyCust(CustId, CreatedDate)
	SELECT a.CustId, @CurrentDate
	FROM #tmpCustomers AS a

	-- #6: Get relevant customer info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET	   a.SRecommend = c.srecommend,
	       a.IsSpecialSite = CASE WHEN c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;

	-- #7: Check active customer
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsPlaceBetWithin30Days = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN dbo.CustomerClassification_LatestActiveDay AS c WITH(NOLOCK) ON a.CustId = c.CustId
	WHERE c.LastTransDate >= @From30Date;

	-- #8: Classify customer without performance 
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime)
	SELECT t.CustId
		,  @GENERAL_SPORTID
		,  CASE WHEN (t.IsCreatedWithin30Days = 1) THEN @CATEGORY_NEWMEMBER ELSE @CATEGORY_NORMALINACTIVE END
		,  @CurrentDate AS CreatedDate
		,  @CurrentDateTime AS CreatedTime
		,  NULL
		,  NULL
		,  NULL
		,  NULL
		,  NULL
	FROM #tmpCustomers AS t
		LEFT JOIN #tmpCustomerAccummulatedInfo AS c ON t.CustId = c.CustId
	WHERE c.CustId IS NULL;	

	-- #9: Classify classification by general rule
	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET t.NewCategoryId = b.CategoryId,
		t.CurrentCategoryId = ISNULL(t.CurrentCategoryId, b.CategoryId)
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
					OR (r.RuleGroupId = 16 AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM) -- RISKY
					OR (r.RuleGroupId = 17 AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM))																			-- RISKY
		) as b
		INNER JOIN #tmpCustomerAccummulatedInfo AS t ON t.CustId = b.CustId
	 WHERE b.RowNum = 1;

	--#10: Insert to CustomerClassification
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime)
	OUTPUT INSERTED.CustId, @GENERAL_SPORTID, INSERTED.CategoryId, INSERTED.BetCount INTO #tmpBetCount
	SELECT a.CustId
		,  @GENERAL_SPORTID
		,  CASE WHEN a.NewCategoryId IS NULL THEN a.CurrentCategoryId ELSE a.NewCategoryId END
		,  @CurrentDate AS CreatedDate
		,  @CurrentDateTime AS CreatedTime
		,  a.TurnoverRM
		,  a.WinlossRM
		,  a.BetCount
		,  a.ActiveDays
		,  a.PerformanceTime
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
	WHERE a.IsPlaceBetWithin30Days = 1;

	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime)
	SELECT a.CustId
		,  @GENERAL_SPORTID
		,  CASE WHEN a.CurrentCategoryId IN (@CATEGORY_SMARTPUNTER, @CATEGORY_RISKY, @CATEGORY_PROBATION) THEN @CATEGORY_SMARTINACTIVE ELSE @CATEGORY_NORMALINACTIVE END AS CategoryId
		,  @CurrentDate AS CreatedDate
		,  @CurrentDateTime AS CreatedTime
		,  a.TurnoverRM
		,  a.WinlossRM
		,  a.BetCount
		,  a.ActiveDays
		,  a.PerformanceTime
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
	WHERE a.IsPlaceBetWithin30Days = 0;
	
	-- #11: Update last settle betcounts
	EXEC dbo.CTS_NormalAccountsClassification_BetCount_Update @CurrentDateTime = @CurrentDateTime, @IsGeneralFlow = 1;

	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpRawData;		
	DROP TABLE #tmpBetCount;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Classify] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Classify] TO [bodbSPUNet]
GO