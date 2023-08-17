/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
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
		- 20230601@Jonas.Huynh: Update SP get accumulated performance (Renovate Phase2) [Redmine ID: #186684]
		- 20230627@Jonas.Huynh: Reset Balance for Credit with Inactive Normal with new place-bet [Redmine ID: #189876]
		- 20230807@Jonas.Huynh: HF exclude Non-sport for General [Redmine ID: #192388]
		- 20230726@Jonas.Huynh: Saba Classification [Redmine ID: #185320]

	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @PROBLEMACCOUNT_LOSING		INT = 0
		,	@PROBLEMACCOUNT_KEEPSTATE	INT = 1
		,	@PROBLEMACCOUNT_WINNING		INT = 2;

	DECLARE @CurrentDateTime			DATETIME = GETDATE();
	DECLARE @CurrentDate				DATE	 = GETDATE();

	DECLARE @SportGroup_SabaVRSoccer	 SMALLINT = 145,
			@SportGroup_SabaVRBasketball SMALLINT = 912,
			@SportGroup_NonSport		 SMALLINT = 229;

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
		PRIMARY KEY CLUSTERED (CustId, SportGroup)
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

	-- #0: Distinct custid
	INSERT INTO #tmpCustomers(CustId)
	SELECT val FROM dbo.SPU_StrSplit(@ListCustIds, ',');

	SELECT @ListCustIds = STUFF((SELECT ',', CONVERT(VARCHAR(15), t.CustId) 
								FROM (SELECT DISTINCT CustId FROM #tmpCustomers WITH (NOLOCK)) AS t
								FOR XML PATH('')), 1, 1, '');

	-- #1: GetCustomer Accummulated data
	INSERT INTO #tmpRawData(CustId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDaysCustID, ActiveDaysSportGroup, WindaysCustID, WinDaysSportGroup, ProcessedTime)
	EXEC bodb_dwrs.dbo.Acc_Rpt_CTS_GetCustAccumulatedInfo @ListCustID = @ListCustIds, @isResetBalance = 1;

	DELETE a WITH (ROWLOCK)
	FROM #tmpRawData AS a
	WHERE a.SportGroup IN (@SportGroup_NonSport, @SportGroup_SabaVRSoccer, @SportGroup_SabaVRBasketball);

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
