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
		- 20220801@Harvey.Nguyen: Update coding convention					[Redmine ID: #169671]
		- 20230713@Victoria.Le: Add default for new columns					[Redmine ID: #189505]

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

	CREATE CLUSTERED INDEX PK_TmpPreGroupBettingTicket ON #PreGroupBettingTicket (CustId, TransDate);

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
	FROM #PreGroupBettingTicket AS pgbt WITH(UPDLOCK, ROWLOCK)
	INNER JOIN dbo.SPU_GroupBettingCustomer AS gbc WITH (NOLOCK) ON pgbt.CustId = gbc.CustId AND pgbt.TransDate = gbc.ScanDate ;

	INSERT INTO dbo.SPU_GroupBettingCustomer (
		CustId
		,GBTicketCount
		,ScanDate
		,LastModifiedDate
		,TicketCount
		,ParlayTicketCount
		,RejectTicketCount
		,DesktopTicketCount
		)
	SELECT CustId
		,COUNT(TransId)
		,TransDate
		,GETDATE()
		,0
		,0
		,0
		,0
	FROM #PreGroupBettingTicket
	WHERE IsUpdateCount = 0
	GROUP BY CustId, TransDate;

	UPDATE gbc
	SET gbc.GBTicketCount = TEMP.GBTicketCount
		,gbc.LastModifiedDate = GETDATE()
	FROM dbo.SPU_GroupBettingCustomer AS gbc WITH(UPDLOCK, ROWLOCK)
	INNER JOIN (
		SELECT CustId
			,TransDate
			,COUNT(TransId) 'GBTicketCount'
		FROM #PreGroupBettingTicket
		WHERE IsUpdateCount = 1
		GROUP BY CustId,TransDate
		) TEMP ON TEMP.CustId = gbc.CustId AND TEMP.TransDate = gbc.ScanDate;
END