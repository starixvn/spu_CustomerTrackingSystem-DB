/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_GeneralNormalClassification_NormalPool_Classify]    Script Date: 20/04/2023 11:05:2022 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_GeneralNormalClassification_NormalPool_Classify]
		@CustomersXML		XML
AS
/*
	Created: 20230421@Jonas.Huynh
	Task : Insert customers to normal pool for classification
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230421@Jonas.Huynh: Created [Redmine ID: #186678]
		- 20230519@Jonas.Huynh: HF Wrong inactive category with new placebet [Redmine ID: #188464]
		- 20230601@Jonas.Huynh: Normal Renovation (Phase2) [Redmine ID: #186684]
		- 20230627@Jonas.Huynh: Reset Balance for Credit with Inactive Normal with new place-bet [Redmine ID: #189876]
		- 20230807@Jonas.Huynh: HF exclude Non-sport for General [Redmine ID: #192388]
		- 20230726@Jonas.Huynh: Saba Classification [Redmine ID: #185320]
		- 20230816@Jonas.Huynh: Tagging Classification [Redmine ID: #191400]

	Param's Explanation:
		@CustomersXML		: This parameter is used to classify customer perf which bases on currentCategory
		@IsScanOnlyTagging  : 0-Performance Classification, 1-Behaviour Classification (Tagging)
    Script:
        EXEC bodb_VR2Model.dbo.CTS_GeneralNormalClassification_NormalPool_Classify 
			@CustomersXML = N'<Root>
								<r CustId="5002646" CategoryId="201" IsNewCreated="0" IsCheckBetCount= "0" IsProbationLastDay="0" ScanTaggingType="0"/>
								<r CustId="5022391" CategoryId="0"  IsNewCreated="1" IsCheckBetCount= "1" IsProbationLastDay="0" ScanTaggingType="0"/>
								<r CustId="1275" CategoryId="205"  IsNewCreated="0" IsCheckBetCount= "1" IsProbationLastDay="1" ScanTaggingType="0"/>
								<r CustId="1280" CategoryId="202"  IsNewCreated="1" IsCheckBetCount= "1" IsProbationLastDay="1" ScanTaggingType="0"/>
							</Root>';
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @GENERAL_SPORTID		 SMALLINT = 200;
	DECLARE @CurrentDateTime		 DATETIME = GETDATE();
	DECLARE	@ToDate					 DATE	  = GETDATE();
	DECLARE @YesterdayDate			 DATE	  = DATEADD(DAY, -1, @ToDate);
	DECLARE @From30Date				 DATE	  = DATEADD(DAY, -29, @ToDate);

	DECLARE @CATEGORY_NULL			 SMALLINT = 0,
			@CATEGORY_NORMALINACTIVE SMALLINT = 1001,
	   	    @CATEGORY_SMARTINACTIVE	 SMALLINT = 1002,
			@CATEGORY_NEWMEMBER		 SMALLINT = 201,
			@CATEGORY_NORMALMEMBER	 SMALLINT = 202,
			@CATEGORY_SMARTPUNTER	 SMALLINT = 203,
			@CATEGORY_RISKY			 SMALLINT = 204,
			@CATEGORY_GOODMEMBER	 SMALLINT = 205,
			@CATEGORY_PROBATION		 SMALLINT = 206;

	DECLARE @SportGroup_SabaVRSoccer	 SMALLINT = 145,
			@SportGroup_SabaVRBasketball SMALLINT = 912,
			@SportGroup_NonSport		 SMALLINT = 229;

	DECLARE @ScanTaggingType_NotExist  TINYINT = 0,
			@ScanTaggingType_Exist	   TINYINT = 1,
			@ScanTaggingType_ExistOnly TINYINT = 2;

	DECLARE @ListCustIds			 VARCHAR(MAX);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers(
		CustId			       INT PRIMARY KEY,
		CurrentCategoryId      SMALLINT NOT NULL,
		IsNewCreated	       BIT	    NOT NULL DEFAULT 0,
		IsCheckBetCount		   BIT	    NOT NULL DEFAULT 0,
		IsProbationLastDay	   BIT		NOT NULL DEFAULT 0,
		ScanTaggingType		   TINYINT	NOT NULL DEFAULT 0,
		IsPlaceBetWithin30Days BIT		NOT NULL DEFAULT 0,
		IsDeposit			   BIT		NOT NULL DEFAULT 0,
		IsSpecialSite		   BIT		NOT NULL DEFAULT 0,
		SRecommend			   INT
	);
	
	CREATE NONCLUSTERED INDEX IX_tmpCustomers_ScanTaggingType ON #tmpCustomers(
		ScanTaggingType
	);

	IF OBJECT_ID('tempdb..#tmpScanTaggingCustomer') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpScanTaggingCustomer;
	END

	CREATE TABLE #tmpScanTaggingCustomer(
		CustId			       INT PRIMARY KEY,
		CurrentCategoryId      SMALLINT NOT NULL,
		ScanTaggingType		   TINYINT	NOT NULL DEFAULT 0,
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

	CREATE CLUSTERED INDEX CIX_tmpRawData_CustId ON #tmpRawData(CustId);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		CustId				   INT			  NOT NULL,
		CurrentCategoryId	   SMALLINT		  NOT NULL DEFAULT 0,
		NewCategoryId		   SMALLINT		  NULL,
		IsPlaceBetWithin30Days BIT			  NOT NULL DEFAULT 0,
		IsProbationLastDay	   BIT			  NOT NULL DEFAULT 0,
		IsCheckBetCount		   BIT			  NOT NULL DEFAULT 0,
		IsSpecialSite		   BIT			  NOT NULL DEFAULT 0,
		IsDeposit			   BIT			  NOT NULL DEFAULT 0,
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
		CustId		INT	PRIMARY KEY,
		SportGroup	SMALLINT,
		CategoryId	SMALLINT  NOT NULL,
		BetCount	BIGINT	  NULL
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
	INSERT INTO #tmpCustomers(CustId, CurrentCategoryId, IsNewCreated, IsCheckBetCount, IsProbationLastDay, ScanTaggingType)
	SELECT	T.C.value('./@CustId', 'INT')				AS CustId
		,	T.C.value('./@CategoryId', 'SMALLINT')		AS CurrentCategoryId
		,	T.C.value('./@IsNewCreated', 'BIT')			AS IsNewCreated
		,	T.C.value('./@IsCheckBetCount', 'BIT')		AS IsCheckBetCount
		,	T.C.value('./@IsProbationLastDay', 'BIT')	AS IsProbationLastDay
		,	T.C.value('./@ScanTaggingType', 'TINYINT')	AS ScanTaggingType
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));
	
	SELECT @ListCustIds = STUFF(( SELECT DISTINCT ',', CONVERT(VARCHAR(15), CustId) 
								  FROM #tmpCustomers WITH (NOLOCK)
								  FOR XML PATH('')), 1, 1, '');

	DELETE a WITH (ROWLOCK)
	OUTPUT DELETED.CustId,DELETED.CurrentCategoryId, DELETED.ScanTaggingType INTO #tmpScanTaggingCustomer(CustId, CurrentCategoryId, ScanTaggingType)
	FROM #tmpCustomers AS a
	WHERE ScanTaggingType = @ScanTaggingType_ExistOnly

	IF (EXISTS (SELECT 1 FROM #tmpCustomers))
	BEGIN
		-- #2: Get customer info
		UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET	   a.SRecommend = c.srecommend,
			   a.IsSpecialSite = CASE WHEN c.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') THEN 1 ELSE 0 END
		FROM #tmpCustomers AS a
			INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

		UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET a.IsDeposit = 1
		FROM #tmpCustomers AS a
			INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;

		UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET a.IsPlaceBetWithin30Days = 1
		FROM #tmpCustomers AS a
			INNER JOIN dbo.CustomerClassification_LatestActiveDay AS c WITH(NOLOCK) ON a.CustId = c.CustId
		WHERE c.LastTransDate >= @From30Date;
	
		-- #3: Update reset balance for credit - normal inactive with new placebet
		EXEC dbo.CTS_GeneralNormalClassification_Balance_Reset @CurrentDateTime = @CurrentDateTime, @YesterdayDate = @YesterdayDate;
	END;

	-- #4: Get accummulated performance
	INSERT INTO #tmpRawData(CustId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDaysCustID, ActiveDaysSportGroup, WindaysCustID, WinDaysSportGroup, ProcessedTime)
	EXEC bodb_dwrs.dbo.Acc_Rpt_CTS_GetCustAccumulatedInfo @ListCustID = @ListCustIds, @isResetBalance = 1;

	DELETE a WITH (ROWLOCK)
	FROM #tmpRawData AS a
	WHERE a.SportGroup IN (@SportGroup_NonSport, @SportGroup_SabaVRSoccer, @SportGroup_SabaVRBasketball);
		
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

	IF (EXISTS (SELECT 1 FROM #tmpScanTaggingCustomer))
	BEGIN
		-- #5.1: Classify Tagging (link Association, TWGB,...)
		INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CurrentCategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime, IsScanOnlyTagging)
		SELECT t.CustId
			,  @GENERAL_SPORTID
			,  t.CurrentCategoryId
			,  t.CurrentCategoryId
			,  @ToDate AS CreatedDate
			,  @CurrentDateTime AS CreatedTime
			,  c.TurnoverRM
			,  c.WinlossRM
			,  c.BetCount
			,  c.ActiveDays
			,  ISNULL(c.PerformanceTime, @CurrentDateTime)
			,  1
		FROM #tmpScanTaggingCustomer AS t
			LEFT JOIN #tmpCustomerAccummulatedInfo AS c ON t.CustId = c.CustId;

		-- #5.2: Remove Scan Tagging Performance
		DELETE a WITH (ROWLOCK)
		FROM #tmpCustomerAccummulatedInfo AS a
			INNER JOIN #tmpScanTaggingCustomer AS t ON t.CustId = a.CustId;
	END
	
	IF (EXISTS (SELECT 1 FROM #tmpCustomers))
	BEGIN
		-- #5: Map relevant customer info
		UPDATE a WITH(ROWLOCK, UPDLOCK)
		SET a.CurrentCategoryId = c.CurrentCategoryId,
			a.IsCheckBetCount = c.IsCheckBetCount,
			a.IsPlaceBetWithin30Days = c.IsPlaceBetWithin30Days,
			a.IsProbationLastDay = c.IsProbationLastDay,
			a.SRecommend = c.SRecommend,
			a.IsSpecialSite = c.IsSpecialSite,
			a.IsDeposit = c.IsDeposit
		FROM #tmpCustomerAccummulatedInfo AS a
			INNER JOIN #tmpCustomers AS c ON a.CustId = c.custid;

		-- #6: Remove accounts with settle bet count has not reach the schedule (FOR REALTIME ONLY)
		---- less than 100 settle tickets compared to last scan for Good Member
		---- less than 20 settle tickets compared to last scan for Normal Member
		INSERT INTO #tmpRemoveCust(CustId)
		SELECT a.CustId
		FROM #tmpCustomerAccummulatedInfo AS a
			INNER JOIN dbo.CustomerClassification_BetCount AS b WITH(NOLOCK) ON a.CustId = b.CustId
		WHERE a.IsCheckBetCount = 1 
				AND ((a.CurrentCategoryId = @CATEGORY_GOODMEMBER AND a.BetCount - b.BetCount < 100)
				OR (a.CurrentCategoryId = @CATEGORY_NORMALMEMBER AND a.BetCount - b.BetCount < 20));

		-- #6.1: Classify Tagging (link Association, TWGB,...) If having any from tagging function
		INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CurrentCategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime, IsScanOnlyTagging)
		SELECT r.CustId
			,  @GENERAL_SPORTID
			,  a.CurrentCategoryId
			,  a.CurrentCategoryId
			,  @ToDate AS CreatedDate
			,  @CurrentDateTime AS CreatedTime
			,  a.TurnoverRM
			,  a.WinlossRM
			,  a.BetCount
			,  a.ActiveDays
			,  ISNULL(a.PerformanceTime, @CurrentDateTime)
			,  1
		FROM #tmpRemoveCust AS r
			INNER JOIN #tmpCustomers AS c ON c.CustId = r.CustId
			INNER JOIN #tmpCustomerAccummulatedInfo AS a ON a.CustId = r.CustId
		WHERE c.ScanTaggingType = @ScanTaggingType_Exist;

		-- #6.2: Remove invalid realtime conditions data
		DELETE a WITH (ROWLOCK)
		FROM #tmpCustomerAccummulatedInfo AS a
			INNER JOIN #tmpRemoveCust AS b ON a.CustId = b.CustId;

		DELETE a WITH (ROWLOCK)
		FROM #tmpCustomers AS a
			INNER JOIN #tmpRemoveCust AS b ON a.CustId = b.CustId;

		-- #7: Insert scanned cust daily
		UPDATE b WITH(ROWLOCK, UPDLOCK)
		SET	b.CreatedDate = @ToDate
		FROM #tmpCustomers AS a
			INNER JOIN dbo.CustomerClassification_ScannedDailyCust AS b ON b.CustId = a.CustId;

		INSERT INTO dbo.CustomerClassification_ScannedDailyCust(CustId, CreatedDate)
		SELECT a.CustId, @ToDate
		FROM #tmpCustomers AS a
			LEFT JOIN dbo.CustomerClassification_ScannedDailyCust AS b WITH(NOLOCK) ON b.CustId = a.CustId
		WHERE b.CustId IS NULL;

		-- #8: Classify customer without performance 
		INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CurrentCategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime)
		SELECT t.CustId
			,  @GENERAL_SPORTID
			,  CASE WHEN (t.IsNewCreated = 1 OR t.IsPlaceBetWithin30Days = 1) THEN @CATEGORY_NEWMEMBER ELSE @CATEGORY_NORMALINACTIVE END
			,  @CATEGORY_NULL
			,  @ToDate AS CreatedDate
			,  @CurrentDateTime AS CreatedTime
			,  NULL
			,  NULL
			,  NULL
			,  NULL
			,  @CurrentDateTime
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
						OR (r.RuleGroupId = 12 AND (r.IsProbationLastDay IS NULL OR (r.IsProbationLastDay IS NOT NULL AND a.IsProbationLastDay = r.IsProbationLastDay)) AND a.BetCount >= r.BetCount AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM > r.WinlossRM) -- SMART
						OR (r.RuleGroupId = 13 AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)				-- SMART
						OR (r.RuleGroupId = 14 AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM AND a.WinlossRM <= r.WinlossRM2)											-- SMART
						OR (r.RuleGroupId = 15 AND a.Margin >= r.Margin AND a.Margin <= r.Margin2 AND a.WinlossRM > r.WinlossRM)												-- SMART
						OR (r.RuleGroupId = 16 AND (r.IsProbationLastDay IS NULL OR (r.IsProbationLastDay IS NOT NULL AND a.IsProbationLastDay = r.IsProbationLastDay)) AND a.BetCount >= r.BetCount AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM) -- RISKY
						OR (r.RuleGroupId = 17 AND a.Margin > r.Margin AND a.WinlossRM > r.WinlossRM))																			-- RISKY
			) AS b
			INNER JOIN #tmpCustomerAccummulatedInfo AS t ON t.CustId = b.CustId
			WHERE b.RowNum = 1;

		--#10: Insert to CustomerClassification
		INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CurrentCategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime)
		OUTPUT INSERTED.CustId, @GENERAL_SPORTID, INSERTED.CategoryId, INSERTED.BetCount INTO #tmpBetCount
		SELECT a.CustId
			,  @GENERAL_SPORTID
			,  CASE WHEN a.NewCategoryId IS NULL THEN a.CurrentCategoryId ELSE a.NewCategoryId END
			,  a.CurrentCategoryId
			,  @ToDate AS CreatedDate
			,  @CurrentDateTime AS CreatedTime
			,  a.TurnoverRM
			,  a.WinlossRM
			,  a.BetCount
			,  a.ActiveDays
			,  ISNULL(a.PerformanceTime, @CurrentDateTime)
		FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
		WHERE a.IsPlaceBetWithin30Days = 1;

		INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CurrentCategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime)
		SELECT a.CustId
			,  @GENERAL_SPORTID
			,  CASE WHEN a.CurrentCategoryId IN (@CATEGORY_SMARTPUNTER, @CATEGORY_RISKY, @CATEGORY_PROBATION, @CATEGORY_SMARTINACTIVE) THEN @CATEGORY_SMARTINACTIVE ELSE @CATEGORY_NORMALINACTIVE END AS CategoryId
			,  a.CurrentCategoryId
			,  @ToDate AS CreatedDate
			,  @CurrentDateTime AS CreatedTime
			,  a.TurnoverRM
			,  a.WinlossRM
			,  a.BetCount
			,  a.ActiveDays
			,  ISNULL(a.PerformanceTime, @CurrentDateTime)
		FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
		WHERE a.IsPlaceBetWithin30Days = 0;
	
		-- #11: Update last settle betcounts
		EXEC dbo.CTS_NormalClassification_BetCount_Update @CurrentDateTime = @CurrentDateTime, @IsGeneralFlow = 1;
	END;

	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
	DROP TABLE #tmpRawData;		
	DROP TABLE #tmpBetCount;
	DROP TABLE #tmpRemoveCust;
	DROP TABLE #tmpScanTaggingCustomer;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Classify] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Classify] TO [bodbSPUNet]
GO