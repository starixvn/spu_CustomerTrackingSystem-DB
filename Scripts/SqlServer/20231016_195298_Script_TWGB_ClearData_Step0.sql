/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20231016@Victoria.Le
	Task : TW Group Betting - Delete data with ScanDate = 03/10/2023 & 09/10/2023
	DB:	DB062		
	
	Description: 

	Revisions:	
		- 20231016@Victoria.Le: 	Initial Writing [Redmine ID: #195298]
*/

USE [bodb02]

DECLARE	@EndDate SMALLDATETIME = '2023-10-03'
	,	@ReleasedDate SMALLDATETIME = '2023-10-10'
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
	,	PRIMARY KEY (CustId,ScanDate)
);	

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
)
SELECT 	gbc.CustId						 	
	,	gbc.ScanDate					
	,	gbc.GBTicketCount				
	,	gbc.TicketCount
	,	gbc.LastModifiedDate			
	,	gbc.LastCountTotalTicketDate
	,	gbc.RejectTicketCount
	,	gbc.DesktopTicketCount
	,	gbc.ParlayTicketCount
FROM dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK)
WHERE gbc.ScanDate >= @EndDate
	AND gbc.ScanDate < @ReleasedDate;

SET @MaxRow = (SELECT MAX(ID) FROM #tmpSPU_GroupBettingCustomer);
SET @StartRow = 1;
SET @StopRow = @Threshold;

WHILE (1=1)
BEGIN
	PRINT @StartRow;
	PRINT @StopRow;

	TRUNCATE TABLE #tmp_batch;
	
	DELETE gbc
	OUTPUT deleted.CustId, deleted.ScanDate, deleted.GBTicketCount, deleted.TicketCount, deleted.LastModifiedDate, deleted.LastCountTotalTicketDate, deleted.RejectTicketCount, deleted.DesktopTicketCount, deleted.ParlayTicketCount
	INTO #tmp_batch(CustId, ScanDate, GBTicketCount, TicketCount, LastModifiedDate, LastCountTotalTicketDate, RejectTicketCount, DesktopTicketCount, ParlayTicketCount)
	FROM #tmpSPU_GroupBettingCustomer AS gbc
	WHERE gbc.ID BETWEEN @StartRow AND @StopRow;

	IF @@ROWCOUNT = 0
		BREAK;
		
	SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121);
	RAISERROR (@debug_message, 0, 1) WITH NOWAIT;
	
	DELETE gbc 
	FROM dbo.SPU_GroupBettingCustomer AS gbc WITH(ROWLOCK)
		INNER JOIN #tmp_batch AS b ON b.CustId = gbc.CustId AND b.ScanDate = gbc.ScanDate
	;
	
	WAITFOR DELAY '00:00:0.100';

	SET @StartRow = @StopRow + 1;
	SET @StopRow = @StopRow + @Threshold;

	IF @StartRow > @MaxRow
		BREAK;
END;