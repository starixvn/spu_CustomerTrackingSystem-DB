/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
CREATE OR ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_SyncDataGroupBettingTicket]
		@GBTicketXMLString	VARCHAR(MAX)
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Insert group betting ticket from DB061 -> DB062 %
	DB	 : DBCTS.bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Init sp [Redmine ID: #170160]
		- 20220505@Harvey.Nguyen: Insert GroupBetting ticket into history table

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_SyncDataGroupBettingTicket] 
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @GBTicketXML	XML
		,	@ArchivedDate	DATETIME = DATEADD(day, -3, GETDATE())
		;
	SET @GBTicketXML = CONVERT(XML,@GBTicketXMLString);

	IF OBJECT_ID('tempdb..#TmpGroupBettingTicket') IS NOT NULL
		DROP TABLE #TmpGroupBettingTicket;

	CREATE TABLE #TmpGroupBettingTicket (
		TransId		BIGINT	PRIMARY KEY
		,CustId		INT
		,TransDate	DATE
	);

	INSERT INTO #TmpGroupBettingTicket (TransId, Custid, TransDate)
	SELECT	T.C.value('./@TransId', 'BIGINT') AS TransId
		,	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@TransDate', 'DATE') AS TransDate
	FROM @GBTicketXML.nodes('//TWGroupBettingTicket') AS T(C)
	OPTION (OPTIMIZE FOR (@GBTicketXML = NULL));

	DELETE FROM SPU_GroupBettingTicket_History
	WHERE TransDate <= @ArchivedDate

	INSERT INTO SPU_GroupBettingTicket_History (
		TransId
		,TransDate
		)
	SELECT TransId
		,TransDate
	FROM #TmpGroupBettingTicket

	DELETE FROM SPU_GroupBettingTicket;

	INSERT INTO SPU_GroupBettingTicket (
		CustId
		,TransId
		,TransDate
		)
	SELECT Custid
		,TransId
		,TransDate
	FROM #TmpGroupBettingTicket

	DROP TABLE #TmpGroupBettingTicket

END

