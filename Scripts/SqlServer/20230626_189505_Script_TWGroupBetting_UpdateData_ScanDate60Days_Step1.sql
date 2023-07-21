/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/
/*
	Created:	20230626@Victoria.Le
	Task : TW Group Betting - Initial Data - Latest 60 days 
	DB:	DB062		
	
	Description: 

	Revisions:	
		- 20230626@Victoria.Le: 	Initial Writing - Update Data for ScanDate < '2023-07-12' AND ScanDate >  DATEADD(DAY,-60,'2023-07-12')
									[Redmine ID: #189505]
		- 20230713@Victoria.Le: 	Get latest 61 days - Change ReleasedDate = 2023-07-13
									[Redmine ID: #189505]
*/

USE [bodb02]

DECLARE	@ReleasedDate DATE = '2023-07-13'
	,	@Day60 SMALLDATETIME
	,	@ScannedDate SMALLDATETIME
	,	@StartRow INT = 1
	,	@StopRow INT 
	,	@MaxRow INT 
	,	@Threshold INT = 5000 
	,	@iday INT = 1
	,	@TotalCount_Updated INT = 0
	,	@debug_message VARCHAR(500)
	,	@ScannedDate_message VARCHAR(500)
;

IF OBJECT_ID('tempdb..#tmpSPU_GroupBettingCustomer') IS NOT NULL
	DROP TABLE #tmpSPU_GroupBettingCustomer;

CREATE TABLE #tmpSPU_GroupBettingCustomer (
		ID							INT IDENTITY (1,1)
	,	CustId						INT 	
	,	ScanDate					DATE
	,	PRIMARY KEY (CustId,ScanDate)
);	

IF OBJECT_ID('tempdb..#tmp_batch_updated') IS NOT NULL
	DROP TABLE #tmp_batch_updated;

CREATE TABLE #tmp_batch_updated (
		CustId						INT 	
	,	ScanDate					DATE
	,	PRIMARY KEY (CustId,ScanDate)
);	

-------------------------------------------------------------------------

SET @Day60 = DATEADD(DAY,-61,@ReleasedDate)
SET @ScannedDate = @ReleasedDate;

WHILE (@ScannedDate > @Day60)
BEGIN
	TRUNCATE TABLE #tmpSPU_GroupBettingCustomer;

	INSERT INTO #tmpSPU_GroupBettingCustomer (CustId,ScanDate)
	SELECT gbc.CustId,gbc.ScanDate
	FROM dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK)
	WHERE gbc.ScanDate =  @ScannedDate;

	SET @TotalCount_Updated = @@ROWCOUNT;

	IF (@TotalCount_Updated = 0)
	BEGIN
		SET @ScannedDate_message = CONCAT('Step 1, ',@Day60, ', ', @ScannedDate);
		PRINT @ScannedDate_message;

		SET @ScannedDate = DATEADD(DAY,-@iday,@ReleasedDate);
		SET @iday = @iday + 1;

		IF (@ScannedDate <= @Day60)
		BEGIN
			BREAK;
		END
		ELSE
		BEGIN
			CONTINUE;
		END;
		
	END;

	SET @ScannedDate_message = CONCAT('Step 2, ', @Day60, ', ', @ScannedDate);
	PRINT @ScannedDate_message;

	SET @ScannedDate = DATEADD(DAY,-@iday,@ReleasedDate);
	SET @iday = @iday + 1;

	SET @MaxRow = (SELECT MAX(ID) FROM #tmpSPU_GroupBettingCustomer);
	SET @StartRow = 1;
	SET @StopRow = @Threshold;

	WHILE (1=1)
	BEGIN
		PRINT @StartRow;
		PRINT @StopRow;

		TRUNCATE TABLE #tmp_batch_updated;

		DELETE gbc
		OUTPUT deleted.CustId, deleted.ScanDate
		INTO #tmp_batch_updated(CustId, ScanDate)
		FROM #tmpSPU_GroupBettingCustomer AS gbc
		WHERE gbc.ID BETWEEN @StartRow AND @StopRow;

		IF @@ROWCOUNT = 0
			BREAK;

		UPDATE gbc WITH(UPDLOCK, ROWLOCK)
		SET gbc.TicketCount = 0
		,	gbc.RejectTicketCount = 0
		,	gbc.DesktopTicketCount = 0
		,	gbc.ParlayTicketCount = 0
		,	gbc.LastCountTotalTicketDate = NULL
		FROM dbo.SPU_GroupBettingCustomer AS gbc
			INNER JOIN #tmp_batch_updated AS b ON gbc.CustId = b.CustId AND gbc.ScanDate = b.ScanDate;

		WAITFOR DELAY '00:00:0.100';

		SET @StartRow = @StopRow + 1;
		SET @StopRow = @StopRow + @Threshold;

		IF @StartRow > @MaxRow
			BREAK;
	END;

	IF @ScannedDate <= @Day60
		BREAK;
END;
