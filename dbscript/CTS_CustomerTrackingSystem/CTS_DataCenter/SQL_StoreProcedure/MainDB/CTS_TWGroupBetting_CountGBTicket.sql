/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_CountGBTicket]
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Caculate Group betting ticket
	DB	 : DBCTS.bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Scan ticket 								[Redmine ID: #169671]
		- 20220614@Harvey.Nguyen: Add rowlock in updating 					[Redmine ID: #169671]
		- 20220711@Harvey.Nguyen: Change solution to scan on each ticket	[Redmine ID: #169671]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_CountGBTicket]
*/
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#PreGroupBettingTicket') IS NOT NULL
	DROP TABLE #PreGroupBettingTicket;

	CREATE TABLE #PreGroupBettingTicket (
		CustId			INT		NOT NULL
		,TransId		BIGINT	NOT NULL
		,TransDate		DATE	NOT NULL
		,IsUpdateCount	BIT
		);

	INSERT INTO #PreGroupBettingTicket (
		CustId
		,TransId
		,TransDate
		,IsUpdateCount
		)
	SELECT CustId
		,TransId
		,TransDate
		,0
	FROM dbo.SPU_GroupBettingTicket WITH (NOLOCK);
	
	UPDATE pgbt
	SET pgbt.IsUpdateCount = 1
	FROM #PreGroupBettingTicket pgbt
	INNER JOIN dbo.SPU_GroupBettingCustomer gbc WITH (NOLOCK) ON pgbt.CustId = gbc.CustId AND pgbt.TransDate = gbc.ScanDate ;

	INSERT INTO dbo.SPU_GroupBettingCustomer (
		CustId
		,GBTicketCount
		,ScanDate
		,LastModifiedDate
		)
	SELECT CustId
		,COUNT(TransId)
		,TransDate
		,GETDATE()
	FROM #PreGroupBettingTicket
	WHERE IsUpdateCount = 0
	GROUP BY CustId, TransDate;

	UPDATE gbc
	SET gbc.GBTicketCount = TEMP.GBTicketCount
		,gbc.LastModifiedDate = GETDATE()
	FROM dbo.SPU_GroupBettingCustomer gbc WITH(UPDLOCK, ROWLOCK)
	INNER JOIN (
		SELECT CustId
			,TransDate
			,COUNT(TransId) 'GBTicketCount'
		FROM #PreGroupBettingTicket
		WHERE IsUpdateCount = 1
		GROUP BY CustId,TransDate
		) TEMP ON TEMP.CustId = gbc.CustId AND TEMP.TransDate = gbc.ScanDate;
END