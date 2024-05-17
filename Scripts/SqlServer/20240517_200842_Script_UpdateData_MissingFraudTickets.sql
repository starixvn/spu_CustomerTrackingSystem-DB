/*<info serverAlias="DBCTS-WASAVerse" executers="" viewers="" isFunction="0"></info>*/
/*
	Creator:	20240517@Victoria.Le
	Task:		Update data - Missing fraud tickets(20240516) and update param to clean data
	Server:		DB062
	
	Revisions:
			- 20240517@Victoria.Le:  Initial Writing [Redmine ID: #200842]	
*/


USE	WASAVerse;
GO

/*Param to clean data*/
DECLARE 	@CleanTicketFlag_ParameterID		SMALLINT = 7
		,	@CleanTicketFlag_Value				SMALLINT
		,	@CleanTicketFlag_WAITING			SMALLINT = -1
		,	@CleanTicketFlag_FINISH				SMALLINT = 2
		;
		
UPDATE 	dbo.SystemParameter WITH(UPDLOCK, ROWLOCK)
SET 	ParameterValue = @CleanTicketFlag_FINISH
WHERE 	ParameterID = @CleanTicketFlag_ParameterID
	AND ParameterValue = @CleanTicketFlag_WAITING;


/* Missing fraud tickets(20240516)*/
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

-- 20240516
INSERT INTO #tmpTWGroupBettingCustomer_updated (CustId,ScanDate,GBTicketCount) 
SELECT b.custid, h.TransDate, COUNT(1)
FROM dbo.TWGroupBettingTicket_History AS h WITH (NOLOCK)
	INNER JOIN bodb02.dbo.bettrans AS b WITH (NOLOCK) ON b.TransId = h.TransId 
WHERE h.TransDate = '2024-05-16'
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