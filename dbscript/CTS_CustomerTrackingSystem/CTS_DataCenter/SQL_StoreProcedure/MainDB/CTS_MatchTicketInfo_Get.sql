/*<info serverAlias="DBCTS-bodb02" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
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
	,	@MatchSection		VARCHAR(10) = '' 	-- STRING
	,	@DangerLevels		VARCHAR(10)
	,	@SportSabaLeagueGroup	VARCHAR(200) = ''
	,	@IsExclTestCurr		BIT = 1
AS
/*
	Created: 20240102@Casey.Huynh
	Task : Get Match Ticket Info
	DB	 : bodb02

	Revisions:
		- 20240102@Casey.Huynh: Created [Redmine ID: #196361]
		- 20240322@Vitoria.Le: 	Change inputs to optimize query data [Redmine ID: #201380]

	Params Explaination:
		,@BettypeList='[	{"BetType":1, "BetChoiceType":2}
						,	{"BetType":2, "BetChoiceType":2}
						,	{"BetType":126, "BetChoiceType":1}]'
		
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
	,	@MatchSection		= '1,2' -- multi selection instead of single selection
	,	@DangerLevels       = '1_10' -- remove @DangerList= NULL due to single seletion
	,	@SportSabaLgGroup	= '1_42,1_74,50_42'
	,	@IsExclTestCurr		= 1
	
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @Today					DATE = GETDATE();

	DECLARE @BalanceUpDay			DATETIME
		,	@MoveBetsDay			DATETIME
		,	@FDate 					DATETIME 
		, 	@TDate 					DATETIME 
		
		,	@MatchSection_Live		TINYINT = 1
		,	@MatchSection_Today		TINYINT = 2
		,	@MatchSection_Early		TINYINT = 3
		,	@MatchSection_Closed	TINYINT = 4
		
		,	@DangerType				TINYINT
		,	@Danger					TINYINT
		,	@IsExcludeSabaGroup		BIT = 1
		,	@IsFromActive14			TINYINT = 0
		;

	--===============================================================================================
	DECLARE @tmpBUMBData AS TABLE (BUDay DATETIME,	MBDay DATETIME);
	DECLARE @tmpSport AS TABLE (SportType TINYINT PRIMARY KEY);
	DECLARE @tmpMatchSection AS TABLE (Id TINYINT, EventStatus NVARCHAR(50), IsFrom14 BIT DEFAULT 0);
	DECLARE @tmpSportSabaLeagueGroup AS TABLE (SportType TINYINT, LeagueGroupID INT INDEX IX_SabaLeagueGroup);

	IF	OBJECT_ID('tempdb..#tmpBetType') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBetType;
	END;

	CREATE TABLE #tmpBetType (
				BetType			INT
			,	BetChoiceType	TINYINT 		
			,	BetChoiceHome	NVARCHAR(10) 	
			,	BetChoiceAway	NVARCHAR(10) 	
			,	BetIdPattern	NVARCHAR(20)	
			,	BetId			BIGINT			
	);
	
	IF	OBJECT_ID('tempdb..#tmpDangerCust') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDangerCust;
	END;

	CREATE TABLE	#tmpDangerCust(
			CustId				INT 	
	);
	
	IF	OBJECT_ID('tempdb..#tmpMatchSum') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatchSum;
	END;

	CREATE TABLE #tmpMatchSum (
			MatchId				INT NOT NULL
		,	LiveIndicator		BIT NOT NULL
		,	Bettype				INT NOT NULL
		,	BetId				BIGINT 
		,	BetChoiceType		TINYINT
		,	TotalAmountHome		MONEY
		,	TotalAmountAway		MONEY
		,	TotalTicketHome		MONEY
		,	TotalTicketAway		MONEY
		,	IsFrom14			BIT DEFAULT 0
	);
	
	--===============================================================================================
	INSERT INTO @tmpBUMBData (BUDay, MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;
	
	SELECT	TOP(1) @BalanceUpDay = BUDay, @MoveBetsDay	= MBDay
	FROM @tmpBUMBData;
	
	IF (@ToDate IS NULL)
	BEGIN
		SET @ToDate = (SELECT MAX(m.EventDate) FROM bodb02.dbo.Match AS m WITH(NOLOCK));
	END
	
	SELECT 	@FDate = @FromDate, @TDate = @ToDate;
	
	INSERT INTO @tmpSport (SportType)
	SELECT ssk.value FROM STRING_SPLIT (@SportList, ',') AS ssk;
	
	INSERT INTO #tmpBetType(BetType,BetChoiceType,BetChoiceHome,BetChoiceAway,BetIdPattern,BetId)
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
	
	INSERT INTO @tmpMatchSection (Id, EventStatus)
	SELECT 	ssk.value
		,	CASE 
				WHEN ssk.value = @MatchSection_Closed THEN 'Completed'
				WHEN ssk.value IN (@MatchSection_Live,@MatchSection_Today,@MatchSection_Early) THEN 'running'
				ELSE ''
			END
	FROM STRING_SPLIT(@MatchSection, ',') AS ssk;
	
	IF EXISTS (SELECT 1 FROM @tmpMatchSection WHERE Id IN (@MatchSection_Live,@MatchSection_Today,@MatchSection_Early))
	BEGIN
		INSERT INTO @tmpMatchSection (Id, EventStatus)
		SELECT Id,a
		FROM (VALUES ('Closed'),('Postponed'),('internal'))  AS X(a)
			CROSS APPLY (SELECT Id 
						FROM @tmpMatchSection
						WHERE Id IN (@MatchSection_Live,@MatchSection_Today,@MatchSection_Early)) AS ms;
		
	END;
	
	WITH CTE_Danger AS (
		SELECT 	CAST(LEFT(ssk.value, CHARINDEX('_', ssk.value)-1) AS TINYINT) AS DangerType
			,	CAST(SUBSTRING(ssk.value, CHARINDEX('_', ssk.value)+1, 6) AS TINYINT) AS Danger
		FROM STRING_SPLIT (@DangerLevels, ',') AS ssk
		WHERE LEN(ssk.value) > 0
	)
	SELECT @DangerType = DangerType, @Danger = Danger
	FROM CTE_Danger;
	
	IF (@SportSabaLeagueGroup <> '')
	BEGIN
		SET @IsExcludeSabaGroup = 0;
	
		INSERT INTO @tmpSportSabaLeagueGroup (SportType, LeagueGroupID)
		SELECT 	CAST(LEFT(ssk.value, CHARINDEX('_', ssk.value)-1) AS TINYINT) AS SportType
			,	CAST(SUBSTRING(ssk.value, CHARINDEX('_', ssk.value)+1, 6) AS TINYINT) AS LeagueGroupID
		FROM STRING_SPLIT (@SportSabaLeagueGroup, ',') AS ssk
		WHERE LEN(ssk.value) > 0;
	END;

	IF @DangerType = 1 
	BEGIN
		INSERT INTO #tmpDangerCust(CustId)
		SELECT cust.custid
		FROM bodb02.dbo.CustInfo AS cust WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Customer AS cs WITH (NOLOCK) ON cs.custid = cust.custid 
		WHERE cs.site NOT IN ('Nextbet','9wickets','9wsports')
			AND cust.username NOT LIKE '%Cashout%'
			AND cust.mrecommend NOT IN (27899314,11656504,12146012) 
			AND cust.recommend NOT IN (52466,5707545,29270764,134456,27787409,48367475,93558369,16604398)
			AND (CASE WHEN @IsExclTestCurr = 0 THEN 1 
					  WHEN @IsExclTestCurr = 1 AND cust.currency NOT IN (20,27,28) THEN 1 
					  ELSE 0 END = 1)
			AND cust.srecommend NOT IN (41430709) 
			AND cust.RoleId = 1
			AND cust.danger > 0 AND cust.danger = @Danger
			;
	END;
	IF @DangerType = 2
	BEGIN
		INSERT INTO #tmpDangerCust(CustId)
		SELECT cust.custid
		FROM bodb02.dbo.CustInfo AS cust WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Customer AS cs WITH (NOLOCK) ON cs.custid = cust.custid
		WHERE cs.site NOT IN ('Nextbet','9wickets','9wsports')
			AND cust.username NOT LIKE '%Cashout%'
			AND cust.mrecommend NOT IN (27899314,11656504,12146012) 
			AND cust.recommend NOT IN (52466,5707545,29270764,134456,27787409,48367475,93558369,16604398)
			AND (CASE WHEN @IsExclTestCurr = 0 THEN 1 
					  WHEN @IsExclTestCurr = 1 AND cust.currency NOT IN (20,27,28) THEN 1 
					  ELSE 0 END = 1)
			AND cust.srecommend NOT IN (41430709) 
			AND cust.RoleId = 1
			AND cust.danger2 > 0 AND cust.danger2 = @Danger
			;
	END;
	IF @DangerType = 3
	BEGIN
		INSERT INTO #tmpDangerCust(CustId)
		SELECT cust.custid
		FROM bodb02.dbo.CustInfo AS cust WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Customer AS cs WITH (NOLOCK) ON cs.custid = cust.custid 
		WHERE cs.site NOT IN ('Nextbet','9wickets','9wsports')
			AND cust.username NOT LIKE '%Cashout%'
			AND cust.mrecommend NOT IN (27899314,11656504,12146012) 
			AND cust.recommend NOT IN (52466,5707545,29270764,134456,27787409,48367475,93558369,16604398)
			AND (CASE WHEN @IsExclTestCurr = 0 THEN 1 
					  WHEN @IsExclTestCurr = 1 AND cust.currency NOT IN (20,27,28) THEN 1 
					  ELSE 0 END = 1)
			AND cust.srecommend NOT IN (41430709) 
			AND cust.RoleId = 1
			AND cust.danger3 > 0 AND cust.danger3 = @Danger
			;
	END;
	IF @DangerType = 4
	BEGIN
		INSERT INTO #tmpDangerCust(CustId)
		SELECT cust.custid
		FROM bodb02.dbo.CustInfo AS cust WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Customer AS cs WITH (NOLOCK) ON cs.custid = cust.custid 
		WHERE cs.site NOT IN ('Nextbet','9wickets','9wsports')
			AND cust.username NOT LIKE '%Cashout%'
			AND cust.mrecommend NOT IN (27899314,11656504,12146012) 
			AND cust.recommend NOT IN (52466,5707545,29270764,134456,27787409,48367475,93558369,16604398)
			AND (CASE WHEN @IsExclTestCurr = 0 THEN 1 
					  WHEN @IsExclTestCurr = 1 AND cust.currency NOT IN (20,27,28) THEN 1 
					  ELSE 0 END = 1)
			AND cust.srecommend NOT IN (41430709) 
			AND cust.RoleId = 1
			AND cust.danger4 > 0 AND cust.danger4 = @Danger
			;
	END;
	IF @DangerType = 5
	BEGIN
		INSERT INTO #tmpDangerCust(CustId)
		SELECT cust.custid
		FROM bodb02.dbo.CustInfo AS cust WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Customer AS cs WITH (NOLOCK) ON cs.custid = cust.custid 
		WHERE cs.site NOT IN ('Nextbet','9wickets','9wsports')
			AND cust.username NOT LIKE '%Cashout%'
			AND cust.mrecommend NOT IN (27899314,11656504,12146012) 
			AND cust.recommend NOT IN (52466,5707545,29270764,134456,27787409,48367475,93558369,16604398)
			AND (CASE WHEN @IsExclTestCurr = 0 THEN 1 
					  WHEN @IsExclTestCurr = 1 AND cust.currency NOT IN (20,27,28) THEN 1 
					  ELSE 0 END = 1)
			AND cust.srecommend NOT IN (41430709) 
			AND cust.RoleId = 1
			AND cust.danger5 > 0 AND cust.danger5 = @Danger
			;
	END;

	CREATE CLUSTERED INDEX CIX_tmpDangerCust ON #tmpDangerCust(CustId);

	IF @Todate > @MoveBetsDay
	BEGIN
		IF @FromDate <= @MoveBetsDay
		BEGIN
			SET @FDate = DATEADD(DD, 1, @MoveBetsDay);
		END;

		INSERT INTO #tmpMatchSum(MatchId, LiveIndicator,BetChoiceType, Bettype,BetID, TotalAmountHome, TotalAmountAway, TotalTicketHome, TotalTicketAway)
		SELECT 	b.MatchId
			,	b.LiveIndicator
			,	t.BetChoiceType
			,	b.Bettype
			,	b.BetID
			,	SUM(CASE WHEN t.BetChoiceType = 2 AND b.betteam = t.BetChoiceHome THEN b.stake * b.actualrate 
						 WHEN t.BetChoiceType = 1 THEN b.stake * b.actualrate 
						 ELSE 0 END) AS TotalAmountHome
			,	SUM(CASE WHEN t.BetChoiceType = 2 AND b.betteam = t.BetChoiceAway THEN b.stake * b.actualrate 
						 ELSE 0 END) AS TotalAmountAway
			,	SUM(CASE WHEN t.BetChoiceType = 2 AND b.betteam = t.BetChoiceHome THEN 1 
						 WHEN t.BetChoiceType = 1 THEN 1
						 ELSE 0 END) AS TotalTicketHome
			,	SUM(CASE WHEN t.BetChoiceType = 2 AND b.betteam = t.BetChoiceAway THEN 1 
						 ELSE 0 END) AS TotalTicketAway
		FROM bodb02.dbo.bettrans AS b WITH(NOLOCK)
			INNER JOIN #tmpDangerCust AS cust WITH(NOLOCK) ON cust.custid = b.custid
			INNER JOIN #tmpBetType AS t WITH(NOLOCK) ON b.bettype = t.bettype AND t.BetId = b.betid
		WHERE b.winlostdate >= @FDate AND b.winlostdate <= @TDate
			AND (CASE WHEN @MarketList = '' THEN 1
					  WHEN @MarketList <> '' AND b.LiveIndicator IN (SELECT ssk.value FROM STRING_SPLIT (@MarketList, ',') AS ssk) THEN 1
					  ELSE 0 END = 1)
		GROUP BY b.MatchId, t.BetChoiceType, b.Bettype, b.LiveIndicator, b.BetId
		-- OPTION (RECOMPILE)
		;

		IF (@@ROWCOUNT > 0)
		BEGIN
			SET @IsFromActive14 = 1;
		END;
	END;

	IF @Fromdate <= @MoveBetsDay
	BEGIN
		IF @BalanceUpDay < @FromDate
		BEGIN
			SET @FDate = @FromDate;
		END
		ELSE
		BEGIN
			SET @FDate = @BalanceUpDay;
		END;
			
		IF @ToDate > @MoveBetsDay
		BEGIN
			SET @TDate = @MoveBetsDay;
		END;
		
		INSERT INTO #tmpMatchSum(MatchId, LiveIndicator,BetChoiceType, Bettype,BetID, TotalAmountHome, TotalAmountAway, TotalTicketHome, TotalTicketAway, IsFrom14)
		SELECT 	b.MatchId
				,	b.LiveIndicator
				,	t.BetChoiceType
				,	b.Bettype
				,	b.BetID
				,	SUM(CASE WHEN t.BetChoiceType = 2 AND b.betteam = t.BetChoiceHome THEN b.stake * b.actualrate 
							WHEN t.BetChoiceType = 1 THEN b.stake * b.actualrate 
							ELSE 0 END) AS TotalAmountHome
				,	SUM(CASE WHEN t.BetChoiceType = 2 AND b.betteam = t.BetChoiceAway THEN b.stake * b.actualrate 
							ELSE 0 END) AS TotalAmountAway
				,	SUM(CASE WHEN t.BetChoiceType = 2 AND b.betteam = t.BetChoiceHome THEN 1 
							WHEN t.BetChoiceType = 1 THEN 1
							ELSE 0 END) AS TotalTicketHome
				,	SUM(CASE WHEN t.BetChoiceType = 2 AND b.betteam = t.BetChoiceAway THEN 1 
							ELSE 0 END) AS TotalTicketAway
				,	1
			FROM bodb02.dbo.bettrans14 AS b WITH(NOLOCK)
				INNER JOIN #tmpDangerCust AS cust WITH(NOLOCK) ON cust.custid = b.custid
				INNER JOIN #tmpBetType AS t WITH(NOLOCK) ON b.bettype = t.bettype AND t.BetId = b.betid
			WHERE b.winlostdate BETWEEN @FDate AND @TDate
				AND (CASE WHEN @MarketList = '' THEN 1
					      WHEN @MarketList <> '' AND b.LiveIndicator IN (SELECT ssk.value FROM STRING_SPLIT (@MarketList, ',') AS ssk) THEN 1
					      ELSE 0 END = 1)
			GROUP BY b.MatchId, t.BetChoiceType, b.Bettype, b.LiveIndicator, b.BetId
			-- OPTION (RECOMPILE)
			;

		IF (@@ROWCOUNT > 0)
		BEGIN
			IF EXISTS (SELECT 1 FROM @tmpMatchSection WHERE Id = @MatchSection_Closed)
			BEGIN
				INSERT INTO @tmpMatchSection (Id, IsFrom14, EventStatus)
				SELECT @MatchSection_Closed, 1, *
				FROM (VALUES ('Completed'),('Closed'),('Postponed'),('internal'))  AS X(a);
			END;
			
			IF (@IsFromActive14 = 0)
			BEGIN
				SET @IsFromActive14 = 2;
			END
			ELSE
			BEGIN
				SET @IsFromActive14 = 3;
			END;
		END;
	END

	-- CREATE CLUSTERED INDEX CIX_tmpMatchSum ON #tmpMatchSum(MatchId,IsFrom14);
	CREATE CLUSTERED INDEX CIX_tmpMatchSum ON #tmpMatchSum(MatchId);

	IF @IsFromActive14 = 1
	BEGIN
		SELECT 	tms.MatchId
			,	m.leagueid AS LeagueId
			,	l.LeagueName
			,	m.EventDate
			,	m.GlobalShowTime
			,	mss.MatchSection
			,	m.SportType
			,	m.homeid AS HomeId
			,	h.TeamName AS HomeName
			,	m.awayid AS AwayId
			,	a.TeamName AS AwayName
			,	tms.LiveIndicator
			,	tms.Bettype
			,	tms.BetID
			,	tms.BetChoiceType
			,	tms.TotalAmountHome
			,	tms.TotalAmountAway
			,	tms.TotalTicketHome
			,	tms.TotalTicketAway
			,	tms.IsFrom14
			FROM #tmpMatchSum AS tms
				INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON m.MatchId = tms.MatchId AND tms.IsFrom14 = 0
				INNER JOIN bodb02.dbo.team AS h WITH(NOLOCK) ON h.TeamId = m.homeid 
				INNER JOIN bodb02.dbo.team AS a WITH(NOLOCK) ON a.TeamId = m.awayid
				INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid 
				CROSS APPLY (SELECT TOP 1 ms.Id AS MatchSection
							 FROM @tmpMatchSection AS ms
							 WHERE ms.IsFrom14 = 0
								AND 1 = CASE WHEN m.EventStatus <> 'completed' THEN (CASE WHEN ms.Id = @MatchSection_Live AND m.GlobalShowTime <= GETDATE() THEN 1
																						WHEN ms.Id = @MatchSection_Today AND m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN 1
																						WHEN ms.Id = @MatchSection_Early AND m.EventDate > @Today THEN 1 END)
											 WHEN m.EventStatus = ms.EventStatus AND ms.Id = @MatchSection_Closed THEN 1
											 ELSE 0 END) AS mss
			WHERE l.IsTest = 0 AND m.isTestMatch = 0 AND m.IsDeleted = 0 
				AND (CASE WHEN @IsExcludeSabaGroup = 1 AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
								AND EXISTS (SELECT 1 FROM @tmpSport AS s WHERE m.SportType = s.SportType) THEN 1
						  WHEN @IsExcludeSabaGroup = 0 AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
								AND EXISTS (SELECT 1 FROM @tmpSport AS s WHERE m.SportType = s.SportType) THEN 1
						  WHEN @IsExcludeSabaGroup = 0 AND l.LeagueGroupID IN (42,74,108,113,122,151)
								AND EXISTS (SELECT 1 FROM @tmpSportSabaLeagueGroup AS sl 
														WHERE m.SportType = sl.SportType AND l.LeagueGroupID = sl.LeagueGroupID) THEN 1
						  ELSE 0 END = 1)
				AND (l.LeagueName LIKE '%' + @LeagueEvent + '%'
						OR h.TeamName LIKE '%' + @LeagueEvent + '%'
						OR a.TeamName LIKE '%' + @LeagueEvent + '%')
		-- OPTION (RECOMPILE)
		;
	END
	ELSE IF @IsFromActive14 = 2
	BEGIN
		SELECT 	tms.MatchId
			,	m.leagueid AS LeagueId
			,	l.LeagueName
			,	m.EventDate
			,	m.GlobalShowTime
			,	mss.MatchSection
			,	m.SportType
			,	m.homeid AS HomeId
			,	h.TeamName AS HomeName
			,	m.awayid AS AwayId
			,	a.TeamName AS AwayName
			,	tms.LiveIndicator
			,	tms.Bettype
			,	tms.BetID
			,	tms.BetChoiceType
			,	tms.TotalAmountHome
			,	tms.TotalAmountAway
			,	tms.TotalTicketHome
			,	tms.TotalTicketAway
			,	tms.IsFrom14
			FROM #tmpMatchSum AS tms
				INNER JOIN bodb02.dbo.match14 AS m WITH(NOLOCK) ON m.MatchId = tms.MatchId AND tms.IsFrom14 = 1
				INNER JOIN bodb02.dbo.team AS h WITH(NOLOCK) ON h.TeamId = m.homeid 
				INNER JOIN bodb02.dbo.team AS a WITH(NOLOCK) ON a.TeamId = m.awayid
				INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid 
				CROSS APPLY (SELECT TOP 1 ms.Id AS MatchSection
							 FROM @tmpMatchSection AS ms
							 WHERE ms.IsFrom14 = 1
								AND 1 = CASE WHEN ms.Id = @MatchSection_Closed AND m.EventStatus = ms.EventStatus THEN 1
											 ELSE 0 END) AS mss
			WHERE l.IsTest = 0 AND m.isTestMatch = 0
				AND (CASE WHEN @IsExcludeSabaGroup = 1 AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
								AND EXISTS (SELECT 1 FROM @tmpSport AS s WHERE m.SportType = s.SportType) THEN 1
						  WHEN @IsExcludeSabaGroup = 0 AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
								AND EXISTS (SELECT 1 FROM @tmpSport AS s WHERE m.SportType = s.SportType) THEN 1
						  WHEN @IsExcludeSabaGroup = 0 AND l.LeagueGroupID IN (42,74,108,113,122,151)
								AND EXISTS (SELECT 1 FROM @tmpSportSabaLeagueGroup AS sl 
														WHERE m.SportType = sl.SportType AND l.LeagueGroupID = sl.LeagueGroupID) THEN 1
						  ELSE 0 END = 1)
				AND (l.LeagueName LIKE '%' + @LeagueEvent + '%'
						OR h.TeamName LIKE '%' + @LeagueEvent + '%'
						OR a.TeamName LIKE '%' + @LeagueEvent + '%')
		-- OPTION (RECOMPILE)
		;
	END
	ELSE
	BEGIN
		SELECT 	tms.MatchId,m.leagueid AS LeagueId,l.LeagueName,m.EventDate,m.GlobalShowTime,mss.MatchSection,m.SportType
			,	m.homeid AS HomeId,h.TeamName AS HomeName,m.awayid AS AwayId,a.TeamName AS AwayName,tms.LiveIndicator
			,	tms.Bettype,tms.BetID,tms.BetChoiceType,tms.TotalAmountHome,tms.TotalAmountAway,tms.TotalTicketHome
			,	tms.TotalTicketAway,tms.IsFrom14
		FROM #tmpMatchSum AS tms
			INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON m.MatchId = tms.MatchId AND tms.IsFrom14 = 0
			INNER JOIN bodb02.dbo.team AS h WITH(NOLOCK) ON h.TeamId = m.homeid 
			INNER JOIN bodb02.dbo.team AS a WITH(NOLOCK) ON a.TeamId = m.awayid
			INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid 
			CROSS APPLY (SELECT TOP 1 ms.Id AS MatchSection
						 FROM @tmpMatchSection AS ms
						 WHERE ms.IsFrom14 = 0
							AND 1 = CASE WHEN m.EventStatus <> 'completed' THEN (CASE WHEN ms.Id = @MatchSection_Live AND m.GlobalShowTime <= GETDATE() THEN 1
																					WHEN ms.Id = @MatchSection_Today AND m.EventDate = @Today AND m.GlobalShowTime > GETDATE() THEN 1
																					WHEN ms.Id = @MatchSection_Early AND m.EventDate > @Today THEN 1 END)
										 WHEN m.EventStatus = ms.EventStatus AND ms.Id = @MatchSection_Closed THEN 1
										 ELSE 0 END) AS mss
		WHERE l.IsTest = 0 AND m.isTestMatch = 0 AND m.IsDeleted = 0 
			AND (CASE WHEN @IsExcludeSabaGroup = 1 AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
							AND EXISTS (SELECT 1 FROM @tmpSport AS s WHERE m.SportType = s.SportType) THEN 1
					  WHEN @IsExcludeSabaGroup = 0 AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
							AND EXISTS (SELECT 1 FROM @tmpSport AS s WHERE m.SportType = s.SportType) THEN 1
					  WHEN @IsExcludeSabaGroup = 0 AND l.LeagueGroupID IN (42,74,108,113,122,151)
							AND EXISTS (SELECT 1 FROM @tmpSportSabaLeagueGroup AS sl 
													WHERE m.SportType = sl.SportType AND l.LeagueGroupID = sl.LeagueGroupID) THEN 1
					  ELSE 0 END = 1)
			AND (l.LeagueName LIKE '%' + @LeagueEvent + '%'
					OR h.TeamName LIKE '%' + @LeagueEvent + '%'
					OR a.TeamName LIKE '%' + @LeagueEvent + '%')
		UNION ALL
		SELECT 	tms.MatchId,m.leagueid AS LeagueId,l.LeagueName,m.EventDate,m.GlobalShowTime,mss.MatchSection,m.SportType
			,	m.homeid AS HomeId,h.TeamName AS HomeName,m.awayid AS AwayId,a.TeamName AS AwayName,tms.LiveIndicator
			,	tms.Bettype,tms.BetID,tms.BetChoiceType,tms.TotalAmountHome,tms.TotalAmountAway,tms.TotalTicketHome
			,	tms.TotalTicketAway,tms.IsFrom14
		FROM #tmpMatchSum AS tms
			INNER JOIN bodb02.dbo.match14 AS m WITH(NOLOCK) ON m.MatchId = tms.MatchId AND tms.IsFrom14 = 1
			INNER JOIN bodb02.dbo.team AS h WITH(NOLOCK) ON h.TeamId = m.homeid 
			INNER JOIN bodb02.dbo.team AS a WITH(NOLOCK) ON a.TeamId = m.awayid
			INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON m.leagueid = l.leagueid 
			CROSS APPLY (SELECT TOP 1 ms.Id AS MatchSection
						 FROM @tmpMatchSection AS ms
						 WHERE ms.IsFrom14 = 1
							AND 1 = CASE WHEN ms.Id = @MatchSection_Closed AND m.EventStatus = ms.EventStatus THEN 1
										 ELSE 0 END) AS mss
		WHERE l.IsTest = 0 AND m.isTestMatch = 0
			AND (CASE WHEN @IsExcludeSabaGroup = 1 AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
							AND EXISTS (SELECT 1 FROM @tmpSport AS s WHERE m.SportType = s.SportType) THEN 1
					  WHEN @IsExcludeSabaGroup = 0 AND l.LeagueGroupID NOT IN (42,74,108,113,122,151)
							AND EXISTS (SELECT 1 FROM @tmpSport AS s WHERE m.SportType = s.SportType) THEN 1
					  WHEN @IsExcludeSabaGroup = 0 AND l.LeagueGroupID IN (42,74,108,113,122,151)
							AND EXISTS (SELECT 1 FROM @tmpSportSabaLeagueGroup AS sl 
													WHERE m.SportType = sl.SportType AND l.LeagueGroupID = sl.LeagueGroupID) THEN 1
					  ELSE 0 END = 1)
			AND (l.LeagueName LIKE '%' + @LeagueEvent + '%'
					OR h.TeamName LIKE '%' + @LeagueEvent + '%'
					OR a.TeamName LIKE '%' + @LeagueEvent + '%')
		-- OPTION (RECOMPILE)
		;
	END;
	
	DROP TABLE IF EXISTS #tmpBetType;
	DROP TABLE IF EXISTS #tmpDangerCust;
	DROP TABLE IF EXISTS #tmpMatchSum;

END;