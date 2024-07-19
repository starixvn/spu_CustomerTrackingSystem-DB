/*<info serverAlias="DBCTS-bodb02" executers="wsv_cts" isFunction="0" isNested="0"></info>*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_Rpt_MatchMonitor_GetTicketInfo]
		@QueryType					TINYINT = 1
	,	@LastScannedSequenceID		BIGINT = 0
	,	@IsLive						BIT = 1
	,	@BatchSize					INT = 500
	,	@ListSportBettype			VARCHAR(MAX)

AS
/*
	Created: 20240411@Victoria.Le
	Task : CTS - Match Monitor Staging - Ticket Info
	DB	 : bodb02

	Revisions:
		- 20240411@Vitoria.Le: 	Separate between QueryType = 1 and QueryType in (2,3)  [Redmine ID: #201380]
		- 20240607@CaseyHuynh:	Return Saba Scocer Ticket [Redmine ID: #191972]
        - 20240704@Casey.Huynh: Saba Group Betting - Add Basketball and enhance Soccer [Redmine ID: #207523]

	Params Explaination:
		- @QueryType: 1 - to run service MM Staging (get tickets by @LastScannedTransID, @IsLive & @BatchSize & @ListSportBettype)
					 
	Example:

		EXEC CTS_Rpt_MatchMonitor_GetTicketInfo @QueryType=1
			,@LastScannedSequenceID=119779209696
			,@IsLive=1
			,@BatchSize=500
			,@ListSportBettype='[		{"SportTypeID":1, "BetTypeID":1, "BetChoiceType":1}
									,	{"SportTypeID":1, "BetTypeID":3, "BetChoiceType":1}
									,	{"SportTypeID":1, "BetTypeID":7, "BetChoiceType":1}
									,	{"SportTypeID":1, "BetTypeID":8, "BetChoiceType":1}
									,	{"SportTypeID":43, "BetTypeID":9001, "BetChoiceType":1}
									,	{"SportTypeID":43, "BetTypeID":9003, "BetChoiceType":1}]';
*/
BEGIN
	SET NOCOUNT ON;
	
	IF	OBJECT_ID('tempdb..#tmpSportBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSportBettype;
	END;

	CREATE TABLE	#tmpSportBettype(
			SportTypeID				SMALLINT
		,	BetTypeID				INT
		,	BetChoiceType			TINYINT
		,	BetChoiceHome			NVARCHAR(10)
		,	BetChoiceAway			NVARCHAR(10)
		,	BetIDPattern			NVARCHAR(20)
		,	BetID					BIGINT
	);
	
	--==================================================================
	IF @ListSportBettype <> ''
		BEGIN
			INSERT INTO #tmpSportBettype(SportTypeID,BetTypeID,BetChoiceType,BetChoiceHome,BetChoiceAway,BetIDPattern,BetID)
			SELECT	j.SportTypeID
				,	j.BetTypeID
				,	j.BetChoiceType
				,	j.BetChoiceHome
				,	j.BetChoiceAway
				,	j.BetIDPattern
				,	j.BetID
			FROM OPENJSON (@ListSportBettype) WITH (
					SportTypeID			SMALLINT		'$.SportTypeID'
				,	BetTypeID			INT				'$.BetTypeID'
				,	BetChoiceType		TINYINT			'$.BetChoiceType'
				,	BetChoiceHome		NVARCHAR(10)	'$.BetChoiceHome'
				,	BetChoiceAway		NVARCHAR(10)	'$.BetChoiceAway'
				,	BetIDPattern		NVARCHAR(20)	'$.BetIDPattern'
				,	BetID				BIGINT			'$.BetID'
				) AS j;
				
			CREATE INDEX IX_tmpSportBettype_SportTypeIDBetTypeID ON #tmpSportBettype(SportTypeID, BetTypeID);
		END;
	
	--==========================================================================================
	IF (@QueryType = 1)
	BEGIN --Get ticket for MM Detection
		
		SELECT	TOP (@BatchSize) 
				b.sequenceid 				AS SequenceId
			,	b.transid 					AS TransId
			,	b.transdate 				AS TransDate
			,	b.matchid 					AS MatchId
			,	m.eventdate 				AS EventDate
			,	m.Eventstatus 				AS EventStatus
			,	m.GlobalShowTime 			AS KickOffTime
			,	m.homeid 					AS HomeId
			,	m.awayid 					AS AwayId
			,	m.leagueid 					AS LeagueId
			,	l.leaguename 				AS LeagueName
			,	CASE 
					WHEN l.LeagueGroupID IN (1,2,3) THEN 1
					ELSE 0
				END 						AS IsMajorLeague
			,	m.sporttype 				AS SportType
			,	b.bettype 					AS BetType
			,	b.custid 					AS CustId
			,	b.betteam 					AS BetTeam
			,	b.betid 					AS BetId
			,	(b.stake * b.actualrate) 	AS Stake
			,	b.stake 					AS OrgStake
			,	CASE 
					-- Decimal
					WHEN b.oddstype = 1 THEN (CASE
												WHEN ot.OddsType IS NOT NULL THEN (CASE 
																					WHEN b.odds <= 2 THEN (b.odds - 1)
																					WHEN b.odds > 2 THEN -(1/(b.odds - 1)) END)
												ELSE (CASE 
														WHEN b.odds <= 1 THEN b.odds
														WHEN b.odds > 1 THEN -(1/b.odds) END) END)
					-- Hong Kong
					WHEN b.oddstype = 2 THEN (CASE	
												WHEN b.odds <= 1 THEN b.odds
												WHEN b.odds > 1 THEN -(1/b.odds) END)
					-- Indonesia
					WHEN b.oddstype = 3 THEN -(1/NULLIF(b.odds,0))
					-- Malaysian & Myanmar
					WHEN b.oddstype IN (4,6) THEN b.odds
					-- US
					WHEN b.oddstype = 5 THEN -(1/NULLIF(b.odds,0))
				END 						AS Odds
			,	b.hdp1 						AS Hdp1
			,	b.hdp2 						AS Hdp2
			,	b.livehomescore 			AS LiveHomeScore
			,	b.liveawayscore 			AS LiveAwayScore
			,	b.statusID 					AS TicketStatus
			,	b.liveindicator 			AS LiveIndicator
			,	(CASE WHEN l.LeagueGroupID = 42 THEN LeagueGroupID ELSE NULL END) AS LeagueGroupID
		FROM bodb02.dbo.bettrans AS b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
			INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
			INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON b.recommend = c.custid
			INNER JOIN #tmpSportBettype AS t WITH(NOLOCK) ON m.sporttype = t.SportTypeID AND b.bettype = t.BetTypeID
			LEFT JOIN bodb02.dbo.f_Set_OddsTypeBettypes() AS ot ON ot.BetType = t.BetTypeID
		WHERE	b.sequenceid > @LastScannedSequenceID
			AND m.eventstatus <> 'completed'
			AND b.LiveIndicator = @IsLive
			AND b.Currency NOT IN (20,27,28)
			AND b.BetFrom NOT IN ('p','m','w','0','3','6')
			AND b.Username NOT LIKE '%Cashout%'
			AND b.srecommend NOT IN (41430709) 
			AND b.mrecommend NOT IN (27899314,11656504,12146012) 
			AND b.recommend NOT IN (52466,5707545,29270764,134456,27787409,48367475,93558369,16604398)AND b.statusID <> 101 -- Reject		
			AND c.site NOT IN ('Nextbet','9wickets','9wsports')
			AND (l.LeagueGroupID NOT IN (42,74,108,113,122,151)
				 OR (l.LeagueGroupID = 42 AND m.Sporttype IN (1,2)))-- SABA leagues
			AND ISNULL(b.oddstype,0) <> 0
		ORDER BY b.sequenceid ASC;
		
	END;

	DROP TABLE IF EXISTS #tmpSportBettype;

END;
GO
