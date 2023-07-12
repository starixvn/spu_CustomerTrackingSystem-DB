/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20230626@Victoria.Le
	Task : TW Group Betting - Initial Data - Latest 60 days (Calculated from ReleasedDate = '2023-07-12')
	DB:	DB062		
	
	Description: 

	Revisions:	
		- 20230626@Victoria.Le: 	Initial Writing - Range 14
									[Redmine ID: #189505]
*/

USE [bodb02]

DECLARE	@ReleasedDate DATE = '2023-07-12'
	,	@Day60 SMALLDATETIME
	,	@ScannedDate SMALLDATETIME
	,	@Today DATETIME
	,	@TotalTicket INT = 0
	,	@StartRow INT = 1
	,	@StopRow INT 
	,	@MaxRow INT 
	,	@Threshold INT = 2000 
	,	@iday INT = 1
	,	@debug_message VARCHAR(500)
	,	@ScannedDate_message VARCHAR(500)
;

DECLARE @BalanceUpDay SMALLDATETIME
	,	@MoveBetsDay SMALLDATETIME
;

IF	OBJECT_ID('tempdb..#BUMBData') IS NOT NULL
	DROP TABLE	#BUMBData;

CREATE TABLE	#BUMBData (
		BUDay	SMALLDATETIME
	,	MBDay	SMALLDATETIME
);

IF OBJECT_ID('tempdb..#tmp_WCLeagues') IS NOT NULL
	DROP TABLE #tmp_WCLeagues;

CREATE TABLE #tmp_WCLeagues (
		LeagueId	INT PRIMARY KEY
);

IF OBJECT_ID('tempdb..#tmp_PlatformDesktop') IS NOT NULL
	DROP TABLE #tmp_PlatformDesktop;

CREATE TABLE #tmp_PlatformDesktop (
		BetFrom		VARCHAR(5) PRIMARY KEY
);

IF OBJECT_ID('tempdb..#tmpSPU_GroupBettingCustomer') IS NOT NULL
	DROP TABLE #tmpSPU_GroupBettingCustomer;

CREATE TABLE #tmpSPU_GroupBettingCustomer (
		ID							INT IDENTITY (1,1)
	,	CustId						INT 	
	,	ScanDate					DATE
	,	LastCountTotalTicketDate	DATETIME	
	,	TicketCount					INT
	,	RejectTicketCount			INT
	,	DesktopTicketCount			INT
	,	ParlayTicketCount			INT
	,	IsInserted					BIT DEFAULT 0
	,	PRIMARY KEY (CustId,ScanDate)
);	

IF OBJECT_ID('tempdb..#tmpSPU_GroupBettingCustomer_updated') IS NOT NULL
	DROP TABLE #tmpSPU_GroupBettingCustomer_updated;

CREATE TABLE #tmpSPU_GroupBettingCustomer_updated (
		ID							INT IDENTITY (1,1)
	,	CustId						INT 	
	,	ScanDate					DATE
	,	LastCountTotalTicketDate	DATETIME	
	,	TicketCount					INT
	,	RejectTicketCount			INT
	,	DesktopTicketCount			INT
	,	ParlayTicketCount			INT
	,	IsInserted					BIT
	,	PRIMARY KEY (CustId,ScanDate)
);

IF OBJECT_ID('tempdb..#tmp_batch_updated') IS NOT NULL
	DROP TABLE #tmp_batch_updated;

CREATE TABLE #tmp_batch_updated (
		CustId						INT 	
	,	ScanDate					DATE
	,	LastCountTotalTicketDate	DATETIME	
	,	TicketCount					INT
	,	RejectTicketCount			INT
	,	DesktopTicketCount			INT
	,	ParlayTicketCount			INT
	,	IsInserted					BIT
	,	PRIMARY KEY (CustId,ScanDate)
);	

IF OBJECT_ID('tempdb..#Tmp_Trans') IS NOT NULL
	DROP TABLE #Tmp_Trans;

CREATE TABLE #Tmp_Trans (
		TransId			BIGINT PRIMARY KEY
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
-- ------------------------------------------------------------------------------
INSERT INTO #BUMBData(BUDay,MBDay)
EXECUTE bodb02.dbo.Age_SelBalanceUpDay

SELECT	TOP(1)
		@BalanceUpDay	= BUDay
	,	@MoveBetsDay	= MBDay
FROM #BUMBData WITH(NOLOCK);

INSERT INTO #tmp_WCLeagues(LeagueId)
SELECT DISTINCT LeagueId
FROM dbo.league WITH(NOLOCK)
WHERE ProgramID = '2022' AND DisplayMode = 2;
	
INSERT INTO #tmp_PlatformDesktop(BetFrom)
SELECT b.BetFrom
FROM DBWH.bodb_account.dbo.tbl_Betfrom AS b WITH (NOLOCK)
WHERE b.platform2 = 'Desktop';

SET @Day60 = DATEADD(DAY,-60,@ReleasedDate)
SET @ScannedDate = @MoveBetsDay;

WHILE (@ScannedDate >= @BalanceUpDay)
BEGIN
	TRUNCATE TABLE #Tmp_Trans;
	TRUNCATE TABLE #tmpSPU_GroupBettingCustomer;
	TRUNCATE TABLE #tmp_match;
	TRUNCATE TABLE #tmpSPU_GroupBettingCustomer_updated;

	INSERT INTO #Tmp_Trans (TransId,Custid,Matchid,Bettype,StatusID,BetFrom,ScanDate,IsLicensee)
	SELECT 	bt.TransId
		,	bt.custid
		,	bt.matchid
		,	bt.bettype
		,	bt.statusID
		,	bt.BetFrom
		,	bt.transdate
		,	CASE WHEN dCust.custid IS NOT NULL THEN 1 ELSE 0 END
	FROM dbo.bettrans14 AS bt WITH(NOLOCK)
		LEFT JOIN dbo.Dep_CustSuper AS dCust WITH (NOLOCK) ON dCust.custid = bt.srecommend
	WHERE bt.winlostdate = @ScannedDate;

	DELETE FROM #Tmp_Trans WHERE IsLicensee = 0 OR ScanDate < @Day60;
	
	INSERT INTO #tmp_match (MatchId)
	SELECT DISTINCT tmp_trans.Matchid 
	FROM #Tmp_Trans AS tmp_trans
		INNER JOIN dbo.match14 AS m WITH (NOLOCK) ON m.matchid = tmp_trans.MatchId
		LEFT JOIN #Tmp_WCLeagues AS wc WITH(NOLOCK) ON m.leagueid = wc.LeagueId
	WHERE tmp_trans.Matchid <> 29 
		AND m.Sporttype < 100
		AND wc.LeagueId IS NULL;

	DELETE tmp_trans
	FROM #Tmp_Trans AS tmp_trans
		LEFT JOIN #tmp_match AS tmp_match ON tmp_match.MatchId = tmp_trans.MatchId
	WHERE tmp_trans.Matchid <> 29 AND tmp_match.MatchId IS NULL;

	SET @TotalTicket = (SELECT COUNT(1) FROM #Tmp_Trans);

	IF @TotalTicket = 0
	BEGIN
		SET @ScannedDate_message = CONCAT('Step 1, ', @BalanceUpDay, ', ', @ScannedDate);
		PRINT @ScannedDate_message;

		SET @ScannedDate = DATEADD(DAY,-@iday,@MoveBetsDay);
		SET @iday = @iday + 1;

		IF @ScannedDate < @BalanceUpDay
		BEGIN
			BREAK;
		END
		ELSE
		BEGIN
			CONTINUE;
		END;

	END;
		
	INSERT INTO #tmpSPU_GroupBettingCustomer (
			CustId
		,	ScanDate
		,	TicketCount
		,	RejectTicketCount
		,	DesktopTicketCount
		,	ParlayTicketCount
		,	IsInserted
	)
	SELECT DISTINCT tmp_trans.CustId
		,	tmp_trans.ScanDate
		,	0
		,	0
		,	0
		,	0
		, 	CASE WHEN tmp_trans.CustId IS NOT NULL AND gbc.CustId IS NULL THEN 1 ELSE 0 END AS 'IsInserted'
	FROM #Tmp_Trans AS tmp_trans
		LEFT JOIN dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK) ON gbc.CustId = tmp_trans.CustId AND gbc.ScanDate = tmp_trans.ScanDate
	WHERE tmp_trans.CustId IS NOT NULL;
	
	WITH cte_TicketCount_FromOrg AS 
	(
		SELECT DISTINCT bt.Custid
			,	bt.ScanDate
			,	COUNT(1) OVER (PARTITION BY bt.Custid,bt.ScanDate) AS 'TicketCount'
			,	SUM(CASE WHEN bt.StatusID = 101 THEN 1 ELSE 0 END) OVER (PARTITION BY bt.Custid,bt.ScanDate) AS 'RejectTicketCount'
			,	SUM(CASE WHEN b.BetFrom IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY bt.Custid,bt.ScanDate) AS 'DesktopTicketCount'		
			,	SUM(CASE WHEN bt.Bettype IN (29,38) THEN 1 ELSE 0 END) OVER (PARTITION BY bt.Custid,bt.ScanDate) AS 'ParlayTicketCount'		
		FROM #Tmp_Trans AS bt
			LEFT JOIN #Tmp_PlatformDesktop AS b WITH (NOLOCK) ON b.BetFrom = bt.BetFrom
	)
	UPDATE gbc WITH(UPDLOCK, ROWLOCK)
	SET		gbc.TicketCount = ct.TicketCount
		,	gbc.RejectTicketCount = ct.RejectTicketCount
		,	gbc.DesktopTicketCount = ct.DesktopTicketCount
		,	gbc.ParlayTicketCount = ct.ParlayTicketCount
	FROM #tmpSPU_GroupBettingCustomer AS gbc
		INNER JOIN cte_TicketCount_FromOrg AS ct WITH (NOLOCK) ON gbc.CustId = ct.CustId AND gbc.ScanDate = ct.ScanDate;

	INSERT INTO #tmpSPU_GroupBettingCustomer_updated (CustId, ScanDate, TicketCount, RejectTicketCount, DesktopTicketCount, ParlayTicketCount, IsInserted)
	SELECT gbc.CustId, gbc.ScanDate, gbc.TicketCount, gbc.RejectTicketCount, gbc.DesktopTicketCount, gbc.ParlayTicketCount, gbc.IsInserted
	FROM #tmpSPU_GroupBettingCustomer AS gbc;

	SET @ScannedDate_message = CONCAT('Step 2, ', @BalanceUpDay, ', ', @ScannedDate);
	PRINT @ScannedDate_message;

	SET @ScannedDate = DATEADD(DAY,-@iday,@MoveBetsDay);
	SET @iday = @iday + 1;

	SET @MaxRow = (SELECT MAX(ID) FROM #tmpSPU_GroupBettingCustomer_updated);
	SET @StartRow = 1;
	SET @StopRow = @Threshold;
	SET @Today = GETDATE();

	WHILE (1=1)
	BEGIN
		PRINT @StartRow;
		PRINT @StopRow;

		TRUNCATE TABLE #tmp_batch_updated;
	
		DELETE gbc
		OUTPUT deleted.CustId, deleted.ScanDate, deleted.TicketCount, deleted.RejectTicketCount, deleted.DesktopTicketCount, deleted.ParlayTicketCount, deleted.IsInserted
		INTO #tmp_batch_updated(CustId, ScanDate, TicketCount, RejectTicketCount, DesktopTicketCount, ParlayTicketCount, IsInserted)
		FROM #tmpSPU_GroupBettingCustomer_updated AS gbc
		WHERE gbc.ID BETWEEN @StartRow AND @StopRow;

		IF @@ROWCOUNT = 0
			BREAK;

		SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121);
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT;

		UPDATE gbc WITH(UPDLOCK, ROWLOCK)
		SET gbc.TicketCount = gbc.TicketCount + b.TicketCount
		,	gbc.RejectTicketCount = gbc.RejectTicketCount + b.RejectTicketCount
		,	gbc.DesktopTicketCount = gbc.DesktopTicketCount + b.DesktopTicketCount
		,	gbc.ParlayTicketCount = gbc.ParlayTicketCount + b.ParlayTicketCount
		,	gbc.LastCountTotalTicketDate = @Today
		FROM dbo.SPU_GroupBettingCustomer AS gbc
			INNER JOIN #tmp_batch_updated AS b ON gbc.CustId = b.CustId AND gbc.ScanDate = b.ScanDate
		WHERE b.IsInserted = 0;
	
		INSERT INTO dbo.SPU_GroupBettingCustomer (CustId, ScanDate, TicketCount, RejectTicketCount, DesktopTicketCount, ParlayTicketCount, GBTicketCount, LastCountTotalTicketDate)
		SELECT b.CustId, b.ScanDate, b.TicketCount, b.RejectTicketCount, b.DesktopTicketCount, b.ParlayTicketCount, 0, @Today
		FROM #tmp_batch_updated AS b
		WHERE b.IsInserted = 1;
	
		WAITFOR DELAY '00:00:0.100';

		SET @StartRow = @StopRow + 1;
		SET @StopRow = @StopRow + @Threshold;

		IF @StartRow > @MaxRow
			BREAK;
	END;

	IF @ScannedDate < @BalanceUpDay
		BREAK;
END;