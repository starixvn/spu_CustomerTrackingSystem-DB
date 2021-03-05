CREATE PROCEDURE [dbo].[CTS_Rpt_BettingPattern_TicketDetails]
		@EventDate			DATETIME
	,	@CustIds			VARCHAR(200)  = ''
	,	@MatchId			INT
	,	@Bettypes			VARCHAR(2000) = ''

AS
/*
	Created: 20210304@John.Ngo
	Task : Match List Betting Pattern - Match Details
	DB	 : bodb_FraudSensor

	Revisions:
		- 20210304@John.Ngo: Display betting pattern details [Redmine ID: #151156]

	Params Explaination:
		EXECUTE [dbo].[CTS_Rpt_BettingPattern_TicketDetails] @EventDate = '2021-02-23 00:00:00.000',@CustIds = '46777100,47717138',	@MatchId = 40391219, @Bettypes = '1,3'
*/
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @BalanceUpDay			SMALLDATETIME
		,	@MoveBetsDay			SMALLDATETIME;

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

	IF	OBJECT_ID('tempdb..#tmpCustIds') IS NOT NULL
	BEGIN
		DROP TABLE #tmpCustIds;
	END;

	CREATE TABLE #tmpCustIds(
			CustId				INT NOT NULL PRIMARY KEY
	);

	IF	OBJECT_ID('tempdb..#tmpBettypes') IS NOT NULL
	BEGIN
		DROP TABLE #tmpBettypes;
	END;

	CREATE TABLE #tmpBettypes(
			BettypeId			INT NOT NULL PRIMARY KEY
	);

	IF	OBJECT_ID('tempdb..#tmpMatchDetails') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatchDetails;
	END;

	CREATE TABLE	#tmpMatchDetails(
			CustId				INT
		,	MatchId				INT
		,	EventDate			DATETIME
		,	TransDate			DATETIME
		,	TransId				BIGINT
		,	BetType				SMALLINT
		,	BetTeam				NVARCHAR(10)
		,	Stake				MONEY
		,	Odds				SMALLMONEY
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
	);	
	
	CREATE CLUSTERED INDEX #CIX_tmpMatchDetailsIdx ON #tmpMatchDetails (
			EventDate			DESC
	);
	
	IF @CustIds <> ''
	BEGIN
		INSERT INTO #tmpCustIds (CustId)
		SELECT ssk.val FROM dbo.SPU_StrSplit(@CustIds, ',') ssk;
	END;

	IF @Bettypes <> ''
	BEGIN
		INSERT INTO #tmpBettypes (BettypeId)
		SELECT ssk.val FROM dbo.SPU_StrSplit(@Bettypes, ',') ssk;
	END;

	-- START --
	IF @IsGetDataFromBK = 1
	BEGIN
		INSERT INTO #tmpMatchDetails(	
				CustId
			,	MatchId
			,	EventDate
			,	TransDate
			,	TransId
			,	BetType
			,	BetTeam
			,	Stake
			,	Odds
			,	LiveHomeScore
			,	LiveAwayScore)
		SELECT	b.custid
			,	b.matchid
			,	b.winlostdate
			,	b.transdate
			,	b.transid
			,	b.bettype
			,	b.betteam
			,	b.stake
			,	b.odds
			,	b.livehomescore
			,	b.liveawayscore
		FROM bodb_Archive.dbo.bettrans_bk AS b WITH(NOLOCK)
			LEFT JOIN #tmpCustIds AS tc WITH(NOLOCK) ON tc.CustId = b.custid
			LEFT JOIN #tmpBettypes AS tbt WITH(NOLOCK) ON tbt.BettypeId = b.bettype
		WHERE	b.winlostdate = @EventDate
			AND b.matchid = @MatchId
			AND (@CustIds = '' OR tc.CustId IS NOT NULL)
			AND (@Bettypes = '' OR tbt.BettypeId IS NOT NULL);
	END;

	IF	@IsGetDataFrom14 = 1
	BEGIN
		INSERT INTO #tmpMatchDetails(	
				CustId
			,	MatchId
			,	EventDate
			,	TransDate
			,	TransId
			,	BetType
			,	BetTeam
			,	Stake
			,	Odds
			,	LiveHomeScore
			,	LiveAwayScore)
		SELECT	b.custid
			,	b.matchid
			,	b.winlostdate
			,	b.transdate
			,	b.transid
			,	b.bettype
			,	b.betteam
			,	b.stake
			,	b.odds
			,	b.livehomescore
			,	b.liveawayscore
		FROM bodb02.dbo.bettrans14 AS b WITH(NOLOCK)
			LEFT JOIN #tmpCustIds AS tc WITH(NOLOCK) ON tc.CustId = b.custid
			LEFT JOIN #tmpBettypes AS tbt WITH(NOLOCK) ON tbt.BettypeId = b.bettype
		WHERE	b.winlostdate = @EventDate
			AND b.matchid = @MatchId
			AND (@CustIds = '' OR tc.CustId IS NOT NULL)
			AND (@Bettypes = '' OR tbt.BettypeId IS NOT NULL);
	END;

	IF	@IsGetDataFromOrigin = 1
	BEGIN
		INSERT INTO #tmpMatchDetails(	
				CustId
			,	MatchId
			,	EventDate
			,	TransDate
			,	TransId
			,	BetType
			,	BetTeam
			,	Stake
			,	Odds
			,	LiveHomeScore
			,	LiveAwayScore)
		SELECT	b.custid
			,	b.matchid
			,	b.winlostdate
			,	b.transdate
			,	b.transid
			,	b.bettype
			,	b.betteam
			,	b.stake
			,	b.odds
			,	b.livehomescore
			,	b.liveawayscore
		FROM bodb02.dbo.bettrans AS b WITH(NOLOCK)
			LEFT JOIN #tmpCustIds AS tc WITH(NOLOCK) ON tc.CustId = b.custid
			LEFT JOIN #tmpBettypes AS tbt WITH(NOLOCK) ON tbt.BettypeId = b.bettype
		WHERE	b.winlostdate = @EventDate
			AND b.matchid = @MatchId
			AND (@CustIds = '' OR tc.CustId IS NOT NULL)
			AND (@Bettypes = '' OR tbt.BettypeId IS NOT NULL);
	END;

	-- Return data
	SELECT	c.username AS UserName
		,	m.TransDate
		,	m.TransId
		,	bt.typenamee AS TypeName
		,	m.BetTeam
		,	m.Stake
		,	m.Odds
		,	m.LiveHomeScore
		,	m.LiveAwayScore
	FROM #tmpMatchDetails AS m WITH(NOLOCK)
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON c.custid = m.CustId
		INNER JOIN bodb02.dbo.bettype AS bt WITH(NOLOCK) ON bt.typeid = m.BetType
	ORDER BY m.TransDate DESC;
	
	DROP TABLE #tmpMatchDetails;

END;

GO
/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/