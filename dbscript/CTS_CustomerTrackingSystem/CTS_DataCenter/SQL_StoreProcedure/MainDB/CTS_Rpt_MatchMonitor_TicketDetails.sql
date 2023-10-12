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
	,	@TicketType					TINYINT = 1	
	,	@IsLicensee					BIT = NULL
	,	@IsExclTestCurr				BIT = 0
	,	@ListCurrency				VARCHAR(MAX) = NULL
	,	@ListHDPBetTeam				VARCHAR(MAX) = NULL
	,	@ListScore					VARCHAR(MAX) = NULL
	,	@CustAmountRM				MONEY = 0
	,	@BetID						BIGINT = 0
	,	@ListDanger					VARCHAR(MAX) = NULL
	,	@ListStatus					VARCHAR(50) = NULL
	,	@ListCustomerClass			VARCHAR(MAX) = NULL	
	,	@ListReason					VARCHAR(MAX) = NULL
	,	@ListAGroup					VARCHAR(MAX) = NULL
	,	@ListMGroup					VARCHAR(MAX) = NULL
	,	@MinSequenceId				BIGINT = NULL OUTPUT
	,	@TotalTicket				INT = NULL OUTPUT

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
		- 20230721@Victoria.Le	Get CurrencyName from table Exchange [Redmine ID: #191422]
		- 20230724@Victoria.Le	Add condition BetID with BetType = Quarter X HDP/OU/MoneyLine [Redmine ID: #191703]
		- 20230724@Victoria.Le	Using STRING_SPLIT instead of dbo.f_SplitString
								Show all tickets - Add Filter by Danger and Status [Redmine ID: #191401]
		- 20230911@Casey.Huynh:	Filter by CustomerClass, TotalAmount, Reason, AGroup, MGroup [Redmine ID: #193029]
		- 20231009@Casey.Huynh: Fixed Sum CustAmount [Redmine ID: #195204]
		- 20231010@Casey.Huynh: Fixed Filter Trans With Multi Reason [Redmine ID: #195204]

	Params Explaination:
		- @QueryType: 1 - to run service (get tickets by @LastScannedTransID, @IsLive & @BatchSize)
					  2 - to show on report (get tickets by @EventDate & @ListTransId)
					  3	- to show on report (get all tickets by @MatchID, @BetType, @IsLive, @LastScannedSequenceID, @BatchSize, @IsLicensee, @ListCurrency, 
																@ListHDPBetTeam, @ListScore, @CustAmountRM, @ListDanger, @ListStatus, @ListCustomerClass)
							+ @BatchSize = 0 ==> @MinSequenceId: Total tickets
							+ @BatchSize > 0 ==> @MinSequenceId: Min SequenceId
							+ @BatchSize = 0 & @ListExclTransId <> '' & @ListTransId ==> get total tickets (By @ListTransId) AND (excluded  @ListExclTransId)
		- @ListDanger: format JSON
			SET @ListDanger = '[{"Danger1":10},{"Danger1":17},{"Danger1":28},{"Danger2":28},{"Danger2":6},{"Danger2":12},{"Danger3":48}]'

		- @ListStatus: List StatusID
			SET @ListStatus = '111,113,103,101,0,102,112,1,131' --Draw: 111;Lose: 113;Refund: 103;Reject: 101;Running: 0;Void: 102;Won:112;Waiting: 1;Completed: 131
		- @BetType:
			+ @QueryType: 1&2 - Soccer: 1,3,7,8 / Basketball: 1,3,7,8,20,609,610,612 / E-Sports: 1,3,20
						  3 - Soccer: 1,3,7,8,2,12,413,414,6,126 / Basketball: 1,3,7,8,20,609,610,612 / E-Sports: 1,3,20	
		- @ListHDPBetTeam:
			+ @BetType IN (3,8,610) - then ABS(Hdp1)
			+ @BetType IN (1,7,20,609,612,2,12) - if BetTeam = 'h' then ABS(Hdp2 - Hdp1) else BetTeam = 'a' then ABS(Hdp1 - Hdp2) 
			+ @BetType IN (413,414,6,126) - then BetTeam

		- @ListCustomerClass: format VARCHAR(MAX)
		     SET = '200,201,2201'
			
	Example:
		DECLARE @MinTotal BIGINT;
		EXEC [dbo].[CTS_Rpt_MatchMonitor_TicketDetails] @QueryType = 3,@LastScannedSequenceID = 117286612760,@IsLive = 1,@BatchSize = 4000,@MatchID = 70099921,@BetType = 1, 
		@IsLicensee = 1, @ListCurrency = '1',@ListHDPBetTeam = '0.18,0.17',@ListScore = '0 - 0, 3 - 3',@CustAmountRM = NULL,@MinSequenceId = @MinTotal OUTPUT;
		SELECT @MinTotal;
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @BalanceUpDay			SMALLDATETIME
		,	@MoveBetsDay			SMALLDATETIME
		,	@IsGetDataFromOrigin	BIT = 0
		,	@IsGetDataFrom14		BIT = 0
		,	@IsGetDataFromBK		BIT = 0;

	--==================================================================
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
		,	BetFrom				NVARCHAR(4)
		,	Reason				VARCHAR(50) DEFAULT '0'
		,	ListReason			VARCHAR(MAX)
		,	AGroup				INT  DEFAULT 0
		,	MGroup				INT  DEFAULT 0
	);	

	CREATE CLUSTERED INDEX #CIX_tmpTickets_CustId ON #tmpTickets (
			CustId			DESC
	);

	CREATE NONCLUSTERED INDEX #IX_tmpTickets_IsLicensee ON #tmpTickets (
			IsLicensee		ASC
	);

	CREATE NONCLUSTERED INDEX #IX_tmpTickets_Score ON #tmpTickets (
			LiveHomeScore		ASC
		,	LiveAwayScore		ASC
	);
	
	IF	OBJECT_ID('tempdb..#tmpBUMBData') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpBUMBData;
	END;

	CREATE TABLE	#tmpBUMBData (
			BUDay	SMALLDATETIME
		,	MBDay	SMALLDATETIME
	);
	
	IF	OBJECT_ID('tempdb..#tmpTransIds') IS NOT NULL
	BEGIN
		DROP TABLE #tmpTransIds;
	END;

	CREATE TABLE #tmpTransIds(
			TransId		BIGINT NOT NULL 
		,	Reason		VARCHAR(50) DEFAULT '0'
		,	AGroup		INT
		,	MGroup		INT
	);

	CREATE CLUSTERED INDEX #CIX_tmpCustAmount_CustID ON #tmpTransIds (
			TransId	ASC
		,	Reason	ASC
	);


	IF	OBJECT_ID('tempdb..#tmpSupportedSportBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedSportBettype;
	END;

	CREATE TABLE	#tmpSupportedSportBettype(
			SportType				SMALLINT
		,	BetType					SMALLINT
		,	IsFilterBetID			BIT
		,	IsDetectMatchMonitor	BIT
		,	IsFilterBetTeam			BIT
		,	IsFilterHdp				BIT
		,	IsOnlyGetHdp1			BIT
	);
	
	CREATE INDEX IX_tmpSupportedSportBettype_SportTypeBetType ON #tmpSupportedSportBettype(SportType, BetType);

	IF	OBJECT_ID('tempdb..#tmpSupportedCurrency') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedCurrency;
	END;

	CREATE TABLE	#tmpSupportedCurrency(
			CurrencyId			TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpSupportedReason') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedReason;
	END;

	CREATE TABLE	#tmpSupportedReason(
			Reason		VARCHAR(50) DEFAULT '0' PRIMARY KEY 
	);


	IF	OBJECT_ID('tempdb..#tmpSupportedMGroup') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedMGroup;
	END;

	CREATE TABLE	#tmpSupportedMGroup(
			MGroup		INT PRIMARY KEY 
	);

	IF	OBJECT_ID('tempdb..#tmpSupportedAGroup') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedAGroup;
	END;

	CREATE TABLE	#tmpSupportedAGroup(
			AGroup		INT PRIMARY KEY 
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

	IF	OBJECT_ID('tempdb..#tmpSupportedBetTeam') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedBetTeam;
	END;

	CREATE TABLE	#tmpSupportedBetTeam(
			BetTeam				NVARCHAR(10)
	);

	IF	OBJECT_ID('tempdb..#tmpSupportedStatus') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedStatus;
	END;

	CREATE TABLE	#tmpSupportedStatus(
			StatusID			TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpSupportedDanger') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedDanger;
	END;

	CREATE TABLE	#tmpSupportedDanger(
			Danger1				TINYINT 
		,	Danger2				TINYINT 
		,	Danger3				TINYINT
		,	Danger4				TINYINT
		,	Danger5				TINYINT 
	);

	IF	OBJECT_ID('tempdb..#tmpCustomerClass') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomerClass;
	END;

	CREATE TABLE	#tmpCustomerClass(
			CustomerClass		SMALLINT PRIMARY KEY 
	);

	IF	OBJECT_ID('tempdb..#tmpCustAmount') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustAmount;
	END;

	CREATE TABLE	#tmpCustAmount(
			CustId		INT
		,	BetTeam		NVARCHAR(10)
	);

	CREATE CLUSTERED INDEX #CIX_tmpCustAmount_CustIDBetTeam ON #tmpCustAmount (
			CustID	ASC
		,	BetTeam ASC
	);

	IF	OBJECT_ID('tempdb..#tmpTransIdReason') IS NOT NULL
				BEGIN
					DROP TABLE #tmpTransIdReason;
				END;

				CREATE TABLE #tmpTransIdReason(
						TransId			BIGINT NOT NULL PRIMARY KEY
					,	ListReason		VARCHAR(MAX)
					,	MinReason		VARCHAR(50) DEFAULT '0'	
				);

	--=======GET BALANCE UP/ MOVE BET DAY===========================================================
	INSERT INTO #tmpBUMBData(BUDay,MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;

	SELECT	TOP(1)
			@BalanceUpDay	= BUDay
		,	@MoveBetsDay	= MBDay
	FROM #tmpBUMBData WITH(NOLOCK);

	IF @EventDate < @BalanceUpDay
	BEGIN
		SELECT @IsGetDataFromBK = 1;
	END
	ELSE IF @EventDate <= @MoveBetsDay
	BEGIN
		SELECT @IsGetDataFrom14 = 1;
	END
	ELSE
	BEGIN
		SELECT @IsGetDataFromOrigin = 1;
	END;

	--==================================================================
	-- Soccer
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType,IsDetectMatchMonitor,IsFilterBetID,IsFilterBetTeam,IsFilterHdp,IsOnlyGetHdp1)
	VALUES	(1,1,1,0,0,1,0)
		,	(1,3,1,0,0,1,1)
		,	(1,7,1,0,0,1,0)
		,	(1,8,1,0,0,1,1)
		,	(1,2,0,0,0,1,0)
		,	(1,12,0,0,0,1,0)
		,	(1,413,0,0,1,0,0)
		,	(1,414,0,0,1,0,0)
		,	(1,6,0,0,1,0,0)
		,	(1,126,0,0,1,0,0)
		,	(1,5,0,0,1,0,0)
		,	(1,15,0,0,1,0,0)
	;
	-- Basketball
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType,IsDetectMatchMonitor,IsFilterBetID,IsFilterBetTeam,IsFilterHdp,IsOnlyGetHdp1)
	VALUES	(2,1,1,0,0,1,0)
		,	(2,3,1,0,0,1,1)
		,	(2,7,1,0,0,1,0)
		,	(2,8,1,0,0,1,1)
		,	(2,20,1,0,0,1,0)
		,	(2,609,1,1,0,1,0)
		,	(2,610,1,1,0,1,1)
		,	(2,612,1,1,0,1,0)
	;
	-- E-Sports
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType,IsDetectMatchMonitor,IsFilterBetID,IsFilterBetTeam,IsFilterHdp,IsOnlyGetHdp1)
	VALUES	(43,1,1,0,0,1,0)
		,	(43,3,1,0,0,1,1)
		,	(43,20,1,0,0,1,0)
	;

	--==========================================================================================

	IF @ListTransId <> ''
		BEGIN
			INSERT INTO #tmpTransIds (TransID,Reason,AGroup,MGroup)
			SELECT	ISNULL(JSON_VALUE(ssk.value, '$.TransID'),0) AS TransID
				,	ISNULL(JSON_VALUE(ssk.value, '$.Reason'),'0') AS Reason
				,	ISNULL(JSON_VALUE(ssk.value, '$.AGroup'),0) AS AGroup
				,	ISNULL(JSON_VALUE(ssk.value, '$.MGroup'),0) AS MGroup
			FROM OPENJSON (@ListTransId) AS ssk;
		END;

	IF (@QueryType = 1)
		BEGIN --Get ticket for MM Detection
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
				INNER JOIN #tmpSupportedSportBettype AS t WITH(NOLOCK) ON m.sporttype = t.SportType AND b.bettype = t.BetType AND t.IsDetectMatchMonitor = 1
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
		END;
	IF (@QueryType = 2)
		BEGIN --Get Ticket for MM Details Report 
			----==================GET Trans==================
			IF @IsGetDataFromBK = 1
			BEGIN
				IF (@ListTransId <> '' AND @TicketType = 1) 
				BEGIN
					INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup)
					SELECT 
							b.transid
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
						,	ABS(CASE WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 1 THEN	b.Hdp1
										WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 0 THEN  (CASE WHEN b.BetTeam = 'h'	THEN (b.Hdp2 - b.Hdp1)
																									WHEN b.BetTeam = 'a'	THEN (b.Hdp1 - b.Hdp2) END) END)
						,	b.BetFrom
						,	ISNULL(tmpTs.Reason,'0')
						,	ISNULL(tmpTs.AGroup,0)
						,	ISNULL(tmpTs.MGroup,0)
					FROM #tmpTransIds AS tmpTs WITH(NOLOCK)
						INNER JOIN bodb_Archive.dbo.bettrans_bk AS b WITH(NOLOCK) ON b.TransId = tmpTs.TransId
						INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON b.matchid = m.matchid
						INNER JOIN #tmpSupportedSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportType AND b.bettype = st.BetType 
						INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
					;
				END;
			END;

			IF	@IsGetDataFrom14 = 1
			BEGIN
				IF (@ListTransId <> '' AND @TicketType = 1) 
				BEGIN
					INSERT INTO #tmpTickets(TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup)
					SELECT 
							b.transid
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
						,	ABS(CASE WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 1 THEN	b.Hdp1
										WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 0 THEN  (CASE WHEN b.BetTeam = 'h'	THEN (b.Hdp2 - b.Hdp1)
																									WHEN b.BetTeam = 'a'	THEN (b.Hdp1 - b.Hdp2) END) END)
						,	b.BetFrom
						,	ISNULL(tmpTs.Reason,'0')
						,	ISNULL(tmpTs.AGroup,0)
						,	ISNULL(tmpTs.MGroup,0)
					FROM #tmpTransIds AS tmpTs WITH(NOLOCK)
						INNER JOIN dbo.bettrans14 AS b WITH(NOLOCK) ON b.TransId = tmpTs.TransId
						INNER JOIN dbo.match14 AS m WITH(NOLOCK) ON b.matchid = m.matchid
						INNER JOIN #tmpSupportedSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportType AND b.bettype = st.BetType 
						INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
					;
				END;
			END;

			IF	@IsGetDataFromOrigin = 1
			BEGIN
				IF (@ListTransId <> '' AND @TicketType = 1) 
				BEGIN
					INSERT INTO #tmpTickets(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup)
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
						,	e.currency
						,	e.ExchangeId
						,	ABS(CASE WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 1 THEN	b.Hdp1
										WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 0 THEN  (CASE WHEN b.BetTeam = 'h'	THEN (b.Hdp2 - b.Hdp1)
																									WHEN b.BetTeam = 'a'	THEN (b.Hdp1 - b.Hdp2) END) END)
						,	b.BetFrom
						,	ISNULL(tmpTs.Reason,'0')
						,	ISNULL(tmpTs.AGroup,0)
						,	ISNULL(tmpTs.MGroup,0)
					FROM #tmpTransIds AS tmpTs WITH(NOLOCK)
						INNER JOIN dbo.bettrans AS b WITH(NOLOCK) ON b.TransId = tmpTs.TransId
						INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
						INNER JOIN #tmpSupportedSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportType AND b.bettype = st.BetType 
						INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
					;
				END
				ELSE IF (@TicketType = 0)
				BEGIN	
					IF (@CustAmountRM > 0) 
					BEGIN	

						INSERT INTO #tmpTickets(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup)
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
								,	e.currency
								,	e.ExchangeId
								,	ABS(CASE WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 1 THEN	b.Hdp1
											 WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 0 THEN  (CASE WHEN b.BetTeam = 'h'	THEN (b.Hdp2 - b.Hdp1)
																										  WHEN b.BetTeam = 'a'	THEN (b.Hdp1 - b.Hdp2) END) END)
								,	b.BetFrom
							,	ISNULL(tmpTs.Reason,'0')
							,	ISNULL(tmpTs.AGroup,0)
							,	ISNULL(tmpTs.MGroup,0)
							FROM dbo.bettrans AS b WITH(NOLOCK, INDEX=IX_sequenceid)
								INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
								INNER JOIN #tmpSupportedSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportType AND b.bettype = st.BetType 
								INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency	
								LEFT JOIN #tmpTransIds AS tmpTs WITH(NOLOCK) ON b.TransId = tmpTs.TransId
							WHERE	b.matchid = @MatchID								
								AND b.liveindicator = @IsLive
								AND b.bettype = @BetType
								AND b.sequenceid < @LastScannedSequenceID
								AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
								AND (@BetID = 0 OR (@BetID > 0 AND st.IsFilterBetID = 1 AND b.betid = @BetID));
				
					END;

					IF (@CustAmountRM <= 0) 
					BEGIN
						IF (@BatchSize = 0) ---GET TotalTicket
						BEGIN

							INSERT INTO #tmpTickets(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup)
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
								,	e.currency
								,	e.ExchangeId
								,	ABS(CASE WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 1 THEN	b.Hdp1
											 WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 0 THEN  (CASE WHEN b.BetTeam = 'h'	THEN (b.Hdp2 - b.Hdp1)
																										  WHEN b.BetTeam = 'a'	THEN (b.Hdp1 - b.Hdp2) END) END)
								,	b.BetFrom
							,	ISNULL(tmpTs.Reason,'0')
							,	ISNULL(tmpTs.AGroup,0)
							,	ISNULL(tmpTs.MGroup,0)
							FROM dbo.bettrans AS b WITH(NOLOCK, INDEX=IX_sequenceid)
								INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
								INNER JOIN #tmpSupportedSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportType AND b.bettype = st.BetType 
								INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
								LEFT JOIN #tmpTransIds AS tmpTs WITH(NOLOCK) ON b.TransId = tmpTs.TransId
							WHERE	b.matchid = @MatchID								
								AND b.liveindicator = @IsLive
								AND b.bettype = @BetType
								AND b.sequenceid < @LastScannedSequenceID
								AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
								AND (@BetID = 0 OR (@BetID > 0 AND st.IsFilterBetID = 1 AND b.betid = @BetID));
							
						END
						ELSE IF (@BatchSize > 0) --- GET Ticket Details 
						BEGIN
							INSERT INTO #tmpTickets(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,KickOffTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetTeam,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup)
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
								,	e.currency
								,	e.ExchangeId
								,	ABS(CASE WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 1 THEN	b.Hdp1
											 WHEN st.IsFilterHdp = 1 AND st.IsOnlyGetHdp1 = 0 THEN  (CASE WHEN b.BetTeam = 'h'	THEN (b.Hdp2 - b.Hdp1)
																										  WHEN b.BetTeam = 'a'	THEN (b.Hdp1 - b.Hdp2)
																									END)
										 END)
								,	b.BetFrom							
							,	ISNULL(tmpTs.Reason,'0')
							,	ISNULL(tmpTs.AGroup,0)
							,	ISNULL(tmpTs.MGroup,0)
							FROM dbo.bettrans AS b WITH(NOLOCK, INDEX=IX_sequenceid)
								INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
								INNER JOIN dbo.league AS l WITH(NOLOCK) ON l.leagueid = m.leagueid
								INNER JOIN #tmpSupportedSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportType AND b.bettype = st.BetType 
								INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
								LEFT JOIN #tmpTransIds AS tmpTs WITH(NOLOCK) ON b.TransId = tmpTs.TransId
							WHERE	b.matchid = @MatchID
								AND b.liveindicator = @IsLive
								AND b.bettype = @BetType
								AND b.sequenceid < @LastScannedSequenceID
								AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
								AND (@BetID = 0 OR (@BetID > 0 AND st.IsFilterBetID = 1 AND b.betid = @BetID))
							ORDER BY b.sequenceid DESC;

							SET @MinSequenceId = (SELECT MIN(SequenceId) FROM #tmpTickets);


						END 
					END;
					
				END;
			END;

			----==================UPDATE Trans Info==================
			UPDATE t WITH(ROWLOCK, UPDLOCK)
			SET t.IsLicensee	= 1
			,	t.Danger1		= c.danger
			,	t.Danger2		= c.danger2
			,	t.Danger3		= c.danger3
			,	t.Danger4		= c.Danger4
			,	t.Danger5		= c.Danger5
			,	t.CustomerClass	= c.CustomerClass
			FROM #tmpTickets AS t
				INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
				INNER JOIN dbo.Dep_CustSuper AS cs WITH (NOLOCK) ON cs.custid = c.srecommend;

			UPDATE t WITH(ROWLOCK, UPDLOCK)
			SET t.IsLicensee	= 0
			,	t.Danger1		= c.danger
			,	t.Danger2		= c.danger2
			,	t.Danger3		= c.danger3
			,	t.Danger4		= c.Danger4
			,	t.Danger5		= c.Danger5
			,	t.CustomerClass	= c.CustomerClass
			FROM #tmpTickets AS t
				INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
				INNER JOIN dbo.CustProductStatus AS s WITH (NOLOCK) ON s.custid = c.custid
			WHERE t.IsLicensee IS NULL;

			----==================FILTERS=========================		
			
			--====================Fitler By Score==================	
			IF (@ListScore IS NOT NULL)
			BEGIN
				INSERT INTO #tmpSupportedScore (LiveHomeScore,LiveAwayScore)
				SELECT cas.LiveHomeScore, cas.LiveAwayScore
				FROM STRING_SPLIT(@ListScore, ',') ssk
					CROSS APPLY (SELECT	LiveHomeScore = xDim.value('/x[1]','varchar(max)')
									,	LiveAwayScore = xDim.value('/x[2]','varchar(max)')
								From (SELECT CAST('<x>' + REPLACE(REPLACE(ssk.value,'-',''),'  ','</x><x>')+'</x>' AS XML) AS xDim) AS s
								) AS cas;

				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpSupportedScore AS s ON s.LiveHomeScore = t.LiveHomeScore AND s.LiveAwayScore = t.LiveAwayScore
				WHERE s.LiveHomeScore IS NULL;
			END;
			
			--========================Fitler By Site(IsLicensee)==================
			IF (@IsLicensee IS NOT NULL)
			BEGIN
				DELETE t
				FROM #tmpTickets AS t
				WHERE t.IsLicensee != @IsLicensee;
			END;
			
			--========================Fitler By CustomerClass==================
			IF @ListCustomerClass <> ''
			BEGIN
				INSERT INTO #tmpCustomerClass (CustomerClass)
				SELECT ssk.value FROM STRING_SPLIT(@ListCustomerClass, ',') ssk;

				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpCustomerClass AS c ON c.CustomerClass = ISNULL(t.CustomerClass,0)
				WHERE c.CustomerClass IS NULL;
			END;

			--========================Fitler By Danger==================		
			IF (@ListDanger IS NOT NULL)
			BEGIN
				INSERT INTO #tmpSupportedDanger (Danger1,Danger2,Danger3,Danger4,Danger5)
				SELECT	ISNULL(JSON_VALUE(ssk.value, '$.Danger1'),0) AS Danger1
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger2'),0) AS Danger2
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger3'),0) AS Danger3
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger4'),0) AS Danger4
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger5'),0) AS Danger5
				FROM OPENJSON (@ListDanger) AS ssk;
				
				IF NOT EXISTS (SELECT 1 FROM #tmpSupportedDanger AS t WHERE t.Danger1 = 0 AND t.Danger2 = 0 AND t.Danger3 = 0 AND t.Danger4 = 0 AND t.Danger5 = 0)
				BEGIN
					DELETE t
					FROM #tmpTickets AS t
						LEFT JOIN #tmpSupportedDanger AS d1 ON d1.Danger1 = t.Danger1 AND t.Danger1 > 0
						LEFT JOIN #tmpSupportedDanger AS d2 ON d2.Danger2 = t.Danger2 AND t.Danger2 > 0
						LEFT JOIN #tmpSupportedDanger AS d3 ON d3.Danger3 = t.Danger3 AND t.Danger3 > 0
						LEFT JOIN #tmpSupportedDanger AS d4 ON d4.Danger4 = t.Danger4 AND t.Danger4 > 0
						LEFT JOIN #tmpSupportedDanger AS d5 ON d5.Danger5 = t.Danger5 AND t.Danger5 > 0
					WHERE d1.Danger1 IS NULL 
						AND d2.Danger2 IS NULL 
						AND d3.Danger3 IS NULL
						AND d4.Danger4 IS NULL
						AND d5.Danger5 IS NULL;
				END
				ELSE
				BEGIN
					DELETE t
					FROM #tmpTickets AS t
						LEFT JOIN #tmpSupportedDanger AS d1 ON d1.Danger1 = t.Danger1 AND t.Danger1 > 0
						LEFT JOIN #tmpSupportedDanger AS d2 ON d2.Danger2 = t.Danger2 AND t.Danger2 > 0
						LEFT JOIN #tmpSupportedDanger AS d3 ON d3.Danger3 = t.Danger3 AND t.Danger3 > 0
						LEFT JOIN #tmpSupportedDanger AS d4 ON d4.Danger4 = t.Danger4 AND t.Danger4 > 0
						LEFT JOIN #tmpSupportedDanger AS d5 ON d5.Danger5 = t.Danger5 AND t.Danger5 > 0
					WHERE NOT (t.Danger1 = 0 AND t.Danger2 = 0 AND t.Danger3 = 0 AND t.Danger4 = 0 AND t.Danger5 = 0)
						AND d1.Danger1 IS NULL 
						AND d2.Danger2 IS NULL 
						AND d3.Danger3 IS NULL
						AND d4.Danger4 IS NULL
						AND d5.Danger5 IS NULL;
				END;

			END;
			
			--========================Fitler By Currency==================	
			IF (@ListCurrency IS NOT NULL)
			BEGIN
				INSERT INTO #tmpSupportedCurrency (CurrencyId)
				SELECT ssk.value FROM STRING_SPLIT(@ListCurrency, ',') ssk;

				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpSupportedCurrency AS curr ON curr.CurrencyId = t.CurrencyId
				WHERE curr.CurrencyId IS NULL;
			END;

			--========================Fitler By Reason==================
			IF @ListReason <> ''
			BEGIN
				INSERT INTO #tmpSupportedReason (Reason)
				SELECT ssk.value FROM STRING_SPLIT(@ListReason, ',') ssk;				
				
				--Delete Dup ticket 
				INSERT INTO #tmpTransIdReason(TransID, ListReason, MinReason)
				SELECT	tmpTr.TransID
					,	STRING_AGG(tmpRs.Reason, ',') WITHIN GROUP (ORDER BY tmpRs.Reason) AS Reason
					,	MIN(tmpRs.Reason)
				FROM #tmpTransIds AS tmpTr WITH(NOLOCK)
					LEFT JOIN #tmpSupportedReason AS tmpRs ON tmpRs.Reason = tmpTr.Reason
				GROUP BY TransID;

				UPDATE tmpTk
				SET	tmpTk.ListReason = tmpTr.ListReason
				,	tmpTk.Reason = CASE WHEN tmpTr.MinReason = tmpTk.Reason THEN tmpTr.MinReason ELSE '-1' END
				FROM #tmpTickets AS tmpTk
					INNER JOIN #tmpTransIdReason AS tmpTr ON tmpTk.TransId = tmpTr.TransID
				
				--Delete ticket is not in Reason Filter
				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpSupportedReason AS c ON c.Reason = ISNULL(t.Reason,'0')
				WHERE c.Reason IS NULL;				

			END;

			--========================Fitler By AGroup==================
			IF @ListAGroup <> ''
			BEGIN
				INSERT INTO #tmpSupportedAGroup (AGroup)
				SELECT ssk.value FROM STRING_SPLIT(@ListAGroup, ',') ssk;

				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpSupportedAGroup AS c ON c.AGroup = ISNULL(t.AGroup,0)
				WHERE c.AGroup IS NULL;
			END;

			--========================Fitler By MGroup==================
			IF @ListMGroup <> ''
			BEGIN
				INSERT INTO #tmpSupportedMGroup (MGroup)
				SELECT ssk.value FROM STRING_SPLIT(@ListMGroup, ',') ssk;

				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpSupportedMGroup AS c ON c.MGroup = ISNULL(t.MGroup,0)
				WHERE c.MGroup IS NULL;
			END;

			--========================Fitler By HDP(Betteam)==================	
			IF (@ListHDPBetTeam IS NOT NULL)
			BEGIN
				IF EXISTS (SELECT 1 
							FROM #tmpSupportedSportBettype AS st WITH(NOLOCK) 
							WHERE st.BetType = @BetType AND st.IsFilterBetTeam = 1)
				BEGIN
					INSERT INTO #tmpSupportedBetTeam (BetTeam)
					SELECT ssk.value FROM STRING_SPLIT(@ListHDPBetTeam, ',') ssk;
					
					DELETE t
					FROM #tmpTickets AS t
						LEFT JOIN #tmpSupportedBetTeam AS bt ON bt.BetTeam = t.BetTeam
					WHERE bt.BetTeam IS NULL;
				END
				ELSE
				BEGIN
					INSERT INTO #tmpSupportedHDP (Hdp)
					SELECT ssk.value FROM STRING_SPLIT(@ListHDPBetTeam, ',') ssk;

					DELETE t
					FROM #tmpTickets AS t
						LEFT JOIN #tmpSupportedHDP AS h ON h.Hdp = t.Hdp
					WHERE h.Hdp IS NULL;
				END;
			END;			

			--========================Fitler By Status==================	
			IF (@ListStatus IS NOT NULL)
			BEGIN
				INSERT INTO #tmpSupportedStatus (StatusID)
				SELECT ssk.value FROM STRING_SPLIT(@ListStatus, ',') ssk;
				
				DELETE t
				FROM #tmpTickets AS t
					LEFT JOIN #tmpSupportedStatus AS s ON s.StatusID = t.TicketStatus
				WHERE s.StatusID IS NULL;
			END;		

			--========================Cust Amount(RM)==================	
			IF (@CustAmountRM > 0)
			BEGIN

				INSERT INTO #tmpCustAmount(CustId, BetTeam)
				SELECT	tmpTk.CustId
					,	tmpTk.BetTeam
				FROM #tmpTickets AS tmpTk WITH(NOLOCK)
				GROUP BY tmpTk.CustId, tmpTk.BetTeam
				HAVING SUM(tmpTk.Stake) >= @CustAmountRM;

				DELETE tmpTk
				FROM #tmpTickets AS tmpTk WITH(NOLOCK)
					LEFT JOIN #tmpCustAmount AS tmpCa WITH(NOLOCK) ON tmpCa.CustId = tmpTk.CustId and tmpCa.BetTeam = tmpTk.BetTeam
				WHERE tmpCa.CustId IS NULL;
			END;
		END;	

	--====================RETURN DATA================================================
	IF (@QueryType = 2 AND @BatchSize = 0)
		BEGIN					
			SET @TotalTicket = (SELECT COUNT(1) FROM #tmpTickets);
		END
	ELSE --Return Ticket Details
		BEGIN
			SELECT	tmpTk.SequenceId
				,	tmpTk.TransId
				,	tmpTk.TransDate
				,	tmpTk.MatchId
				,	tmpTk.EventDate
				,	tmpTk.EventStatus
				,	tmpTk.KickOffTime
				,	tmpTk.HomeId
				,	tmpTk.AwayId
				,	tmpTk.LeagueId
				,	tmpTk.LeagueName
				,	tmpTk.IsMajorLeague
				,	tmpTk.SportType
				,	tmpTk.BetType
				,	tmpTk.CustId
				,	tmpTk.BetTeam
				,	tmpTk.BetId
				,	tmpTk.Stake
				,	tmpTk.OrgStake
				,	tmpTk.Odds
				,	tmpTk.Hdp1
				,	tmpTk.Hdp2
				,	tmpTk.LiveHomeScore
				,	tmpTk.LiveAwayScore
				,	tmpTk.LiveIndicator
				,	tmpTk.TicketStatus
				,	tmpTk.Danger1
				,	tmpTk.Danger2
				,	tmpTk.Danger3
				,	tmpTk.Danger4
				,	tmpTk.Danger5
				,	tmpTk.CustomerClass
				,	tmpTk.CurrencyName
				,	tmpTk.CurrencyId
				,	tmpTk.Hdp
				,	tmpTk.IsLicensee
				,	tmpTk.BetFrom
				,	tmpTk.Reason
				,	ISNULL(tmpTk.ListReason,tmpTk.Reason) AS ListReason
				,	tmpTk.AGroup
				,	tmpTk.MGroup
			FROM #tmpTickets AS tmpTk WITH(NOLOCK);
		END;

	DROP TABLE IF EXISTS #tmpTransIds;
	DROP TABLE IF EXISTS #tmpTickets;
	DROP TABLE IF EXISTS #tmpSupportedSportBettype;
	DROP TABLE IF EXISTS #tmpSupportedCurrency;
	DROP TABLE IF EXISTS #tmpSupportedHDP;
	DROP TABLE IF EXISTS #tmpSupportedScore;
	DROP TABLE IF EXISTS #tmpSupportedBetTeam;
	DROP TABLE IF EXISTS #tmpSupportedStatus;
	DROP TABLE IF EXISTS #tmpSupportedDanger;

END;

GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/