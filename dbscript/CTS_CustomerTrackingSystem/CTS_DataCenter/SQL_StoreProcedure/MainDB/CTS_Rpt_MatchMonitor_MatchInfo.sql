/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CTS_Rpt_MatchMonitor_MatchInfo]
		@MatchIds			VARCHAR(MAX) = ''
	,	@FromDateTime		DATETIME
	,	@ToDateTime			DATETIME
	,	@MatchSection		VARCHAR(20)
AS
/*
	Created: 20230214@Victoria.Le
	Task : Get Match Info
	DB	 : bodb02

	Revisions:
		- 20230214@Victoria.Le:			Initial Writing [Redmine ID: #183280]

	Params Explaination:
		- @MatchIds:
			+ @MatchIds = ''	==> Get Match Info by EventDate (FromDateTime & ToDateTime)
			+ @MatchIds <> ''	==> Get Match Info by List MatchId
	
	Filter by ScanDate:
		EXECUTE [dbo].[CTS_Rpt_MatchMonitor_MatchInfo] @MatchIds = '40391219,40391223,1207560', @FromDateTime = '', @ToDateTime = '', @MatchSection = '1,2,3,4'
	Filter by EventDate:
		EXECUTE [dbo].[CTS_Rpt_MatchMonitor_MatchInfo] @MatchIds = '', @FromDateTime = '2023-02-21', @ToDateTime = '2023-02-25', @MatchSection = '1,2,3,4'
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @Today			DATE = GETDATE()

	IF	OBJECT_ID('tempdb..#tmpMatchSection') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatchSection
	END

	CREATE TABLE #tmpMatchSection (
			MatchSection		TINYINT
	)

	IF	OBJECT_ID('tempdb..#tmpMatchesInfo') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatchesInfo
	END

	CREATE TABLE #tmpMatchesInfo (
			MatchId				INT NOT NULL PRIMARY KEY
		,	EventDate			DATETIME
		,	KickOffTime			DATETIME
		,	MatchSection		TINYINT
	)

	INSERT INTO #tmpMatchSection (MatchSection)
	SELECT ms.value FROM STRING_SPLIT (@MatchSection, ',') ms

	IF ISNULL(@MatchIds,'') = ''
	BEGIN

		DECLARE @BalanceUpDay			SMALLDATETIME
			,	@MoveBetsDay			SMALLDATETIME

		DECLARE @IsGetDataFromOrigin	BIT = 0
			,	@IsGetDataFrom14		BIT = 0
			,	@IsGetDataFromBK		BIT = 0

		DECLARE @FromDateOrigin			SMALLDATETIME = NULL
			,	@ToDateOrigin			SMALLDATETIME = NULL
			,	@FromDate14				SMALLDATETIME = NULL
			,	@ToDate14				SMALLDATETIME = NULL
			,	@FromDateBK				SMALLDATETIME = NULL
			,	@ToDateBK				SMALLDATETIME = NULL
	
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
		
		-- For @FromDateTime
		IF @FromDateTime < @BalanceUpDay
		BEGIN
			SET @IsGetDataFromBK = 1
		END
		ELSE IF @FromDateTime <= @MoveBetsDay
		BEGIN
			SET @IsGetDataFrom14 = 1
		END
		ELSE IF @FromDateTime > @MoveBetsDay
		BEGIN
			SET @IsGetDataFromOrigin = 1
		END

		-- For @ToDateTime
		IF @ToDateTime < @BalanceUpDay
		BEGIN
			SET @IsGetDataFromBK = 1
		END
		ELSE IF @ToDateTime <= @MoveBetsDay
		BEGIN
			SET @IsGetDataFrom14 = 1
		END
		ELSE IF @ToDateTime > @MoveBetsDay
		BEGIN
			SET @IsGetDataFromOrigin = 1
		END

		IF @FromDateTime < @BalanceUpDay AND @ToDateTime > @MoveBetsDay
		BEGIN
			SET @IsGetDataFromBK		= 1
			SET @IsGetDataFrom14		= 1
			SET @IsGetDataFromOrigin	= 1
		END

		IF (@IsGetDataFromBK = 1 AND @IsGetDataFromOrigin = 1)
			OR (@IsGetDataFromBK = 1 AND @IsGetDataFrom14 = 1 AND @IsGetDataFromOrigin = 1)
		BEGIN
			SELECT	@FromDateOrigin		=	DATEADD(DD,1,@MoveBetsDay)
				,	@ToDateOrigin		=	@ToDateTime
				,	@FromDate14			=	@BalanceUpDay
				,	@ToDate14			=	@MoveBetsDay
				,	@FromDateBK			=	@FromDateTime 
				,	@ToDateBK			=	DATEADD(DD,-1,@BalanceUpDay)
		END

		IF @IsGetDataFromBK = 1 AND @IsGetDataFrom14 = 1 AND @IsGetDataFromOrigin = 0
		BEGIN
			SELECT	@FromDate14			=	@BalanceUpDay
				,	@ToDate14			=	@ToDateTime
				,	@FromDateBK			=	@FromDateTime 
				,	@ToDateBK			=	DATEADD(DD,-1,@BalanceUpDay)
		END

		IF @IsGetDataFromBK = 0 AND @IsGetDataFrom14 = 1 AND @IsGetDataFromOrigin = 1
		BEGIN
			SELECT	@FromDateOrigin		=	DATEADD(DD,1,@MoveBetsDay)
				,	@ToDateOrigin		=	@ToDateTime
				,	@FromDate14			=	@FromDateTime
				,	@ToDate14			=	@MoveBetsDay
		END

		IF @IsGetDataFromBK = 1 AND @IsGetDataFrom14 = 0 AND @IsGetDataFromOrigin = 0
		BEGIN
			SELECT	@FromDateBK			=	@FromDateTime 
				,	@ToDateBK			=	@ToDateTime
		END

		IF @IsGetDataFromBK = 0 AND @IsGetDataFrom14 = 1 AND @IsGetDataFromOrigin = 0
		BEGIN
			SELECT	@FromDate14			=	@FromDateTime
				,	@ToDate14			=	@ToDateTime
		END

		IF @IsGetDataFromBK = 0 AND @IsGetDataFrom14 = 0 AND @IsGetDataFromOrigin = 1
		BEGIN
			SELECT	@FromDateOrigin		=	@FromDateTime
				,	@ToDateOrigin		=	@ToDateTime
		END

		IF	@IsGetDataFromBK = 1
		BEGIN
			INSERT INTO #tmpMatchesInfo (MatchId,EventDate,KickOffTime,MatchSection)
			SELECT	m.MatchId
				,	m.EventDate
				,	m.GlobalShowTime
				,	CASE
						WHEN m.eventstatus <> 'completed' THEN (CASE 
																	WHEN m.GlobalShowTime <= GETDATE() THEN 1 --LIVE
																	WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN 2 --TODAY
																	WHEN m.EventDate > @Today THEN 3 -- EARLY
																END)
						ELSE 4 -- CLOSED
					END
			FROM bodb_Archive.dbo.match_bk AS m WITH(NOLOCK)
			WHERE m.EventDate BETWEEN @FromDateBK AND @ToDateBK
				AND m.sporttype IN (1,2,43) --1: Soccer; 2: Baseketball, 43: ESport

		END

		IF	@IsGetDataFrom14 = 1
		BEGIN
			INSERT INTO #tmpMatchesInfo (MatchId,EventDate,KickOffTime,MatchSection)
			SELECT	m.MatchId
				,	m.EventDate
				,	m.GlobalShowTime
				,	CASE
						WHEN m.eventstatus <> 'completed' THEN (CASE 
																	WHEN m.GlobalShowTime <= GETDATE() THEN 1 --LIVE
																	WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN 2 --TODAY
																	WHEN m.EventDate > @Today THEN 3 -- EARLY
																END)
						ELSE 4 -- CLOSED
					END
			FROM bodb02.dbo.match14 AS m WITH(NOLOCK)
			WHERE m.EventDate BETWEEN @FromDate14 AND @ToDate14
				AND m.sporttype IN (1,2,43) --1: Soccer; 2: Baseketball, 43: ESport
		END

		IF	@IsGetDataFromOrigin = 1
		BEGIN
			INSERT INTO #tmpMatchesInfo (MatchId,EventDate,KickOffTime,MatchSection)
			SELECT	m.MatchId
				,	m.EventDate
				,	m.GlobalShowTime
				,	CASE
						WHEN m.eventstatus <> 'completed' THEN (CASE 
																	WHEN m.GlobalShowTime <= GETDATE() THEN 1 --LIVE
																	WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN 2 --TODAY
																	WHEN m.EventDate > @Today THEN 3 -- EARLY
																END)
						ELSE 4 -- CLOSED
					END
			FROM bodb02.dbo.Match AS m WITH(NOLOCK)
			WHERE m.EventDate BETWEEN @FromDateOrigin AND @ToDateOrigin
				AND m.sporttype IN (1,2,43) --1: Soccer; 2: Baseketball, 43: ESport

		END
	
		DROP TABLE #BUMBData
	END
	ELSE
	BEGIN

		IF	OBJECT_ID('tempdb..#tmpMatches') IS NOT NULL
		BEGIN
			DROP TABLE #tmpMatches
		END

		CREATE TABLE #tmpMatches(
				MatchId				INT NOT NULL PRIMARY KEY
		)

		INSERT INTO #tmpMatches (MatchId)
		SELECT ssk.value FROM STRING_SPLIT (@MatchIds, ',') ssk

		--FromBK
		INSERT INTO #tmpMatchesInfo (MatchId,EventDate,KickOffTime,MatchSection)
		SELECT	m.MatchId
			,	m.EventDate
			,	m.GlobalShowTime
			,	CASE
					WHEN m.eventstatus <> 'completed' THEN (CASE 
																WHEN m.GlobalShowTime <= GETDATE() THEN 1 --LIVE
																WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN 2 --TODAY
																WHEN m.EventDate > @Today THEN 3 -- EARLY
															END)
					ELSE 4 -- CLOSED
				END
		FROM #tmpMatches AS tm 
			INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON tm.MatchId = m.matchid
		
		DELETE tm
		FROM #tmpMatches AS tm
		INNER JOIN #tmpMatchesInfo AS m ON tm.MatchId = m.matchid

		--From14
		INSERT INTO #tmpMatchesInfo (MatchId,EventDate,KickOffTime,MatchSection)
		SELECT	m.MatchId
			,	m.EventDate
			,	m.GlobalShowTime
			,	CASE
					WHEN m.eventstatus <> 'completed' THEN (CASE 
																WHEN m.GlobalShowTime <= GETDATE() THEN 1 --LIVE
																WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN 2 --TODAY
																WHEN m.EventDate > @Today THEN 3 -- EARLY
															END)
					ELSE 4 -- CLOSED
				END
		FROM #tmpMatches AS tm 
			INNER JOIN bodb02.dbo.match14 AS m WITH(NOLOCK) ON tm.MatchId = m.matchid

		DELETE tm
		FROM #tmpMatches AS tm
		INNER JOIN #tmpMatchesInfo AS m ON tm.MatchId = m.matchid

		-- FromOrigin
		INSERT INTO #tmpMatchesInfo (MatchId,EventDate,KickOffTime,MatchSection)
		SELECT	m.MatchId
			,	m.EventDate
			,	m.GlobalShowTime
			,	CASE
					WHEN m.eventstatus <> 'completed' THEN (CASE 
																WHEN m.GlobalShowTime <= GETDATE() THEN 1 --LIVE
																WHEN m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN 2 --TODAY
																WHEN m.EventDate > @Today THEN 3 -- EARLY
															END)
					ELSE 4 -- CLOSED
				END
		FROM #tmpMatches AS tm
			INNER JOIN bodb02.dbo.Match AS m WITH(NOLOCK) ON tm.MatchId = m.matchid

		DROP TABLE #tmpMatches
	END

	SELECT	tmi.MatchId
		,	tmi.EventDate
		,	tmi.KickOffTime
		,	tmi.MatchSection
	FROM #tmpMatchesInfo AS tmi
		LEFT JOIN #tmpMatchSection AS tms ON tmi.MatchSection = tms.MatchSection

	DROP TABLE #tmpMatchesInfo
	DROP TABLE #tmpMatchSection

END

GO
