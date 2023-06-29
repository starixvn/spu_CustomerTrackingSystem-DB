/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_Rpt_MatchMonitor_TicketDetails]
		@QueryType					TINYINT = 1

	,	@LastScannedSequenceID		BIGINT = 0
	,	@IsLive						BIT = 1
	,	@BatchSize					INT = 500

	,	@ListTransId				VARCHAR(MAX) = ''
	,	@EventDate					DATETIME = '1900-09-22'
	,	@MatchID					INT = 0
	,	@BetType					SMALLINT = 0
	,	@IsLicensee					BIT = NULL
	,	@ListCurrency				VARCHAR(MAX) = NULL
	,	@ListHDP					VARCHAR(MAX) = NULL
	,	@ListScore					VARCHAR(MAX) = NULL
	,	@FromStakeRM				MONEY = NULL
	,	@ToStakeRM					MONEY = NULL
	,	@MinSequenceIDTotalAll		BIGINT = NULL OUTPUT

	

AS
/*
	Created: 20210526@Long.Luu
	Task : CTS - Match Monitor Details - Get Fraud Tickets
	DB	 : bodb02

	Revisions:
		- 20210526@Long.Luu:	Created [Redmine ID: #152883]
		- 20210728@Long.Luu:	Exclude SABA's leaguegroup [Redmine ID: #159187]		
		- 20210820@Long.Luu:	Separate Live/Nonlive ticket selection [Redmine ID: #159195]
		- 20210928@Long.Luu:	Remove useless filter [Redmine ID: #159195]		
		- 20211214@Long.Luu:	Return danger info [Redmine ID: #165606]
		- 20220110@Long.Luu:	Return BetId and support data for Basketbal & Esports [Redmine ID: #166986]
		- 20220728@Long.Luu:	Convert stake to RM [Redmine ID: #175913]
		- 20220725@Long.Luu:	Return More Ticket's Info [Redmine ID: #175700]
		- 20230203@Victoria.Le	Various Odds will be converted to a unique one - Malaysian Odds [Redmine ID: #183277]
		- 20230220@Victoria.Le	Modify Formula to calculate Odds - For Decimal Odds [Redmine ID: #184080]
		- 202302220@Victoria.Le	Modify Formula to calculate Odds - For US Odds [Redmine ID: #184041]
		- 20230105@Victoria.Le	Get GlobalShowTime instead of KickOffTime
								Return StakeRM [Redmine ID: #181995]
		- 20230602@Long.Luu:	Add new agent as internal account [Redmine ID: #188554]
		- 20230607@Long.Luu:	Exclude more Saba's LeagueGroupID [Redmine ID: #189439]
		- 20230601@Victoria.Le	Show all tickets [Redmine ID: #185793]

	Params Explaination:
		- @QueryType: 1 - to run service (get tickets by @LastScannedTransID, @IsLive & @BatchSize)
					  2 - to show on report (get tickets by @EventDate & @ListTransId)
					  3	- to show on report (get all tickets by @MatchID, @BetType, @IsLive, @LastScannedSequenceID, @BatchSize, @IsLicensee, @ListCurrency, @ListHDP, @ListScore, @FromStakeRM, @ToStakeRM)
							+ @BatchSize = 0 ==> @MinSequenceIDTotalAll: Total tickets
							+ @BatchSize > 0 ==> @MinSequenceIDTotalAll: Min SequenceId
							+ @BatchSize = 0 & @ListTransId <> '' ==> get total tickets (excluded  @ListTransId)
	Example:
		DECLARE @MinTotal BIGINT;
		EXEC [dbo].[CTS_Rpt_MatchMonitor_TicketDetails] @QueryType = 3,@LastScannedSequenceID = 117286612760,@IsLive = 1,@BatchSize = 4000,@MatchID = 70099921,@BetType = 1, @IsLicensee = 1, @ListCurrency = '1',@ListHDP = '0.18,0.17',@ListScore = '0 - 0, 3 - 3',@FromStakeRM = NULL,@ToStakeRM = NULL,@MinSequenceIDTotalAll = @MinTotal OUTPUT;
		SELECT @MinTotal;
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
	
	IF	OBJECT_ID('tempdb..#tmpSupportedCurrency') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedCurrency;
	END;

	CREATE TABLE	#tmpSupportedCurrency(
			CurrencyId			TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpSupportedHDP') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedHDP;
	END;

	CREATE TABLE	#tmpSupportedHDP(
			Hdp					SMALLMONEY
	);

	IF	OBJECT_ID('tempdb..#tmpSupportedScore') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedScore;
	END;

	CREATE TABLE	#tmpSupportedScore(
			LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
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
			SequenceId			BIGINT
		,	TransId				BIGINT
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
		,	OrgStake			MONEY
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
		,	CustomerClass		SMALLINT
		,	CurrencyName		NVARCHAR(100)
		,	CurrencyId			TINYINT
		,	Hdp					SMALLMONEY
		,	IsLicensee			BIT
	);	

	CREATE CLUSTERED INDEX #CIX_tmpTickets_CustID ON #tmpTickets (
			CustId			DESC
	);

	CREATE NONCLUSTERED INDEX #IX_tmpTickets_LeagueId ON #tmpTickets (
			LeagueId		DESC
	);

	IF @ListTransId <> ''
		BEGIN
			INSERT INTO #tmpTransIds (TransId)
			SELECT ssk.val FROM dbo.f_SplitString(@ListTransId, ',') ssk
			OPTION (MAXRECURSION 0);
		END;

	IF (@QueryType = 1)
		BEGIN
			INSERT INTO #tmpTickets(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,LeagueName,IsMajorLeague,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus,LiveIndicator)
			SELECT	TOP (@BatchSize) b.sequenceid
				,	b.transid
				,	b.transdate
				,	b.matchid
				,	m.eventdate
				,	m.Eventstatus
				,	m.GlobalShowTime
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
				,	b.stake
				,	CASE 
						-- Decimal
						WHEN b.oddstype = 1 THEN (CASE
													WHEN ot.OddsType IS NOT NULL THEN (CASE 
																						WHEN b.odds <= 2 THEN (b.odds - 1)
																						WHEN b.odds > 2 THEN -(1/(b.odds - 1)) END)
													ELSE b.odds END)
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
					END AS odds
				,	b.hdp1
				,	b.hdp2
				,	b.livehomescore
				,	b.liveawayscore
				,	b.statusID
				,	b.liveindicator
			FROM dbo.bettrans AS b WITH(NOLOCK, INDEX=IX_sequenceid)
				INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid
				INNER JOIN bodb02.dbo.Customer AS c WITH(NOLOCK) ON b.recommend = c.custid
				INNER JOIN #tmpSupportedSportBettype AS t WITH(NOLOCK) ON m.sporttype = t.SportType AND b.bettype = t.BetType
				LEFT JOIN bodb02.dbo.f_Set_OddsTypeBettypes() AS ot ON ot.BetType = t.BetType
			WHERE	b.sequenceid > @LastScannedSequenceID
                AND m.eventstatus <> 'completed'
				AND b.LiveIndicator = @IsLive
				AND b.Currency NOT IN (20,27,28)
				AND b.BetFrom NOT IN ('p','m','w','0','3','6')
				AND b.Username NOT LIKE '%Cashout%'
				AND b.srecommend NOT IN (41430709) 
				AND b.mrecommend NOT IN (27899314,11656504,12146012) 
				AND b.recommend NOT IN (52466,5707545,29270764,134456,27787409)		
				AND c.site NOT IN ('Nextbet','9wickets','9wsports')
				AND l.LeagueGroupID NOT IN (42,74,108,113,122,151) -- SABA leagues
				AND ISNULL(b.oddstype,0) <> 0
			ORDER BY b.sequenceid ASC
				;
		END
	ELSE IF (@QueryType = 2)
		BEGIN
			-- START --
			IF @IsGetDataFromBK = 1
			BEGIN
				INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus,LiveIndicator,CurrencyName,CurrencyId)
				SELECT	b.transid
					,	b.transdate
					,	b.matchid
					,	m.eventdate
					,	m.Eventstatus
					,	m.GlobalShowTime
					,	m.homeid
					,	m.awayid
					,	m.leagueid
					,	m.sporttype
					,	b.bettype
					,	b.custid
					,	b.betteam
					,	b.betid
					,	b.stake * b.actualrate 
					,	b.stake
					,	b.odds
					,	b.hdp1
					,	b.hdp2
					,	b.livehomescore
					,	b.liveawayscore
					,	b.statusID
					,	b.liveindicator
					,	e.currency
					,	e.ExchangeId
				FROM bodb_Archive.dbo.bettrans_bk AS b WITH(NOLOCK)
					INNER JOIN #tmpTransIds AS t WITH(NOLOCK) ON t.TransId = b.transid
					INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON b.matchid = m.matchid
					INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
				;
			END;

			IF	@IsGetDataFrom14 = 1
			BEGIN
				INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus,LiveIndicator,CurrencyName,CurrencyId)
				SELECT	b.transid
					,	b.transdate
					,	b.matchid
					,	m.eventdate
					,	m.Eventstatus
					,	m.GlobalShowTime
					,	m.homeid
					,	m.awayid
					,	m.leagueid
					,	m.sporttype
					,	b.bettype
					,	b.custid
					,	b.betteam
					,	b.betid
					,	b.stake * b.actualrate 
					,	b.stake
					,	b.odds
					,	b.hdp1
					,	b.hdp2
					,	b.livehomescore
					,	b.liveawayscore
					,	b.statusID
					,	b.liveindicator
					,	b.CurrencyName
					,	b.currency
				FROM dbo.bettrans14 AS b WITH(NOLOCK)
					INNER JOIN #tmpTransIds AS t WITH(NOLOCK) ON t.TransId = b.transid
					INNER JOIN dbo.match14 AS m WITH(NOLOCK) ON b.matchid = m.matchid
				;
			END;

			IF	@IsGetDataFromOrigin = 1
			BEGIN
				INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId)
				SELECT	b.transid
					,	b.transdate
					,	b.matchid
					,	m.eventdate
					,	m.Eventstatus
					,	m.GlobalShowTime
					,	m.homeid
					,	m.awayid
					,	m.leagueid
					,	m.sporttype
					,	b.bettype
					,	b.custid
					,	b.betteam
					,	b.betid
					,	b.stake * b.actualrate 
					,	b.stake
					,	b.odds
					,	b.hdp1
					,	b.hdp2
					,	b.livehomescore
					,	b.liveawayscore
					,	b.statusID
					,	b.liveindicator
					,	b.CurrencyName
					,	b.currency
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
				,	t.CustomerClass	= c.CustomerClass
			FROM #tmpTickets AS t
				INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON t.LeagueId = l.leagueid
				INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid;
		END;	
	ELSE IF (@QueryType = 3)
		BEGIN
			IF (@BatchSize = 0)
				BEGIN
					INSERT INTO #tmpTickets(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp)
					SELECT b.sequenceid
						,	b.transid
						,	b.transdate
						,	b.matchid
						,	m.eventdate
						,	m.Eventstatus
						,	m.GlobalShowTime
						,	m.homeid
						,	m.awayid
						,	m.leagueid
						,	m.sporttype
						,	b.bettype
						,	b.custid
						,	b.betteam
						,	b.betid
						,	b.stake * b.actualrate 
						,	b.stake
						,	b.odds
						,	b.hdp1
						,	b.hdp2
						,	b.livehomescore
						,	b.liveawayscore
						,	b.statusID
						,	b.liveindicator
						,	b.CurrencyName
						,	b.currency
						,	ABS(CASE WHEN @BetType IN (3,8,610)	THEN Hdp1
								 ELSE (CASE	WHEN BetTeam = 'h'	THEN (Hdp2 - Hdp1)
											WHEN BetTeam = 'a'	THEN (Hdp1 - Hdp2)
										END)
								 END)
					FROM dbo.bettrans AS b WITH(NOLOCK, INDEX=IX_sequenceid)
						INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
						LEFT JOIN #tmpTransIds AS t ON t.TransId = b.TransId
					WHERE	b.matchid = @MatchID
						AND b.liveindicator = @IsLive
						AND b.bettype = @BetType
						AND b.sequenceid < @LastScannedSequenceID
						AND t.TransId IS NULL;
				END
			ELSE 
				BEGIN
					INSERT INTO #tmpTickets(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp)
					SELECT TOP (@BatchSize) b.sequenceid
						,	b.transid
						,	b.transdate
						,	b.matchid
						,	m.eventdate
						,	m.Eventstatus
						,	m.GlobalShowTime
						,	m.homeid
						,	m.awayid
						,	m.leagueid
						,	m.sporttype
						,	b.bettype
						,	b.custid
						,	b.betteam
						,	b.betid
						,	b.stake * b.actualrate 
						,	b.stake
						,	b.odds
						,	b.hdp1
						,	b.hdp2
						,	b.livehomescore
						,	b.liveawayscore
						,	b.statusID
						,	b.liveindicator
						,	b.CurrencyName
						,	b.currency
						,	ABS(CASE WHEN @BetType IN (3,8,610)	THEN Hdp1
								 ELSE (CASE	WHEN BetTeam = 'h'	THEN (Hdp2 - Hdp1)
											WHEN BetTeam = 'a'	THEN (Hdp1 - Hdp2)
										END)
								 END)
					FROM dbo.bettrans AS b WITH(NOLOCK, INDEX=IX_sequenceid)
						INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
					WHERE	b.matchid = @MatchID
						AND b.liveindicator = @IsLive
						AND b.bettype = @BetType
						AND b.sequenceid < @LastScannedSequenceID
					ORDER BY b.sequenceid DESC;

					SET @MinSequenceIDTotalAll = (SELECT MIN(SequenceId) FROM #tmpTickets);
				END;

			UPDATE t WITH(ROWLOCK, UPDLOCK)
			SET t.IsLicensee = 1
			FROM #tmpTickets AS t
				INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
				INNER JOIN dbo.Dep_CustSuper AS cs WITH (NOLOCK) ON cs.custid = c.srecommend;

			UPDATE t WITH(ROWLOCK, UPDLOCK)
			SET t.IsLicensee = 0
			FROM #tmpTickets AS t
				INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
				INNER JOIN dbo.CustProductStatus AS s WITH (NOLOCK) ON s.custid = c.custid
			WHERE t.IsLicensee IS NULL;

			IF (@IsLicensee IS NOT NULL)
			BEGIN
				DELETE t
				FROM #tmpTickets AS t
				WHERE t.IsLicensee != @IsLicensee;
			END;

			IF (@FromStakeRM IS NOT NULL AND @ToStakeRM IS NOT NULL)
			BEGIN
				DELETE t
				FROM #tmpTickets AS t
				WHERE t.Stake < @FromStakeRM
					OR t.Stake > @ToStakeRM;
			END;

			IF (@ListCurrency IS NOT NULL)
			BEGIN
				INSERT INTO #tmpSupportedCurrency (CurrencyId)
				SELECT ssk.val 
				FROM dbo.f_SplitString(@ListCurrency, ',') AS ssk;

				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpSupportedCurrency AS curr ON curr.CurrencyId = t.CurrencyId
				WHERE curr.CurrencyId IS NULL;
			END;

			IF (@ListScore IS NOT NULL)
			BEGIN
				INSERT INTO #tmpSupportedScore (LiveHomeScore,LiveAwayScore)
				SELECT cas.LiveHomeScore, cas.LiveAwayScore
				FROM dbo.f_SplitString(@ListScore, ',') AS ssk
					CROSS APPLY (SELECT	LiveHomeScore = xDim.value('/x[1]','varchar(max)')
									,	LiveAwayScore = xDim.value('/x[2]','varchar(max)')
								From (SELECT CAST('<x>' + REPLACE(REPLACE(ssk.val,'-',''),'  ','</x><x>')+'</x>' AS XML) AS xDim) AS s
								) AS cas;

				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpSupportedScore AS s ON s.LiveHomeScore = t.LiveHomeScore AND s.LiveAwayScore = t.LiveAwayScore
				WHERE s.LiveHomeScore IS NULL;
			END;

			IF (@ListHDP IS NOT NULL)
			BEGIN
				INSERT INTO #tmpSupportedHDP (Hdp)
				SELECT ssk.val 
				FROM dbo.f_SplitString(@ListHDP, ',') AS ssk;

				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpSupportedHDP AS h ON h.Hdp = t.Hdp
				WHERE h.Hdp IS NULL;
			END;

			UPDATE	t WITH(ROWLOCK, UPDLOCK)
			SET		t.Danger1		= c.danger
				,	t.Danger2		= c.danger2
				,	t.Danger3		= c.danger3
				,	t.Danger4		= c.Danger4
				,	t.Danger5		= c.Danger5
				,	t.LeagueName	= l.leaguename
				,	t.CustomerClass	= c.CustomerClass
			FROM #tmpTickets AS t
				INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON t.LeagueId = l.leagueid
				INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid;
		END;

	-- Return data
	IF (@QueryType = 3 AND @BatchSize = 0)
		BEGIN
			SET @MinSequenceIDTotalAll = (SELECT COUNT(1) FROM #tmpTickets);
		END
	ELSE
		BEGIN
			SELECT	*
			FROM #tmpTickets AS m WITH(NOLOCK);
		END;
	
	DROP TABLE IF EXISTS #tmpTransIds;
	DROP TABLE IF EXISTS #tmpTickets;
	DROP TABLE IF EXISTS #tmpSupportedSportBettype;
	DROP TABLE IF EXISTS #tmpSupportedCurrency;
	DROP TABLE IF EXISTS #tmpSupportedHDP;
	DROP TABLE IF EXISTS #tmpSupportedScore;

END;

GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/