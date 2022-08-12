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
	
	DROP TABLE IF EXISTS #tmpCustIds;
	CREATE TABLE #tmpCustIds(
			CustId				BIGINT NOT NULL PRIMARY KEY
	);

	IF @ListCustId <> ''
		BEGIN
			INSERT INTO #tmpCustIds (CustId)
			SELECT ssk.Value
			FROM STRING_SPLIT(@ListCustId, ',') AS ssk
			OPTION (MAXRECURSION 0);
		END;

	SET @DataFromDate = DATEADD(DAY, -7, @Today);

	DROP TABLE IF EXISTS #tmpRawTickets;
	CREATE TABLE	#tmpRawTickets(
			TransID				BIGINT
		,	TransDate_Int		BIGINT
		,	CustID				INT
		,	MatchID				INT
		,	EventDate			DATE
		,	LeagueId			INT
		,	HomeId				INT
		,	AwayId				INT
		,	BetType				SMALLINT
		,	BetTeam				NVARCHAR(10)
	);	

	DROP TABLE IF EXISTS #tmpAssociation;
	CREATE TABLE	#tmpAssociation(
			CustID1				INT
		,	CustID2				INT		
		,	MatchID				INT
		,	EventDate			DATE
		,	LeagueId			INT
		,	HomeId				INT
		,	AwayId				INT
		,	TransID1			BIGINT
		,	TransID2			BIGINT
	);
	
	-- Get full data from bettrans
	INSERT INTO #tmpRawTickets(TransID,TransDate_Int,MatchID,BetType,CustID,BetTeam,EventDate,LeagueId,HomeId,AwayId)
	SELECT	b.transid
		,	DATEDIFF(ss, @CutOffDate, b.transdate)
		,	b.matchid
		,	b.bettype
		,	b.custid
		,	b.betteam
		,	m.kickofftime
		,	m.leagueid
		,	m.homeid
		,	m.awayid
	FROM #tmpCustIds AS a WITH(NOLOCK)
		INNER JOIN dbo.bettrans AS b WITH(NOLOCK) ON a.CustID = b.custid		
		INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.MatchID = m.matchid AND m.sporttype < 100		
		INNER JOIN dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
	WHERE b.Currency NOT IN (20,27,28)
		AND l.LeagueGroupID NOT IN (42,72,74,108,113,122); -- exclude SABA, Virtual Sport

	-- Get more data from bettrans 14
	INSERT INTO #tmpRawTickets(TransID,TransDate_Int,MatchID,BetType,CustID,BetTeam,EventDate,LeagueId,HomeId,AwayId)
	SELECT	b.transid
		,	DATEDIFF(ss, @CutOffDate, b.transdate)
		,	b.matchid
		,	b.bettype
		,	b.custid
		,	b.betteam
		,	m.kickofftime
		,	m.leagueid
		,	m.homeid
		,	m.awayid
	FROM #tmpCustIds AS a WITH(NOLOCK)
		INNER JOIN dbo.bettrans14 AS b WITH(NOLOCK) ON a.CustID = b.custid		
		INNER JOIN dbo.match14 AS m WITH(NOLOCK) ON b.MatchID = m.matchid AND m.sporttype < 100		
		INNER JOIN dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
	WHERE	b.winlostdate > @DataFromDate
		AND b.Currency NOT IN (20,27,28)
		AND l.LeagueGroupID NOT IN (42,72,74,108,113,122); -- exclude SABA, Virtual Sport

	;WITH cte_custPerMatch AS (
		SELECT DISTINCT c1.CustID AS CustID1, c1.MatchID, c1.Bettype, c1.BetTeam, c2.CustID AS CustID2
			,	c1.EventDate, c1.LeagueId, c1.HomeId, c1.AwayId
		FROM #tmpRawTickets AS c1
			INNER JOIN #tmpRawTickets AS c2 
				ON c1.MatchID = c2.MatchID AND c1.BetType = c2.BetType
					AND c1.BetTeam = c2.BetTeam AND c1.CustID <> c2.CustID
	), 
	cte_SeekPerMatch AS (
		SELECT ck.CustID1, ck.CustID2
		FROM cte_custPerMatch AS ck
		GROUP BY ck.CustID1, ck.CustID2
		HAVING COUNT(DISTINCT ck.MatchID) >= 3
	)
	INSERT INTO #tmpAssociation(CustID1,CustID2,TransID1,TransID2, MatchID, EventDate, LeagueId, HomeId, AwayId)
	SELECT DISTINCT CASE 
						WHEN c.CustID1 > c.CustID2 THEN c.CustID2
						ELSE c.CustID1
					END AS CustID1
				,	CASE 
						WHEN c.CustID1 > c.CustID2 THEN c.CustID1
						ELSE c.CustID2
					END AS CustID2
				,	CASE 
						WHEN t.TransID1 > t.TransID2 THEN t.TransID2
						ELSE t.TransID1
					END AS TransID1
				,	CASE 
						WHEN t.TransID1 > t.TransID2 THEN t.TransID1
						ELSE t.TransID2
					END AS TransID2
				,	m.MatchID
				,	m.EventDate
				,	m.LeagueId
				,	m.HomeId
				,	m.AwayId
	FROM cte_SeekPerMatch AS c
		INNER JOIN cte_custPerMatch AS m ON m.CustID1 = c.CustID1 AND m.CustID2 = c.CustID2
		CROSS APPLY (
			SELECT c1.TransID AS TransID1, c2.TransID AS TransID2
			FROM (
				SELECT t1.TransID, t1.TransDate_Int
				FROM #tmpRawTickets AS t1
				WHERE t1.MatchID = m.MatchID AND t1.BetType = m.BetType 
					AND t1.BetTeam = m.BetTeam AND t1.CustID IN (c.CustID1)
			) AS c1
			INNER JOIN (
				SELECT t2.TransID, t2.TransDate_Int
				FROM #tmpRawTickets AS t2
				WHERE t2.MatchID = m.MatchID AND t2.BetType = m.BetType 
					AND t2.BetTeam = m.BetTeam AND t2.CustID IN (c.CustID2)
			) AS c2
				ON ABS(c1.TransDate_Int - c2.TransDate_Int) <= @CONST_MAXTIMEINTERVAL
		) AS t
	;

	IF (@IsDetecting = 1) 
		BEGIN			
			SELECT DISTINCT CustID1, CustID2
			FROM #tmpAssociation;
		END;
	ELSE
		BEGIN
			;WITH cte_orderedMatch	AS (
				SELECT TOP 3 MatchID
				FROM #tmpAssociation 
				ORDER BY EventDate
			)
			SELECT b.TransId, b.TransDate, b.UserName, b.BetType, b.BetTeam, b.Stake, b.Odds, b.LiveHomeScore, b.LiveAwayScore, b.status AS TicketStatus, b.MatchId, c.EventDate, c.HomeId, c.AwayId, c.LeagueId
			FROM cte_orderedMatch AS cte
				INNER JOIN #tmpAssociation AS c ON cte.MatchID = c.MatchID
				INNER JOIN dbo.bettrans AS b WITH(NOLOCK) ON b.TransId = c.TransID1 OR b.TransId = c.TransID2
			UNION
			SELECT b.TransId, b.TransDate, b.UserName, b.BetType, b.BetTeam, b.Stake, b.Odds, b.LiveHomeScore, b.LiveAwayScore, b.status AS TicketStatus, b.MatchId, c.EventDate, c.HomeId, c.AwayId, c.LeagueId
			FROM cte_orderedMatch AS cte
				INNER JOIN #tmpAssociation AS c ON cte.MatchID = c.MatchID
				INNER JOIN dbo.bettrans14 AS b WITH(NOLOCK) ON b.TransId = c.TransID1 OR b.TransId = c.TransID2
		END;

	DROP TABLE #tmpCustIds;
	DROP TABLE #tmpRawTickets;
END;

