USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_Probation_CheckLoser]    Script Date: 9/28/2020 10:33:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_Probation_CheckLoser]
		@CustomersXML			XML
AS
/*
	Created: 20200918@Long.Luu
	Task : Check whether probation accounts are loser
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200918@Long.Luu: Created [Redmine ID: #141755]
        - 20200924@Irena.Vo: Updated [Redmine ID: #141755]
		- 20201026@Long.Luu: Allow to move from Probation back to Normal, VIP [Redmine ID: #142546]
         
	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @GENERAL_SPORTID	SMALLINT = 200;

	DECLARE @GENERALCATEGORY_NORMALMEMBER		INT = 202
		,	@GENERALCATEGORY_SMARTPUNTER		INT = 203
		,	@GENERALCATEGORY_HIGHRISKPUNTER		INT = 204
		,	@GENERALCATEGORY_VIP				INT = 205
		,	@DETAILEDCATEGORY_NORMALMEMBER		INT = 4
		,	@DETAILEDCATEGORY_VIP				INT = 5
		,	@DETAILEDCATEGORY_SMARTPUNTER		INT = 6
		,	@DETAILEDCATEGORY_HIGHRISKPUNTER	INT = 7;

	DECLARE	@CustIdList			VARCHAR(MAX)	
		,	@CurrentDateTime	DATETIME = GETDATE()
		,	@CurrentDate		DATE = GETDATE();
	
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
		[ActiveDays]		INT NULL
	);

	IF	OBJECT_ID('tempdb..#tmpLoser') IS NOT NULL
		DROP TABLE	#tmpLoser;

	CREATE TABLE #tmpLoser(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[Margin]			MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerAccummulatedInfo') IS NOT NULL
		DROP TABLE	#tmpCustomerAccummulatedInfo;

	CREATE TABLE #tmpCustomerAccummulatedInfo(
		[CustId]			INT NOT NULL,
		[SportId]			INT NOT NULL,
		[TurnoverRM]		MONEY NULL,
		[WinlossRM]			MONEY NULL,
		[Margin]			MONEY NULL,
		[BetCount]			BIGINT NULL,
		[ActiveDays]		INT NULL
	);

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END
	
	CREATE TABLE #tmpCustomers(
		[CustId]			INT,
		[SportId]			SMALLINT,
		PRIMARY KEY (CustId, SportId)
	);


	IF	OBJECT_ID('tempdb..#tmpSportGroups') IS NOT NULL
		DROP TABLE	#tmpSportGroups;

	CREATE TABLE #tmpSportGroups(
		[SportId]			INT NOT NULL, --1 soccer, 2 basketball, 3 othersports, 4 esports, 5 nonsports
		[MainDBSportId]		INT NOT NULL,
		PRIMARY KEY (SportId, MainDBSportId)
	);

	-- Init sportgroups
	INSERT INTO #tmpSportGroups(SportId, MainDBSportId)
	VALUES (1,1), (2,2), (4,43), (6,-100);

	INSERT INTO #tmpSportGroups(SportId, MainDBSportId)
	SELECT DISTINCT 3, s.SportType
	FROM bodb02.dbo.SportBettypeMatrix AS s WITH(NOLOCK)
	WHERE s.ProductID = 1
		AND s.SportType NOT IN (1,2,43);

	-- Parse customers info
	INSERT INTO #tmpCustomers(CustId, SportId)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@SportGroupId', 'SMALLINT') AS SportId
	FROM @CustomersXML.nodes('//ProbationModel') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- Get Customer's ID List
	SELECT @CustIdList = STUFF((SELECT DISTINCT ',' + CAST(CustId AS VARCHAR(10))
			  FROM #tmpCustomers
			  FOR XML PATH ('')), 1, 1, '');

	-- Get Customer's Accummulated data
	INSERT INTO #tmpRawData(CustId, SportId, TurnoverRM, WinlossRM, TurnoverORG, WinlossORG, BetCount, ActiveDays)
	EXEC bodb_dwrs.dbo.Acc_Rpt_GetCustAccumulatedInfo_Realtime_ByListCustID  @ListCustID = @CustIdList;

	INSERT INTO #tmpCustomerAccummulatedInfo(CustId, SportId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END
		,	SUM(a.TurnoverRM)
		,	SUM(a.WinlossRM)
		,	CASE WHEN SUM(a.TurnoverRM) = 0 THEN 0 ELSE SUM(a.WinlossRM) / SUM(a.TurnoverRM) * 100 END
		,	SUM(a.BetCount)
		,	MAX(a.ActiveDays)
	FROM #tmpRawData AS a WITH(NOLOCK)
		LEFT JOIN #tmpSportGroups AS s WITH(NOLOCK) ON a.SportId = s.MainDBSportId
	GROUP BY a.CustId, CASE WHEN s.SportId IS NULL THEN 5 ELSE s.SportId END
	UNION
	SELECT	s.CustId
		,	@GENERAL_SPORTID
		,	SUM(s.TurnoverRM)
		,	SUM(s.WinlossRM)
		,	CASE WHEN SUM(s.TurnoverRM) = 0 THEN 0 ELSE SUM(s.WinlossRM) / SUM(s.TurnoverRM) * 100 END
		,	SUM(s.BetCount)
		,	MAX(s.ActiveDays)
	FROM #tmpRawData AS s WITH(NOLOCK)
	GROUP BY s.CustId;
	
	INSERT INTO #tmpLoser(CustId, SportId, TurnoverRM, WinlossRM, Margin, BetCount, ActiveDays)
	SELECT	a.CustId
		,	a.SportId
		,	t.TurnoverRM
		,	t.WinlossRM
		,	CASE WHEN SUM(t.TurnoverRM) = 0 THEN 0 ELSE SUM(t.WinlossRM) / SUM(t.TurnoverRM) * 100 END
		,	t.BetCount
		,	t.ActiveDays
	FROM #tmpCustomers AS a WITH(NOLOCK)
		INNER JOIN #tmpCustomerAccummulatedInfo AS t WITH(NOLOCK) ON a.CustId = t.CustId AND a.SportId = t.SportId
	WHERE t.WinlossRM < 0
	GROUP BY a.CustId
		,	a.SportId
		,	t.TurnoverRM
		,	t.WinlossRM
		,	t.BetCount
		,	t.ActiveDays;

	INSERT INTO dbo.CustomerClassification(CustId, SportId, CategoryId, CreatedDate, CreatedTime, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT	t.CustId
		,	t.SportId
		,	CASE 
				WHEN (t.Margin <= -2 AND t.TurnoverRM > 150000 AND t.BetCount > 300 AND t.ActiveDays >= 8) THEN 
					CASE WHEN t.SportId = 200 THEN @GENERALCATEGORY_VIP
					ELSE @DETAILEDCATEGORY_VIP END
				ELSE
					CASE WHEN t.SportId = 200 THEN @GENERALCATEGORY_NORMALMEMBER
					ELSE @DETAILEDCATEGORY_NORMALMEMBER END
			END
		,	@CurrentDate AS CreatedDate
		,	@CurrentDateTime AS CreatedTime
		,	t.TurnoverRM
		,	t.WinlossRM
		,	t.BetCount
		,	t.ActiveDays
	FROM #tmpLoser AS t WITH(NOLOCK);
						
	-- Return results
	SELECT	t.CustId
		,	t.SportId AS 'SportGroupId'
	FROM #tmpLoser AS t WITH(NOLOCK);
END;