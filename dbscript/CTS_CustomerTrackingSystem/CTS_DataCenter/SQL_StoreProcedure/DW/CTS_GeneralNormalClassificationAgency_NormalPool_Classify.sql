/*<info serverAlias="DBVR2-bodb_VR2Model" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
USE [bodb_VR2Model]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_GeneralNormalClassificationAgency_NormalPool_Classify]
		@CustomersXML		XML
AS
/*
	Created: 20241003@Jonas.Huynh
	Task : Insert customers to normal pool for classification
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20241003@Jonas.Huynh: Created [Redmine ID: #185799]

	Param's Explanation:
		@CustomersXML		: This parameter is used to classify customer perf which bases on currentCategory
		@IsScanOnlyTagging  : 0-Performance Classification, 1-Behaviour Classification (Tagging)
    Script:
        EXEC bodb_VR2Model.dbo.CTS_GeneralNormalClassificationAgency_NormalPool_Classify 
			@CustomersXML = N'<Root>
								<r CustId="5002646" CategoryId="201" IsNewCreated="0" IsRealtimeOnly= "0" IsProbationLastDay="0" ScanTaggingType="0"/>
								<r CustId="5022391" CategoryId="0"  IsNewCreated="1" IsRealtimeOnly= "1" IsProbationLastDay="0" ScanTaggingType="0"/>
								<r CustId="1275" CategoryId="205"  IsNewCreated="0" IsRealtimeOnly= "1" IsProbationLastDay="1" ScanTaggingType="0"/>
								<r CustId="1280" CategoryId="202"  IsNewCreated="1" IsRealtimeOnly= "1" IsProbationLastDay="1" ScanTaggingType="0"/>
							</Root>';
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @CATEGORY_NULL					INT = NULL;
	DECLARE	@CATEGORY_INACTIVE				INT = 140700;
	DECLARE	@CATEGORY_NEW					INT = 140100;
	DECLARE	@CATEGORY_GOOD					INT = 140200;
	DECLARE	@CATEGORY_NORMAL				INT = 140300;
	DECLARE	@CATEGORY_PROBATION				INT = 140400;
	DECLARE	@CATEGORY_SMART					INT = 140500;
	DECLARE	@CATEGORY_RISKY					INT = 140600;

	DECLARE	@LASTXDAYS						VARCHAR(5) = '60';
	DECLARE	@LASTYDAYS						VARCHAR(5) = '365';

	DECLARE @CurrentDateTime				DATETIME  = GETDATE();
	DECLARE	@ToDate							DATE	  = GETDATE();
	DECLARE @From30Date						DATE	  = DATEADD(DAY, -29, @ToDate);

	DECLARE @ListCustIds					VARCHAR(MAX);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers(
		CustId			       INT PRIMARY KEY,
		RoleId				   TINYINT	NOT NULL,
		CurrentCategoryId      INT		NOT NULL,
		IsNewCreated	       BIT	    NOT NULL DEFAULT 0,
		IsRealtimeOnly		   BIT	    NOT NULL DEFAULT 0,
		IsProbationLastDay	   BIT		NOT NULL DEFAULT 0,
		IsActiveWithin30Days   BIT		NOT NULL DEFAULT 0
	);
	
	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		CustId				 INT				PRIMARY KEY,
		SportGroup			 INT				NOT NULL,
		TurnoverRM			 DECIMAL(19, 4)		NOT NULL,
		WinlossRM			 DECIMAL(19, 4)		NOT NULL,
		TurnoverORG			 DECIMAL(19, 4)		NOT NULL,
		WinlossORG			 DECIMAL(19, 4)		NOT NULL,
		BetCount			 BIGINT				NOT NULL,
		FirstBetDate		 INT				NOT NULL,
        LastXDaysTurnoverRM  DECIMAL(19, 4)		NOT NULL,
        LastXDaysWinlossRM	 DECIMAL(19, 4)		NOT NULL,
        LastXDaysBetCount	 INT				NOT NULL,
		LastYDaysTurnoverRM  DECIMAL(19, 4)		NOT NULL,
        LastYDaysWinlossRM	 DECIMAL(19, 4)		NOT NULL,
        LastYDaysBetCount	 INT				NOT NULL,
		ProcessedTime        DATETIME			NOT NULL
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		CustId					INT				NOT NULL,
		RoleId					TINYINT			NOT NULL,
		CurrentCategoryId		INT				NULL,
		NewCategoryId			INT				NULL,
		IsActiveWithin30Days	BIT				NOT NULL DEFAULT 0,
		IsProbationLastDay		BIT				NOT NULL DEFAULT 0,
		IsRealtimeOnly			BIT				NOT NULL DEFAULT 0,
		TurnoverRM				DECIMAL(19, 4)	NOT NULL,
		WinlossRM				DECIMAL(19, 4)	NOT NULL,
		Margin					DECIMAL(19, 4)	NOT NULL,
		BetCount				BIGINT			NOT NULL,
		FirstBetDate			INT				NOT NULL,
        LastXDaysTurnoverRM		DECIMAL(19, 4)	NOT NULL,
        LastXDaysWinlossRM		DECIMAL(19, 4)	NOT NULL,
        LastXDaysMargin			DECIMAL(19, 4)	NOT NULL,
        LastXDaysBetCount		INT				NOT NULL,
		LastYDaysTurnoverRM		DECIMAL(19, 4)	NOT NULL,
		LastYDaysMargin			DECIMAL(19, 4)	NOT NULL,
        LastYDaysWinlossRM		DECIMAL(19, 4)	NOT NULL,
        LastYDaysBetCount		INT				NOT NULL,
		LastXYDaysWinlossRatio	SMALLINT		NOT NULL,
		PerformanceTime			DATETIME		NOT NULL
	);

	CREATE CLUSTERED INDEX CIX_tmpCustomerAccummulatedInfo_CustId ON #tmpCustomerAccummulatedInfo(
		CustId
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_CurrentCategoryId ON #tmpCustomerAccummulatedInfo(
		CurrentCategoryId
	);

	IF	OBJECT_ID('tempdb..#tmpBetCount') IS NOT NULL
		DROP TABLE	#tmpBetCount;

	CREATE TABLE #tmpBetCount(
		CustId		INT,
		RoleId		INT NOT NULL,
		CategoryId	INT	NOT NULL,
		BetCount	BIGINT NULL
	);

	CREATE CLUSTERED INDEX CIX_tmpBetCount_CustIdRoleId ON #tmpBetCount(
		CustId,
		RoleId
	);

	IF	OBJECT_ID('tempdb..#tmpRemoveCust') IS NOT NULL
	DROP TABLE	#tmpRemoveCust;

	CREATE TABLE #tmpRemoveCust(
		CustId INT PRIMARY KEY
	);

	-- #1: Get list customers
	INSERT INTO #tmpCustomers(CustId, CurrentCategoryId, IsNewCreated, IsRealtimeOnly, IsProbationLastDay)
	SELECT	T.C.value('./@CustId', 'INT')				AS CustId
		,	T.C.value('./@RoleId', 'TINYINT')			AS RoleId
		,	T.C.value('./@CategoryId', 'INT')			AS CurrentCategoryId
		,	T.C.value('./@IsNewCreated', 'BIT')			AS IsNewCreated
		,	T.C.value('./@IsRealtimeOnly', 'BIT')		AS IsRealtimeOnly
		,	T.C.value('./@IsProbationLastDay', 'BIT')	AS IsProbationLastDay
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));
	
	-- #2: Remove realtime classification with category not in (null, new, good, normal)
	DELETE a WITH (ROWLOCK)
	FROM #tmpCustomers AS a
	WHERE   a.IsRealtimeOnly = 1 
		AND a.CurrentCategoryId NOT IN (@CATEGORY_NULL, @CATEGORY_NEW, @CATEGORY_INACTIVE);
	
	IF (EXISTS (SELECT 1 FROM #tmpCustomers))
	BEGIN
		-- #3: Get list customers to retrieve performances
		SELECT @ListCustIds = STUFF(( SELECT DISTINCT ',', CONVERT(VARCHAR(15), CustId) 
									  FROM #tmpCustomers WITH (NOLOCK)
									  FOR XML PATH('')), 1, 1, '');

		-- #4: Get accummulated performance
		INSERT INTO #tmpRawData(CustId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, FirstBetDate, LastXDaysTurnoverRM, LastXDaysWinlossRM, LastXDaysBetCount, LastYDaysTurnoverRM, LastYDaysWinlossRM, LastYDaysBetCount, ProcessedTime)
		EXEC bodb_dwrs.dbo.Acc_Rpt_CTS_GetSMAAccumulatedInfo @ListCustID = @ListCustIds, @RangeDays = CONCAT_WS(',',@LASTXDAYS,@LASTYDAYS), @IsAccumulated = 1;
		
		INSERT INTO #tmpCustomerAccummulatedInfo(CustId, TurnoverRM, WinlossRM, Margin, BetCount, FirstBetDate, LastXDaysTurnoverRM, LastXDaysWinlossRM, LastXDaysMargin, LastXDaysBetCount, LastYDaysTurnoverRM, LastYDaysWinlossRM, LastYDaysMargin, LastYDaysBetCount, LastXYDaysWinlossRatio, PerformanceTime)
		SELECT a.CustId,
				SUM(a.TurnoverRM),
				SUM(a.WinlossRM),
				CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END,
				SUM(a.BetCount),
				MIN(a.FirstBetDate),
				SUM(a.LastXDaysTurnoverRM),
				SUM(a.LastXDaysWinlossRM),
				CASE WHEN SUM(a.LastXDaysTurnoverRM) = 0 THEN 0 ELSE SUM(a.LastXDaysWinlossRM) / SUM(a.LastXDaysTurnoverRM) * 100 END,
				SUM(a.LastXDaysBetCount),
				SUM(a.LastYDaysTurnoverRM),
				SUM(a.LastYDaysWinlossRM),
				CASE WHEN SUM(a.LastYDaysTurnoverRM) = 0 THEN 0 ELSE SUM(a.LastYDaysWinlossRM) / SUM(a.LastYDaysTurnoverRM) * 100 END,
				SUM(a.LastYDaysBetCount),
				CASE WHEN SUM(a.LastXDaysWinlossRM) = 0 || SUM(a.LastYDaysWinlossRM) = 0 THEN 0 ELSE SUM(a.LastXDaysWinlossRM) / SUM(a.LastYDaysWinlossRM) * 100 END,
				MAX(a.ProcessedTime)
		FROM #tmpRawData AS a
		GROUP BY a.CustId;

		-- #5: Check Agency's active days
		UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET a.IsActiveWithin30Days = 1
		FROM #tmpCustomers AS a
			LEFT JOIN dbo.CustomerClassificationAgency_LatestActiveDay AS c WITH(NOLOCK) ON a.CustId = c.CustId
		WHERE (c.CustId IS NOT NULL AND c.LastTransDate >= @From30Date)
			OR a.IsNewCreated = 1;

		-- #6: Map relevant customer info
		UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET a.CurrentCategoryId = c.CurrentCategoryId,
			a.RoleId = c.RoleId,
			a.IsRealtimeOnly = c.IsRealtimeOnly,
			a.IsActiveWithin30Days = c.IsActiveWithin30Days,
			a.IsProbationLastDay = c.IsProbationLastDay
		FROM #tmpCustomerAccummulatedInfo AS a
			INNER JOIN #tmpCustomers AS c ON a.CustId = c.custid;

		-- #7: Remove accounts with settle bet count has not reach the schedule (FOR REALTIME ONLY)
		---- less than 10 settle tickets compared to last scan for New Member
		INSERT INTO #tmpRemoveCust(CustId)
		SELECT a.CustId
		FROM #tmpCustomerAccummulatedInfo AS a
			INNER JOIN dbo.CustomerClassificationAgency_BetCount AS b WITH(NOLOCK) ON a.CustId = b.CustId
		WHERE a.IsRealtimeOnly = 1 
				AND (a.CurrentCategoryId = @CATEGORY_NEW AND a.BetCount - b.BetCount < 10);

		-- #8: Remove invalid realtime conditions data
		DELETE a WITH (ROWLOCK)
		FROM #tmpCustomerAccummulatedInfo AS a
			INNER JOIN #tmpRemoveCust AS b ON a.CustId = b.CustId;

		DELETE a WITH (ROWLOCK)
		FROM #tmpCustomers AS a
			INNER JOIN #tmpRemoveCust AS b ON a.CustId = b.CustId;

		-- #9: Classify customer without performance 
		INSERT INTO dbo.CustomerClassificationAgency(CustId, RoleId, CategoryId, CurrentCategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, FirstBetDate, LastXDaysTurnoverRM, LastXDaysWinlossRM, LastXDaysBetCount, LastYDaysTurnoverRM, LastYDaysWinlossRM, LastYDaysBetCount, LastXYDaysWinlossRatio, ProcessedTime)
		OUTPUT INSERTED.CustId, INSERTED.RoleId, INSERTED.CategoryId, 0 INTO #tmpBetCount
		SELECT t.CustId
			,  t.RoleId
			,  CASE WHEN t.IsActiveWithin30Days = 1 THEN @CATEGORY_NEW ELSE @CATEGORY_INACTIVE END
			,  @CATEGORY_NULL
			,  @ToDate AS CreatedDate
			,  @CurrentDateTime AS CreatedTime
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  @CurrentDateTime
		FROM #tmpCustomers AS t
			LEFT JOIN #tmpCustomerAccummulatedInfo AS c ON t.CustId = c.CustId
		WHERE c.CustId IS NULL;	

		-- #10: Classify classification by general rule
		UPDATE t WITH(ROWLOCK, UPDLOCK)
		SET t.NewCategoryId = b.CategoryId
		FROM (
				SELECT  a.CustId
					,   r.CategoryId
					,	ROW_NUMBER() OVER(PARTITION BY a.CustId ORDER BY r.Prioity ASC) AS RowNum
					FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK) 
						INNER JOIN dbo.CustomerClassificationAgency_Rule AS r WITH(NOLOCK) ON a.RoleId = r.RoleId
					WHERE 	   (r.RuleGroupId = 1 AND a.BetCount < r.BetCount)
						OR (r.RuleGroupId = 100 AND a.FirstBetDate < r.FirstBetDate AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.Margin2 < r.Margin2)
						OR (r.RuleGroupId = 200 AND a.FirstBetDate > r.FirstBetDate AND a.BetCount > r.BetCount AND a.Margin >= r.Margin AND  a.Margin2 < r.Margin2 AND a.LastXYDaysWinlossRatio > r.WinlossRM)
						OR (r.RuleGroupId = 300 AND a.FirstBetDate <= r.FirstBetDate  AND a.BetCount >= r.BetCount)
						OR (r.RuleGroupId = 400 AND a.FirstBetDate > r.FirstBetDate AND a.BetCount >= r.BetCount AND a.Margin < r.Margin AND a.Margin2 >= r.Margin2 AND a.LastXYDaysWinlossRatio > r.WinlossRM)
						OR (r.RuleGroupId = 500 AND a.FirstBetDate > r.FirstBetDate AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.WinlossRM >= r.WinlossRM)
			) AS b
			INNER JOIN #tmpCustomerAccummulatedInfo AS t ON t.CustId = b.CustId
		WHERE b.RowNum = 1;

		--#11: Insert to CustomerClassification
		INSERT INTO dbo.CustomerClassificationAgency(CustId, RoleId, CategoryId, CurrentCategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, FirstBetDate, LastXDaysTurnoverRM, LastXDaysWinlossRM, LastXDaysBetCount, LastYDaysTurnoverRM, LastYDaysWinlossRM, LastYDaysBetCount, LastXYDaysWinlossRatio, ProcessedTime)
		OUTPUT INSERTED.CustId, INSERTED.RoleId, INSERTED.CategoryId, INSERTED.BetCount INTO #tmpBetCount
		SELECT a.CustId
			,	a.RoleId
			,	CASE 
					WHEN a.IsActiveWithin30Days = 0 THEN @CATEGORY_INACTIVE
					WHEN a.NewCategoryId IS NULL THEN a.CurrentCategoryId 
					ELSE a.NewCategoryId 
				END
			,	a.CurrentCategoryId
			,	@ToDate AS CreatedDate
			,	@CurrentDateTime AS CreatedTime
			,	a.TurnoverRM
			,	a.WinlossRM
			,	a.BetCount
			,	a.FirstBetDate
			,	a.LastXDaysTurnoverRM
			,	a.LastXDaysWinlossRM
			,	a.LastXDaysBetCount
			,	a.LastYDaysTurnoverRM
			,	a.LastYDaysWinlossRM
			,	a.LastYDaysBetCount
			,	a.LastXYDaysWinlossRatio
			,	ISNULL(a.PerformanceTime, @CurrentDateTime)
		FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK);
	
		-- #12: Update last settle betcounts
		EXEC dbo.CTS_NormalClassificationAgency_BetCount_Update @CurrentDateTime = @CurrentDateTime, @IsGeneralFlow = 1;

		DROP TABLE #tmpCustomerAccummulatedInfo;
		DROP TABLE #tmpCustomers;
		DROP TABLE #tmpRawData;		
		DROP TABLE #tmpBetCount;
		DROP TABLE #tmpRemoveCust;
	END;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_GeneralNormalClassificationAgency_NormalPool_Classify] TO [wsv_cts]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_GeneralNormalClassificationAgency_NormalPool_Classify] TO [wsv_cts]
GO