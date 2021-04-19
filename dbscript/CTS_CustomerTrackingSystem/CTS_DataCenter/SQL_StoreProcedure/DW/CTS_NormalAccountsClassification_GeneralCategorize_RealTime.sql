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

	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @GENERAL_SPORTID	SMALLINT = 200;

	DECLARE @GENERALCATEGORY_NEWMEMBER			INT = 201
		,	@GENERALCATEGORY_NORMALMEMBER		INT = 202
		,	@GENERALCATEGORY_SMARTPUNTER		INT = 203
		,	@GENERALCATEGORY_HIGHRISKPUNTER		INT = 204
		,	@GENERALCATEGORY_VIP				INT = 205
		,	@GENERALCATEGORY_PROBATION			INT = 206;

	DECLARE	@CurrentDateTime			DATETIME = GETDATE()
		,	@CurrentDate				DATE = GETDATE();

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

	IF	OBJECT_ID('tempdb..#tmpDangerousCustomer') IS NOT NULL
		DROP TABLE	#tmpDangerousCustomer;

	CREATE TABLE #tmpDangerousCustomer(
		[CustId]			INT NOT NULL
	);

	CREATE CLUSTERED INDEX IX_tmpDangerousCustomer_CustId ON #tmpDangerousCustomer(
		[CustId]			ASC
	);
	
	IF	OBJECT_ID('tempdb..#tmpNewCustomer') IS NOT NULL
		DROP TABLE	#tmpNewCustomer;

	CREATE TABLE #tmpNewCustomer(
		[CustId]			INT NOT NULL PRIMARY KEY,
		[TurnoverRM]		MONEY,
		[WinlossRM]			MONEY,
		[BetCount]			INT,
		[ActiveDays]		INT
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
			CustId			INT
		,	SportId			SMALLINT
		,	CategoryId		SMALLINT
		,	PRIMARY KEY (CustId, SportId)
	);

	-- PARSE VIP CUSTOMERS
	INSERT INTO #tmpCustomers(CustId, SportId, CategoryId)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportGroupId', 'SMALLINT') AS SportId
		,	T.C.value('./@CategoryId', 'SMALLINT') AS CategoryId
	FROM @CustomersXML.nodes('//CustomerClassificationModel') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- START
	-- #1: GetCustomer Accummulated data
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, Site, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	cu.Site
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.Margin
		,	a.BetCount
		,	a.ActiveDays
	FROM dbo.CustomerClassification_LatestGeneralChanged AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.CustId
		LEFT JOIN bodb02.dbo.Customer AS cu WITH(NOLOCK) ON a.CustId = cu.custid;
		
	-- #2: Insert Accounts's BetCount
	INSERT INTO dbo.CustomerClassification_BetCount(CustId, SportId, BetCount)
	SELECT c.CustId, @GENERAL_SPORTID, 0
	FROM #tmpCustomers AS c WITH(NOLOCK)
		LEFT JOIN dbo.CustomerClassification_BetCount AS v WITH(NOLOCK) ON c.CustId = v.CustId
	WHERE c.CategoryId IN (@GENERALCATEGORY_NORMALMEMBER, @GENERALCATEGORY_VIP)
		AND v.CustId IS NULL;

	-- #3: Remove Accounts less than 100 tickets compared to last scan
	DELETE a WITH(ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN dbo.CustomerClassification_BetCount AS v WITH(NOLOCK) ON a.CustId = v.CustId
	WHERE (v.CustId IS NOT NULL AND (a.BetCount - v.BetCount < 100));

	-- #4: Remove SMA account
	DELETE a WITH(ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON a.CustId = c.custid
	WHERE c.roleid <> 1;
	
	-- #5: Classify New Member
	DELETE	a WITH(ROWLOCK)
	OUTPUT	DELETED.CustId
		,	DELETED.TurnoverRM
		,	DELETED.WinlossRM
		,	DELETED.BetCount
		,	DELETED.ActiveDays 
	INTO #tmpNewCustomer(CustId, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	FROM #tmpCustomerAccummulatedInfo AS a
	WHERE a.BetCount < 10;
	
	-- Remove 'haifa doesn't change category'
	DELETE a
	FROM  #tmpCustomerAccummulatedInfo AS a WITH(ROWLOCK)
	WHERE (a.Site = 'haifa' AND a.Margin < 0 AND a.WinlossRM < -20000);
	
	-- #6: Classify Normal Member, Smart Punter & High Risk Punter
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	@GENERAL_SPORTID
		,	CASE
				WHEN (a.Margin <= -2 AND a.TurnoverRM > 150000 AND a.BetCount > 300 AND a.ActiveDays >= 8) THEN @GENERALCATEGORY_VIP
				WHEN (a.Margin >= 0.1 AND a.Margin <= 1 AND a.BetCount >= 20 AND a.WinlossRM > 15000) THEN @GENERALCATEGORY_SMARTPUNTER
				WHEN (a.Margin > 1 AND a.BetCount >= 20 AND a.WinlossRM > 15000) THEN @GENERALCATEGORY_HIGHRISKPUNTER
				WHEN (a.Margin >= 0) THEN @GENERALCATEGORY_PROBATION
				WHEN (a.Margin < 0 AND (a.Site <> 'haifa' OR a.Site IS NULL)) THEN @GENERALCATEGORY_NORMALMEMBER
				WHEN (a.Margin < 0 AND a.Site = 'haifa' AND a.WinlossRM >= -20000) THEN @GENERALCATEGORY_NORMALMEMBER
			END		
		,	@CurrentDate
		,	@CurrentDateTime
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.BetCount
		,	a.ActiveDays
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK);

	-- #7: Insert new members
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	v.CustId, @GENERAL_SPORTID
		,	@GENERALCATEGORY_NEWMEMBER --CASE WHEN (c.CustId IS NULL) THEN @GENERALCATEGORY_NEWMEMBER ELSE 0 END
		,	@CurrentDate, GETDATE()
		,	v.TurnoverRM, v.WinlossRM, v.BetCount, v.ActiveDays
	FROM #tmpNewCustomer AS v WITH(NOLOCK)
		LEFT JOIN #tmpDangerousCustomer AS c WITH(NOLOCK) ON v.CustId = c.CustId;

	-- #8: Log Dangerous Customers for tracking
	INSERT INTO dbo.CustomerClassification_DangerousCustomerLog(CustId, ScannedTime)
	SELECT	t.CustId
		,	GETDATE()
	FROM #tmpDangerousCustomer AS t WITH(NOLOCK)
		LEFT JOIN dbo.CustomerClassification_DangerousCustomerLog AS d WITH(NOLOCK) ON t.CustId = d.CustId
	WHERE d.CustId IS NULL;

	-- #9: Update last scanned ticket count back to dbo.CustomerClassification_BetCount
	UPDATE v WITH(ROWLOCK, UPDLOCK)
	SET v.BetCount = (a.BetCount - (a.BetCount % 100))
		,	v.LastScannedDate = @CurrentDateTime
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
		INNER JOIN dbo.CustomerClassification_BetCount AS v ON a.CustId = v.CustId;
	
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpDangerousCustomer;
	DROP TABLE #tmpNewCustomer;
	DROP TABLE #tmpCustomers;
END;