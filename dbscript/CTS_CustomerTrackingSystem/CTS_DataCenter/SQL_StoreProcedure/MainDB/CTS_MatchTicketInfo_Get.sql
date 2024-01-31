/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
/*
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
*/
ALTER PROCEDURE [dbo].[CTS_MatchTicketInfo_Get]
		@FromDate			DATETIME = NULL
	,	@ToDate				DATETIME = NULL
	,	@SportList			VARCHAR(MAX) = ''
	,	@LeagueEvent		VARCHAR(500) = ''
	,	@MarketList			VARCHAR(10)  = ''
	,	@BettypeList		VARCHAR(MAX) = '[]' --JSON
	,	@DangerList			VARCHAR(MAX) = NULL --JSON
	,	@MatchSection		TINYINT = 1
	,	@IsExclTestCurr		BIT = 0

	,	@BatchSize			INT = 100
	,	@LastEventDate		DATE = NULL
	,	@LastMatchID		INT =NULL
AS
/*
	Created: 20240102@Casey.Huynh
	Task : Get Match Ticket Info
	DB	 : bodb02

	Revisions:
		- 20240102@Casey.Huynh: Created [Redmine ID: #196361]

	Params Explaination:
		,@BettypeList='[	{"BetType":1, "BetChoiceType":2}
						,	{"BetType":2, "BetChoiceType":2}
						,	{"BetType":126, "BetChoiceType":1}]'
		
		,@DangerList='[	[{"Danger1":1,"Danger2":20},{"Danger3":30},{"Danger1":28},{"Danger2":28},{"Danger2":6},{"Danger2":12},{"Danger3":48}]'
		
		EXECUTE [dbo].[CTS_MatchTicketInfo_Get] 
		@FromDate			='2024-01-08'
	,	@ToDate				= NULL
	,	@SportList			= '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,99,154'
	,	@LeagueEvent		= ''
	,	@MarketList			= '0,1'
	,	@BettypeList		= '[	{"BetType":1, "BetChoiceType":2, "BetChoiceHome":"h", "BetChoiceAway":"a", "BetID":0}
						,	{"BetType":3, "BetChoiceType":2, "BetChoiceHome":"h", "BetChoiceAway":"a", "BetID":0}
						,	{"BetType":610, "BetChoiceType":2, "BetChoiceHome":"o", "BetChoiceAway":"u", "BetID":801}
						,	{"BetType":126, "BetChoiceType":1}]' --JSON
	,	@DangerList			= NULL
	,	@MatchSection		= 1
	,	@IsExclTestCurr		= 1

	,	@BatchSize			= 100
	,	@LastEventDate		= NULL
	,	@LastMatchID		= NULL 
	
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @Today			DATE = GETDATE();

	DECLARE @BalanceUpDay	SMALLDATETIME
		,	@MoveBetsDay	SMALLDATETIME

	DECLARE @IsGetDataFromOrigin	BIT = 0
		,	@IsGetDataFrom14		BIT = 0
		,	@IsGetDataFromBK		BIT = 0

	DECLARE @FromDateOrigin			DATETIME = NULL
		,	@ToDateOrigin			DATETIME = NULL
		,	@FromDate14				DATETIME = NULL
		,	@ToDate14				DATETIME = NULL
		,	@FromDateBK				DATETIME = NULL
		,	@ToDateBK				DATETIME = NULL

	DECLARE @MatchSection_Live		TINYINT = 1
		,	@MatchSection_Today		TINYINT = 2
		,	@MatchSection_Early		TINYINT = 3
		,	@MatchSection_Closed	TINYINT = 4;

	DECLARE @DataSource_Origin	TINYINT = 0
		,	@DataSource_14		TINYINT = 1
		,	@DataSource_bk		TINYINT = 2;

	DECLARE @IsFilterDanger BIT = 0;
	DECLARE @TotalRow INT;

	--===============================================================================================
	IF	OBJECT_ID('tempdb..#tmpSport') IS NOT NULL
	BEGIN
		DROP TABLE #tmpSport
	END

	CREATE TABLE #tmpSport (
		SportType	TINYINT
	);

	CREATE INDEX IX_tmpSport_SportType ON #tmpSport(SportType);
	--=================================================================================================

	IF	OBJECT_ID('tempdb..#tmpMatchSection') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatchSection
	END

	CREATE TABLE #tmpMatchSection (
		MatchSection	TINYINT
	);
    
	--=================================================================================================
	IF	OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatches;
	END;

	CREATE TABLE #tmpMatches(
			MatchId		INT
		,	EventDate	DATETIME
	);

	CREATE CLUSTERED INDEX #CIX_tmpMatches_MatchId ON #tmpMatches(MatchId);	

	--=================================================================================================
	IF	OBJECT_ID('tempdb..#tmpInputMatches') IS NOT NULL
	BEGIN
		DROP TABLE #tmpInputMatches;
	END;

	CREATE TABLE #tmpInputMatches(
		MatchId		INT 
	);

	CREATE CLUSTERED INDEX #CIX_tmpInputMatches_MatchId ON #tmpInputMatches(MatchId);	
	
	--=================================================================================================
	IF	OBJECT_ID('tempdb..#tmpMarket') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMarket;
	END;

	CREATE TABLE #tmpMarket(
		LiveIndicator		BIT 
	);

	--=================================================================================================
	IF	OBJECT_ID('tempdb..#tmpBetType') IS NOT NULL
	BEGIN
		DROP TABLE #tmpBetType
	END

	CREATE TABLE	#tmpBetType(
			SportTypeID				SMALLINT
		,	BetType					INT
		,	BetChoiceType			TINYINT
		,	BetChoiceHome			NVARCHAR(10)
		,	BetChoiceAway			NVARCHAR(10)
		,	BetIDPattern			NVARCHAR(20)
		,	BetID					BIGINT
	)

	--=================================================================================================
	IF	OBJECT_ID('tempdb..#tmpDanger') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger;
	END;

	CREATE TABLE	#tmpDanger(
			Danger1		TINYINT
		,	Danger2		TINYINT
		,	Danger3		TINYINT
		,	Danger4		TINYINT
		,	Danger5		TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpDanger1') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger1;
	END;

	CREATE TABLE	#tmpDanger1(
		Danger1		TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpDanger2') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger2;
	END;

	CREATE TABLE	#tmpDanger2(
		Danger2		TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpDanger3') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger3;
	END;

	CREATE TABLE	#tmpDanger3(
		Danger3		TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpDanger4') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger4;
	END;

	CREATE TABLE	#tmpDanger4(
		Danger4		TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpDanger5') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger5;
	END;

	CREATE TABLE	#tmpDanger5(
		Danger5		TINYINT
	);
	--==============================================================================	
	IF	OBJECT_ID('tempdb..#tmpMatch') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMatch;
	END;

	CREATE TABLE #tmpMatch(
			EventDate		DATE
		,	MatchID INT
		,	LeagueId		INT
		,	HomeId			INT
		,	HomeName		VARCHAR(100)
		,	AwayId			INT
		,	AwayName		VARCHAR(100)
		,	LeagueName		VARCHAR(500)
		,	GlobalShowTime	SMALLDATETIME	
		,	SportType		INT
	)
	CREATE CLUSTERED INDEX #CIX_tmpMatchByLeagueEvent_MatchId ON #tmpMatch(EventDate DESC, MatchID DESC);

	--================================================================================
	IF	OBJECT_ID('tempdb..#tmpMatchesTicketInfo') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatchesTicketInfo;
	END;

	CREATE TABLE #tmpMatchesTicketInfo (
			MatchId			INT NOT NULL		
		,	LiveIndicator	BIT
		,	Bettype			INT NOT NULL
		,	BetID			BIGINT
		,	BetChoiceType	TINYINT
		,	TotalAmountHome MONEY -- IF BetChoiceType = 1  then TOTAL ALL
		,	TotalAmountAway MONEY  -- IF BetChoiceType = 1 then 0
		,	TotalTicketHome INT -- IF BetChoiceType = 1  then TOTAL ALL
		,	TotalTicketAway INT  -- IF BetChoiceType = 1 then 0
	);

	CREATE CLUSTERED INDEX #CIX_tmpMatchesTicketInfo_MatchIdBettype ON #tmpMatchesTicketInfo (
			MatchId	DESC
		,	LiveIndicator	DESC
		,	Bettype ASC
		,	BetID	ASC
	);
	--=========Parse Market From @MarketList======================================
	INSERT INTO #tmpMarket(LiveIndicator)
	SELECT ssk.value FROM STRING_SPLIT (@MarketList, ',') ssk;

	--=========Parse Bettype From @BettypeList======================================
	INSERT INTO #tmpBettype(BetType,BetChoiceType,BetChoiceHome,BetChoiceAway,BetIDPattern,BetID)
	SELECT	j.BetType
		,	j.BetChoiceType
		,	j.BetChoiceHome
		,	j.BetChoiceAway
		,	j.BetIDPattern
		,	j.BetID
	FROM OPENJSON (@BettypeList) WITH (
			BetType			INT				'$.BetType'
		,	BetChoiceType	TINYINT			'$.BetChoiceType'
		,	BetChoiceHome	NVARCHAR(10)	'$.BetChoiceHome'
		,	BetChoiceAway	NVARCHAR(10)	'$.BetChoiceAway'
		,	BetIDPattern	NVARCHAR(20)	'$.BetIDPattern'
		,	BetID			BIGINT			'$.BetID'
		) AS j;
	
	--========Parse @Danger From @DangerList=========================================
	IF @DangerList IS NOT NULL
	BEGIN
		SET @IsFilterDanger = 1;
		INSERT INTO #tmpDanger (Danger1,Danger2,Danger3,Danger4,Danger5)
			SELECT	j.Danger1
				,	j.Danger2
				,	j.Danger3
				,	j.Danger4
				,	j.Danger5
			FROM OPENJSON (@DangerList) WITH (
					Danger1	TINYINT	'$.Danger1'
				,	Danger2	TINYINT	'$.Danger2'
				,	Danger3	TINYINT	'$.Danger3'
				,	Danger4	TINYINT	'$.Danger4'
				,	Danger5	TINYINT	'$.Danger5'
				) AS j;		
		
		INSERT INTO #tmpDanger1 (Danger1)
		SELECT Danger1
		FROM #tmpDanger WITH(NOLOCK) WHERE Danger1 > 0

		INSERT INTO #tmpDanger2 (Danger2)
		SELECT Danger2
		FROM #tmpDanger WITH(NOLOCK) WHERE Danger2 > 0

		INSERT INTO #tmpDanger3 (Danger3)
		SELECT Danger3
		FROM #tmpDanger WITH(NOLOCK) WHERE Danger3 > 0

		INSERT INTO #tmpDanger4 (Danger4)
		SELECT Danger4
		FROM #tmpDanger WITH(NOLOCK) WHERE Danger4 > 0
		
		INSERT INTO #tmpDanger5 (Danger5)
		SELECT Danger5
		FROM #tmpDanger WITH(NOLOCK) WHERE Danger5 > 0
	END
	;

	--==================================================================================================
	--=========Date Range===================================================

	IF (@ToDate IS NULL)
	BEGIN
		SET @ToDate = (	SELECT MAX(m.EventDate) 
						FROM dbo.Match AS m WITH(NOLOCK))
	END
	
    IF @LastMatchID  IS NULL 
		SET @LastMatchID = (SELECT MAX(MatchID) + 1 FROM Match);
    
    IF @LastEventDate IS NULL 
		SET  @LastEventDate	= @ToDate;

	IF @LastEventDate < @ToDate
		SET @ToDate = @LastEventDate;

	--=========Parse Sport From @SportList======================================
	INSERT INTO #tmpSport (SportType)
	SELECT ssk.value FROM STRING_SPLIT (@SportList, ',') ssk;

	--===========================================
	IF	OBJECT_ID('tempdb..#BUMBData') IS NOT NULL
	BEGIN
		DROP TABLE	#BUMBData
	END

	CREATE TABLE	#BUMBData (
			BUDay	SMALLDATETIME
		,	MBDay	SMALLDATETIME
	)

	INSERT INTO #BUMBData(BUDay,MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay

	SELECT	TOP(1)
			@BalanceUpDay	= BUDay
		,	@MoveBetsDay	= MBDay
	FROM #BUMBData WITH(NOLOCK)
	
	-- For @FromDate
	IF @FromDate < @BalanceUpDay
	BEGIN
		SET @IsGetDataFromBK = 1
	END
	ELSE IF @FromDate <= @MoveBetsDay
	BEGIN
		SET @IsGetDataFrom14 = 1
	END
	ELSE IF @FromDate > @MoveBetsDay
	BEGIN
		SET @IsGetDataFromOrigin = 1
	END

	-- For @ToDate
	IF @ToDate < @BalanceUpDay
	BEGIN
		SET @IsGetDataFromBK = 1
	END
	ELSE IF @ToDate <= @MoveBetsDay
	BEGIN
		SET @IsGetDataFrom14 = 1
	END
	ELSE IF @ToDate > @MoveBetsDay
	BEGIN
		SET @IsGetDataFromOrigin = 1
	END

	IF @FromDate < @BalanceUpDay AND @ToDate > @MoveBetsDay
	BEGIN
		SET @IsGetDataFromBK		= 1
		SET @IsGetDataFrom14		= 1
		SET @IsGetDataFromOrigin	= 1
	END

	IF (@IsGetDataFromBK = 1 AND @IsGetDataFromOrigin = 1)
		OR (@IsGetDataFromBK = 1 AND @IsGetDataFrom14 = 1 AND @IsGetDataFromOrigin = 1)
	BEGIN
		SELECT	@FromDateOrigin		=	DATEADD(DD,1,@MoveBetsDay)
			,	@ToDateOrigin		=	@ToDate
			,	@FromDate14			=	@BalanceUpDay
			,	@ToDate14			=	@MoveBetsDay
			,	@FromDateBK			=	@FromDate 
			,	@ToDateBK			=	DATEADD(DD,-1,@BalanceUpDay)
	END

	IF @IsGetDataFromBK = 1 AND @IsGetDataFrom14 = 1 AND @IsGetDataFromOrigin = 0
	BEGIN
		SELECT	@FromDate14			=	@BalanceUpDay
			,	@ToDate14			=	@ToDate
			,	@FromDateBK			=	@FromDate 
			,	@ToDateBK			=	DATEADD(DD,-1,@BalanceUpDay)
	END

	IF @IsGetDataFromBK = 0 AND @IsGetDataFrom14 = 1 AND @IsGetDataFromOrigin = 1
	BEGIN
		SELECT	@FromDateOrigin		=	DATEADD(DD,1,@MoveBetsDay)
			,	@ToDateOrigin		=	@ToDate
			,	@FromDate14			=	@FromDate
			,	@ToDate14			=	@MoveBetsDay
	END

	IF @IsGetDataFromBK = 1 AND @IsGetDataFrom14 = 0 AND @IsGetDataFromOrigin = 0
	BEGIN
		SELECT	@FromDateBK			=	@FromDate 
			,	@ToDateBK			=	@ToDate
	END

	IF @IsGetDataFromBK = 0 AND @IsGetDataFrom14 = 1 AND @IsGetDataFromOrigin = 0
	BEGIN
		SELECT	@FromDate14			=	@FromDate
			,	@ToDate14			=	@ToDate
	END

	IF @IsGetDataFromBK = 0 AND @IsGetDataFrom14 = 0 AND @IsGetDataFromOrigin = 1
	BEGIN
		SELECT	@FromDateOrigin		=	@FromDate
			,	@ToDateOrigin		=	@ToDate
	END
	--==================================================================================================	
	IF	@IsGetDataFromOrigin = 1
	BEGIN
      INSERT INTO #tmpMatch(EventDate, MatchId, HomeId, HomeName, AwayId, AwayName, GlobalShowTime, SportType, LeagueId, LeagueName)
		SELECT	TOP(@BatchSize)
				m.EventDate
			,	m.MatchId
			,	m.HomeId
			,	h.teamname AS HomeName
			,	m.AwayId
			,	a.teamname AS AwayName
			,	m.GlobalShowTime
			,	m.SportType
			,	l.LeagueId
			,	l.LeagueName
		FROM bodb02.dbo.match AS m WITH(NOLOCK)
			INNER JOIN #tmpSport AS tmpSp WITH(NOLOCK) ON m.sporttype = ISNULL(tmpSp.SportType,m.sporttype)
			INNER JOIN bodb02.dbo.League AS l WITH(NOLOCK) ON m.LeagueId = l.leagueid 
			INNER JOIN bodb02.dbo.Team AS h WITH(NOLOCK) ON m.Homeid = h.TeamId 
			INNER JOIN bodb02.dbo.Team AS a WITH(NOLOCK) ON m.awayid = a.TeamId
		WHERE m.EventDate = @ToDateOrigin
			AND m.MatchID < @LastMatchID
			AND l.IsTest = 0	
			AND	(	l.LeagueName LIKE '%' + @LeagueEvent + '%'
					OR  h.TeamName LIKE '%' + @LeagueEvent + '%'
					OR  a.TeamName LIKE '%' + @LeagueEvent + '%')
			AND (CASE
						WHEN m.eventstatus <> 'completed' THEN (CASE 
																	WHEN m.GlobalShowTime <= GETDATE() THEN @MatchSection_Live --LIVE
																	WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN @MatchSection_Today	 --TODAY
																	WHEN m.EventDate > @Today THEN @MatchSection_Early -- EARLY
																END)
						ELSE @MatchSection_Closed -- CLOSED
					END) = @MatchSection
		ORDER BY m.EventDate DESC
			,	m.MatchId DESC;

		SET @TotalRow = (SELECT COUNT(1) FROM #tmpMatch WITH(NOLOCK))
		IF (@TotalRow < @BatchSize)
		BEGIN
                
			INSERT INTO #tmpMatch(EventDate, MatchId, HomeId, HomeName, AwayId, AwayName, GlobalShowTime, SportType, LeagueId, LeagueName)
			SELECT	TOP(@BatchSize)
					m.EventDate
				,	m.MatchId
				,	m.HomeId
				,	h.teamname AS HomeName
				,	m.AwayId
				,	a.teamname AS AwayName
				,	m.GlobalShowTime
				,	m.SportType
				,	l.LeagueId
				,	l.LeagueName
			FROM bodb02.dbo.match AS m WITH(NOLOCK)
				INNER JOIN #tmpSport AS tmpSp WITH(NOLOCK) ON m.sporttype = ISNULL(tmpSp.SportType,m.sporttype)
				INNER JOIN bodb02.dbo.League AS l WITH(NOLOCK) ON m.LeagueId = l.leagueid 
				INNER JOIN bodb02.dbo.Team AS h WITH(NOLOCK) ON m.Homeid = h.TeamId 
				INNER JOIN bodb02.dbo.Team AS a WITH(NOLOCK) ON m.awayid = a.TeamId
			WHERE m.EventDate >= @FromDateOrigin AND m.EventDate < @ToDateOrigin
				AND l.IsTest = 0	
				AND	(	l.LeagueName LIKE '%' + @LeagueEvent + '%'
						OR  h.TeamName LIKE '%' + @LeagueEvent + '%'
						OR  a.TeamName LIKE '%' + @LeagueEvent + '%')
				AND (CASE
						WHEN m.eventstatus <> 'completed' THEN (CASE 
																	WHEN m.GlobalShowTime <= GETDATE() THEN @MatchSection_Live --LIVE
																	WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN @MatchSection_Today	 --TODAY
																	WHEN m.EventDate > @Today THEN @MatchSection_Early -- EARLY
																END)
						ELSE @MatchSection_Closed -- CLOSED
					END) = @MatchSection
			ORDER BY m.EventDate DESC
				,	m.MatchId DESC;		
		END;
  
        IF EXISTS (SELECT 1 FROM  #tmpMatch AS tmpMt WITH(NOLOCK))
		BEGIN
          SELECT TOP(1) tmpMt.EventDate AS LastEventDate
              ,	tmpMt.MatchId AS LastMatchId
          FROM #tmpMatch AS tmpMt WITH(NOLOCK)
          ORDER BY EventDate ASC, MatchId ASC
		END
        ELSE 
		BEGIN
          SELECT TOP(1) m.EventDate AS LastEventDate
            ,	m.MatchId + 1 AS LastMatchId
          FROM bodb02.dbo.match14 AS m WITH(NOLOCK)
          WHERE m.EventDate = @ToDate14
          ORDER BY m.MatchId DESC
        END

		SELECT	tmpMt.EventDate						
		,	tmpMt.MatchId
		,	b.LiveIndicator
		,	b.Bettype
		,	ISNULL(tmpBt.BetID,0) AS BetID
		,	MAX(tmpBt.BetChoiceType) AS BetChoiceType
		,	MAX(tmpMt.SportType) AS SportType
		,	MAX(tmpMt.LeagueId) AS LeagueId
		,	MAX(tmpMt.LeagueName) AS LeagueName	
		,	MAX(tmpMt.GlobalShowTime) AS GlobalShowTime
		,	MAX(tmpMt.homeid) AS homeid
		,	MAX(tmpMt.HomeName) AS HomeName
		,	MAX(tmpMt.AwayId) AS AwayId
		,	MAX(tmpMt.AwayName) AS AwayName
		,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN b.stake * b.actualrate 
					WHEN tmpBt.BetChoiceType = 1 THEN b.stake * b.actualrate 
					ELSE 0 END) AS TotalAmountHome
		,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN b.stake * b.actualrate 
					ELSE 0 END) AS TotalAmountAway
		,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN 1 
					WHEN tmpBt.BetChoiceType = 1 THEN 1
					ELSE 0 END) AS TotalTicketHome
		,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN 1 
					ELSE 0 END) AS TotalTicketAway	
		FROM #tmpMatch AS tmpMt WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettrans AS b WITH(NOLOCK) ON b.MatchID = tmpMt.MatchID 
			INNER JOIN #tmpBetType AS tmpBt WITH(NOLOCK) ON b.bettype = ISNULL(tmpBt.BetType,b.bettype) AND tmpBt.betID = b.betid
			INNER JOIN #tmpMarket AS tmpMk WITH(NOLOCK) ON b.liveindicator = ISNULL(tmpMk.LiveIndicator,b.LiveIndicator)
			INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.CustId = b.CustId
			LEFT JOIN  #tmpDanger1 AS tmpDg1 WITH(NOLOCK) ON tmpDg1.Danger1 = c.danger
			LEFT JOIN  #tmpDanger2 AS tmpDg2 WITH(NOLOCK) ON tmpDg2.Danger2 = c.danger2
			LEFT JOIN  #tmpDanger3 AS tmpDg3 WITH(NOLOCK) ON tmpDg3.Danger3 = c.danger3
			LEFT JOIN  #tmpDanger4 AS tmpDg4 WITH(NOLOCK) ON tmpDg4.Danger4 = c.danger4
			LEFT JOIN  #tmpDanger5 AS tmpDg5 WITH(NOLOCK) ON tmpDg5.Danger5 = c.danger5
		WHERE (ISNULL(tmpDg1.Danger1,0)+ ISNULL(tmpDg2.danger2,0) + ISNULL(tmpDg3.danger3,0) + ISNULL(tmpDg4.danger4,0) + ISNULL(tmpDg5.danger5,0) > 0 OR @IsFilterDanger = 0)
			AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
		GROUP BY  tmpMt.eventdate, tmpMt.MatchId, tmpMt.HomeId, tmpMt.AwayId, tmpMt.SportType, tmpMt.LeagueId, b.Bettype, b.LiveIndicator, tmpBt.BetID
		ORDER BY tmpMt.eventdate DESC, tmpMt.matchid DESC, b.Bettype ASC, b.LiveIndicator DESC, tmpBt.BetID ASC;		
	END

	ELSE IF	(@IsGetDataFrom14 = 1) and (@MatchSection = @MatchSection_Closed)
			BEGIN     
			INSERT INTO #tmpMatch(EventDate, MatchId, HomeId, HomeName, AwayId, AwayName, GlobalShowTime, SportType, LeagueId, LeagueName)
			SELECT	TOP(@BatchSize)
					m.EventDate
				,	m.MatchId
				,	m.HomeId
				,	h.teamname AS HomeName
				,	m.AwayId
				,	a.teamname AS AwayName
				,	m.GlobalShowTime
				,	m.SportType
				,	l.LeagueId
				,	l.LeagueName
			FROM bodb02.dbo.match14 AS m WITH(NOLOCK)
				INNER JOIN #tmpSport AS tmpSp WITH(NOLOCK) ON m.sporttype = ISNULL(tmpSp.SportType,m.sporttype)
				INNER JOIN bodb02.dbo.League AS l WITH(NOLOCK) ON m.LeagueId = l.leagueid 
				INNER JOIN bodb02.dbo.Team AS h WITH(NOLOCK) ON m.Homeid = h.TeamId 
				INNER JOIN bodb02.dbo.Team AS a WITH(NOLOCK) ON m.awayid = a.TeamId
			WHERE m.EventDate = @ToDate14
				AND m.MatchID < @LastMatchID
				AND l.IsTest = 0	
				AND	(	l.LeagueName LIKE '%' + @LeagueEvent + '%'
						OR  h.TeamName LIKE '%' + @LeagueEvent + '%'
						OR  a.TeamName LIKE '%' + @LeagueEvent + '%')
			ORDER BY m.EventDate DESC
				,	m.MatchId DESC;
            
			SET @TotalRow = (SELECT COUNT(1) FROM #tmpMatch WITH(NOLOCK))

			SELECT TOP(1) tmpMt.EventDate AS LastEventDate
			,	tmpMt.MatchId AS LastMatchId
			FROM #tmpMatch AS tmpMt WITH(NOLOCK)
			ORDER BY EventDate ASC, MatchId ASC

			IF (@TotalRow < @BatchSize)
			BEGIN
				SET @ToDate14 = DATEADD(DAY,-1,@ToDate14);

				INSERT INTO #tmpMatch(EventDate, MatchId, HomeId, HomeName, AwayId, AwayName, GlobalShowTime, SportType, LeagueId, LeagueName)
				SELECT	TOP(@BatchSize)
						m.EventDate
					,	m.MatchId
					,	m.HomeId
					,	h.teamname AS HomeName
					,	m.AwayId
					,	a.teamname AS AwayName
					,	m.GlobalShowTime
					,	m.SportType
					,	l.LeagueId
					,	l.LeagueName
				FROM bodb02.dbo.match14 AS m WITH(NOLOCK)
					INNER JOIN #tmpSport AS tmpSp WITH(NOLOCK) ON m.sporttype = ISNULL(tmpSp.SportType,m.sporttype)
					INNER JOIN bodb02.dbo.League AS l WITH(NOLOCK) ON m.LeagueId = l.leagueid 
					INNER JOIN bodb02.dbo.Team AS h WITH(NOLOCK) ON m.Homeid = h.TeamId 
					INNER JOIN bodb02.dbo.Team AS a WITH(NOLOCK) ON m.awayid = a.TeamId
				WHERE m.EventDate Between @FromDate14 AND @ToDate14
					AND l.IsTest = 0	
					AND	(	l.LeagueName LIKE '%' + @LeagueEvent + '%'
							OR  h.TeamName LIKE '%' + @LeagueEvent + '%'
							OR  a.TeamName LIKE '%' + @LeagueEvent + '%')
					AND (CASE
							WHEN m.eventstatus <> 'completed' THEN (CASE 
																		WHEN m.GlobalShowTime <= GETDATE() THEN @MatchSection_Live --LIVE
																		WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN @MatchSection_Today	 --TODAY
																		WHEN m.EventDate > @Today THEN @MatchSection_Early -- EARLY
																	END)
							ELSE @MatchSection_Closed -- CLOSED
						END) = @MatchSection
				ORDER BY	m.EventDate DESC
					,		m.MatchId DESC;		
			END;
			
			SELECT	tmpMt.EventDate						
			,	tmpMt.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	ISNULL(tmpBt.BetID,0) AS BetID
			,	MAX(tmpBt.BetChoiceType) AS BetChoiceType
			,	MAX(tmpMt.SportType) AS SportType
			,	MAX(tmpMt.LeagueId) AS LeagueId
			,	MAX(tmpMt.LeagueName) AS LeagueName	
			,	MAX(tmpMt.GlobalShowTime) AS GlobalShowTime
			,	MAX(tmpMt.homeid) AS homeid
			,	MAX(tmpMt.HomeName) AS HomeName
			,	MAX(tmpMt.AwayId) AS AwayId
			,	MAX(tmpMt.AwayName) AS AwayName
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN b.stake * b.actualrate 
						WHEN tmpBt.BetChoiceType = 1 THEN b.stake * b.actualrate 
						ELSE 0 END) AS TotalAmountHome
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN b.stake * b.actualrate 
						ELSE 0 END) AS TotalAmountAway
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN 1 
						WHEN tmpBt.BetChoiceType = 1 THEN 1
						ELSE 0 END) AS TotalTicketHome
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN 1 
						ELSE 0 END) AS TotalTicketAway	
			FROM #tmpMatch AS tmpMt WITH(NOLOCK)
				INNER JOIN bodb02.dbo.bettrans14 AS b WITH(NOLOCK) ON b.MatchID = tmpMt.MatchID 
				INNER JOIN #tmpBetType AS tmpBt WITH(NOLOCK) ON b.bettype = ISNULL(tmpBt.BetType,b.bettype) AND tmpBt.betID = b.betid
				INNER JOIN #tmpMarket AS tmpMk WITH(NOLOCK) ON b.liveindicator = ISNULL(tmpMk.LiveIndicator,b.LiveIndicator)
				INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.CustId = b.CustId
				LEFT JOIN  #tmpDanger1 AS tmpDg1 WITH(NOLOCK) ON tmpDg1.Danger1 = c.danger
			LEFT JOIN  #tmpDanger2 AS tmpDg2 WITH(NOLOCK) ON tmpDg2.Danger2 = c.danger2
			LEFT JOIN  #tmpDanger3 AS tmpDg3 WITH(NOLOCK) ON tmpDg3.Danger3 = c.danger3
			LEFT JOIN  #tmpDanger4 AS tmpDg4 WITH(NOLOCK) ON tmpDg4.Danger4 = c.danger4
			LEFT JOIN  #tmpDanger5 AS tmpDg5 WITH(NOLOCK) ON tmpDg5.Danger5 = c.danger5
		WHERE (ISNULL(tmpDg1.Danger1,0)+ ISNULL(tmpDg2.danger2,0) + ISNULL(tmpDg3.danger3,0) + ISNULL(tmpDg4.danger4,0) + ISNULL(tmpDg5.danger5,0) > 0 OR @IsFilterDanger = 0)
			AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
		GROUP BY  tmpMt.eventdate, tmpMt.MatchId, tmpMt.HomeId, tmpMt.AwayId, tmpMt.SportType, tmpMt.LeagueId, b.Bettype, b.LiveIndicator, tmpBt.BetID
		ORDER BY tmpMt.eventdate DESC, tmpMt.matchid DESC, b.Bettype ASC, b.LiveIndicator DESC, tmpBt.BetID ASC;	

	END	;
END;
GO

GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/