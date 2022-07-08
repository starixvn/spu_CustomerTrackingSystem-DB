/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_UpdateTotalTicket]
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Caculate Group betting ticket
	DB	 : DBCTS.bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Scan ticket [Redmine ID: #169671]
		- 20220614@Harvey.Nguyen: Add rowlock in updating [Redmine ID: #169671]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_UpdateTotalTicket] @LastScannedTime = '2022-03-10 03:39:12.230'
*/
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#tmpScanningCust') IS NOT NULL
	DROP TABLE #tmpScanningCust;
	CREATE TABLE #tmpScanningCust(
		CustId		INT,
		ScanDate	DATE,
		CONSTRAINT PK_tmpScanningCust PRIMARY KEY (CustId,ScanDate)
	)

	INSERT INTO #tmpScanningCust
	SELECT DISTINCT CustId
		,CONVERT(DATE, getdate()) AS 'ScanDate'
	FROM dbo.SPU_GroupBettingCustomer

	INSERT INTO dbo.SPU_GroupBettingCustomer (
		CustId
		,ScanDate
		,GBTicketCount
		,TicketCount
		)
	SELECT sc.CustId
		,sc.ScanDate
		,0
		,0
	FROM #tmpScanningCust sc
	LEFT JOIN dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK) ON sc.CustId = gbc.CustId AND sc.ScanDate = gbc.ScanDate
	WHERE gbc.CustId IS NULL;

	;WITH count_ticket AS (
		SELECT bt.custid
			,gbc.ScanDate
			,COUNT(1) 'TicketCount'
		FROM dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK)
		INNER JOIN bettrans bt WITH (NOLOCK) ON gbc.CustId = bt.custid
			AND (
				bt.transdate >= CONVERT(DATETIME, gbc.ScanDate)
				AND bt.transdate < DATEADD(day, 1, CONVERT(DATETIME, gbc.ScanDate))
				)
		WHERE gbc.LastCountTotalTicketDate IS NULL
			OR gbc.LastCountTotalTicketDate BETWEEN gbc.ScanDate AND DATEADD(MINUTE, 1470, CONVERT(DATETIME,gbc.ScanDate))
		GROUP BY bt.custid
			,gbc.ScanDate
		)
	UPDATE gbc
	SET gbc.TicketCount = ct.TicketCount
		,gbc.LastCountTotalTicketDate = GETDATE()
	FROM dbo.SPU_GroupBettingCustomer AS gbc WITH(UPDLOCK, ROWLOCK)
	INNER JOIN count_ticket ct WITH (NOLOCK) ON gbc.CustId = ct.custid
		AND gbc.ScanDate = ct.ScanDate;

	-- Clear unused data
	DELETE FROM dbo.SPU_GroupBettingCustomer
	WHERE ScanDate < DATEADD(day,-5, GETDATE()) AND TicketCount = 0 AND GBTicketCount = 0;

END