/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
	Creator:	20240701@John.Ngo
	Task:		Update data - Missing fraud tickets(20240628,20240629)
	Server:		DB062
	
	Revisions:
			- 20240701@John.Ngo: GBTicketCount is being updated latency because schedule of service ScanTicket [Redmine ID: #207291]	
*/


USE	WASAVerse;
GO

/* Missing fraud tickets(20240628,20240629)*/
IF OBJECT_ID('tempdb..#tmpTWGroupBettingCustomer_updated') IS NOT NULL
BEGIN
	DROP TABLE	#tmpTWGroupBettingCustomer_updated;
END;

CREATE TABLE #tmpTWGroupBettingCustomer_updated (
		[CustId] [int] NOT NULL
	,	[GBTicketCount] [int] NULL
	,	[ScanDate] [date] NOT NULL
	,	PRIMARY KEY (CustId,ScanDate)
);

-- 20240628,20240629
INSERT INTO #tmpTWGroupBettingCustomer_updated (CustId,ScanDate,GBTicketCount) 
SELECT b.custid, h.TransDate, COUNT(1)
FROM dbo.TWGroupBettingTicket_History AS h WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettrans AS b WITH (NOLOCK) ON b.TransId = h.TransId 
WHERE h.TransDate IN ('2024-06-28','2024-06-29')
GROUP BY b.custid, h.TransDate
;

UPDATE gbc
SET 	gbc.GBTicketCount 		= tmp.GBTicketCount
	, 	gbc.LastModifiedDate  	= GETDATE()
FROM dbo.TWGroupBettingCustomer AS gbc WITH(UPDLOCK, ROWLOCK)
	INNER JOIN #tmpTWGroupBettingCustomer_updated AS tmp WITH (NOLOCK) ON tmp.CustId = gbc.CustId AND tmp.ScanDate = gbc.ScanDate
WHERE gbc.GBTicketCount <> tmp.GBTicketCount
;

DROP TABLE	#tmpTWGroupBettingCustomer_updated;