DECLARE @LastScannedTime DATETIME = '2022-03-10 03:39:12.230';

IF OBJECT_ID('tempdb..#PreGroupBettingCustomer') IS NOT NULL
	DROP TABLE #PreGroupBettingCustomer;

CREATE TABLE #PreGroupBettingCustomer (
	CustId INT
	,TicketCount INT
	,IsUpdateCount BIT
	)

INSERT INTO #PreGroupBettingCustomer (
	CustId
	,TicketCount
	,IsUpdateCount
	)

SELECT bt.custid
	,COUNT(bt.transid) 'NoOfTicket'
	,0
FROM bettrans bt WITH (NOLOCK)
INNER JOIN SPU_GroupBettingCustomer gbc WITH (NOLOCK) ON bt.custid = gbc.CustId
WHERE gbc.LastModifiedDate > @LastScannedTime
GROUP BY bt.custid

UPDATE gbc
SET gbc.TicketCount = gbc.TicketCount + pgbc.TicketCount
FROM SPU_GroupBettingCustomer gbc
INNER JOIN #PreGroupBettingCustomer pgbc ON gbc.CustId = pgbc.CustId
WHERE gbc.TicketCount IS NOT NULL

UPDATE gbc
SET gbc.TicketCount = pgbc.TicketCount
FROM SPU_GroupBettingCustomer gbc
INNER JOIN #PreGroupBettingCustomer pgbc ON gbc.CustId = pgbc.CustId
WHERE gbc.TicketCount IS NULL