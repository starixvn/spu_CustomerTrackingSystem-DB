/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20231026@Victoria.Le
	Task : TW Group Betting - Correct Data - Update value SPU_GroupBettingCustomer.GBTicketCount with ScanDate = '2023-10-09'
	DB:	DB062		
	
	Description: 

	Revisions:	
		- 20231026@Victoria.Le: 	Initial Writing [Redmine ID: #195298]
*/

USE [bodb02]

DECLARE	@ScanDate DATE = '2023-10-09'
	,	@StartRow INT = 1
	,	@StopRow INT 
	,	@MaxRow INT 
	,	@Threshold INT = 2000
	,	@debug_message VARCHAR(500)
;

IF OBJECT_ID('tempdb..#tmpSPU_GroupBetting_GBTicketCount') IS NOT NULL
	DROP TABLE #tmpSPU_GroupBetting_GBTicketCount;

CREATE TABLE #tmpSPU_GroupBetting_GBTicketCount (
		ID				INT IDENTITY (1,1)
	,	CustId			BIGINT PRIMARY KEY
	,	GBTicketCount	INT
);


IF OBJECT_ID('tempdb..#tmpSPU_GroupBettingCustomer') IS NOT NULL
	DROP TABLE #tmpSPU_GroupBettingCustomer;

CREATE TABLE #tmpSPU_GroupBettingCustomer (
		ID				INT IDENTITY (1,1)
	,	CustId			BIGINT PRIMARY KEY
	,	GBTicketCount	INT
);	

-- ------------------------------------------------------------------------------
INSERT INTO #tmpSPU_GroupBetting_GBTicketCount (CustId,GBTicketCount)
SELECT bt.custid, COUNT(1)
FROM DBSPARE.bodb02_20231009_cts.dbo.SPU_GroupBettingTicket_History AS hs WITH (NOLOCK)
INNER JOIN DBSPARE.bodb02_20231009_cts.dbo.bettrans AS bt WITH (NOLOCK) on bt.TransId = hs.TransId
WHERE hs.TransDate = @ScanDate
GROUP BY bt.custid
;

SET @MaxRow = (SELECT MAX(ID) FROM #tmpSPU_GroupBetting_GBTicketCount);
SET @StartRow = 1;
SET @StopRow = @Threshold;

WHILE (1=1)
BEGIN
	PRINT @StartRow;
	PRINT @StopRow;
	
	TRUNCATE TABLE #tmpSPU_GroupBettingCustomer;
	
	DELETE gbc
	OUTPUT deleted.CustId, deleted.GBTicketCount
	INTO #tmpSPU_GroupBettingCustomer(CustId, GBTicketCount)
	FROM #tmpSPU_GroupBetting_GBTicketCount AS gbc
	WHERE gbc.ID BETWEEN @StartRow AND @StopRow;
	
	IF @@ROWCOUNT = 0
		BREAK;
		
	SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121);
	RAISERROR (@debug_message, 0, 1) WITH NOWAIT;
	
	UPDATE gbc WITH(UPDLOCK, ROWLOCK)
	SET 	gbc.GBTicketCount = b.GBTicketCount
		,	gbc.LastModifiedDate = GETDATE()
	FROM dbo.SPU_GroupBettingCustomer AS gbc
		INNER JOIN #tmpSPU_GroupBettingCustomer AS b ON b.CustId = gbc.CustId 
	WHERE gbc.ScanDate = @ScanDate
	;
	
	WAITFOR DELAY '00:00:0.100';

	SET @StartRow = @StopRow + 1;
	SET @StopRow = @StopRow + @Threshold;

	IF @StartRow > @MaxRow
		BREAK;
	
END;

-- ------------------------------------------------------------------------------
DROP TABLE IF EXISTS #tmpSPU_GroupBetting_GBTicketCount;
DROP TABLE IF EXISTS #tmpSPU_GroupBettingCustomer;
