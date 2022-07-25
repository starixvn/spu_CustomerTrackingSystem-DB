/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_Rpt_MatchMonitor_TicketDetails]
		@QueryType				TINYINT = 1

	,	@LastScannedTransID		BIGINT = 0
	,	@IsLive					BIT = 1
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
		- 20210728@Long.Luu: Exclude SABA's leaguegroup [Redmine ID: #159187]		
		- 20210820@Long.Luu: Separate Live/Nonlive ticket selection [Redmine ID: #159195]
		- 20210928@Long.Luu: Remove useless filter [Redmine ID: #159195]		
		- 20211214@Long.Luu: Return danger info [Redmine ID: #165606]
		- 20220110@Long.Luu: Return BetId and support data for Basketbal & Esports [Redmine ID: #166986]
		- 20220728@Long.Luu: Convert stake to RM [Redmine ID: #175913]
		- 20220725@Long.Luu: Return More Ticket's Info [Redmine ID: #175700]

	Params Explaination:
		- @QueryType: 1 - to run service (get tickets by @LastScannedTransID, @IsLive & @BatchSize)
					  2 - to show on report (get tickets by @EventDate & @ListTransId)

	Example:
		EXECUTE [dbo].[CTS_Rpt_MatchMonitor_TicketDetails] @QueryType = 1, @LastScannedTransID = 0, @IsLive = 1,	@BatchSize = 500;
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @BalanceUpDay			SMALLDATETIME
		,	@MoveBetsDay			SMALLDATETIME
		,	@Today					DATE = GETDATE();

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

	IF	OBJECT_ID('tempdb..#tmpSupportedSportBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedSportBettype;
	END;

	CREATE TABLE	#tmpSupportedSportBettype(
			SportType			SMALLINT
		,	BetType				SMALLINT
	);

	INSERT INTO #tmpSupportedSportBettype(SportType,BetType)
	VALUES (1,1),(1,3),(1,7),(1,8); -- Soccer
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType)
	VALUES (2,1),(2,3),(2,7),(2,8),(2,20),(2,609),(2,610),(2,612); -- Basketball
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType)
	VALUES (43,1),(43,3),(43,20); -- E-Sports

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
		,	LeagueName			NVARCHAR(500)
		,	IsMajorLeague		BIT
		,	SportType			SMALLINT
		,	BetType				SMALLINT
		,	CustId				INT
		,	BetTeam				NVARCHAR(10)
		,	BetId				BIGINT
		,	Stake				MONEY
		,	Odds				SMALLMONEY
		,	Hdp1				SMALLMONEY
		,	Hdp2				SMALLMONEY
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	LiveIndicator		BIT
		,	TicketStatus		SMALLINT
		,	Danger1				TINYINT
		,	Danger2				TINYINT
		,	Danger3				TINYINT
		,	Danger4				TINYINT
		,	Danger5				TINYINT
	);	

	CREATE CLUSTERED INDEX #CIX_tmpTickets_CustID ON #tmpTickets (
			CustId			DESC
	);

	CREATE NONCLUSTERED INDEX #IX_tmpTickets_LeagueId ON #tmpTickets (
			LeagueId		DESC
	);

	IF (@QueryType = 1)
		BEGIN
			INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,LeagueName,IsMajorLeague,SportType,BetType,CustId,BetTeam, BetId,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
			SELECT	TOP (@BatchSize) b.transid
				,	b.transdate
				,	b.matchid
				,	m.eventdate
				,	m.Eventstatus
				,	m.kickofftime
				,	m.homeid
				,	m.awayid
				,	m.leagueid
				,	l.leaguename
				,	CASE 
						WHEN l.LeagueGroupID IN (1,2,3) THEN 1
						ELSE 0
					END AS IsMajorLeague
				,	m.sporttype
				,	b.bettype
				,	b.custid
				,	b.betteam
				,	b.betid
				,	b.stake * b.actualrate
				,	CASE 
						WHEN b.odds < 0 THEN 1/ABS(b.odds)
						ELSE b.odds
					END AS odds
				,	b.hdp1
				,	b.hdp2
				,	b.livehomescore
				,	b.liveawayscore
				,	b.statusID
				,	b.liveindicator
			FROM dbo.bettrans AS b WITH(NOLOCK)
				INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
				INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON b.recommend = c.custid
				INNER JOIN #tmpSupportedSportBettype AS t WITH(NOLOCK) ON m.sporttype = t.SportType AND b.bettype = t.BetType
			WHERE	b.transid > @LastScannedTransID
                AND m.eventstatus <> 'completed'
				AND b.LiveIndicator = @IsLive
				AND b.Currency NOT IN (20,27,28)
				AND b.BetFrom NOT IN ('p','m','w','0','3','6')
				AND b.recommend NOT IN (52466,5707545) -- 8RM, BARM
				AND b.Username NOT LIKE '%Cashout%'
				AND l.LeagueGroupID NOT IN (42,74,108,113) -- SABA leagues
				AND c.Site NOT IN ('NextBet','9wickets','9wsports')
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
				INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
				SELECT	b.transid
					,	b.transdate
					,	b.matchid
					,	m.eventdate
					,	m.Eventstatus
					,	m.kickofftime
					,	m.homeid
					,	m.awayid
					,	m.leagueid
					,	m.sporttype
					,	b.bettype
					,	b.custid
					,	b.betteam
					,	b.betid
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
				;
			END;

			IF	@IsGetDataFrom14 = 1
			BEGIN
				INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
				SELECT	b.transid
					,	b.transdate
					,	b.matchid
					,	m.eventdate
					,	m.Eventstatus
					,	m.kickofftime
					,	m.homeid
					,	m.awayid
					,	m.leagueid
					,	m.sporttype
					,	b.bettype
					,	b.custid
					,	b.betteam
					,	b.betid
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
				;
			END;

			IF	@IsGetDataFromOrigin = 1
			BEGIN
				INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
				SELECT	b.transid
					,	b.transdate
					,	b.matchid
					,	m.eventdate
					,	m.Eventstatus
					,	m.kickofftime
					,	m.homeid
					,	m.awayid
					,	m.leagueid
					,	m.sporttype
					,	b.bettype
					,	b.custid
					,	b.betteam
					,	b.betid
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
				;
			END;

			UPDATE	t WITH(ROWLOCK, UPDLOCK)
			SET		t.Danger1 = c.danger
				,	t.Danger2 = c.danger2
				,	t.Danger3 = c.danger3
				,	t.Danger4 = c.Danger4
				,	t.Danger5 = c.Danger5
				,	t.LeagueName = l.leaguename
			FROM #tmpTickets AS t
				INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON t.LeagueId = l.leagueid
				INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid;
		END;	

	-- Return data
	SELECT	*
	FROM #tmpTickets AS m WITH(NOLOCK);
	
	DROP TABLE #tmpTransIds;
	DROP TABLE #tmpTickets;
END;

GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/