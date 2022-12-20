USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_RealTime_CheckChanges]    Script Date: 9/6/2022 11:08:05 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_GeneralCategorize_RealTime_CheckChanges]
AS
/*
	Created: 20200901@Long.Luu
	Task : Check Customers who have data changed from a range of time
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200901@Long.Luu: Created [Redmine ID: #137550]
		- 20210730@John.Ngo: [CTS] New way to store Closed Status [Redmine ID: #152259]
		- 20280628@Long.Luu: Exclude more Internal Accounts [Redmine ID: #174430]

	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE	@LastScanDateTime			DATETIME
		,	@tmpLastScannedDatetime		DATETIME
		,	@CurrentdDate				DATETIME = GETDATE();
	
	SELECT @LastScanDateTime = CAST([Value] AS DATETIME)
	FROM dbo.CustomerClassification_Parameter WITH(NOLOCK)
	WHERE DataId = 3;

	IF	OBJECT_ID('tempdb..#tmpRawData') IS NOT NULL
		DROP TABLE	#tmpRawData;

	CREATE TABLE #tmpRawData(
		[CustId]			INT NOT NULL,
		[MainDBSportId]		INT NOT NULL,
		[SportGroup]		VARCHAR(50) NOT NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[TurnoverORG]		MONEY NULL,
		[WinlossORG]		MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL,
		PRIMARY KEY (CustId, MainDBSportId)
	);

	-- START
	-- #0: GetCustomer Accummulated data
	INSERT INTO #tmpRawData(CustId, MainDBSportId, SportGroup, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByModifiedDate @LastModifiedDatetime = @LastScanDateTime, @ScannedModifiedDatetime = @tmpLastScannedDatetime OUTPUT;
	
	-- #1: Remove closed & disabled accounts
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
		LEFT JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE c.[Enabled] = 0 OR c.roleid <> 1;
	
	-- #2: Remove Internal Accounts
	DELETE r WITH(ROWLOCK)
	FROM #tmpRawData AS r
		INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON r.CustId = c.custid
	WHERE c.srecommend IN (41430709)
		OR c.mrecommend IN (27899314,11656504,12146012)
		OR c.recommend IN (52466,5707545,29270764,134456)
		OR c.username LIKE '%CashOut'
		OR (c.Site = 'NextBet' OR c.Site = '9wickets' OR c.Site = '9wsports');

	-- #3: Group data by sportgroups
	TRUNCATE TABLE bodb_VR2Model.dbo.CustomerClassification_LatestGeneralChanged;

	INSERT INTO bodb_VR2Model.dbo.CustomerClassification_LatestGeneralChanged(CustId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays, LastModifiedDate)
	SELECT	a.CustId
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDays)
		,	@CurrentdDate
	FROM #tmpRawData AS a WITH(NOLOCK)
	GROUP BY a.CustId;

	-- #4: Store Last Scanned Datetime
	UPDATE dbo.CustomerClassification_Parameter WITH(ROWLOCK, UPDLOCK)
	SET [Value] = @tmpLastScannedDatetime
	WHERE DataId = 4;

	-- #5: return the results
	SELECT DISTINCT CustId
		,	200 AS SportGroupId
	FROM bodb_VR2Model.dbo.CustomerClassification_LatestGeneralChanged WITH(NOLOCK);
END;