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
		- 20230417@Casey.Huynh: Ignore Duplicate TransID 							[Redmine ID: #187030]
		- 20230626@Victoria.Le: Add new columns	RulesType,IsRule1[tag by %RFM],IsRule2[tag by %CC],IsRule3[tag by %Betfrom]
																			[Redmine ID: #189505]
		- 20230818@Victoria.Le: Add ROWLOCK with the delete statement [Redmine ID: #191955]
		- 20231011@Victoria.Le: Keep data 14 days instead of 7 days [Redmine ID: #195298]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_SyncDataGroupBettingTicket] 
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @GBTicketXML				XML
		,	@ArchivedDateTicketHistory	DATETIME = DATEADD(day, -14, GETDATE())
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
		,RuleId				TINYINT
		,IsViolateRFM		BIT
		,IsViolateCC		BIT
		,IsViolateBetFrom	BIT
	);

	INSERT INTO #TmpGroupBettingTicket (TransId, Custid, TransDate, RuleId, IsViolateRFM, IsViolateCC, IsViolateBetFrom)
	SELECT	T.C.value('./@TransId', 'BIGINT') AS TransId
		,	T.C.value('./@CustId', 'INT') AS CustId
		,	T.C.value('./@TransDate', 'DATE') AS TransDate
		,	T.C.value('./@RuleId', 'TINYINT') AS RuleId
		,	T.C.value('./@IsViolateRFM', 'BIT') AS IsViolateRFM
		,	T.C.value('./@IsViolateCC', 'BIT') AS IsViolateCC
		,	T.C.value('./@IsViolateBetFrom', 'BIT') AS IsViolateBetFrom
	FROM @GBTicketXML.nodes('//TWGroupBettingTicket') AS T(C)
	OPTION (OPTIMIZE FOR (@GBTicketXML = NULL));

	DELETE FROM dbo.SPU_GroupBettingTicket_History WITH (ROWLOCK)
	WHERE TransDate <= @ArchivedDateTicketHistory

	INSERT INTO dbo.SPU_GroupBettingTicket_History (
			TransId
		,	TransDate
		,	RulesType
		,	IsRule1
		,	IsRule2
		,	IsRule3
		)
	SELECT 	tmp.TransId
		,	tmp.TransDate
		,	gbr.RuleName
		,	tmp.IsViolateRFM
		,	tmp.IsViolateCC
		,	tmp.IsViolateBetFrom
	FROM #TmpGroupBettingTicket AS tmp
		INNER JOIN dbo.SPU_GroupBettingRule	AS gbr WITH(NOLOCK) ON tmp.RuleId = gbr.RuleId
		LEFT JOIN dbo.SPU_GroupBettingTicket_History AS his WITH(NOLOCK) ON tmp.TransID = his.TransID
	WHERE his.TransID IS NULL;

	SELECT @RunningDate = transdate
	FROM dbo.bettrans WITH (NOLOCK)
	WHERE sequenceid = @RunningSequenceId;

	SET @DailyMidnight = DATEADD(MINUTE, 30, CONVERT(SMALLDATETIME, CONVERT(DATE, @RunningDate)));

	IF @RunningDate > @DailyMidnight
	BEGIN
		DELETE FROM dbo.SPU_GroupBettingTicket WITH (ROWLOCK)
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

