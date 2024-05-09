/*<info serverAlias="DBCTS-WASAVerse" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_SyncDataGroupBettingTicket]
			@GBTicketXMLString	VARCHAR(MAX)
		,	@RunningSequenceId	BIGINT
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Insert group betting ticket from DB061 -> DB062 %
	DB	 : DBCTS.WASAVerse

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
		- 20231024@John.Ngo:	[CTS] - Customer Classification - TW GB - Resolve Deadlock Problems [Redmine ID: #195866]
		- 20240130@Victoria.Le:	Change tables - TWGB Migrate data from bodb02 to WASAVerse [Redmine ID: #191955]
		- 20240509@Victoria.Le: Incorrect logic to clean up data yesterday of table TWGroupBettingTicket [Redmine ID: #204731]

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
	
	IF EXISTS (SELECT (1) FROM dbo.TWGroupBettingTicket_History gbh WITH (NOLOCK) 
			   WHERE gbh.TransDate <= @ArchivedDateTicketHistory)
	BEGIN
		WHILE(1 = 1)
		BEGIN
			DELETE TOP(5000) gbh
			FROM dbo.TWGroupBettingTicket_History gbh WITH(ROWLOCK)
			WHERE gbh.TransDate <= @ArchivedDateTicketHistory
			
			IF (@@ROWCOUNT = 0)
			BEGIN
				BREAK;
			END;
			WAITFOR DELAY '00:00:0.100';
		END;
	END;
	
	INSERT INTO dbo.TWGroupBettingTicket_History (
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
		INNER JOIN dbo.TWGroupBettingRule	AS gbr WITH(NOLOCK) ON tmp.RuleId = gbr.RuleId
		LEFT JOIN dbo.TWGroupBettingTicket_History AS his WITH(NOLOCK) ON tmp.TransID = his.TransID
	WHERE his.TransID IS NULL;

	SELECT @RunningDate = transdate
	FROM bodb02.dbo.bettrans WITH (NOLOCK)
	WHERE sequenceid = @RunningSequenceId;

	SET @DailyMidnight = DATEADD(MINUTE, 30, CONVERT(SMALLDATETIME, CONVERT(DATE, @RunningDate)));

	IF @RunningDate > @DailyMidnight
	BEGIN
		WHILE(1 = 1)
		BEGIN
			DELETE TOP(5000) gb
			FROM dbo.TWGroupBettingTicket gb WITH(ROWLOCK)
			WHERE gb.TransDate = CONVERT(DATE, DATEADD(DAY,-1,@RunningDate));
			
			IF (@@ROWCOUNT = 0)
			BEGIN
				BREAK;
			END;
			WAITFOR DELAY '00:00:0.100';
		END;
		
	END;

	INSERT INTO dbo.TWGroupBettingTicket (
		CustId
		,TransId
		,TransDate
		)
	SELECT Custid
		,TransId
		,TransDate
	FROM #TmpGroupBettingTicket

	DROP TABLE #TmpGroupBettingTicket

END;

