USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_ProblemAccountsClassification_Daily]    Script Date: 9/6/2022 11:08:29 PM ******/
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
		- 20221118@Jonas.Huynh: Update parameter of DW SP GetCustAccumulatedInfo [Redmine ID: #179500]
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
		CustId					INT				NOT NULL,
		SportId					INT				NOT NULL,
		TurnoverRM				DECIMAL(19, 4)	NULL,
		WinlossRM				DECIMAL(19, 4)	NULL,
		TurnoverORG				DECIMAL(19, 4)	NULL,
		WinlossORG				DECIMAL(19, 4)	NULL,
		BetCount				BIGINT			NULL,
		ActiveDaysCustID		INT				NOT NULL,
        ActiveDaysSportGroup	INT				NOT NULL,
        WindaysCustID			INT				NOT NULL,
        WinDaysSportGroup		INT				NOT NULL
		PRIMARY KEY CLUSTERED (CustId, SportId)
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
	INSERT INTO #tmpRawData(CustId, SportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDaysCustID, ActiveDaysSportGroup, WindaysCustID, WinDaysSportGroup)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @ListCustIds, @ResultDataMode = 1;	
	
	-- #2: Sum data by custid
	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	a.CustId
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDaysCustID)
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
