ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_Daily]
	@ListCustIds			VARCHAR(MAX),
	@IsCheckLast14Days		BIT = 1 
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

	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @GENERALCATEGORY_NEWMEMBER			INT = 201
		,	@GENERALCATEGORY_NORMALMEMBER		INT = 202
		,	@GENERALCATEGORY_SMARTPUNTER		INT = 203
		,	@GENERALCATEGORY_HIGHRISKPUNTER		INT = 204
		,	@GENERALCATEGORY_VIP				INT = 205
		,	@GENERALCATEGORY_PROBATION			INT = 206;

	DECLARE @CurrentDateTime			DATETIME = GETDATE();
	DECLARE @CurrentDate				DATE	 = GETDATE();
	DECLARE @Back14DaysFromToday		DATE	 = DATEADD(DAY, -14, @CurrentDate);
	DECLARE @Back3DaysFromToday			DATE	 = DATEADD(DAY, -3, @CurrentDate);

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

	CREATE CLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_Margin ON #tmpCustomerAccummulatedInfo(
		Margin				ASC,
		TurnoverRM			ASC
	);

	CREATE NONCLUSTERED INDEX IX_tmpCustomerAccummulatedInfo_ActiveDaysBetCount ON #tmpCustomerAccummulatedInfo(
		ActiveDays			ASC,
		BetCount			ASC
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
	);

	IF OBJECT_ID('tempdb..#tmpActiveCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpActiveCustomers;
	END
	
	CREATE TABLE #tmpActiveCustomers(
			CustId			INT PRIMARY KEY
	);
	
	IF OBJECT_ID('tempdb..#tmpDeletedCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDeletedCustomers;
	END
	
	CREATE TABLE #tmpDeletedCustomers(
			CustId			INT PRIMARY KEY
	);
	
	-- GET LIST CUSTOMER-SPORT
	INSERT INTO #tmpCustomers(CustId)
	SELECT val FROM dbo.SPU_StrSplit(@ListCustIds, ',');

	-- START
/*	IF(@IsCheckLast14Days = 1)
	BEGIN		
		-- #0: Get active customers in last 14 days
		INSERT INTO #tmpActiveCustomers(CustId)
		EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustIDList_ByModifiedDate  @LastModifiedDatetime = @Back14DaysFromToday;
	
		-- #1: Remove inactive customers to be scanned
		DELETE r WITH(ROWLOCK)
		FROM #tmpCustomers AS r
			LEFT JOIN #tmpActiveCustomers AS a ON a.CustId = r.CustId
		WHERE a.CustId IS NULL;
	END;
*/
	-- #2: GetCustomer Accummulated data
	SELECT @ListCustIds = STUFF((SELECT ',', CONVERT(VARCHAR(15), CustId) 
								FROM #tmpCustomers WITH (NOLOCK)
								FOR XML PATH('')), 1, 1, '');

	INSERT INTO #tmpRawData(CustId, MainDBSportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds;	

	INSERT INTO #tmpDeletedCustomers(CustId)
	SELECT DISTINCT r.CustId FROM #tmpRawData AS r
		LEFT JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE c.closed = 1 OR c.[Enabled] = 0
		AND c.roleid = 1;

	INSERT INTO #tmpDeletedCustomers(CustId)
	SELECT DISTINCT r.CustId FROM #tmpRawData AS r
		LEFT JOIN bodb02.dbo.CS_CustomerStatus AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.InactiveInfo > 0)
		OR (c.InactiveInfo = 0 AND c.SuspendedInfo > 0);
	
	-- #3: Remove closed & disabled accounts & SMA account	
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
		LEFT JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE c.closed = 1 OR c.[Enabled] = 0
		OR c.roleid <> 1;

	-- #4: Remove closed & disabled of CN88
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
		LEFT JOIN bodb02.dbo.CS_CustomerStatus AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE (c.InactiveInfo > 0)
		OR (c.InactiveInfo = 0 AND c.SuspendedInfo > 0);

	-- #5: Sum data by custid
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, Site, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	c.site
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDays)
	FROM #tmpRawData AS a WITH(NOLOCK)
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid
	GROUP BY a.CustId, c.site;
	
	-- #6: Classify new members
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
		AND dc.CustId IS NULL;
		
	-- Remove 'haifa doesn't change category'
	DELETE a
	FROM  #tmpCustomerAccummulatedInfo AS a WITH(ROWLOCK)
	WHERE (a.Margin < 0 AND a.Site = 'haifa' AND a.WinlossRM < -20000);

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
				WHEN (a.Margin < 0 AND a.Site <> 'haifa') THEN @GENERALCATEGORY_NORMALMEMBER
				WHEN (a.Margin < 0 AND a.Site = 'haifa' AND a.WinlossRM >= -20000) THEN @GENERALCATEGORY_NORMALMEMBER
			END AS CategoryId
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.BetCount
		,	a.ActiveDays
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK);

	-- #8: Delete old data
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
