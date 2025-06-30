/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
	Creator:	20250626@John.Ngo
	Task:		Update data - Missing fraud tickets(20250623)
	Server:		DB062
	
	Revisions:
			- 20250626@John.Ngo: GBTicketCount is being updated latency because schedule of service ScanTicket [Redmine ID: #207291]	
*/


USE	WASAVerse;
GO

/* Missing fraud tickets(20250623)*/
IF OBJECT_ID('tempdb..#tmpTWGroupBettingCustomer_updated') IS NOT NULL
BEGIN
	DROP TABLE	#tmpTWGroupBettingCustomer_updated;
END;

CREATE TABLE #tmpTWGroupBettingCustomer_updated (
		[CustId] [int] NOT NULL
	,	[GBTicketCount] [int] NULL
	,	[ScanDate] [date] NOT NULL
	,	PRIMARY KEY (CustId,ScanDate)
);

-- 20250623
INSERT INTO #tmpTWGroupBettingCustomer_updated (CustId,ScanDate,GBTicketCount) 
SELECT b.custid, h.TransDate, COUNT(1)
FROM dbo.TWGroupBettingTicket_History AS h WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettrans AS b WITH (NOLOCK) ON b.TransId = h.TransId 
WHERE h.TransDate IN ('2025-06-23')
GROUP BY b.custid, h.TransDate
;

-- Update old cust
UPDATE gbc
SET 	gbc.GBTicketCount 		= tmp.GBTicketCount
	, 	gbc.LastModifiedDate  	= GETDATE()
FROM dbo.TWGroupBettingCustomer AS gbc WITH(UPDLOCK, ROWLOCK)
	INNER JOIN #tmpTWGroupBettingCustomer_updated AS tmp WITH (NOLOCK) ON tmp.CustId = gbc.CustId AND tmp.ScanDate = gbc.ScanDate
WHERE gbc.GBTicketCount <> tmp.GBTicketCount -- AND gbc.CustId IS NOT NULL
;

-- Insert new cust
IF EXISTS (SELECT 1 FROM #tmpTWGroupBettingCustomer_updated AS tmp_up
			  LEFT JOIN dbo.TWGroupBettingCustomer AS gbc WITH (NOLOCK) ON gbc.CustId = tmp_up.CustId AND gbc.ScanDate = tmp_up.ScanDate
		   WHERE gbc.CustId IS NULL)
	BEGIN
		IF OBJECT_ID('tempdb..#tmp_custid') IS NOT NULL
			DROP TABLE #tmp_custid;

		CREATE TABLE #tmp_custid (
				[CustId]	[int]	NOT NULL
			,	ScanDate	[date]	NOT NULL
		);	

		INSERT INTO #tmp_custid (
				CustId
			,	ScanDate
		)
		SELECT DISTINCT tmp_up.CustId
			,	tmp_up.ScanDate
		FROM #tmpTWGroupBettingCustomer_updated AS tmp_up
			LEFT JOIN dbo.TWGroupBettingCustomer AS gbc WITH (NOLOCK) ON gbc.CustId = tmp_up.CustId AND gbc.ScanDate = tmp_up.ScanDate
		WHERE gbc.CustId IS NULL;

		INSERT INTO dbo.TWGroupBettingCustomer (
				CustId
			,	ScanDate
			,	GBTicketCount
			,	TicketCount
			,	RejectTicketCount
			,	DesktopTicketCount
			,	ParlayTicketCount
		)
		SELECT DISTINCT tmp_c.CustId
			,	tmp_c.ScanDate
			,	0
			,	0
			,	0
			,	0
			,	0
		FROM #tmp_custid AS tmp_c;

		IF OBJECT_ID('tempdb..#tmp_PlatformDesktop') IS NOT NULL
			DROP TABLE #tmp_PlatformDesktop;

		CREATE TABLE #tmp_PlatformDesktop (
				BetFrom		VARCHAR(5) PRIMARY KEY
		);

		INSERT INTO #tmp_PlatformDesktop(BetFrom)
		SELECT b.BetFrom
		FROM DBWH.bodb_account.dbo.tbl_Betfrom AS b WITH (NOLOCK)
		WHERE b.platform2 = 'Desktop';

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
			,	IsGBTicket		TINYINT 
		);

		INSERT INTO #Tmp_Trans (TransId,Custid,Matchid,Bettype,StatusID,BetFrom,ScanDate,IsGBTicket)
		SELECT 	bt.TransId
			,	bt.custid
			,	bt.matchid
			,	bt.bettype
			,	bt.statusID
			,	bt.BetFrom
			,	bt.transdate
			,	CASE WHEN h.TransId IS NOT NULL THEN 1 ELSE 0 END
		FROM dbo.TWGroupBettingTicket_History AS h WITH (NOLOCK)
			INNER JOIN bodb02.dbo.bettrans AS bt WITH (NOLOCK) ON bt.TransId = h.TransId
			INNER JOIN #tmp_custid AS c WITH (NOLOCK) ON bt.custid = c.custid
		WHERE h.TransDate IN ('2025-06-23')
		;

		WITH cte_TicketCount_FromOrg AS 
		(
			SELECT DISTINCT bt.Custid
				,	bt.ScanDate
				,	COUNT(1) OVER (PARTITION BY bt.Custid,bt.ScanDate) AS 'TicketCount'
				,	SUM(CASE WHEN bt.StatusID = 101 THEN 1 ELSE 0 END) OVER (PARTITION BY bt.Custid,bt.ScanDate) AS 'RejectTicketCount'
				,	SUM(CASE WHEN b.BetFrom IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY bt.Custid,bt.ScanDate) AS 'DesktopTicketCount'
				,	SUM(CASE WHEN bt.Bettype IN (29,38) THEN 1 ELSE 0 END) OVER (PARTITION BY bt.Custid,bt.ScanDate) AS 'ParlayTicketCount'	
				,	SUM(bt.IsGBTicket) OVER (PARTITION BY bt.Custid,bt.ScanDate) AS 'GBTicketCount'
			FROM #Tmp_Trans AS bt
				LEFT JOIN #Tmp_PlatformDesktop AS b WITH (NOLOCK) ON b.BetFrom = bt.BetFrom
		)
		UPDATE gbc WITH(UPDLOCK, ROWLOCK)
		SET		gbc.TicketCount = ct.TicketCount
			,	gbc.RejectTicketCount = ct.RejectTicketCount
			,	gbc.DesktopTicketCount = ct.DesktopTicketCount
			,	gbc.ParlayTicketCount = ct.ParlayTicketCount
			,	gbc.GBTicketCount = ct.GBTicketCount
		FROM dbo.TWGroupBettingCustomer AS gbc
			INNER JOIN cte_TicketCount_FromOrg AS ct WITH (NOLOCK) ON gbc.CustId = ct.CustId AND gbc.ScanDate = ct.ScanDate
		;
	
	DROP TABLE	#Tmp_Trans;
	DROP TABLE	#tmp_PlatformDesktop;
	DROP TABLE	#tmp_custid;

END;

DROP TABLE	#tmpTWGroupBettingCustomer_updated;