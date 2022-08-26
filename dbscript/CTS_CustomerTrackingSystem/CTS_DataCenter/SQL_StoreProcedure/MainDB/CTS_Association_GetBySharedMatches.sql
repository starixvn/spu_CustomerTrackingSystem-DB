/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_Association_GetBySharedMatches]
	@ListCustId			VARCHAR(MAX) = '',
	@RootCustId			BIGINT = 0,
	@QueryType			TINYINT = 0
AS
/*
	Created: 20220726@Long.Luu
	Task : CTS - Association Detection by Shared At Least 3 Matches Within last 7 days
	DB	 : bodb02

	Revisions:
		- 20220726@Long.Luu: Created [Redmine ID: #175701]

	Params Explaination:
		- @QueryType: 1 detect associations, 2 get fraud tickets, 3 get association custlist of a group

	Example:
		EXECUTE [dbo].[CTS_Association_GetBySharedMatches] @ListCustId = '2,3',@RootCustId=2,@QueryType=2;
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @CONST_MAXTIMEINTERVAL	SMALLINT = 180; -- 180 Seconds = 3 minutes

	DECLARE @DataFromDate			SMALLDATETIME
		,	@Today					DATE = GETDATE()
		,	@CutOffDate				DATE = '2021-09-22'
		,	@BalanceUpDay			SMALLDATETIME
		,	@MoveBetsDay			SMALLDATETIME;
	
	DROP TABLE IF EXISTS #tmpCustIds;
	CREATE TABLE #tmpCustIds(
			CustId				INT NOT NULL PRIMARY KEY
	);

	DROP TABLE IF EXISTS #BUMBData;
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

	DROP TABLE IF EXISTS #tmpTopMatches;
	CREATE TABLE	#tmpTopMatches(
			MatchID				INT
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
	WHERE b.winlostdate > @MoveBetsDay
		AND b.Currency NOT IN (20,27,28)
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
	WHERE	b.winlostdate <= @MoveBetsDay AND b.winlostdate > @DataFromDate
		AND b.Currency NOT IN (20,27,28)
		AND l.LeagueGroupID NOT IN (42,72,74,108,113,122); -- exclude SABA, Virtual Sport

	CREATE CLUSTERED INDEX CIX_tmpRawTickets
	ON #tmpRawTickets (MatchID, Bettype, Betteam, CustID); 

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

	CREATE CLUSTERED INDEX CIX_tmpAssociation
	ON #tmpAssociation (MatchID, EventDate, TransID1, TransID2);

	CREATE NONCLUSTERED INDEX IX_tmpAssociation_CustID1CustID2
	ON #tmpAssociation (CustID1, CustID2);

	CREATE NONCLUSTERED INDEX CIX_tmpAssociation_CustID2
	ON #tmpAssociation (CustID2);

	;WITH cte_lessThan3Matches AS (
		SELECT CustID1, CustID2
		FROM #tmpAssociation
		GROUP BY CustID1, CustID2
		HAVING COUNT(DISTINCT MatchID) < 3
	)
	DELETE a WITH(ROWLOCK)
	FROM cte_lessThan3Matches AS t
		INNER JOIN #tmpAssociation AS a ON t.CustID1 = a.CustID1 AND t.CustID2 = a.CustID2;

	IF (@QueryType = 1) 
		BEGIN			
			SELECT DISTINCT CustID1, CustID2
			FROM #tmpAssociation;
		END;
	ELSE IF (@QueryType = 2)
		BEGIN
			;WITH cte_topMatches AS(				
				SELECT DISTINCT MatchID, EventDate
				FROM #tmpAssociation
			)		
			INSERT INTO #tmpTopMatches(MatchID)	
			SELECT TOP 3 MatchID
			FROM cte_topMatches 
			ORDER BY EventDate DESC;

			SELECT b.TransId, b.TransDate, b.UserName, b.BetType, b.BetTeam, b.Stake, b.Odds, b.LiveHomeScore, b.LiveAwayScore, b.status AS TicketStatus, b.MatchId, c.EventDate, c.HomeId, c.AwayId, c.LeagueId
			FROM #tmpTopMatches AS cte
				INNER JOIN #tmpAssociation AS c ON cte.MatchID = c.MatchID
				INNER JOIN dbo.bettrans AS b WITH(NOLOCK) ON b.TransId = c.TransID1 OR b.TransId = c.TransID2
			UNION ALL
			SELECT b.TransId, b.TransDate, b.UserName, b.BetType, b.BetTeam, b.Stake, b.Odds, b.LiveHomeScore, b.LiveAwayScore, b.status AS TicketStatus, b.MatchId, c.EventDate, c.HomeId, c.AwayId, c.LeagueId
			FROM #tmpTopMatches AS cte
				INNER JOIN #tmpAssociation AS c ON cte.MatchID = c.MatchID
				INNER JOIN dbo.bettrans14 AS b WITH(NOLOCK) ON b.TransId = c.TransID1 OR b.TransId = c.TransID2
		END
	ELSE 
		BEGIN			
			SELECT DISTINCT CustID2 AS CustID
			FROM #tmpAssociation
			WHERE CustID1 = @RootCustId
			UNION ALL
			SELECT DISTINCT CustID1 AS CustID
			FROM #tmpAssociation
			WHERE CustID2 = @RootCustId;
		END;

	DROP TABLE #tmpCustIds;
	DROP TABLE #tmpRawTickets;
END;

