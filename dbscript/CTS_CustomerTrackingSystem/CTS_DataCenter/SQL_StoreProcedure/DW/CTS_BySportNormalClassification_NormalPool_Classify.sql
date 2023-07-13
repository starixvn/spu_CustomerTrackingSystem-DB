USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_BySportNormalClassification_NormalPool_Classify] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_BySportNormalClassification_NormalPool_Classify]
	@CustomersXML	XML
AS
/*
	Created: 20230630@Jonas.Huynh
	Task : Insert customers to normal pool for classification bySport
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230630@Jonas.Huynh: Created [Redmine ID: #189875]

	Param's Explanation:
		@CustomersXML	 : This parameter is used to classify customer perf which bases on currentCategory

    Script:
        EXEC bodb_VR2Model.dbo.CTS_BySportNormalClassification_NormalPool_Classify
			@CustomersXML = N'<Root>
								<r CustId="5002646" SportGroup="2" CategoryId="201" IsCheckBetCount= "0" IsProbationLastDay="0"/>
								<r CustId="5022391" SportGroup="2" CategoryId="0" IsCheckBetCount= "1" IsProbationLastDay="0"/>
								<r CustId="1275" SportGroup="2" CategoryId="205" IsCheckBetCount= "1" IsProbationLastDay="1"/>
								<r CustId="1280" SportGroup="2" CategoryId="202" IsCheckBetCount= "1" IsProbationLastDay="1"/>
							</Root>';
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE	@CATEGORY_NULL			SMALLINT = 0,
			@CATEGORY_NEWMEMBER		SMALLINT = 201,
			@CATEGORY_NORMALMEMBER	SMALLINT = 202,
			@CATEGORY_GOODMEMBER	SMALLINT = 205;

	DECLARE @SPORT_SOCCER			SMALLINT = 1,
			@SPORT_BASKETBALL		SMALLINT = 2,
			@SPORT_ESPORT			SMALLINT = 43,
			@SPORT_OTHERSPORT		SMALLINT = 99,
			@SPORT_NONSPORT			SMALLINT = 229;

	DECLARE @CurrentDateTime		DATETIME = GETDATE();
	DECLARE @CurrentDate			DATE	 = GETDATE();
	DECLARE	@ToDate					DATE	 = GETDATE();
	DECLARE @From30Date				DATE	 = DATEADD(DAY, -29, @ToDate);

	DECLARE @ListCustIds			VARCHAR(MAX);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers(
		CustId			       INT,
		SportGroup			   SMALLINT,
		CurrentCategoryId      SMALLINT NOT NULL,
		IsCheckBetCount		   BIT	    NOT NULL DEFAULT 0,
		IsProbationLastDay	   BIT		NOT NULL DEFAULT 0,
		PRIMARY KEY (CustId, SportGroup)
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomers_IsCheckBetCount_CurrentCategory ON #tmpCustomers(
		IsCheckBetCount DESC,
		CurrentCategoryId
	);

	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		CustId				 INT			NOT NULL,
		SportGroup			 SMALLINT		NOT NULL,
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

	CREATE CLUSTERED INDEX CIX_tmpRawData_CustId ON #tmpRawData(CustId, SportGroup);

	CREATE NONCLUSTERED INDEX IX_tmpRawData_BetCount ON #tmpRawData(
		BetCount
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		CustId				   INT			  NOT NULL,
		SportGroup			   SMALLINT		  NOT NULL,
		CurrentCategoryId	   SMALLINT		  NOT NULL DEFAULT 0,
		NewCategoryId		   SMALLINT		  NULL,
		IsProbationLastDay	   BIT			  NOT NULL DEFAULT 0,
		IsCheckBetCount		   BIT			  NOT NULL DEFAULT 0,
		IsSpecialSite		   BIT			  DEFAULT 0,
		IsDeposit			   BIT			  NOT NULL DEFAULT 0,
		SRecommend			   INT,
		TurnoverRM			   DECIMAL(19, 4) NOT NULL,
		WinlossRM			   DECIMAL(19, 4) NOT NULL,
		Margin				   DECIMAL(19, 4) NOT NULL,
		BetCount			   BIGINT		  NOT NULL,
		ActiveDays			   INT			  NOT NULL,
		WinDaysRate			   DECIMAL(5,2)	  NULL,
		PerformanceTime        DATETIME       NOT NULL
		PRIMARY KEY(CustId, SportGroup)
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
		CustId		INT,
		SportGroup	SMALLINT,
		CategoryId	SMALLINT  NOT NULL,
		BetCount	BIGINT	  NULL,
		PRIMARY KEY (CustId, SportGroup)
	);

	CREATE NONCLUSTERED INDEX IX_tmpBetCount_CategoryId ON #tmpBetCount(
		CategoryId
	);

	-- #1: Get list customers
	INSERT INTO #tmpCustomers(CustId, SportGroup, CurrentCategoryId, IsCheckBetCount, IsProbationLastDay)
	SELECT	T.C.value('./@CustId', 'INT')				AS CustId
		,	T.C.value('./@SportGroup', 'SMALLINT')		AS SportGroup
		,	T.C.value('./@CategoryId', 'SMALLINT')		AS CurrentCategoryId
		,	T.C.value('./@IsCheckBetCount', 'BIT')		AS IsCheckBetCount
		,	T.C.value('./@IsProbationLastDay', 'BIT')	AS IsProbationLastDay
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));
	
	-- #2: Remove realtime classification with category not in (null, new, good, normal)
	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
	WHERE r.IsCheckBetCount = 1 
		AND r.CurrentCategoryId NOT IN (@CATEGORY_NULL, @CATEGORY_NEWMEMBER, @CATEGORY_NORMALMEMBER, @CATEGORY_GOODMEMBER);

	-- #3: Get accummulated performance
	SELECT @ListCustIds = STUFF(( SELECT DISTINCT ',', CONVERT(VARCHAR(15), CustId) 
								  FROM #tmpCustomers WITH (NOLOCK)
								  FOR XML PATH('')), 1, 1, '');

	INSERT INTO #tmpRawData(CustId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDaysCustID, ActiveDaysSportGroup, WindaysCustID, WinDaysSportGroup, ProcessedTime)
	EXEC bodb_dwrs.dbo.Acc_Rpt_CTS_GetCustAccumulatedInfo @ListCustID = @ListCustIds, @isResetBalance = 0;

	-- #4: Remove SportType with no perf (void/reject/exclude/... tickets)
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
	WHERE r.BetCount = 0;
	
	-- #5: Calculate accumulated customer performance data
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, SportGroup, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays, WinDaysRate, PerformanceTime)
	SELECT a.CustId,
		   a.SportGroup,
		   a.TurnoverRM,
		   a.WinlossRM,
		   CASE WHEN a.TurnoverRM = 0 THEN 0 ELSE a.WinlossRM / a.TurnoverRM * 100 END,
		   a.BetCount,
		   a.ActiveDaysSportGroup,
		   CASE WHEN  a.ActiveDaysSportGroup = 0 THEN 0 ELSE ((a.WinDaysSportGroup * 1.0) / a.ActiveDaysSportGroup) * 100 END,
		   a.ProcessedTime
	FROM #tmpRawData AS a
		INNER JOIN #tmpCustomers AS c ON c.CustId = a.CustId AND c.SportGroup = a.SportGroup;

	-- #6: Mapping customer info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.CurrentCategoryId = c.CurrentCategoryId,
		a.IsCheckBetCount = c.IsCheckBetCount,
		a.IsProbationLastDay = c.IsProbationLastDay
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN #tmpCustomers AS c ON a.CustId = c.custid AND a.SportGroup = c.SportGroup;

	-- #7: Remove accounts with settle bet count has not reach the schedule (FOR REALTIME ONLY)
	---- less than 100 settle tickets compared to last scan for Good Member
	---- less than 20 settle tickets compared to last scan for Normal Member
	DELETE a WITH (ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN dbo.CustomerClassification_BySport_BetCount AS b WITH(NOLOCK) ON a.CustId = b.CustId AND a.SportGroup = b.SportId
	WHERE a.IsCheckBetCount = 1 
		  AND ((a.CurrentCategoryId = @CATEGORY_GOODMEMBER AND a.BetCount - b.BetCount < 100)
		  OR (a.CurrentCategoryId = @CATEGORY_NORMALMEMBER AND a.BetCount - b.BetCount < 20));
	
	-- #8: Insert scanned cust daily
	UPDATE b WITH(ROWLOCK, UPDLOCK)
	SET	b.CreatedDate = @CurrentDate
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN dbo.CustomerClassification_BySport_ScannedDailyCust AS b ON b.CustId = a.CustId AND b.SportGroup = a.SportGroup;

	INSERT INTO dbo.CustomerClassification_BySport_ScannedDailyCust(CustId, SportGroup, CreatedDate)
	SELECT a.CustId, a.SportGroup, @CurrentDate
	FROM #tmpCustomerAccummulatedInfo AS a
	WHERE NOT EXISTS (SELECT 1 FROM dbo.CustomerClassification_BySport_ScannedDailyCust AS b WITH(NOLOCK) WHERE b.CustId = a.CustId AND b.SportGroup = a.SportGroup);

	-- #9: Get relevant customer info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET	   a.SRecommend = c.srecommend,
		   a.IsSpecialSite = CASE
								WHEN a.SportGroup = @SPORT_NONSPORT THEN NULL
								WHEN a.SportGroup = @SPORT_ESPORT AND c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada', 'WINHX1') THEN 1
								WHEN a.SportGroup <> @SPORT_ESPORT AND c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1
								ELSE 0	
							 END	
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;

	-- #10: Classify classification by general rule
	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET t.NewCategoryId = b.CategoryId
	FROM (
			SELECT  a.CustId
				,	a.SportGroup
				,   r.CategoryId
				,	ROW_NUMBER() OVER(PARTITION BY a.CustId, a.SportGroup ORDER BY r.Prioity ASC) AS RowNum
			 FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK) 
				INNER JOIN dbo.CustomerClassification_BySport_Rule AS r WITH(NOLOCK) ON a.SportGroup = r.SportId 
			 WHERE  (r.RuleGroupId = 1 AND a.CurrentCategoryId = r.CurrentCategory AND a.BetCount < r.BetCount)												
					OR (r.RuleGroupId = 2 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM > r.WinlossRM)												-- NEW MEMBER	
					OR (r.RuleGroupId = 3 AND a.BetCount > r.BetCount AND a.Margin < r.Margin AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays)													-- GOOD
					OR (r.RuleGroupId = 4 AND (a.IsSpecialSite IS NULL OR a.IsSpecialSite = r.IsSpecialSite) AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin < r.Margin2)					-- NORMAL
					OR (r.RuleGroupId = 5 AND (a.IsSpecialSite IS NULL OR a.IsSpecialSite = r.IsSpecialSite) AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND NOT (a.BetCount > r.BetCount2 AND a.TurnoverRM > r.TurnoverRM AND a.ActiveDays >= r.ActiveDays))	-- NORMAL
					OR (r.RuleGroupId = 6 AND a.IsSpecialSite = r.IsSpecialSite AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.WinlossRM <= r.WinlossRM)											-- NORMAL
					OR (r.RuleGroupId = 7 AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM < r.WinlossRM)													-- NORMAL
					OR (r.RuleGroupId = 8 AND a.CurrentCategoryId = r.CurrentCategory AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM <= r.WinlossRM)			-- PROBATION
					OR (r.RuleGroupId = 9 AND a.CurrentCategoryId = r.CurrentCategory AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM <= r.WinlossRM)			-- PROBATION
					OR (r.RuleGroupId = 10 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin)										-- PROBATION
					OR (r.RuleGroupId = 11 AND a.CurrentCategoryId = r.CurrentCategory AND a.IsDeposit = r.IsDeposit AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM >= r.WinlossRM)		-- PROBATION
					OR (r.RuleGroupId = 12 AND a.CurrentCategoryId = r.CurrentCategory AND (r.IsProbationLastDay IS NULL OR (r.IsProbationLastDay IS NOT NULL AND a.IsProbationLastDay = r.IsProbationLastDay)) AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)			-- SMART
					OR (r.RuleGroupId = 13 AND a.CurrentCategoryId = r.CurrentCategory AND (r.IsProbationLastDay IS NULL OR (r.IsProbationLastDay IS NOT NULL AND a.IsProbationLastDay = r.IsProbationLastDay)) AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)		-- SMART
					OR (r.RuleGroupId = 14 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)		-- SMART
					OR (r.RuleGroupId = 15 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)									-- SMART
					OR (r.RuleGroupId = 16 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM > r.WinlossRM)										-- SMART
					OR (r.RuleGroupId = 17 AND a.CurrentCategoryId = r.CurrentCategory AND (r.IsProbationLastDay IS NULL OR (r.IsProbationLastDay IS NOT NULL AND a.IsProbationLastDay = r.IsProbationLastDay)) AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM)										-- RISKY
					OR (r.RuleGroupId = 18 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM)																	-- RISKY
					OR (r.RuleGroupId = 19 AND a.CurrentCategoryId = r.CurrentCategory AND a.BetCount > r.BetCount AND a.Margin > r.Margin)	
					OR (r.RuleGroupId = 20 AND a.CurrentCategoryId = r.CurrentCategory AND (r.IsProbationLastDay IS NULL OR (r.IsProbationLastDay IS NOT NULL AND a.IsProbationLastDay = r.IsProbationLastDay)) AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM AND a.WinDaysRate > r.WinDaysRate)	-- SMART
					OR (r.RuleGroupId = 21 AND a.CurrentCategoryId = r.CurrentCategory AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM <= r.WinlossRM AND a.WinDaysRate > r.WinDaysRate)	 -- SMART
					OR (r.RuleGroupId = 22 AND a.CurrentCategoryId = r.CurrentCategory AND (r.IsProbationLastDay IS NULL OR (r.IsProbationLastDay IS NOT NULL AND a.IsProbationLastDay = r.IsProbationLastDay)) AND a.Margin > r.Margin AND a.BetCount >= r.BetCount AND a.WinlossRM > r.WinlossRM AND a.WinDaysRate > r.WinDaysRate)	 -- RISKY																		-- RISKY
		) AS b
		INNER JOIN #tmpCustomerAccummulatedInfo AS t ON t.CustId = b.CustId AND t.SportGroup = b.SportGroup
	 WHERE b.RowNum = 1;

	--#11: Insert to CustomerClassification BySport
	INSERT INTO dbo.CustomerClassification_BySport(CustId, SportId, CategoryId, CurrentCategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime)
	OUTPUT INSERTED.CustId, INSERTED.SportId, INSERTED.CategoryId, INSERTED.BetCount INTO #tmpBetCount  
	SELECT  a.CustId
		,	a.SportGroup
		,	CASE WHEN a.NewCategoryId IS NULL THEN a.CurrentCategoryId ELSE a.NewCategoryId END
		,	a.CurrentCategoryId
		,	@CurrentDate
		,	@CurrentDateTime
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.BetCount
		,	a.ActiveDays
		,  ISNULL(a.PerformanceTime, @CurrentDateTime)
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)

	
	-- #12: Update last settle betcounts
	EXEC dbo.CTS_NormalAccountsClassification_BetCount_Update @CurrentDateTime = @CurrentDateTime, @IsGeneralFlow = 0;

	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpRawData;		
	DROP TABLE #tmpBetCount;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_BySportNormalClassification_NormalPool_Classify] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_BySportNormalClassification_NormalPool_Classify] TO [bodbSPUNet]
GO