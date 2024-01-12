/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_MatchTicketInfo_Get]
		@FromDate			DATETIME = NULL
	,	@ToDate				DATETIME = NULL
	,	@SportList			VARCHAR(MAX) = ''
	,	@LeagueEvent		VARCHAR(100) 
	,	@MarketList			VARCHAR(10)  = ''
	,	@BettypeList		VARCHAR(MAX) = '[]' --JSON
	,	@DangerList			VARCHAR(MAX) = '[]' --JSON

	,	@MatchSection		TINYINT
	,	@BatchSize			INT = 500
	,	@LastEventDate		DATE
	,	@LastMatchID		INT
	
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
		
		,@DangerList='[	[{"Danger1":1,"Danger2":3},{"Danger1":2},{"Danger1":28},{"Danger2":28},{"Danger2":6},{"Danger2":12},{"Danger3":48}]'
		
		EXECUTE [dbo].[CTS_MatchTicketInfo_Get] @MatchIds = '77936152,77933630,77933651'--,67089553,77935045,76886100'
		,	@BettypeList='[	{"BetType":1, "BetChoiceType":2, "BetChoiceHome":"h", "BetChoiceAway":"a", "BetID":0}
						,	{"BetType":3, "BetChoiceType":2, "BetChoiceHome":"h", "BetChoiceAway":"a", "BetID":0}
						,	{"BetType":610, "BetChoiceType":2, "BetChoiceHome":"o", "BetChoiceAway":"u", "BetID":801}
						,	{"BetType":126, "BetChoiceType":1}]'
		,	@DangerList =  '[{"Danger1":0},{"Danger1":10},{"Danger3":10},{"Danger4":45},{"Danger5":1},{"Danger5":5}]'
		,	@MarketList = '0,1'
		,	@MatchSection		TINYINT	
		
		,	@LastEventDate		DATE
		,	@LastMatchID		INT
		,	@BatchSize			INT = 500;

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @Today			DATE = GETDATE();

	DECLARE @BalanceUpDay	SMALLDATETIME
		,	@MoveBetsDay	SMALLDATETIME

	DECLARE @IsGetDataFromOrigin	BIT = 0
		,	@IsGetDataFrom14		BIT = 0
		,	@IsGetDataFromBK		BIT = 0

	DECLARE @FromDateOrigin			SMALLDATETIME = NULL
		,	@ToDateOrigin			SMALLDATETIME = NULL
		,	@FromDate14				SMALLDATETIME = NULL
		,	@ToDate14				SMALLDATETIME = NULL
		,	@FromDateBK				SMALLDATETIME = NULL
		,	@ToDateBK				SMALLDATETIME = NULL

	DECLARE @MatchSection_Live		TINYINT = 1
		,	@MatchSection_Today		TINYINT = 2
		,	@MatchSection_Early		TINYINT = 3
		,	@MatchSection_Closed	TINYINT = 4;

	DECLARE @DataSource_Origin	TINYINT = 0
		,	@DataSource_14		TINYINT = 1
		,	@DataSource_bk		TINYINT = 2;

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
	--=============================================================================================
	IF	OBJECT_ID('tempdb..#tmpMatchesInfo') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatchesInfo;
	END;

	CREATE TABLE #tmpMatchesInfo (
			MatchId				INT NOT NULL PRIMARY KEY
		,	MatchCode			NVARCHAR(50)
		,	SportType			SMALLINT
		,	LeagueId			INT
		,	EventDate			DATETIME
		,	KickOffTime			DATETIME
		,	HomeId				INT
		,	AwayId				INT
		,	EventStatus			NVARCHAR(50)
		,	LiveHomeScore		INT
		,	LiveAwayScore		INT
		,	HTHomeScore			INT
		,	HTAwayScore			INT
		,	FinalHomeScore		INT
		,	FinalAwayScore		INT
		,	MatchSection		TINYINT
		,	DataSource			TINYINT
	);

	CREATE INDEX IX_tmpMatchesInfo_EventDate ON #tmpMatchesInfo(EventDate DESC);
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


--==================================================================================================
--=========Parse @ToDate===================================================
	IF (@ToDate IS NULL)
	BEGIN
		SET @ToDate = (	SELECT MAX(m.EventDate) 
						FROM dbo.Match AS m WITH(NOLOCK))
	END
	--=========Parse Sport From @SportList======================================
	INSERT INTO #tmpSport (SportType)
	SELECT ssk.value FROM STRING_SPLIT (@SportList, ',') ssk;
	--========Parse MatchSection From @MatchSection=========================================
	INSERT INTO #tmpMatchSection(MatchSection)
	SELECT ssk.value FROM STRING_SPLIT (@MatchSectionList, ',') ssk;

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
	
	IF	@IsGetDataFromOrigin = 1
	BEGIN

		INSERT INTO #tmpMatchesInfo (MatchId,MatchCode,SportType,LeagueId,EventDate,KickOffTime,HomeId,AwayId,EventStatus
		,LiveHomeScore,LiveAwayScore,HTHomeScore,HTAwayScore,FinalHomeScore,FinalAwayScore,MatchSection,DataSource)
			
		SELECT	tmp.MatchId
			,	tmp.MatchCode
			,	tmp.SportType
			,	tmp.LeagueId
			,	tmp.EventDate
			,	tmp.GlobalShowTime
			,	tmp.HomeId
			,	tmp.AwayId
			,	tmp.EventStatus
			,	tmp.LiveHomeScore
			,	tmp.LiveAwayScore
			,	tmp.HTHomeScore
			,	tmp.HTAwayScore
			,	tmp.FinalHomeScore
			,	tmp.FinalAwayScore
			,	tmp.MatchSection
			,	@DataSource_Origin
		FROM (
				SELECT	m.MatchId
					,	m.MatchCode
					,	m.SportType
					,	m.LeagueId
					,	m.EventDate
					,	m.GlobalShowTime
					,	m.HomeId
					,	m.AwayId
					,	m.EventStatus
					,	m.LiveHomeScore
					,	m.LiveAwayScore
					,	m.HTHomeScore
					,	m.HTAwayScore
					,	m.FinalHomeScore
					,	m.FinalAwayScore
					,	(CASE
							WHEN m.eventstatus <> 'completed' THEN (CASE 
																		WHEN m.GlobalShowTime <= GETDATE() THEN @MatchSection_Live --LIVE
																		WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN @MatchSection_Today	 --TODAY
																		WHEN m.EventDate > @Today THEN @MatchSection_Early -- EARLY
																	END)
							ELSE @MatchSection_Closed -- CLOSED
						END) AS MatchSection
				FROM bodb02.dbo.match AS m WITH(NOLOCK) 
					INNER JOIN #tmpSport AS tmpSp ON m.sporttype = ISNULL(tmpSp.SportType,m.sporttype)
				WHERE m.EventDate BETWEEN @FromDateOrigin AND @ToDateOrigin
				) AS tmp
					

	END;
	
	IF	@IsGetDataFrom14 = 1 AND @MatchSection = @MatchSection_Closed
	BEGIN
		INSERT INTO #tmpMatchesInfo (MatchId,MatchCode,SportType,LeagueId,EventDate,KickOffTime,HomeId,AwayId,EventStatus
			,LiveHomeScore,LiveAwayScore,HTHomeScore,HTAwayScore,FinalHomeScore,FinalAwayScore,MatchSection,DataSource)
		SELECT	m.MatchId
					,	m.MatchCode
					,	m.SportType
					,	m.LeagueId
					,	m.EventDate
					,	m.GlobalShowTime
					,	m.HomeId
					,	m.AwayId
					,	m.EventStatus
					,	m.LiveHomeScore
					,	m.LiveAwayScore
					,	m.HTHomeScore
					,	m.HTAwayScore
					,	m.FinalHomeScore
					,	m.FinalAwayScore
					,	@MatchSection_Closed AS MatchSection
					,	@DataSource_14
		FROM bodb02.dbo.match14 AS m WITH(NOLOCK) 
			INNER JOIN #tmpSport AS tmpSp ON m.sporttype = ISNULL(tmpSp.SportType,m.sporttype)
		WHERE m.EventDate BETWEEN @FromDate14 AND @ToDate14

	END

	IF	@IsGetDataFromBK = 1 AND @MatchSection = @MatchSection_Closed
	BEGIN
		
		INSERT INTO #tmpMatchesInfo (MatchId,MatchCode,SportType,LeagueId,EventDate,KickOffTime,HomeId,AwayId,EventStatus
			,LiveHomeScore,LiveAwayScore,HTHomeScore,HTAwayScore,FinalHomeScore,FinalAwayScore,MatchSection,DataSource)
		SELECT	m.MatchId
			,	m.MatchCode
			,	m.SportType
			,	m.LeagueId
			,	m.EventDate
			,	m.GlobalShowTime
			,	m.HomeId
			,	m.AwayId
			,	m.EventStatus
			,	m.LiveHomeScore
			,	m.LiveAwayScore
			,	m.HTHomeScore
			,	m.HTAwayScore
			,	m.FinalHomeScore
			,	m.FinalAwayScore
			,	@MatchSection_Closed AS MatchSection
			,	@DataSource_bk
		FROM bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) 
			INNER JOIN #tmpSport AS tmpSp ON m.sporttype = ISNULL(tmpSp.SportType,m.sporttype)
		WHERE m.EventDate BETWEEN @FromDateBK AND @ToDateBK;

	END
		
		--INSERT INTO #tmpMatchesInfo (MatchId,LiveIndicator, Bettype, BetID, BetChoiceType,TotalAmountHome,TotalAmountAway,TotalTicketHome,TotalTicketAway)
		SELECT	tm.*
			--,	b.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	ISNULL(tmpBt.BetID,0) AS BetID
			,	tmpBt.BetChoiceType
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

		FROM #tmpMatchesInfo AS tm WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Bettrans AS b WITH(NOLOCK) ON b.MatchId = tm.matchid
			INNER JOIN #tmpBetType AS tmpBt WITH(NOLOCK) ON b.bettype = ISNULL(tmpBt.BetType,b.bettype) AND tmpBt.betID = b.betid
			INNER JOIN #tmpMarket AS tmpMk WITH(NOLOCK) ON b.liveindicator = ISNULL(tmpMk.LiveIndicator,b.LiveIndicator)
			INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.CustId = b.CustId
		WHERE EXISTS (	SELECT 1 
						FROM  #tmpDanger AS tmpDg WITH(NOLOCK) 
						WHERE  c.Danger = ISNULL(tmpDg.Danger1,c.Danger)
								AND c.Danger2 = ISNULL(tmpDg.Danger2,c.Danger)
								AND c.Danger3 = ISNULL(tmpDg.Danger3,c.Danger)
								AND c.Danger4 = ISNULL(tmpDg.Danger4,c.Danger)
								AND c.Danger5 = ISNULL(tmpDg.Danger5,c.Danger))
		GROUP BY b.MatchId, b.LiveIndicator, b.Bettype, tmpBt.BetID, tmpBt.BetChoiceType;

		DELETE tmpIM
		FROM #tmpInputMatches AS tmpIM
		INNER JOIN #tmpMatches AS tmpMt WITH(NOLOCK) ON tmpMt.MatchId = tmpIM.matchid;

		TRUNCATE TABLE #tmpMatches;

		INSERT INTO #tmpMatches(MatchId)
		SELECT tmpMt.MatchID
		FROM #tmpInputMatches AS tmpMt
			INNER JOIN bodb02.dbo.Match14 b WITH(NOLOCK) ON tmpMt.MatchId = b.MatchId;

		--INSERT INTO #tmpMatchesInfo (MatchId,LiveIndicator, Bettype, BetID, BetChoiceType,TotalAmountHome,TotalAmountAway,TotalTicketHome,TotalTicketAway)
		SELECT	tm.*
			--,	b.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	ISNULL(tmpBt.BetID,0)
			,	tmpBt.BetChoiceType
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
		FROM #tmpMatchesInfo AS tm WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Bettrans14 AS b WITH(NOLOCK) ON b.MatchId = tm.matchid
			INNER JOIN #tmpBetType AS tmpBt WITH(NOLOCK) ON b.bettype = ISNULL(tmpBt.BetType,b.bettype) AND tmpBt.betID = b.betid
			INNER JOIN #tmpMarket AS tmpMk WITH(NOLOCK) ON b.liveindicator = ISNULL(tmpMk.LiveIndicator,b.LiveIndicator)
			INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.CustId = b.CustId
		WHERE EXISTS (	SELECT 1 
						FROM  #tmpDanger AS tmpDg WITH(NOLOCK) 
						WHERE  c.Danger = ISNULL(tmpDg.Danger1,c.Danger)
								AND c.Danger2 = ISNULL(tmpDg.Danger2,c.Danger)
								AND c.Danger3 = ISNULL(tmpDg.Danger3,c.Danger)
								AND c.Danger4 = ISNULL(tmpDg.Danger4,c.Danger)
								AND c.Danger5 = ISNULL(tmpDg.Danger5,c.Danger))
		GROUP BY b.MatchId, b.LiveIndicator, b.Bettype, tmpBt.BetID, tmpBt.BetChoiceType;
		
		DELETE tmpIM
		FROM #tmpInputMatches AS tmpIM
		INNER JOIN #tmpMatches AS tmpMt WITH(NOLOCK) ON tmpMt.MatchId = tmpIM.matchid;

		TRUNCATE TABLE #tmpMatches;

		INSERT INTO #tmpMatches(MatchId, EventDate)
		SELECT tmpMt.MatchID, b.EventDate
		FROM #tmpInputMatches AS tmpMt
			INNER JOIN bodb_Archive.dbo.Match_bk b WITH(NOLOCK) ON tmpMt.MatchId = b.MatchId;
		
		INSERT INTO #tmpMatchesInfo (MatchId,LiveIndicator, Bettype, BetID, BetChoiceType,TotalAmountHome,TotalAmountAway,TotalTicketHome,TotalTicketAway)
		SELECT	b.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	ISNULL(tmpBt.BetID,0)
			,	tmpBt.BetChoiceType
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
		FROM #tmpMatches AS tm WITH(NOLOCK)
			INNER JOIN bodb_Archive.dbo.Bettrans_bk AS b WITH(NOLOCK) ON b.MatchId = tm.matchid AND tm.EventDate = b.winlostdate
			INNER JOIN #tmpBetType AS tmpBt WITH(NOLOCK) ON b.bettype = ISNULL(tmpBt.BetType,b.bettype) AND tmpBt.betID = b.betid
			INNER JOIN #tmpMarket AS tmpMk WITH(NOLOCK) ON b.liveindicator = ISNULL(tmpMk.LiveIndicator,b.LiveIndicator)
			INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.CustId = b.CustId
		WHERE EXISTS (	SELECT 1 
						FROM  #tmpDanger AS tmpDg WITH(NOLOCK) 
						WHERE  c.Danger = ISNULL(tmpDg.Danger1,c.Danger)
								AND c.Danger2 = ISNULL(tmpDg.Danger2,c.Danger)
								AND c.Danger3 = ISNULL(tmpDg.Danger3,c.Danger)
								AND c.Danger4 = ISNULL(tmpDg.Danger4,c.Danger)
								AND c.Danger5 = ISNULL(tmpDg.Danger5,c.Danger))
		GROUP BY b.MatchId, b.LiveIndicator, b.Bettype, tmpBt.BetID, tmpBt.BetChoiceType;
	END;
	
	-- Return data
	SELECT	tmpMi.MatchId
		,	tmpMi.LiveIndicator
		,	tmpMi.Bettype
		,	tmpMi.BetID
		,	tmpMi.BetChoiceType
		,	tmpMi.TotalAmountHome
		,	tmpMi.TotalAmountAway
		,	tmpMi.TotalTicketHome
		,	tmpMi.TotalTicketAway
	FROM #tmpMatchesInfo AS tmpMi WITH(NOLOCK);

	DROP TABLE #tmpMatches;
	DROP TABLE #tmpMatchesInfo;


GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/