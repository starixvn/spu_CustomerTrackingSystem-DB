/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_UpdateTotalTicket]
		@BatchSize				INT
	,	@LastSequenceId			BIGINT
	,	@LastSequenceId_New		BIGINT OUTPUT
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
		,	IsInserted	BIT DEFAULT 0
		,	PRIMARY KEY (CustId,ScanDate)
	);

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

	IF OBJECT_ID('tempdb..#Tmp_Trans') IS NOT NULL
		DROP TABLE #Tmp_Trans;

	CREATE TABLE #Tmp_Trans (
			SequenceId		BIGINT PRIMARY KEY
		,	Custid			INT
		,	Bettype			SMALLINT
		,	StatusID		TINYINT
		,	Matchid		    INT
		,	BetFrom		    NVARCHAR(4)
		,	ScanDate		DATE
		,	IsLicensee		BIT
	);
	
	IF OBJECT_ID('tempdb..#tmp_match') IS NOT NULL
		DROP TABLE #tmp_match;

	CREATE TABLE #tmp_match (
			MatchId		INT PRIMARY KEY
	);	

	INSERT INTO #Tmp_WCLeagues(LeagueId)
	SELECT DISTINCT LeagueId
	FROM dbo.league WITH(NOLOCK)
	WHERE ProgramID = '2022' AND DisplayMode = 2;
	
	INSERT INTO #Tmp_PlatformDesktop(BetFrom)
	SELECT b.BetFrom
	FROM DBWH.bodb_account.dbo.tbl_Betfrom AS b WITH (NOLOCK)
	WHERE b.platform2 = 'Desktop';

	INSERT INTO #Tmp_Trans (SequenceId,Custid,Matchid,Bettype,StatusID,BetFrom,ScanDate,IsLicensee)
	SELECT TOP (@BatchSize) bt.sequenceid
		,	bt.custid
		,	bt.matchid
		,	bt.bettype
		,	bt.statusID
		,	bt.BetFrom
		,	bt.transdate
		,	CASE WHEN dCust.custid IS NOT NULL THEN 1 ELSE 0 END
	FROM dbo.bettrans AS bt WITH(NOLOCK)
		LEFT JOIN dbo.Dep_CustSuper AS dCust WITH (NOLOCK) ON dCust.custid = bt.srecommend
	WHERE bt.sequenceid > @LastSequenceId
	ORDER BY bt.sequenceid ASC;

	SELECT @LastSequenceId_New = MAX(SequenceId) FROM #Tmp_Trans;
	SET @LastSequenceId_New = ISNULL(@LastSequenceId_New,@LastSequenceId);

	DELETE FROM #Tmp_Trans WHERE IsLicensee = 0;
	
	INSERT INTO #tmp_match (MatchId)
	SELECT DISTINCT tmp_trans.Matchid 
	FROM #Tmp_Trans AS tmp_trans
		INNER JOIN dbo.match AS m WITH (NOLOCK) ON m.matchid = tmp_trans.MatchId
		LEFT JOIN #Tmp_WCLeagues AS wc WITH(NOLOCK) ON m.leagueid = wc.LeagueId
	WHERE tmp_trans.Matchid <> 29 
		AND m.Sporttype < 100
		AND wc.LeagueId IS NULL;
		
	DELETE tmp_trans
	FROM #Tmp_Trans AS tmp_trans
		LEFT JOIN #tmp_match AS tmp_match ON tmp_match.MatchId = tmp_trans.MatchId
	WHERE tmp_trans.Matchid <> 29 AND tmp_match.MatchId IS NULL;

	INSERT INTO #tmpScanningCust(CustId,ScanDate,IsInserted)
	SELECT DISTINCT tmp_trans.Custid
		, tmp_trans.ScanDate
		, CASE WHEN tmp_trans.Custid IS NOT NULL AND gbc.CustId IS NULL THEN 1 ELSE 0 END AS 'IsInserted'
	FROM #Tmp_Trans AS tmp_trans
		LEFT JOIN dbo.SPU_GroupBettingCustomer AS gbc WITH(NOLOCK)  ON gbc.CustId = tmp_trans.Custid AND gbc.ScanDate = tmp_trans.ScanDate;

	INSERT INTO dbo.SPU_GroupBettingCustomer(CustId,ScanDate,GBTicketCount,TicketCount,ParlayTicketCount,RejectTicketCount,DesktopTicketCount)
	SELECT	sc.CustId
		,	sc.ScanDate
		,	0
		,	0
		,	0
		,	0
		,	0 
	FROM #tmpScanningCust AS sc WITH(NOLOCK)
		LEFT JOIN dbo.SPU_GroupBettingCustomer AS gbc WITH(NOLOCK) ON sc.CustId = gbc.CustId AND sc.ScanDate = gbc.ScanDate
	WHERE gbc.CustId IS NULL AND sc.IsInserted = 1;

	;WITH cte_TicketCount AS (
		SELECT DISTINCT bt.Custid
			,	gbc.ScanDate
			,	COUNT(1) OVER (PARTITION BY bt.Custid,gbc.ScanDate) AS 'TicketCount'
			,	SUM(CASE WHEN bt.StatusID = 101 THEN 1 ELSE 0 END) OVER (PARTITION BY bt.Custid,gbc.ScanDate) AS 'RejectTicketCount'
			,	SUM(CASE WHEN b.BetFrom IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY bt.Custid,gbc.ScanDate) AS 'DesktopTicketCount'		
			,	SUM(CASE WHEN bt.Bettype IN (29,38) THEN 1 ELSE 0 END) OVER (PARTITION BY bt.Custid,gbc.ScanDate) AS 'ParlayTicketCount'		
		FROM dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK)
			INNER JOIN #Tmp_Trans AS bt WITH (NOLOCK) ON gbc.CustId = bt.Custid	AND bt.ScanDate = gbc.ScanDate
			LEFT JOIN #Tmp_PlatformDesktop AS b WITH (NOLOCK) ON b.BetFrom = bt.BetFrom
	)
	UPDATE gbc WITH(UPDLOCK, ROWLOCK)
	SET		gbc.TicketCount = CASE WHEN sc.IsInserted = 1 THEN ct.TicketCount ELSE (gbc.TicketCount + ct.TicketCount) END
		,	gbc.RejectTicketCount = CASE WHEN sc.IsInserted = 1 THEN ct.RejectTicketCount ELSE (gbc.RejectTicketCount + ct.RejectTicketCount) END 
		,	gbc.DesktopTicketCount = CASE WHEN sc.IsInserted = 1 THEN ct.DesktopTicketCount ELSE (gbc.DesktopTicketCount + ct.DesktopTicketCount) END 
		,	gbc.ParlayTicketCount = CASE WHEN sc.IsInserted = 1 THEN ct.ParlayTicketCount ELSE (gbc.ParlayTicketCount + ct.ParlayTicketCount) END 
		,	gbc.LastCountTotalTicketDate = GETDATE()
	FROM dbo.SPU_GroupBettingCustomer AS gbc
		INNER JOIN cte_TicketCount AS ct WITH (NOLOCK) ON gbc.CustId = ct.custid AND gbc.ScanDate = ct.ScanDate
		LEFT JOIN #tmpScanningCust AS sc ON sc.CustId = gbc.CustId AND sc.ScanDate = gbc.ScanDate;

	-- Clear unused data
	DELETE FROM dbo.SPU_GroupBettingCustomer WITH (ROWLOCK)
	WHERE ScanDate < DATEADD(day,-7, GETDATE()) AND TicketCount = 0 AND GBTicketCount = 0;

END