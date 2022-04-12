/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[CTS_TWGroupBetting_SyncDataGroupBettingTicket]
		@GBTicketXML	XML
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Insert group betting ticket from DB061 -> DB062 %
	DB	 : DBCTS.bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Init sp [Redmine ID: #170160]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_SyncDataGroupBettingTicket] 
*/
BEGIN
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#TmpGroupBettingTicket') IS NOT NULL
		DROP TABLE #TmpGroupBettingTicket;

	CREATE TABLE #TmpGroupBettingTicket (
		TransId		BIGINT	PRIMARY KEY
		,CustId		INT
		,TransDate	DATE
	);

	INSERT INTO #TmpGroupBettingTicket (Transid, Custid, TransDate)
	SELECT	T.C.value('./@Transid', 'BIGINT') AS Transid
		,	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@TransDate', 'DATE') AS TransDate
	FROM @GBTicketXML.nodes('//TWGroupBettingTicket') AS T(C)
	OPTION (OPTIMIZE FOR (@GBTicketXML = NULL));

	DELETE FROM SPU_GroupBettingTicket;

	INSERT INTO SPU_GroupBettingTicket (
		CustId
		,TransId
		,TransDate
		)
	SELECT Custid
		,Transid
		,TransDate
	FROM #TmpGroupBettingTicket

	DROP TABLE #TmpGroupBettingTicket

END