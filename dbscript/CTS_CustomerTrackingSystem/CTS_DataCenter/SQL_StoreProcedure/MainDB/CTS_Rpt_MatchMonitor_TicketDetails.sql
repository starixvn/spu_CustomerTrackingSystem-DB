--DROP PROCEDURE [dbo].[CTS_Rpt_MatchMonitor_TicketDetails];
CREATE PROCEDURE [dbo].[CTS_Rpt_MatchMonitor_TicketDetails]
		@QueryType				TINYINT = 1

	,	@LastScannedTransID		BIGINT = 0
	,	@BatchSize				INT = 500

	,	@ListTransId			VARCHAR(MAX) = ''
	,	@EventDate				DATETIME = '1900-09-22'

AS
/*
	Created: 20210526@Long.Luu
	Task : CTS - Match Monitor Details - Get Fraud Tickets
	DB	 : bodb02

	Revisions:
		- 20210526@Long.Luu: Created [Redmine ID: #152883]

	Params Explaination:
		- @QueryType: 1 - to run service (get tickets by @LastScannedTransID & @BatchSize)
					  2 - to show on report (get tickets by @EventDate & @ListTransId)

	Example:
		EXECUTE [dbo].[CTS_Rpt_MatchMonitor_TicketDetails] @EventDate = '2021-02-23 00:00:00.000', @MatchId = 40391219, @CustId1 = 46777100, @CustId2 = 47717138, @Bettypes = '1,3'
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @BalanceUpDay			SMALLDATETIME
		,	@MoveBetsDay			SMALLDATETIME;

	IF	OBJECT_ID('tempdb..#BUMBData') IS NOT NULL
	BEGIN;
		DROP TABLE	#BUMBData;
	END;

	CREATE TABLE	#BUMBData (
			BUDay	SMALLDATETIME
		,	MBDay	SMALLDATETIME
	);

	INSERT INTO #BUMBData(BUDay,MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;

	SELECT	TOP(1)
			@BalanceUpDay	= BUDay
		,	@MoveBetsDay	= MBDay
	FROM #BUMBData WITH(NOLOCK);

	-- Initialize date range
	DECLARE @IsGetDataFromOrigin	BIT = 0
		,	@IsGetDataFrom14		BIT = 0
		,	@IsGetDataFromBK		BIT = 0;

	IF @EventDate < @BalanceUpDay
	BEGIN
		SELECT @IsGetDataFromBK = 1;
	END
	ELSE IF @EventDate <= @MoveBetsDay
	BEGIN
		SELECT @IsGetDataFrom14 = 1;
	END
	ELSE IF @EventDate > @MoveBetsDay
	BEGIN
		SELECT @IsGetDataFromOrigin = 1;
	END;

	IF	OBJECT_ID('tempdb..#tmpTransIds') IS NOT NULL
	BEGIN
		DROP TABLE #tmpTransIds;
	END;

	CREATE TABLE #tmpTransIds(
			TransId				BIGINT NOT NULL PRIMARY KEY
	);

	IF	OBJECT_ID('tempdb..#tmpBettypes') IS NOT NULL
	BEGIN
		DROP TABLE #tmpBettypes;
	END;

	CREATE TABLE #tmpBettypes(
			BettypeId			INT NOT NULL PRIMARY KEY
	);

	IF	OBJECT_ID('tempdb..#tmpTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpTickets;
	END;

	CREATE TABLE	#tmpTickets(
			TransId				BIGINT
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

	CREATE CLUSTERED INDEX #CIX_tmpMatchDetailsIdx ON #tmpTickets (
			EventDate			DESC
	);

	IF (@QueryType = 1)
		BEGIN
			INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,BetType,CustId,BetTeam,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
			SELECT	TOP (@BatchSize) b.transid
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
			FROM dbo.bettrans AS b WITH(NOLOCK)
				INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON c.custid = b.custid
			WHERE	b.transid > @LastScannedTransID
				AND b.bettype IN (1,3,7,8)
				AND b.Currency NOT IN (20,27,28)
				AND b.BetFrom NOT IN ('p','m','w','0','3','6')
				AND c.recommend NOT IN (52466,5707545) -- 8RM, BARM
				AND c.Username NOT LIKE '%Cashout%'
				AND m.leagueid NOT IN (42,74,108,113) -- SABA leagues
			ORDER BY b.transid ASC
				;
		END
	ELSE
		BEGIN
			IF @ListTransId <> ''
			BEGIN
				INSERT INTO #tmpTransIds (TransId)
				SELECT ssk.val FROM dbo.f_SplitString(@ListTransId, ',') ssk
				OPTION (MAXRECURSION 0);
			END;

			-- START --
			IF @IsGetDataFromBK = 1
			BEGIN
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
				FROM bodb_Archive.dbo.bettrans_bk AS b WITH(NOLOCK)
					INNER JOIN #tmpTransIds AS t WITH(NOLOCK) ON t.TransId = b.transid
					INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON b.matchid = m.matchid
					INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON c.custid = b.custid
				WHERE	b.bettype IN (1,3,7,8)
					AND b.Currency NOT IN (20,27,28)
					AND b.BetFrom NOT IN ('p','m','w','0','3','6')
					AND c.recommend NOT IN (52466,5707545) -- 8RM, BARM
					AND c.Username NOT LIKE '%Cashout%'
					AND m.leagueid NOT IN (42,74,108,113) -- SABA leagues
					;
			END;

			IF	@IsGetDataFrom14 = 1
			BEGIN
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
				FROM dbo.bettrans14 AS b WITH(NOLOCK)
					INNER JOIN #tmpTransIds AS t WITH(NOLOCK) ON t.TransId = b.transid
					INNER JOIN dbo.match14 AS m WITH(NOLOCK) ON b.matchid = m.matchid
					INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON c.custid = b.custid
				WHERE	b.bettype IN (1,3,7,8)
					AND b.Currency NOT IN (20,27,28)
					AND b.BetFrom NOT IN ('p','m','w','0','3','6')
					AND c.recommend NOT IN (52466,5707545) -- 8RM, BARM
					AND c.Username NOT LIKE '%Cashout%'
					AND m.leagueid NOT IN (42,74,108,113) -- SABA leagues
					;
			END;

			IF	@IsGetDataFromOrigin = 1
			BEGIN
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
				FROM dbo.bettrans AS b WITH(NOLOCK)
					INNER JOIN #tmpTransIds AS t WITH(NOLOCK) ON t.TransId = b.transid
					INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
					INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON c.custid = b.custid
				WHERE	b.bettype IN (1,3,7,8)
					AND b.Currency NOT IN (20,27,28)
					AND b.BetFrom NOT IN ('p','m','w','0','3','6')
					AND c.recommend NOT IN (52466,5707545) -- 8RM, BARM
					AND c.Username NOT LIKE '%Cashout%'
					AND m.leagueid NOT IN (42,74,108,113) -- SABA leagues
					;
			END;
		END;

	

	-- Return data
	SELECT	*
	FROM #tmpTickets AS m WITH(NOLOCK)
	ORDER BY m.TransDate DESC;
	
	DROP TABLE #tmpTransIds;
	DROP TABLE #tmpTickets;
END;

GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/