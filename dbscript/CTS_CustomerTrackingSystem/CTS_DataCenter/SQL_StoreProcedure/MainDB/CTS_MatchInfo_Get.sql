/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_MatchInfo_Get]
		@MatchIds			VARCHAR(MAX) = ''
	,	@FromDate			DATETIME = NULL
	,	@ToDate				DATETIME = NULL
	,	@SportList			VARCHAR(MAX) = ''
	,	@MatchSectionList	VARCHAR(100) = ''
	
AS
/*
	Created: 20220628@Long.Luu
	Task : Get Match Info
	DB	 : bodb02

	Revisions:
		- 20220628@Long.Luu: Created [Redmine ID: #174430]
		- 20230102@Casey.Huynh: Filter Match by @FromDate,@ToDate,@SportList,@MatchSectionList [Redmine ID: #196361]

	Params Explaination:
		EXECUTE [dbo].[CTS_MatchInfo_Get] @MatchIds = '74703210,74703212,74703213,77743434,77743439,77935592,77391610,77391589,77391614';
		EXECUTE [dbo].[CTS_MatchInfo_Get] @MatchIds = NULL,@FromDate='2024-01-01', @ToDate='2024-01-02', @SportList	= '1,2,3,154', @MatchSectionList = '1,2,3,4' ;
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
	--=================================================================================================
	IF	OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatches;
	END;

	CREATE TABLE #tmpMatches(
		MatchId		INT 
	);

	CREATE INDEX IX_tmpMatches_MatchId ON #tmpMatches(MatchId);

	--=================================================================================================
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

	IF @MatchIds <> '' --GET Match Info By List MatchID
	BEGIN

		INSERT INTO #tmpMatches (MatchId)
		SELECT ssk.value FROM STRING_SPLIT (@MatchIds, ',') ssk;

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
			,	(CASE WHEN m.eventstatus <> 'completed' THEN (CASE WHEN m.GlobalShowTime <= GETDATE() THEN @MatchSection_Live --LIVE
																	WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN @MatchSection_Today	 --TODAY
																	WHEN m.EventDate > @Today THEN @MatchSection_Early -- EARLY
																END)
					ELSE @MatchSection_Closed -- CLOSED
				END) AS MatchSection
			,	@DataSource_Origin
		FROM #tmpMatches AS tm WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Match AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;

		DELETE tm
		FROM #tmpMatches AS tm
		INNER JOIN #tmpMatchesInfo AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;

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
			,	@MatchSection_Closed
			,	@DataSource_14
		FROM #tmpMatches AS tm WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Match14 AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;
		
		DELETE tm
		FROM #tmpMatches AS tm
			INNER JOIN #tmpMatchesInfo AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;

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
			,	@MatchSection_Closed
			,	@DataSource_bk
		FROM #tmpMatches AS tm WITH(NOLOCK)
			INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;
	END;
	ELSE IF (@FromDate IS NOT NULL)-- GET Match Info By @FromDate, @ToDate, @SportList, @MatchSectionList
	BEGIN
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
		
		IF	@IsGetDataFromBK = 1
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
					FROM bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) 
						INNER JOIN #tmpSport AS tmpSp ON m.sporttype = ISNULL(tmpSp.SportType,m.sporttype)
					WHERE m.EventDate BETWEEN @FromDateBK AND @ToDateBK
					) AS tmp
				INNER JOIN #tmpMatchSection AS tmpMs ON tmp.MatchSection = ISNULL(tmpMs.MatchSection,tmp.MatchSection);

		END

		IF	@IsGetDataFrom14 = 1
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
					FROM bodb02.dbo.match14 AS m WITH(NOLOCK) 
						INNER JOIN #tmpSport AS tmpSp ON m.sporttype = ISNULL(tmpSp.SportType,m.sporttype)
					WHERE m.EventDate BETWEEN @FromDate14 AND @ToDate14
					) AS tmp
				INNER JOIN #tmpMatchSection AS tmpMs ON tmp.MatchSection = ISNULL(tmpMs.MatchSection,tmp.MatchSection);

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
				INNER JOIN #tmpMatchSection AS tmpMs ON tmp.MatchSection = ISNULL(tmpMs.MatchSection,tmp.MatchSection);			

		END;
	END;

	-- Return data
	SELECT	tmpMi.MatchId
		,	tmpMi.MatchCode
		,	tmpMi.SportType
		,	tmpMi.LeagueId
		,	tmpMi.EventDate
		,	tmpMi.KickOffTime
		,	tmpMi.HomeId
		,	tmpMi.AwayId
		,	tmpMi.EventStatus
		,	tmpMi.LiveHomeScore
		,	tmpMi.LiveAwayScore
		,	tmpMi.HTHomeScore
		,	tmpMi.HTAwayScore
		,	tmpMi.FinalHomeScore
		,	tmpMi.FinalAwayScore
		,	tmpMi.MatchSection
		,	tmpMi.DataSource
	FROM #tmpMatchesInfo AS tmpMi WITH(NOLOCK)
	ORDER BY tmpMi.EventDate DESC;

	DROP TABLE #tmpMatches;
	DROP TABLE #tmpMatchesInfo;

END;

GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/