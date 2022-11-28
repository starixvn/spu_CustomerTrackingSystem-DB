/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_UpdateTotalTicket]
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Caculate Group betting ticket
	DB	 : DBCTS.bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Scan ticket 								[Redmine ID: #169671]
		- 20220614@Harvey.Nguyen: Add rowlock in updating 					[Redmine ID: #169671]
		- 20220711@Harvey.Nguyen: Change solution to scan on each ticket	[Redmine ID: #169671]
		- 20221122@Long.Luu:	  Exclude WC Leagues						[Redmine ID: #181229]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_UpdateTotalTicket] @LastScannedTime = '2022-03-10 03:39:12.230'
*/
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#tmpScanningCust') IS NOT NULL
		DROP TABLE #tmpScanningCust;

	CREATE TABLE #tmpScanningCust(
			CustId		INT
		,	ScanDate	DATE
		,	CONSTRAINT PK_tmpScanningCust PRIMARY KEY (CustId,ScanDate)
	)

	IF OBJECT_ID('tempdb..#Tmp_WCLeagues') IS NOT NULL
		DROP TABLE #Tmp_WCLeagues;

	CREATE TABLE #Tmp_WCLeagues (
			LeagueId	INT PRIMARY KEY
	);

	INSERT INTO #Tmp_WCLeagues(LeagueId)
	SELECT DISTINCT LeagueId
	FROM dbo.league WITH(NOLOCK)
	WHERE ProgramID = '2022' AND DisplayMode = 2;

	INSERT INTO #tmpScanningCust(CustId,ScanDate)
	SELECT DISTINCT CustId
		,	CONVERT(DATE, GETDATE()) AS 'ScanDate'
	FROM dbo.SPU_GroupBettingCustomer WITH(NOLOCK);

	INSERT INTO dbo.SPU_GroupBettingCustomer(CustId,ScanDate,GBTicketCount,TicketCount)
	SELECT	sc.CustId
		,	sc.ScanDate
		,	0
		,	0
	FROM #tmpScanningCust AS sc WITH(NOLOCK)
		LEFT JOIN dbo.SPU_GroupBettingCustomer AS gbc WITH(NOLOCK) 
			ON sc.CustId = gbc.CustId AND sc.ScanDate = gbc.ScanDate
	WHERE gbc.CustId IS NULL;

	;WITH cte_TicketCount AS (
		SELECT	bt.custid
			,	gbc.ScanDate
			,	COUNT(1) 'TicketCount'
		FROM dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK)
			INNER JOIN dbo.bettrans AS bt WITH (NOLOCK) ON gbc.CustId = bt.custid
				AND (
						bt.transdate >= CONVERT(DATETIME, gbc.ScanDate)
						AND bt.transdate < DATEADD(DAY, 1, CONVERT(DATETIME, gbc.ScanDate))
					)			
			INNER JOIN dbo.match AS m WITH (NOLOCK) ON bt.matchid = m.matchid			
			LEFT JOIN #Tmp_WCLeagues AS wc WITH(NOLOCK) ON m.leagueid = wc.LeagueId
		WHERE (gbc.LastCountTotalTicketDate IS NULL
			OR (gbc.LastCountTotalTicketDate BETWEEN gbc.ScanDate AND DATEADD(MINUTE, 1470, CONVERT(DATETIME,gbc.ScanDate))))
			AND wc.LeagueId IS NULL
		GROUP BY bt.custid
			,	gbc.ScanDate
		)
	UPDATE gbc WITH(UPDLOCK, ROWLOCK)
	SET		gbc.TicketCount = ct.TicketCount
		,	gbc.LastCountTotalTicketDate = GETDATE()
	FROM dbo.SPU_GroupBettingCustomer AS gbc
	INNER JOIN cte_TicketCount AS ct WITH (NOLOCK) ON gbc.CustId = ct.custid
		AND gbc.ScanDate = ct.ScanDate;

	-- Clear unused data
	DELETE FROM dbo.SPU_GroupBettingCustomer WITH (ROWLOCK)
	WHERE ScanDate < DATEADD(day,-5, GETDATE()) AND TicketCount = 0 AND GBTicketCount = 0;

END