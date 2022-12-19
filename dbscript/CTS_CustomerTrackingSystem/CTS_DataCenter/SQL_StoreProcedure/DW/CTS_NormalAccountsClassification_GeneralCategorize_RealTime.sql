USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_RealTime]    Script Date: 2/23/2022 2:18:50 AM ******/
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
		
	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @GENERAL_SPORTID		SMALLINT = 200;
	DECLARE @FUNCTIONID				SMALLINT = 1,
			@GeneralParameterId		SMALLINT = 6,
		    @MaxId					BIGINT;

	DECLARE @GENERALCATEGORY_NEWMEMBER			INT = 201
		,	@GENERALCATEGORY_NORMALMEMBER		INT = 202
		,	@GENERALCATEGORY_SMARTPUNTER		INT = 203
		,	@GENERALCATEGORY_HIGHRISKPUNTER		INT = 204
		,	@GENERALCATEGORY_VIP				INT = 205
		,	@GENERALCATEGORY_PROBATION			INT = 206
		,	@GENERALCATEGORY_INACTIVE			INT = 1000
        ,	@GENERALCATEGORY_BLANKED			INT = 0;

	DECLARE	@CurrentDateTime			DATETIME = GETDATE()
		,	@CurrentDate				DATE = GETDATE();

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT NOT NULL,
		[Site]				VARCHAR (10) NULL,
		[IsDeposit]			BIT DEFAULT 0,
		[SRecommend]		INT,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[Margin]			MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
		[CategoryId]		SMALLINT NULL
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
	
	-- LOG INPUT DATA
	INSERT INTO dbo.CustomerClassification_InputLog(CustId,CreatedDate,CreatedTime,FunctionId)
	SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID
	FROM #tmpCustomers;	
	
	-- START	
	-- #1: Get MaxID
	SELECT @MaxId = CAST(a.Value AS BIGINT)
	FROM [dbo].CustomerClassification_Parameter AS a WITH(NOLOCK)
	WHERE a.DataId = @GeneralParameterId;

	-- #2: GetCustomer Accummulated data
	WITH cte_rawData AS  (  
					SELECT  *
					FROM (
							SELECT *, ROW_NUMBER() OVER(PARTITION BY a.CustId ORDER BY a.ID DESC) AS RowNum
							FROM [dbo].[CustomerClassification_LatestChanged] AS a WITH(NOLOCK)
							WHERE a.ID <= @MaxId
						) as b
					WHERE b.RowNum = 1
		) 
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, Site, SRecommend, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays, CategoryId)
	SELECT	a.CustId
		,	cu.Site
		,	cu.srecommend
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.Margin
		,	a.BetCount
		,	a.ActiveDays
		,	c.CategoryId
	FROM cte_rawData AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomers AS c WITH(NOLOCK) ON a.CustId = c.CustId
		LEFT JOIN bodb02.dbo.Customer AS cu WITH(NOLOCK) ON a.CustId = cu.custid;

	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.IsDeposit = 1
	FROM #tmpCustomerAccummulatedInfo AS a
		INNER JOIN bodb02.dbo.Dep_CustSuper AS c WITH(NOLOCK) ON a.SRecommend = c.custid;
/*
INSERT INTO dbo.CustomerClassification_InputLog_RealTime(CustId,CreatedDate,CreatedTime,Step)
SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, 1
FROM #tmpCustomerAccummulatedInfo;	
*/
	-- #3: Insert Accounts's BetCount
	INSERT INTO dbo.CustomerClassification_BetCount(CustId, SportId, BetCount)
	SELECT c.CustId, @GENERAL_SPORTID, 0
	FROM #tmpCustomers AS c WITH(NOLOCK)
		LEFT JOIN dbo.CustomerClassification_BetCount AS v WITH(NOLOCK) ON c.CustId = v.CustId
	WHERE c.CategoryId IN (@GENERALCATEGORY_NORMALMEMBER, @GENERALCATEGORY_VIP)
		AND v.CustId IS NULL;
/*
INSERT INTO dbo.CustomerClassification_InputLog_RealTime(CustId,CreatedDate,CreatedTime,Step)
SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, 3
FROM #tmpCustomers;	
*/
	-- #4: Remove Accounts that Ticket Count has not reach the schedule
	-- Remove Accounts less than 100 tickets compared to last scan for VIP
	DELETE a WITH(ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN dbo.CustomerClassification_BetCount AS v WITH(NOLOCK) ON a.CustId = v.CustId
	WHERE a.CategoryId IN (@GENERALCATEGORY_VIP)
		AND (v.CustId IS NOT NULL AND (a.BetCount - v.BetCount < 100));

	-- Remove Accounts less than 20 tickets compared to last scan for Normal Member
	DELETE a WITH(ROWLOCK)
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN dbo.CustomerClassification_BetCount AS v WITH(NOLOCK) ON a.CustId = v.CustId
	WHERE a.CategoryId IN (@GENERALCATEGORY_NORMALMEMBER)
		AND (v.CustId IS NOT NULL AND (a.BetCount - v.BetCount < 20));
/*
INSERT INTO dbo.CustomerClassification_InputLog_RealTime(CustId,CreatedDate,CreatedTime,Step)
SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, 5
FROM #tmpCustomerAccummulatedInfo;	
*/	
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
/*
INSERT INTO dbo.CustomerClassification_InputLog_RealTime(CustId,CreatedDate,CreatedTime,Step)
SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, 7
FROM #tmpCustomerAccummulatedInfo;	
*/	
	-- #6: Classify Normal Member, Smart Punter & High Risk Punter
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	@GENERAL_SPORTID
		,	CASE
				WHEN (a.Margin <= -2 AND a.TurnoverRM > 150000 AND a.BetCount > 300 AND a.ActiveDays >= 8) THEN @GENERALCATEGORY_VIP
				WHEN (a.Margin >= 0.1 AND a.Margin <= 1 AND a.BetCount >= 20 AND a.WinlossRM > 15000) THEN @GENERALCATEGORY_SMARTPUNTER
				WHEN (a.Margin > 1 AND a.BetCount >= 20 AND a.WinlossRM > 15000) THEN @GENERALCATEGORY_HIGHRISKPUNTER
				WHEN (a.Margin >= 0 AND a.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') AND a.WinlossRM > -5000) THEN @GENERALCATEGORY_NEWMEMBER
				WHEN (a.Margin >= 0 AND a.WinlossRM < 10000 AND a.IsDeposit = 0) THEN @GENERALCATEGORY_NORMALMEMBER
				WHEN (a.Margin >= 0) THEN @GENERALCATEGORY_PROBATION
				WHEN (a.Margin < 0 AND (a.Site NOT IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') OR a.Site IS NULL)) THEN @GENERALCATEGORY_NORMALMEMBER				
				WHEN (a.Margin < 0 AND a.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada') AND a.WinlossRM <= -5000) THEN @GENERALCATEGORY_NORMALMEMBER
				WHEN (a.Margin < 0 AND a.Site IN ('haifa','manbetx','HC6YAYOU','US8YAYOU','BPLE','Okada')) THEN @GENERALCATEGORY_NEWMEMBER
			END					
		,	@CurrentDate
		,	@CurrentDateTime
		,	a.TurnoverRM
		,	a.WinlossRM
		,	a.BetCount
		,	a.ActiveDays
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK);
/*
INSERT INTO dbo.CustomerClassification_InputLog_RealTime(CustId,CreatedDate,CreatedTime,Step)
SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, 9
FROM #tmpCustomerAccummulatedInfo;	
*/
	-- #7: Insert new members
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	v.CustId, @GENERAL_SPORTID
		,	@GENERALCATEGORY_NEWMEMBER 
		,	@CurrentDate, GETDATE()
		,	v.TurnoverRM, v.WinlossRM, v.BetCount, v.ActiveDays
	FROM #tmpNewCustomer AS v WITH(NOLOCK);
/*
INSERT INTO dbo.CustomerClassification_InputLog_RealTime(CustId,CreatedDate,CreatedTime,Step)
SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, 11
FROM #tmpNewCustomer;	
*/
	-- #8: Log Dangerous Customers for tracking
	INSERT INTO dbo.CustomerClassification_DangerousCustomerLog(CustId, ScannedTime)
	SELECT	t.CustId
		,	GETDATE()
	FROM #tmpDangerousCustomer AS t WITH(NOLOCK)
		LEFT JOIN dbo.CustomerClassification_DangerousCustomerLog AS d WITH(NOLOCK) ON t.CustId = d.CustId
	WHERE d.CustId IS NULL;

	-- #9: Update last scanned ticket count back to dbo.CustomerClassification_BetCount
	UPDATE v WITH(ROWLOCK, UPDLOCK)
	SET v.BetCount = CASE 
						WHEN a.CategoryId IN (@GENERALCATEGORY_VIP) 
							THEN (a.BetCount - (a.BetCount % 100))
						WHEN a.CategoryId IN (@GENERALCATEGORY_NORMALMEMBER) 
							THEN (a.BetCount - (a.BetCount % 20))
					END
		,	v.LastScannedDate = @CurrentDateTime
	FROM #tmpCustomerAccummulatedInfo AS a WITH(NOLOCK)
		INNER JOIN dbo.CustomerClassification_BetCount AS v ON a.CustId = v.CustId;
/*
INSERT INTO dbo.CustomerClassification_InputLog_RealTime(CustId,CreatedDate,CreatedTime,Step)
SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, 13
FROM #tmpNewCustomer;
INSERT INTO dbo.CustomerClassification_InputLog_RealTime(CustId,CreatedDate,CreatedTime,Step)
SELECT DISTINCT CustId, @CurrentDate, @CurrentDateTime, 13
FROM #tmpCustomerAccummulatedInfo;	
*/	
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpDangerousCustomer;
	DROP TABLE #tmpNewCustomer;
	DROP TABLE #tmpCustomers;
END;