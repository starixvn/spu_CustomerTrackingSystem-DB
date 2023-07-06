SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CTS_TWGroupBetting_UpdateTotalTicket]
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
		- 20230626@Victoria.Le:	  Calculate TicketCount,RejectTicketCount,DesktopTicketCount,ParlayTicketCount
								  And only get sportttype < 100 			[Redmine ID: #189505]

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
	
	IF OBJECT_ID('tempdb..#Tmp_PlatformDesktop') IS NOT NULL
		DROP TABLE #Tmp_PlatformDesktop;

	CREATE TABLE #Tmp_PlatformDesktop (
			BetFrom		VARCHAR(5) PRIMARY KEY
	);

	INSERT INTO #Tmp_WCLeagues(LeagueId)
	SELECT DISTINCT LeagueId
	FROM dbo.league WITH(NOLOCK)
	WHERE ProgramID = '2022' AND DisplayMode = 2;
	
	INSERT INTO #Tmp_PlatformDesktop(BetFrom)
	SELECT b.BetFrom
	FROM DBWH.bodb_account.dbo.tbl_Betfrom AS b WITH (NOLOCK)
	WHERE b.platform2 = 'Desktop';

	INSERT INTO #tmpScanningCust(CustId,ScanDate)
	SELECT DISTINCT CustId
		,	CONVERT(DATE, GETDATE()) AS 'ScanDate'
	FROM dbo.SPU_GroupBettingCustomer WITH(NOLOCK);

	INSERT INTO dbo.SPU_GroupBettingCustomer(CustId,ScanDate,GBTicketCount,TicketCount,ParlayTicketCount,RejectTicketCount,DesktopTicketCount)
	SELECT	sc.CustId
		,	sc.ScanDate
		,	0
		,	0
		,	0
		,	0
		,	0 
	FROM #tmpScanningCust AS sc WITH(NOLOCK)
		LEFT JOIN dbo.SPU_GroupBettingCustomer AS gbc WITH(NOLOCK) 
			ON sc.CustId = gbc.CustId AND sc.ScanDate = gbc.ScanDate
	WHERE gbc.CustId IS NULL;

	;WITH cte_TicketCount AS (
		SELECT DISTINCT bt.custid
			,	gbc.ScanDate
			,	SUM(CASE WHEN (m.matchid IS NULL AND bt.matchid = 29 AND bt.bettype = 29) OR (m.matchid IS NOT NULL) THEN 1
						 ELSE 0 END) OVER (PARTITION BY bt.custid,gbc.ScanDate) AS 'TicketCount'
			,	SUM(CASE WHEN bt.statusID = 101 THEN (CASE WHEN (m.matchid IS NULL AND bt.matchid = 29 AND bt.bettype = 29) OR (m.matchid IS NOT NULL) THEN 1
													  ELSE 0 END)
					ELSE 0 END) OVER (PARTITION BY bt.custid,gbc.ScanDate) AS 'RejectTicketCount'
			,	SUM(CASE WHEN b.BetFrom IS NOT NULL THEN (CASE WHEN (m.matchid IS NULL AND bt.matchid = 29 AND bt.bettype = 29) OR (m.matchid IS NOT NULL) THEN 1
													  ELSE 0 END)
					ELSE 0 END) OVER (PARTITION BY bt.custid,gbc.ScanDate) AS 'DesktopTicketCount'		
			,	SUM(CASE WHEN (m.matchid IS NULL AND bt.matchid = 29 AND bt.bettype = 29) OR (m.matchid IS NOT NULL AND bt.bettype = 38) THEN 1
						 ELSE 0 END) OVER (PARTITION BY bt.custid,gbc.ScanDate) AS 'ParlayTicketCount'	
		FROM dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK)
			INNER JOIN dbo.bettrans AS bt WITH (NOLOCK) ON gbc.CustId = bt.custid
				AND (
						bt.transdate >= CONVERT(DATETIME, gbc.ScanDate)
						AND bt.transdate < DATEADD(DAY, 1, CONVERT(DATETIME, gbc.ScanDate))
					)			
			LEFT JOIN dbo.match AS m WITH (NOLOCK) ON bt.matchid = m.matchid AND m.sporttype < 100
			LEFT JOIN #Tmp_PlatformDesktop AS b WITH (NOLOCK) ON b.BetFrom = bt.betfrom
			LEFT JOIN #Tmp_WCLeagues AS wc WITH(NOLOCK) ON m.leagueid = wc.LeagueId
		WHERE (gbc.LastCountTotalTicketDate IS NULL
			OR (gbc.LastCountTotalTicketDate BETWEEN gbc.ScanDate AND DATEADD(MINUTE, 1470, CONVERT(DATETIME,gbc.ScanDate))))
			AND wc.LeagueId IS NULL
		)
	UPDATE gbc WITH(UPDLOCK, ROWLOCK)
	SET		gbc.TicketCount = ct.TicketCount
		,	gbc.RejectTicketCount = ct.RejectTicketCount
		,	gbc.DesktopTicketCount = ct.DesktopTicketCount
		,	gbc.ParlayTicketCount = ct.ParlayTicketCount
		,	gbc.LastCountTotalTicketDate = GETDATE()
	FROM dbo.SPU_GroupBettingCustomer AS gbc
	INNER JOIN cte_TicketCount AS ct WITH (NOLOCK) ON gbc.CustId = ct.custid
		AND gbc.ScanDate = ct.ScanDate;

	-- Clear unused data
	DELETE FROM dbo.SPU_GroupBettingCustomer WITH (ROWLOCK)
	WHERE ScanDate < DATEADD(day,-5, GETDATE()) AND TicketCount = 0;

END
GO
GRANT EXECUTE ON [dbo].[CTS_TWGroupBetting_UpdateTotalTicket] TO [bodbSPUNet]
GO
