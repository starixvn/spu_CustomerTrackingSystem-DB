USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[[CTS_Association_GetBySharedMatches]]    Script Date: 01-Aug-22 9:01:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_Association_GetBySharedMatches]
	@ListCustId			VARCHAR(MAX) = '',
	@IsDetecting		BIT = FALSE
AS
/*
	Created: 20220726@Long.Luu
	Task : CTS - Association Detection by Shared At Least 3 Matches Within last 7 days
	DB	 : bodb02

	Revisions:
		- 20220726@Long.Luu: Created [Redmine ID: #175701]

	Params Explaination:

	Example:
		EXECUTE [dbo].[CTS_Association_GetBySharedMatches] @ListCustId = '2,3',@IsDetecting=1;
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @CONST_MAXTIMEINTERVAL	SMALLINT = 180; -- 180 Seconds = 3 minutes

	DECLARE @DataFromDate			SMALLDATETIME
		,	@Today					DATE = GETDATE()
		,	@CutOffDate				DATE = '2021-09-22';

	CREATE TABLE #tmpCustIds(
			CustId				BIGINT NOT NULL PRIMARY KEY
	);

	IF @ListCustId <> ''
		BEGIN
			INSERT INTO #tmpCustIds (CustId)
			SELECT ssk.val 
			FROM dbo.f_SplitString(@ListCustId, ',') AS ssk
			OPTION (MAXRECURSION 0);
		END;

	SET @DataFromDate = DATEADD(DAY, -7, @Today);

	IF	OBJECT_ID('tempdb..#tmpRawTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpRawTickets;
	END;

	CREATE TABLE	#tmpRawTickets(
			TransId				BIGINT
		,	CustId				INT
		,	UserName			NVARCHAR(50)
		,	TransDate			DATETIME
		,	MatchId				INT
		,	EventDate			DATETIME
		,	EventStatus			NVARCHAR(50)
		,	KickOffTime			DATETIME
		,	HomeId				INT
		,	AwayId				INT
		,	LeagueId			INT
		,	LeagueName			NVARCHAR(500)
		,	SportType			SMALLINT
		,	BetType				SMALLINT
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

	IF	OBJECT_ID('tempdb..#tmpTickets') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpTickets;
	END;

	CREATE TABLE	#tmpTickets(
			ID					BIGINT IDENTITY (1,1) PRIMARY KEY
		,	TransId				BIGINT
		,	CustId				INT
		,	UserName			NVARCHAR(50)
		,	TransDate			DATETIME
		,	TransDate_Int		BIGINT
		,	MatchId				INT
		,	EventDate			DATETIME
		,	EventStatus			NVARCHAR(50)
		,	KickOffTime			DATETIME
		,	HomeId				INT
		,	AwayId				INT
		,	LeagueId			INT
		,	LeagueName			NVARCHAR(500)
		,	SportType			SMALLINT
		,	BetType				SMALLINT
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

	CREATE NONCLUSTERED INDEX #CIX_tmpTickets_CustID ON #tmpTickets (
			CustId			DESC
	);

	IF	OBJECT_ID('tempdb..#tmpTicketsCloned') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpTicketsCloned;
	END;

	CREATE TABLE	#tmpTicketsCloned(
			ID					BIGINT PRIMARY KEY
		,	TransId				BIGINT
		,	CustId				INT
		,	UserName			NVARCHAR(50)
		,	TransDate			DATETIME
		,	TransDate_Int		BIGINT
		,	MatchId				INT
		,	EventDate			DATETIME
		,	EventStatus			NVARCHAR(50)
		,	KickOffTime			DATETIME
		,	HomeId				INT
		,	AwayId				INT
		,	LeagueId			INT
		,	LeagueName			NVARCHAR(500)
		,	SportType			SMALLINT
		,	BetType				SMALLINT
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

	CREATE NONCLUSTERED INDEX #CIX_tmpTicketsCloned_CustID ON #tmpTicketsCloned (
			CustId			DESC
	);

	INSERT INTO #tmpRawTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,LeagueName,SportType,BetType,CustId,BetTeam, Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
	SELECT	b.transid
		,	b.transdate
		,	b.matchid
		,	m.eventdate
		,	m.Eventstatus
		,	m.kickofftime
		,	m.homeid
		,	m.awayid
		,	m.leagueid
		,	l.leaguename
		,	m.sporttype
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
	FROM #tmpCustIds AS a WITH(NOLOCK)
		INNER JOIN dbo.bettrans AS b WITH(NOLOCK) ON a.CustID = b.custid
		INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
		INNER JOIN dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON b.recommend = c.custid
		INNER JOIN dbo.SportBettypeMatrix AS t WITH(NOLOCK) ON b.bettype = t.BetType AND t.SportType IN (1,2,43)
	WHERE	b.Currency NOT IN (20,27,28);

	INSERT INTO #tmpRawTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,LeagueName,SportType,BetType,CustId,BetTeam, Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator)
	SELECT	b.transid
		,	b.transdate
		,	b.matchid
		,	m.eventdate
		,	m.Eventstatus
		,	m.kickofftime
		,	m.homeid
		,	m.awayid
		,	m.leagueid
		,	l.leaguename
		,	m.sporttype
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
	FROM #tmpCustIds AS a WITH(NOLOCK)
		INNER JOIN dbo.bettrans14 AS b WITH(NOLOCK) ON a.CustID = b.custid
		INNER JOIN dbo.match14 AS m WITH(NOLOCK) ON b.matchid = m.matchid
		INNER JOIN dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON b.recommend = c.custid
		INNER JOIN dbo.SportBettypeMatrix AS t WITH(NOLOCK) ON b.bettype = t.BetType AND t.SportType IN (1,2,43)
	WHERE	b.winlostdate > @DataFromDate
		AND b.Currency NOT IN (20,27,28);
	
	CREATE NONCLUSTERED INDEX #CIX_tmpTickets_TransDate ON #tmpRawTickets (
			TransDate			ASC
	);

	INSERT INTO #tmpTickets(TransId,TransDate,TransDate_Int,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,LeagueName,SportType,BetType,CustId,BetTeam,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus,LiveIndicator)
	SELECT TransId,TransDate,DATEDIFF(ss, TransDate, @CutOffDate),MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,LeagueName,SportType,BetType,CustId,BetTeam,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus,LiveIndicator
	FROM #tmpRawTickets WITH(NOLOCK)
	ORDER BY TransDate ASC;

	INSERT INTO #tmpTicketsCloned(ID,TransId,TransDate,TransDate_Int,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,LeagueName,SportType,BetType,CustId,BetTeam,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus,LiveIndicator)
	SELECT (ID - 1),TransId,TransDate,TransDate_Int,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,LeagueName,SportType,BetType,CustId,BetTeam,Stake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus,LiveIndicator
	FROM #tmpTickets WITH(NOLOCK)

	IF (@IsDetecting = 1) 
		BEGIN
			;WITH CTE_coupleDetection AS (
				SELECT CASE 
							WHEN t.CustId > c.CustId THEN c.CustId
							ELSE t.CustId
						END AS CustID1
					,	CASE 
							WHEN t.CustId > c.CustId THEN t.CustId
							ELSE c.CustId
						END AS CustID2
				FROM #tmpTickets AS t WITH(NOLOCK)
					INNER JOIN #tmpTicketsCloned AS c WITH(NOLOCK) ON t.ID = c.ID AND t.CustId <> c.CustId
				WHERE ABS(t.TransDate_Int - c.TransDate_Int) <= @CONST_MAXTIMEINTERVAL
			)
			SELECT DISTINCT CustID1, CustID2
			FROM CTE_coupleDetection;
		END;
	ELSE
		BEGIN
			;WITH CTE_fraudTickets AS (
				SELECT t.TransId AS TransId1, c.TransId AS TransId2
				FROM #tmpTickets AS t WITH(NOLOCK)
					INNER JOIN #tmpTicketsCloned AS c WITH(NOLOCK) ON t.ID = c.ID AND t.CustId <> c.CustId
				WHERE ABS(t.TransDate_Int - c.TransDate_Int) <= @CONST_MAXTIMEINTERVAL
			)
			SELECT DISTINCT t.TransId, t.TransDate, t.UserName, t.BetType, t.BetTeam, t.Stake, t.Odds, t.LiveHomeScore, t.LiveAwayScore, t.TicketStatus, t.MatchId, t.EventDate, t.HomeId, t.AwayId, t.LeagueId
			FROM CTE_fraudTickets AS c
				INNER JOIN #tmpTickets AS t ON t.TransId = c.TransId1 OR t.TransId = c.TransId2;
		END;

	DROP TABLE #tmpCustIds;
	DROP TABLE #tmpRawTickets;
	DROP TABLE #tmpTickets;
	DROP TABLE #tmpTicketsCloned;
END;

