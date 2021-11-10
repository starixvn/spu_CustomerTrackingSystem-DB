/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_Rpt_RobotDetection_TicketDetails]
		@ListTransId			VARCHAR(MAX) = ''

AS
/*
	Created: 20211111@Long.Luu
	Task : CTS - Robot Detection - Get Fraud Tickets
	DB	 : bodb02

	Revisions:
		- 20211111@Long.Luu: Created [Redmine ID: #162341]

	Params Explaination:

	Example:
		EXECUTE [dbo].[CTS_Rpt_RobotDetection_TicketDetails] @ListTransId = '1,3'
*/
BEGIN
	SET NOCOUNT ON;

	IF	OBJECT_ID('tempdb..#tmpTransIds') IS NOT NULL
	BEGIN
		DROP TABLE #tmpTransIds;
	END;

	CREATE TABLE #tmpTransIds(
			TransId				BIGINT NOT NULL PRIMARY KEY
	);

	IF	OBJECT_ID('tempdb..#tmpTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpTickets;
	END;

	CREATE TABLE	#tmpTickets(
			TransId				BIGINT PRIMARY KEY
		,	TransDate			DATETIME
		,	MatchId				INT
		,	EventDate			DATETIME
		,	EventStatus			NVARCHAR(50)
		,	KickOffTime			DATETIME
		,	HomeId				INT
		,	AwayId				INT
		,	LeagueId			INT
		,	BetType				SMALLINT
		,	CustId				INT
		,	BetTeam				NVARCHAR(10)
		,	Stake				MONEY
		,	Odds				SMALLMONEY
		,	Hdp1				SMALLMONEY
		,	Hdp2				SMALLMONEY
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	LiveIndicator		BIT
		,	TicketStatus		SMALLINT
	);	
	
	-- START --
	IF @ListTransId <> ''
	BEGIN
		INSERT INTO #tmpTransIds (TransId)
		SELECT ssk.val FROM dbo.f_SplitString(@ListTransId, ',') ssk
		OPTION (MAXRECURSION 0);
	END;

	INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,BetType,CustId,BetTeam,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
	SELECT	b.transid
		,	b.transdate
		,	b.matchid
		,	m.eventdate
		,	m.Eventstatus
		,	m.kickofftime
		,	m.homeid
		,	m.awayid
		,	m.leagueid
		,	b.bettype
		,	b.custid
		,	b.betteam
		,	b.stake
		,	b.odds
		,	b.hdp1
		,	b.hdp2
		,	b.livehomescore
		,	b.liveawayscore
		,	b.statusID
		,	b.liveindicator
	FROM #tmpTransIds AS t WITH(NOLOCK)
		INNER JOIN dbo.bettrans AS b WITH(NOLOCK) ON t.TransId = b.transid
		INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
	;

	DELETE t WITH(ROWLOCK)
	FROM #tmpTransIds AS t
		INNER JOIN #tmpTickets AS b WITH(NOLOCK) ON  t.TransId = b.transid;

	INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,BetType,CustId,BetTeam,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
	SELECT	b.transid
		,	b.transdate
		,	b.matchid
		,	m.eventdate
		,	m.Eventstatus
		,	m.kickofftime
		,	m.homeid
		,	m.awayid
		,	m.leagueid
		,	b.bettype
		,	b.custid
		,	b.betteam
		,	b.stake
		,	b.odds
		,	b.hdp1
		,	b.hdp2
		,	b.livehomescore
		,	b.liveawayscore
		,	b.statusID
		,	b.liveindicator
	FROM #tmpTransIds AS t WITH(NOLOCK)
		INNER JOIN dbo.bettrans14 AS b WITH(NOLOCK) ON t.TransId = b.transid
		INNER JOIN dbo.match14 AS m WITH(NOLOCK) ON b.matchid = m.matchid
	;

	DELETE t WITH(ROWLOCK)
	FROM #tmpTransIds AS t
		INNER JOIN #tmpTickets AS b WITH(NOLOCK) ON  t.TransId = b.transid;

	INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,BetType,CustId,BetTeam,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
	SELECT	b.transid
		,	b.transdate
		,	b.matchid
		,	m.eventdate
		,	m.Eventstatus
		,	m.kickofftime
		,	m.homeid
		,	m.awayid
		,	m.leagueid
		,	b.bettype
		,	b.custid
		,	b.betteam
		,	b.stake
		,	b.odds
		,	b.hdp1
		,	b.hdp2
		,	b.livehomescore
		,	b.liveawayscore
		,	b.statusID
		,	b.liveindicator
	FROM #tmpTransIds AS t WITH(NOLOCK)
		INNER JOIN bodb_Archive.dbo.bettrans_bk AS b WITH(NOLOCK) ON t.TransId = b.transid
		INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON b.matchid = m.matchid
	;

	-- Return data
	SELECT	*
	FROM #tmpTickets AS m WITH(NOLOCK);
	
	DROP TABLE #tmpTransIds;
	DROP TABLE #tmpTickets;
END;

GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/