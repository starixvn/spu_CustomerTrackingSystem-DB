/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_UpdateTotalTicket]
	@LastScannedTime		DATETIME,
	@LastestScannedTime		DATETIME	OUTPUT
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Caculate Group betting ticket
	DB	 : bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Scan ticket [Redmine ID: #169671]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_UpdateTotalTicket] @LastScannedTime = '2022-03-10 03:39:12.230'
*/
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#PreGroupBettingCustomer') IS NOT NULL
		DROP TABLE #PreGroupBettingCustomer;

	CREATE TABLE #PreGroupBettingCustomer (
		CustId INT
		,TicketCount INT
		,IsUpdateCount BIT
		);

	INSERT INTO #PreGroupBettingCustomer (
		CustId
		,TicketCount
		,IsUpdateCount
		)
	SELECT bt.custid
		,COUNT(bt.transid) 'NoOfTicket'
		,0
	FROM bettrans bt WITH (NOLOCK)
	INNER JOIN SPU_GroupBettingCustomer AS gbc WITH (NOLOCK) ON bt.custid = gbc.CustId
	WHERE gbc.LastModifiedDate > @LastScannedTime
	GROUP BY bt.custid;

	SELECT @LastestScannedTime = MAX(gbc.LastModifiedDate)
	FROM #PreGroupBettingCustomer AS pgbc WITH (NOLOCK)
		INNER JOIN SPU_GroupBettingCustomer AS gbc WITH (NOLOCK) ON pgbc.CustId = gbc.CustId

	UPDATE gbc
	SET gbc.TicketCount = gbc.TicketCount + pgbc.TicketCount
	FROM SPU_GroupBettingCustomer AS gbc WITH (NOLOCK)
	INNER JOIN #PreGroupBettingCustomer AS pgbc ON gbc.CustId = pgbc.CustId
	WHERE gbc.TicketCount IS NOT NULL;

	UPDATE gbc
	SET gbc.TicketCount = pgbc.TicketCount
	FROM SPU_GroupBettingCustomer AS gbc WITH (NOLOCK)
	INNER JOIN #PreGroupBettingCustomer AS pgbc ON gbc.CustId = pgbc.CustId
	WHERE gbc.TicketCount IS NULL;
END