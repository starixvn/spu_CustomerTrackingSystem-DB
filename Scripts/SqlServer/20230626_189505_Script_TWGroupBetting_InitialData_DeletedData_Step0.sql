/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20230714@Victoria.Le
	Task : TW Group Betting - Initial Data - Get deleted data from 2023-05-13 and to 2023-07-11 
	DB:	DB062		
	
	Description: 

	Revisions:	
		- 20230714@Victoria.Le: 	Initial Writing [Redmine ID: #189505]
*/

USE [bodb02]

DECLARE @StartDate DATE = '2023-05-13'
	,	@StopDate DATE = '2023-07-10'
	,	@StartRow INT = 1
	,	@StopRow INT 
	,	@MaxRow INT 
	,	@Threshold INT = 2000 
	,	@debug_message VARCHAR(500)
;

IF OBJECT_ID('tempdb..#tmpSPU_GroupBettingCustomer') IS NOT NULL
	DROP TABLE #tmpSPU_GroupBettingCustomer;

CREATE TABLE #tmpSPU_GroupBettingCustomer (
		ID							INT IDENTITY (1,1)
	,	CustId						INT 	
	,	ScanDate					DATE
	,	GBTicketCount				INT	
	,	TicketCount					INT 
	,	LastModifiedDate			DATETIME
	,	LastCountTotalTicketDate	DATETIME
	,	RejectTicketCount			INT
	,	DesktopTicketCount			INT
	,	ParlayTicketCount			INT
	,	IsInserted					BIT DEFAULT 0
	,	PRIMARY KEY (CustId,ScanDate)
);

IF OBJECT_ID('tempdb..#tmp_batch') IS NOT NULL
	DROP TABLE #tmp_batch;

CREATE TABLE #tmp_batch (
		ID							INT IDENTITY (1,1)
	,	CustId						INT 		
	,	ScanDate					DATE
	,	GBTicketCount				INT	
	,	TicketCount					INT 
	,	LastModifiedDate			DATETIME
	,	LastCountTotalTicketDate	DATETIME
	,	RejectTicketCount			INT
	,	DesktopTicketCount			INT
	,	ParlayTicketCount			INT
	,	IsInserted					BIT
	,	PRIMARY KEY (CustId,ScanDate)
);	

WHILE (@StartDate <= @StopDate)
BEGIN
	PRINT @StartDate;
	
	TRUNCATE TABLE #tmpSPU_GroupBettingCustomer;
	
	INSERT INTO #tmpSPU_GroupBettingCustomer
	(
			CustId						 	
		,	ScanDate					
		,	GBTicketCount					
		,	TicketCount					 
		,	LastModifiedDate			
		,	LastCountTotalTicketDate	
		,	RejectTicketCount			
		,	DesktopTicketCount			
		,	ParlayTicketCount
		,	IsInserted
	)
	SELECT 	gbc.CustId						 	
		,	gbc.ScanDate					
		,	ISNULL(gbc.GBTicketCount,0)					
		,	0
		,	gbc.LastModifiedDate			
		,	GETDATE()
		,	0
		,	0
		,	0
		,	CASE WHEN gbc_main.CustId IS NULL THEN 1 ELSE 0 END
	FROM DBSPARE.db062_bodb02_20230711.dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK)
		LEFT JOIN dbo.SPU_GroupBettingCustomer AS gbc_main WITH (NOLOCK) ON gbc_main.CustId = gbc.CustId AND gbc_main.ScanDate = gbc.ScanDate
	WHERE gbc.ScanDate = @StartDate;
	
	SET @StartDate = DATEADD(DAY,1,@StartDate);
	
	SET @MaxRow = (SELECT MAX(ID) FROM #tmpSPU_GroupBettingCustomer);
	SET @StartRow = 1;
	SET @StopRow = @Threshold;
	
	
	WHILE (1=1)
	BEGIN
		PRINT @StartRow;
		PRINT @StopRow;

		TRUNCATE TABLE #tmp_batch;
		
		DELETE gbc
		OUTPUT deleted.CustId, deleted.ScanDate, deleted.GBTicketCount, deleted.TicketCount, deleted.LastModifiedDate, deleted.LastCountTotalTicketDate, deleted.RejectTicketCount, deleted.DesktopTicketCount, deleted.ParlayTicketCount, deleted.IsInserted
		INTO #tmp_batch(CustId, ScanDate, GBTicketCount, TicketCount, LastModifiedDate, LastCountTotalTicketDate, RejectTicketCount, DesktopTicketCount, ParlayTicketCount, IsInserted)
		FROM #tmpSPU_GroupBettingCustomer AS gbc
		WHERE gbc.ID BETWEEN @StartRow AND @StopRow;

		IF @@ROWCOUNT = 0
			BREAK;
			
		SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121);
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT;

		UPDATE gbc WITH(UPDLOCK, ROWLOCK)
		SET gbc.GBTicketCount = b.GBTicketCount
		,	gbc.TicketCount = b.TicketCount
		,	gbc.LastModifiedDate = b.LastModifiedDate
		,	gbc.LastCountTotalTicketDate = b.LastCountTotalTicketDate
		,	gbc.RejectTicketCount = b.RejectTicketCount
		,	gbc.DesktopTicketCount = b.DesktopTicketCount
		,	gbc.ParlayTicketCount = b.ParlayTicketCount
		FROM dbo.SPU_GroupBettingCustomer AS gbc
			INNER JOIN #tmp_batch AS b ON gbc.CustId = b.CustId AND gbc.ScanDate = b.ScanDate
		WHERE b.IsInserted = 0;
	
		INSERT INTO dbo.SPU_GroupBettingCustomer (CustId, ScanDate, GBTicketCount, TicketCount, LastModifiedDate, LastCountTotalTicketDate, RejectTicketCount, DesktopTicketCount, ParlayTicketCount)
		SELECT b.CustId, b.ScanDate, b.GBTicketCount, b.TicketCount, b.LastModifiedDate, b.LastCountTotalTicketDate, b.RejectTicketCount, b.DesktopTicketCount, b.ParlayTicketCount
		FROM #tmp_batch AS b
		WHERE b.IsInserted = 1;
	
		WAITFOR DELAY '00:00:0.100';

		SET @StartRow = @StopRow + 1;
		SET @StopRow = @StopRow + @Threshold;

		IF @StartRow > @MaxRow
			BREAK;
	END;
	
END;