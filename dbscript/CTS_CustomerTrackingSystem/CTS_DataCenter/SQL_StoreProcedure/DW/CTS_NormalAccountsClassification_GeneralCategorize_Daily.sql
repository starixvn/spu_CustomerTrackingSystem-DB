ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_Daily]
	@ListCustIds			VARCHAR(MAX),
	@FunctionId				SMALLINT = -1,
	@IsCheckLast14Days		BIT = 0 
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
		
	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @GENERALCATEGORY_NEWMEMBER			INT = 201
		,	@GENERALCATEGORY_NORMALMEMBER		INT = 202
		,	@GENERALCATEGORY_SMARTPUNTER		INT = 203
		,	@GENERALCATEGORY_HIGHRISKPUNTER		INT = 204
		,	@GENERALCATEGORY_VIP				INT = 205
		,	@GENERALCATEGORY_PROBATION			INT = 206
		,	@GENERALCATEGORY_INACTIVE			INT = 1000;

	DECLARE @CurrentDateTime		DATETIME = GETDATE();
	DECLARE @CurrentDate			DATE	 = GETDATE();
	DECLARE @Back3DaysFromToday		DATE	 = DATEADD(DAY, -3, @CurrentDate);	
	DECLARE	@ToDate					DATE	 = DATEADD(DAY, -1, GETDATE());
	DECLARE	@From30Date				DATE	 = DATEADD(DAY, - 30, @ToDate);

	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		[CustId]			INT NOT NULL,
		[MainDBSportId]		INT NOT NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[TurnoverORG]		MONEY NULL,
		[WinlossORG]		MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
		PRIMARY KEY (CustId, MainDBSportId)
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT NOT NULL,
		[Site]				VARCHAR (10) NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[Margin]			MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_Site ON #tmpCustomerAccummulatedInfo(
		[Site]				ASC
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
			CustId			INT PRIMARY KEY
		,	IsActive		BIT DEFAULT 0
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomers_Site ON #tmpCustomers(
		IsActive			ASC
	);
	
	IF OBJECT_ID('tempdb..#tmpDeletedCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDeletedCustomers;
	END
	
	CREATE TABLE #tmpDeletedCustomers(
			CustId			INT
	);
	
	CREATE CLUSTERED INDEX IX_tmpDeletedCustomers_CustId ON #tmpDeletedCustomers(
		[CustId]			ASC
	);
	
	-- START
	-- #1: Filter Customers
	IF (@FunctionId = 4) 
		BEGIN
			INSERT INTO #tmpCustomers(CustId, IsActive)
			SELECT val, 1 FROM dbo.SPU_StrSplit(@ListCustIds, ',');
		END
	ELSE
		BEGIN
			INSERT INTO #tmpCustomers(CustId, IsActive)
			EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	
		END;

	-- LOG INPUT DATA
	INSERT INTO dbo.CustomerClassification_InputLog(CustId,CreatedDate,CreatedTime,FunctionId,IsActive)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FunctionId, IsActive
	FROM #tmpCustomers;

	-- Remove closed & disabled accounts & SMA account & Internal Account
	DELETE r WITH(ROWLOCK)
		OUTPUT DELETED.CustId INTO #tmpDeletedCustomers(CustId)
	FROM #tmpCustomers AS r
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.[Enabled] = 0 OR c.roleid <> 1)
	   OR c.recommend IN (52466,5707545)
	   OR c.username LIKE '%CashOut';

	/*-- Remove closed & disabled of CN88
	DELETE r WITH(ROWLOCK)
		OUTPUT DELETED.CustId INTO #tmpDeletedCustomers(CustId)
	FROM #tmpRawData AS r
		LEFT JOIN bodb02.dbo.CS_CustomerStatus AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.InactiveInfo > 0)
		OR (c.InactiveInfo = 0 AND c.SuspendedInfo > 0);
	*/

	-- #2: GetCustomer Accummulated data
	SELECT @ListCustIds = STUFF((SELECT ',', CONVERT(VARCHAR(15), CustId) 
								FROM #tmpCustomers WITH (NOLOCK)
								WHERE IsActive = 1
								FOR XML PATH('')), 1, 1, '');

	INSERT INTO #tmpRawData(CustId, MainDBSportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 1;	
	
	-- #3: Sum data by custid
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDays)
	FROM #tmpRawData AS a WITH(NOLOCK)
	GROUP BY a.CustId;
	
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.site = c.site
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;

	-- #4: Remove 'Odd Feed Sites'
	DELETE a
	FROM  #tmpCustomerAccummulatedInfo AS a WITH(ROWLOCK)
	WHERE (a.Site = 'NextBet' OR a.Site = '9wickets' OR a.Site = '9wsports');
	
	-- #5: Classify new members
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	c.CustId
		,	200
		,	@GENERALCATEGORY_NEWMEMBER AS CategoryId
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	0
		,	0
		,	0
		,	0
	FROM #tmpCustomers AS c WITH(NOLOCK)
		LEFT JOIN #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK) ON c.CustId = a.CustId
		LEFT JOIN #tmpDeletedCustomers AS dc WITH(NOLOCK) ON c.CustId = dc.CustId
	WHERE a.CustId IS NULL
		AND dc.CustId IS NULL
		AND c.IsActive = 1;
		
	-- #6: Remove 'haifa/manbetX doesn't change category'
	DELETE a
	FROM  #tmpCustomerAccummulatedInfo AS a WITH(ROWLOCK)
	WHERE (a.Site IN ('haifa','manbetx') AND a.Margin < 0 AND a.WinlossRM < -5000);

	-- #7: Classify customers by General Category
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	200
		,	CASE
				WHEN a.BetCount < 10 THEN @GENERALCATEGORY_NEWMEMBER
				WHEN (a.Margin <= -2 AND a.TurnoverRM > 150000 AND a.BetCount > 300 AND a.ActiveDays >= 8) THEN @GENERALCATEGORY_VIP
				WHEN (a.Margin >= 0.1 AND a.Margin <= 1 AND a.BetCount >= 20 AND a.WinlossRM > 15000) THEN @GENERALCATEGORY_SMARTPUNTER
				WHEN (a.Margin > 1 AND a.BetCount >= 20 AND a.WinlossRM > 15000) THEN @GENERALCATEGORY_HIGHRISKPUNTER
				WHEN (a.Margin >= 0) THEN @GENERALCATEGORY_PROBATION
				WHEN (a.Margin < 0 AND (a.Site NOT IN ('haifa','manbetx') OR a.Site IS NULL)) THEN @GENERALCATEGORY_NORMALMEMBER
				WHEN (a.Margin < 0 AND a.Site IN ('haifa','manbetx') AND a.WinlossRM >= -5000) THEN @GENERALCATEGORY_NORMALMEMBER
			END AS CategoryId
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.BetCount
		,	a.ActiveDays
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK);

	-- #8: Classify Inactive members
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	c.CustId
		,	200
		,	@GENERALCATEGORY_INACTIVE AS CategoryId
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	0
		,	0
		,	0
		,	0
	FROM #tmpCustomers AS c WITH(NOLOCK)
	WHERE c.IsActive = 0;

	-- #9: Delete old data
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
