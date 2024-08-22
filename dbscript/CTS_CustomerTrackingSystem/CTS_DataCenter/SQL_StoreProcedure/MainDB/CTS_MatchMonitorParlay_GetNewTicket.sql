/*<info serverAlias="DBCTS-bodb02" executers="wsv_cts" isFunction="0" isNested="0"></info>*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_MatchMonitorParlay_GetNewTicket]
		@LastScannedSequenceID		BIGINT = 0
	,	@IsLive						BIT = 1
	,	@BatchSize					INT = 500
	,	@ListSportBettype			VARCHAR(MAX)

AS
/*
	Created: 20240822@Casey.Huynh
	Task : CTS - Match Monitor Parlay, Get New Ticket
	DB	 : bodb02

	Revisions:
		- 20240822@Casey.Huynh: Created

	Params Explaination:

	Example:

		EXEC [CTS_MatchMonitorParlay_GetNewTicket] 
			 @LastScannedSequenceID=1
			,@IsLive=1
			,@BatchSize=500
			,@ListSportBettype='[		{"SportTypeID":1, "BetTypeID":1}
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
*/
BEGIN
	SET NOCOUNT ON;
	
	IF	OBJECT_ID('tempdb..#tmpSportBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSportBettype;
	END;

	CREATE TABLE #tmpSportBettype(
			SportTypeID				SMALLINT
		,	BetTypeID				INT
	);
	
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
				
			CREATE INDEX IX_tmpSportBettype_SportTypeIDBetTypeID ON #tmpSportBettype(SportTypeID, BetTypeID);
		END;
	
	--==========================================================================================		
		SELECT	TOP (@BatchSize) 
				bt.sequenceid 				AS MainSequenceId
			,	bt.transid 					AS MainTransId
			,	b.Refno						AS Refno
			,	b.transid 					AS TransId
			,	b.transdate 				AS TransDate
			,	b.matchid 					AS MatchId
			,	m.sporttype 				AS SportType
			,	b.livehomescore 			AS LiveHomeScore
			,	b.liveawayscore 			AS LiveAwayScore
			,	b.bettype 					AS BetType
			,	b.BetCheck 					AS BetId			
			,	b.betteam 					AS BetTeam
			,	b.custid 					AS CustId
			,	m.eventdate 				AS EventDate
			,	m.GlobalShowTime 			AS KickOffTime
			,	m.Eventstatus 				AS EventStatus			
			,	m.homeid 					AS HomeId
			,	m.awayid 					AS AwayId
			,	m.leagueid 					AS LeagueId
			,	l.leaguename 				AS LeagueName
		FROM bodb02.dbo.bettrans AS bt WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettransm AS b WITH(NOLOCK) ON b.Refno = bt.Refno
			INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
			INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
			INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON bt.recommend = c.custid
			INNER JOIN #tmpSportBettype AS tmp WITH(NOLOCK) ON m.sporttype = tmp.SportTypeID AND b.bettype = tmp.BetTypeID
		WHERE	bt.sequenceid > @LastScannedSequenceID
			AND	m.eventstatus <> 'completed'
			AND b.LiveIndicator = @IsLive
			AND bt.Currency NOT IN (20,27,28)
			AND b.BetFrom NOT IN ('p','m','w','0','3','6')
			AND bt.Username NOT LIKE '%Cashout%'
			AND bt.srecommend NOT IN (41430709) 
			AND bt.mrecommend NOT IN (27899314,11656504,12146012) 
			AND bt.recommend NOT IN (52466,5707545,29270764,134456,27787409,48367475,93558369,16604398) AND b.statusID <> 101 -- Reject		
			AND c.site NOT IN ('Nextbet','9wickets','9wsports')
			AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
			AND CONVERT(int,bt.BetCheck) = 6		-- '0110:Combo 2 and 3'
			AND bt.Betteam = 1						-- 1:Mix Parlay
			AND bt.Bettype = 29
			AND bt.MatchID = 29
		ORDER BY bt.sequenceid ASC;

	DROP TABLE IF EXISTS #tmpSportBettype;

END;
GO
