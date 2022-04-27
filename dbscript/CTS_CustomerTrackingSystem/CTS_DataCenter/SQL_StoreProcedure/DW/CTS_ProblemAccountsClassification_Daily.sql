USE [bodb_VR2Model]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_ProblemAccountsClassification_Daily]
	@ListCustIds			VARCHAR(MAX),
	@FunctionId				SMALLINT = 12
AS
/*
	Created: 20220328@Long.Luu
	Task : Classify Problem Account -  Daily
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20220328@Long.Luu: Created [Redmine ID: #170468]
		
	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @PROBLEMACCOUNT_LOSING		INT = 0
		,	@PROBLEMACCOUNT_KEEPSTATE	INT = 1
		,	@PROBLEMACCOUNT_WINNING		INT = 2;  

	DECLARE @CurrentDateTime		DATETIME = GETDATE();
	DECLARE @CurrentDate			DATE	 = GETDATE();

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
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
			CustId			INT
	);

	CREATE CLUSTERED INDEX IX_#mpCustomers_CustId ON #tmpCustomers(
		[CustId]			ASC
	);

	-- START
	/*-- LOG INPUT DATA
	INSERT INTO dbo.CustomerClassification_InputLog(CustId,CreatedDate,CreatedTime,FunctionId,IsActive)
	SELECT CustId, @CurrentDate, @CurrentDateTime, @FunctionId, IsActive
	FROM #tmpCustomers;
	*/

	-- #0: Distinct custid
	INSERT INTO #tmpCustomers(CustId)
	SELECT val FROM dbo.SPU_StrSplit(@ListCustIds, ',');

	SELECT @ListCustIds = STUFF((SELECT ',', CONVERT(VARCHAR(15), t.CustId) 
								FROM (SELECT DISTINCT CustId FROM #tmpCustomers WITH (NOLOCK)) AS t
								FOR XML PATH('')), 1, 1, '');
								
	-- #1: GetCustomer Accummulated data
	INSERT INTO #tmpRawData(CustId, MainDBSportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 1;	
	
	-- #2: Sum data by custid
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDays)
	FROM #tmpRawData AS a WITH(NOLOCK)
	GROUP BY a.CustId;

	-- #3: Classify new members
	--INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	r.CustId
		,	CASE
				WHEN (r.WinlossRM < -10000) THEN @PROBLEMACCOUNT_LOSING
				WHEN (r.WinlossRM >= -5000) THEN @PROBLEMACCOUNT_WINNING
				ELSE @PROBLEMACCOUNT_KEEPSTATE
			END AS WinlossStatus
		,	r.TurnoverRM
		,	r.WinlossRM
		,	r.BetCount
		,	r.ActiveDays
	FROM #tmpCustomerAccummulatedInfo AS r WITH(NOLOCK)
END;
