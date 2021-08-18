USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_Probation]    Script Date: 7/20/2021 12:54:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_Probation]
		@CustomersXML			XML
AS
/*
	Created: 20201111@Long.Luu
	Task : Daily scan for Probation accounts
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20201111@Long.Luu: Created [Redmine ID: #145028]
		- 20201224@Long.Luu: Return more data [Redmine ID: #145951]
		- 20210408@John.Ngo: Special rule for Haifa CC2 & Problem Agent Category (only member level) [Redmine ID: #152884]
		- 20210531@John.Ngo: Exclude non-real Saba Sport on Customer Classification [Redmine ID: #155976]
		- 20210607@Long.Luu: Change probation rules [Redmine ID: #156466]
        - 20210611@Long.Luu: Check Inactive Accounts [Redmine ID: #156465] 
		- 20210714@Long.Luu: Special rule for ManbetX CC2 [Redmine ID: #158465]
		- 20210811@Long.Luu: Change way to check Customers' Inactive status [Redmine ID: #159543]
        
	Param's Explanation:

	Example:
		EXEC [dbo].[CTS_NormalAccountsClassification_Probation] @CustomersXML='<root> <ProbationModel CustId="123" SportGroupId="200" IsProbationLastDay="2" /> </root>';
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @PARLAY_SPORTID		SMALLINT = -100
		,	@GENERAL_SPORTID	SMALLINT = 200;

	DECLARE @FUNCTIONID			SMALLINT = 2;

	DECLARE @GENERALCATEGORY_NORMALMEMBER		INT = 202
		,	@GENERALCATEGORY_SMARTPUNTER		INT = 203
		,	@GENERALCATEGORY_HIGHRISKPUNTER		INT = 204
		,	@GENERALCATEGORY_VIP				INT = 205
		,	@GENERALCATEGORY_PROBATION			INT = 206
		,	@GENERALCATEGORY_INACTIVE			INT = 1000;

	DECLARE	@CustIdList			VARCHAR(MAX)	
		,	@CurrentDateTime	DATETIME = GETDATE()
		,	@CurrentDate		DATE	 = GETDATE()

	DECLARE	@ToDate				DATE	 = DATEADD(DAY, -1, GETDATE());
	DECLARE	@From30Date			DATE	 = DATEADD(DAY, - 30, @ToDate);
	
	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[TurnoverORG]		MONEY NULL,
		[WinlossORG]		MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
		PRIMARY KEY ([CustId],[SportId])
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT NOT NULL PRIMARY KEY,
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
		[CustId]					INT PRIMARY KEY,
		[CategoryId]				SMALLINT DEFAULT 206, --@GENERALCATEGORY_PROBATION
		[IsProbationLastDay]		BIT DEFAULT 0,
		[IsPassed]					BIT DEFAULT 0
	);

	IF OBJECT_ID('tempdb..#tmpActiveCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpActiveCustomers;
	END
	
	CREATE TABLE #tmpActiveCustomers(
			CustId			INT PRIMARY KEY
		,	IsActive		BIT DEFAULT 0
	);
	
	-- Parse customers info
	INSERT INTO #tmpCustomers(CustId, IsProbationLastDay)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@IsProbationLastDay', 'BIT') AS IsProbationLastDay
	FROM @CustomersXML.nodes('//ProbationModel') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- Check inactive customers
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	INSERT INTO #tmpActiveCustomers(CustId, IsActive)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList, @ResultDataMode = 2, @FromDate = @From30Date, @ToDate = @ToDate;	

	-- LOG INPUT DATA
	INSERT INTO dbo.CustomerClassification_InputLog(CustId,CreatedDate,CreatedTime,FunctionId,IsActive)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FUNCTIONID, IsActive
	FROM #tmpActiveCustomers WITH(NOLOCK );

	-- Insert inactive customers
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, LastXDaysMargin, ProbationPeriodWinloss)
	SELECT  CustId
		,  @GENERAL_SPORTID
		,  @GENERALCATEGORY_INACTIVE
		,  @CurrentDate AS CreatedDate
		,  @CurrentDateTime AS CreatedTime
		,  0
		,  0
		,  0
		,  0
		,  0
		,  0
	FROM #tmpActiveCustomers
	WHERE IsActive = 0;

	DELETE r WITH(ROWLOCK)
	FROM #tmpCustomers AS r
		INNER JOIN #tmpActiveCustomers AS a ON a.CustId = r.CustId
	WHERE a.IsActive = 0;

	-- Get Customer's ID List
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	-- Get Customer's Accummulated data
	INSERT INTO #tmpRawData(CustId, SportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList;

	-- Remove Parlay
	DELETE FROM #tmpRawData
	WHERE SportId = @PARLAY_SPORTID;

	-- Remove SMA account
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
		LEFT JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE c.roleid <> 1;

	-- Sum data by sport
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	s.CustId
		,	SUM(s.TurnoverRM)
		,	SUM(s.WinlossRM)
		,	CASE WHEN SUM(s.TurnoverRM) = 0 THEN 0 ELSE SUM(s.WinlossRM) / SUM(s.TurnoverRM) * 100 END
		,	SUM(s.BetCount)
		,	MAX(s.ActiveDays)
	FROM #tmpRawData AS s WITH(NOLOCK)
	GROUP BY s.CustId;

	-- Get site info
	UPDATE a WITH(ROWLOCK, UPDLOCK)
	SET a.site = c.site
	FROM #tmpCustomerAccummulatedInfo AS a
		LEFT JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON a.CustId = c.custid;
		
	-- Assign level for customers with margin <0 (jump down to Normal or VIP)
	UPDATE c WITH(ROWLOCK, UPDLOCK)
	SET c.IsPassed = 1,
		c.CategoryId = CASE 
							WHEN (s.Margin <= -2 AND s.TurnoverRM >= 150000 AND s.BetCount >= 300) THEN @GENERALCATEGORY_VIP
							WHEN (s.Site IN ('haifa','manbetx') AND s.WinlossRM < -5000) THEN @GENERALCATEGORY_PROBATION
							ELSE @GENERALCATEGORY_NORMALMEMBER								
						END
	FROM #tmpCustomers AS c
		INNER JOIN #tmpCustomerAccummulatedInfo AS s ON c.CustId = s.CustId
	WHERE s.Margin < 0;

	-- Assign level for customers with Margin >= 0 (jump up to Smart or High Risk)
	UPDATE c WITH(ROWLOCK, UPDLOCK)
	SET c.IsPassed = 1,
		c.CategoryId =	CASE 
							WHEN (a.Margin <= 1 AND a.WinlossRM > 15000 AND a.BetCount >= 20) THEN 
								 @GENERALCATEGORY_SMARTPUNTER
							WHEN (a.Margin > 1 AND a.WinlossRM > 15000 AND a.BetCount >= 20) THEN
								 @GENERALCATEGORY_HIGHRISKPUNTER
							ELSE @GENERALCATEGORY_PROBATION
						END
	FROM #tmpCustomers AS c
		INNER JOIN #tmpCustomerAccummulatedInfo AS a ON c.CustId = a.CustId
	WHERE c.IsProbationLastDay = 1
		AND a.Margin >= 0;
	
	-- Insert to CustomerClassification
	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays, LastXDaysMargin, ProbationPeriodWinloss)
	SELECT  a.CustId
		,  @GENERAL_SPORTID
		,  a.CategoryId
		,  @CurrentDate AS CreatedDate
		,  @CurrentDateTime AS CreatedTime
		,  t.TurnoverRM
		,  t.WinlossRM
		,  t.BetCount
		,  t.ActiveDays
		,  0
		,  0
	FROM #tmpCustomers AS a WITH(NOLOCK)
	INNER JOIN #tmpCustomerAccummulatedInfo AS t WITH(NOLOCK) ON a.CustId = t.CustId;
	
	-- Return results
	SELECT	CustId
		,	@GENERAL_SPORTID AS 'SportGroupId'
		,	IsProbationLastDay
		,	CategoryId
		,	0
		,	0
		,	IsPassed
	FROM #tmpCustomers WITH(NOLOCK);

	DROP TABLE #tmpRawData;
	DROP TABLE #tmpCustomerAccummulatedInfo;
	DROP TABLE #tmpCustomers;
END;