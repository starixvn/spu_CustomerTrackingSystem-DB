/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_SyncDataGroupBettingTicket]
		@GBTicketXMLString	VARCHAR(MAX)
		,@RunningSequenceId	BIGINT
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Insert group betting ticket from DB061 -> DB062 %
	DB	 : DBCTS.bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Init sp 											[Redmine ID: #170160]
		- 20220505@Harvey.Nguyen: Insert GroupBetting ticket into history table		[Redmine ID: #169671]
		- 20220711@Harvey.Nguyen: Change solution to scan on each ticket			[Redmine ID: #169671]
		- 20220831@Harvey.Nguyen: Update for Scale out DB Trans						[Redmine ID: #176472]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_SyncDataGroupBettingTicket] 
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @GBTicketXML				XML
		,	@ArchivedDateTicketHistory	DATETIME = DATEADD(day, -7, GETDATE())
		,	@DailyMidnight				DATETIME
		,	@RunningDate				DATETIME
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

	DELETE FROM dbo.SPU_GroupBettingTicket_History
	WHERE TransDate <= @ArchivedDateTicketHistory

	INSERT INTO dbo.SPU_GroupBettingTicket_History (
		TransId
		,TransDate
		)
	SELECT tmp.TransId
		,tmp.TransDate
	FROM #TmpGroupBettingTicket AS tmp
		LEFT JOIN dbo.SPU_GroupBettingTicket_History AS his ON tmp.TransID = his.TransID
	WHERE his.TransID IS NULL;

	SELECT @RunningDate = transdate
	FROM dbo.bettrans WITH (NOLOCK)
	WHERE sequenceid = @RunningSequenceId;

	SET @DailyMidnight = DATEADD(MINUTE, 30, CONVERT(SMALLDATETIME, CONVERT(DATE, @RunningDate)));

	IF @RunningDate > @DailyMidnight
	BEGIN
		DELETE FROM dbo.SPU_GroupBettingTicket
		WHERE TransDate = CONVERT(DATE, DATEADD(DAY,-1,GETDATE()));
	END

	INSERT INTO dbo.SPU_GroupBettingTicket (
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

