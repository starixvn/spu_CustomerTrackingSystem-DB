DECLARE
		@LastScannedSequenceID		BIGINT = 0
	,	@IsLive						BIT = 1
	,	@BatchSize					INT = 1
	,	@ListSportBettype			VARCHAR(MAX)

SET @LastScannedSequenceID=1
SET @IsLive=1
SET @BatchSize=500
SET @ListSportBettype='[{"SportTypeID":1, "BetTypeID":1}
                        ,	{"SportTypeID":1, "BetTypeID":3}
                        ,	{"SportTypeID":1, "BetTypeID":7}
                        ,	{"SportTypeID":1, "BetTypeID":8}
                        ,	{"SportTypeID":2, "BetTypeID":1}
                        ,	{"SportTypeID":2, "BetTypeID":3}
                        ,	{"SportTypeID":2, "BetTypeID":7}
                        ,	{"SportTypeID":2, "BetTypeID":8}
                        ,	{"SportTypeID":2, "BetTypeID":20}
                        ,	{"SportTypeID":2, "BetTypeID":609}
                        ,	{"SportTypeID":2, "BetTypeID":610}
                        ,	{"SportTypeID":2, "BetTypeID":612}]';

BEGIN
	SET NOCOUNT ON;
	
	IF	OBJECT_ID('tempdb..#tmpParlayTrans') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpParlayTrans;
	END;

	CREATE TABLE #tmpParlayTrans(
			SequenceID	BIGINT 
		,	Refno BIGINT
	)
	
    
    IF	OBJECT_ID('tempdb..#tmpSportBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSportBettype;
	END;

	CREATE TABLE #tmpSportBettype(
			SportTypeID	SMALLINT
		,	BetTypeID	INT 
	)
	
	CREATE CLUSTERED INDEX CIX_tmpSportBettype ON #tmpSportBettype(SportTypeID,BetTypeID);
	
	--==================================================================
	IF @ListSportBettype <> ''
	BEGIN
		INSERT INTO #tmpSportBettype(SportTypeID,BetTypeID)
		SELECT DISTINCT	j.SportTypeID
					,	j.BetTypeID
		FROM OPENJSON (@ListSportBettype) WITH (
				SportTypeID			SMALLINT		'$.SportTypeID'
			,	BetTypeID			INT				'$.BetTypeID'
			) AS j;
	END;
	
	--==========================================================================================
    
	SELECT	TOP (1) 
			bt.sequenceid-1  AS InitialLiveSequenceId_Live
	FROM bodb02.dbo.bettrans AS bt WITH(NOLOCK)
		INNER JOIN bodb02.dbo.bettransm AS b WITH(NOLOCK) ON b.Refno = bt.Refno
		INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
		INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN bodb02.dbo.vw_Customer AS c WITH(NOLOCK) ON bt.recommend = c.custid
		INNER JOIN #tmpSportBettype AS tmp WITH(NOLOCK) ON m.sporttype = tmp.SportTypeID AND b.bettype = tmp.BetTypeID
	WHERE	bt.sequenceid > 0
		AND	m.eventstatus <> 'completed'
		AND b.LiveIndicator = 1
		AND bt.Currency NOT IN (20,27,28)
		AND b.BetFrom NOT IN ('p','m','w','0','3','6')
		AND bt.Username NOT LIKE '%Cashout%'
		AND bt.srecommend NOT IN (41430709) 
		AND bt.mrecommend NOT IN (27899314,11656504,12146012) 
		AND bt.recommend NOT IN (52466,5707545,29270764,134456,27787409,48367475,93558369,16604398) AND b.statusID <> 101 -- Reject		
		AND c.site NOT IN ('Nextbet','9wickets','9wsports')
		AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
		AND (CAST(bt.BetCheck AS INT) & 2 = 2  -- Combo 2 bit 2
			OR CAST(bt.BetCheck AS INT) & 4 = 4) -- Combo 2 bit 3
		AND bt.Betteam = 1						-- 1:Mix Parlay
		AND bt.Bettype = 29
		AND bt.MatchID = 29
	ORDER BY bt.sequenceid ASC;

    SELECT	TOP (1) 
			bt.sequenceid -1 	AS InitialSequenceId_NonLive
	FROM bodb02.dbo.bettrans AS bt WITH(NOLOCK)
		INNER JOIN bodb02.dbo.bettransm AS b WITH(NOLOCK) ON b.Refno = bt.Refno
		INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
		INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
		INNER JOIN bodb02.dbo.vw_Customer AS c WITH(NOLOCK) ON bt.recommend = c.custid
		INNER JOIN #tmpSportBettype AS tmp WITH(NOLOCK) ON m.sporttype = tmp.SportTypeID AND b.bettype = tmp.BetTypeID
	WHERE	bt.sequenceid > 0
		AND	m.eventstatus <> 'completed'
		AND b.LiveIndicator = 0
		AND bt.Currency NOT IN (20,27,28)
		AND b.BetFrom NOT IN ('p','m','w','0','3','6')
		AND bt.Username NOT LIKE '%Cashout%'
		AND bt.srecommend NOT IN (41430709) 
		AND bt.mrecommend NOT IN (27899314,11656504,12146012) 
		AND bt.recommend NOT IN (52466,5707545,29270764,134456,27787409,48367475,93558369,16604398) AND b.statusID <> 101 -- Reject		
		AND c.site NOT IN ('Nextbet','9wickets','9wsports')
		AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
		AND (CAST(bt.BetCheck AS INT) & 2 = 2  -- Combo 2 bit 2
			OR CAST(bt.BetCheck AS INT) & 4 = 4) -- Combo 2 bit 3
		AND bt.Betteam = 1						-- 1:Mix Parlay
		AND bt.Bettype = 29
		AND bt.MatchID = 29
	ORDER BY bt.sequenceid ASC;

	DROP TABLE IF EXISTS #tmpSportBettype;

END;
GO
