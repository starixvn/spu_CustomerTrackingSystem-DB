CREATE PROCEDURE [dbo].[CTS_TWGroupBetting_CountGBTicket]
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Caculate Group betting ticket
	DB	 : bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Scan ticket [Redmine ID: #169671]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_CountGBTicket]
*/
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#PreGroupBettingTicket') IS NOT NULL
	DROP TABLE #PreGroupBettingTicket;

	CREATE TABLE #PreGroupBettingTicket (
		CustId INT NOT NULL
		,TransId BIGINT NOT NULL
		,IsUpdateCount BIT
		);

	INSERT INTO #PreGroupBettingTicket (
		CustId
		,TransId
		,IsUpdateCount
		)
	SELECT CustId
		,TransId
		,0
	FROM dbo.SPU_GroupBettingTicket WITH (NOLOCK);

	UPDATE pgbt
	SET pgbt.IsUpdateCount = 1
	FROM #PreGroupBettingTicket pgbt
	INNER JOIN dbo.SPU_GroupBettingCustomer gbc WITH (NOLOCK) ON pgbt.CustId = gbc.CustId;

	INSERT INTO SPU_GroupBettingCustomer (
		CustId
		,GBTicketCount
		,LastModifiedDate
		)
	SELECT CustId
		,COUNT(TransId)
		,GETDATE()
	FROM #PreGroupBettingTicket
	WHERE IsUpdateCount = 0
	GROUP BY CustId;

	UPDATE gbc
	SET gbc.GBTicketCount = gbc.GBTicketCount + TEMP.GBTicketCount
		,gbc.LastModifiedDate = GETDATE()
	FROM dbo.SPU_GroupBettingCustomer gbc WITH (NOLOCK)
	INNER JOIN (
		SELECT CustId
			,COUNT(TransId) 'GBTicketCount'
		FROM #PreGroupBettingTicket
		WHERE IsUpdateCount = 1
		GROUP BY CustId
		) TEMP ON TEMP.CustId = gbc.CustId;
END