CREATE PROCEDURE [dbo].[CTS_Rpt_BettingPattern_MatchInfo]
		@MatchIds			VARCHAR(MAX) = ''
AS
/*
	Created: 20210304@John.Ngo
	Task : Match List Betting Pattern
	DB	 : bodb_FraudSensor

	Revisions:
		- 20210304@John.Ngo: Display betting pattern details [Redmine ID: #151156]

	Params Explaination:
		EXECUTE [dbo].[CTS_Rpt_BettingPattern_MatchInfo] @MatchIds = '40391219,40391223,1207560'
*/
BEGIN
	SET NOCOUNT ON;

IF	OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatches;
	END;

	CREATE TABLE #tmpMatches(
			MatchId				INT NOT NULL PRIMARY KEY
	);

	IF	OBJECT_ID('tempdb..#tmpMatchesInfo') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatchesInfo;
	END;

	CREATE TABLE #tmpMatchesInfo (
			MatchId				INT NOT NULL PRIMARY KEY
		,	EventDate			DATETIME
		,	HomeId				INT
		,	AwayId				INT
		,	LeagueId			INT
	);

	INSERT INTO #tmpMatches (MatchId)
	SELECT ssk.val FROM dbo.SPU_StrSplit(@MatchIds, ',') ssk;

	INSERT INTO #tmpMatchesInfo (MatchId, EventDate, HomeId, AwayId, LeagueId)
	SELECT	tm.MatchId
		,	m.eventdate
		,	m.homeid
		,	m.awayid
		,	m.leagueid
	FROM #tmpMatches AS tm WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Match AS m WITH(NOLOCK) ON tm.MatchId = m.matchid

	DELETE tm
	FROM #tmpMatches AS tm
	INNER JOIN #tmpMatchesInfo AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;

	INSERT INTO #tmpMatchesInfo (MatchId, EventDate, HomeId, AwayId, LeagueId)
	SELECT	tm.MatchId
		,	m.eventdate
		,	m.homeid
		,	m.awayid
		,	m.leagueid
	FROM #tmpMatches AS tm WITH(NOLOCK)
		INNER JOIN bodb02.dbo.Match14 AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;
		
	DELETE tm
	FROM #tmpMatches AS tm
		INNER JOIN #tmpMatchesInfo AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;

	INSERT INTO #tmpMatchesInfo (MatchId, EventDate, HomeId, AwayId, LeagueId)
	SELECT	tm.MatchId
		,	m.eventdate
		,	m.homeid
		,	m.awayid
		,	m.leagueid
	FROM #tmpMatches AS tm WITH(NOLOCK)
		INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;
	
	-- Return data
	SELECT	m.MatchId
		,	m.EventDate
		,	m.HomeId
		,	m.AwayId
		,	m.LeagueId
		,	h.teamname	 AS HomeName
		,	a.teamname	 AS AwayName
		,	l.leaguename AS LeagueName
	FROM #tmpMatchesInfo AS m WITH(NOLOCK)
		INNER JOIN bodb02.dbo.league AS l WITH (NOLOCK) ON l.leagueid = m.leagueid
        INNER JOIN bodb02.dbo.team AS h WITH (NOLOCK) ON h.teamid = m.homeid
        INNER JOIN bodb02.dbo.team AS a WITH (NOLOCK) ON a.teamid = m.awayid
	ORDER BY m.EventDate DESC;

	DROP TABLE #tmpMatches;
	DROP TABLE #tmpMatchesInfo;

END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/