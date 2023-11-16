/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_TicketDetails_Info]
		@MatchID					INT = 0
	,	@EventDate					DATETIME = '1900-09-22'
	,	@BetType					SMALLINT = 0
	,	@IsLive						BIT = 0
	,	@ListSuspiciousTransId		VARCHAR(MAX) = ''
	,	@TicketType					TINYINT = 0
	,	@IsExclTestCurr				BIT = 0
	,	@BetID						BIGINT = 0	
	,	@FromTransDate				DATETIME = NULL
	,	@ToTransDate				DATETIME = NULL

	,	@MaxSequenceId				BIGINT OUTPUT
	,	@TotalTicketAll				BIGINT OUTPUT
	,	@TotalTicketLicensee		BIGINT OUTPUT
	,	@TotalTicketCredit			BIGINT OUTPUT

AS
/*
	Created: 20230601@Victoria.Le
	Task : CTS - Match Monitor Details - Get ALL Tickets - Get Distinct Currency,HDP,Score 
	DB	 : bodb02

	Revisions:
		- 20230601@Victoria.Le:		Initial Writing [Redmine ID: #185793]		
		- 20230721@Victoria.Le:		Get CurrencyName from table Exchange [Redmine ID: #191422]
		- 20230724@Victoria.Le:		Add condition BetID with BetType = Quarter X HDP/OU/MoneyLine [Redmine ID: #191703]
		- 20230724@Victoria.Le:		Bettype Selection - Return interdependence of columns  [Redmine ID: #191401]
		- 20230911@Casey.Huynh:		Support Filter For Suspicious Trans AND CustomerClass and  [Redmine ID: #193029]
		- 20231116@Long.Luu: 		Support filter by FromTransDate-ToTransDate [Redmine ID: 195042]

	Params Explaination:
		@ListSuspiciousTransId: format JSON
			@ListSuspiciousTransId = '[{"TransId":1, "Reason":'HED', "GroupId":1},{"TransId":1, "Reason":'GB', "GroupId":1},{"TransId":2, "Reason":'GB', "GroupId":1},{"TransId":3, "Reason":'HED', "Group":1}]'
		@TicketType	: TINYINT
			@TicketType=0: Ticket Type = 'All'
			@TicketType=1: Ticket Type = 'Suspicious'
	Example:
		DECLARE @MaxSequenceId BIGINT,@TotalTicketAll BIGINT,@TotalTicketLicensee BIGINT,@TotalTicketCredit BIGINT;
		EXEC [dbo].[CTS_TicketDetails_Info] 
			72186342 -- @MatchID
		,	NULL -- @EventDate
		,	1 -- @BetType
		,	1 -- @IsLive
		,	'' -- @ListSuspiciousTransId
		,	0  --@TicketType (0:All, 1: Suspicious)
		,	0 -- @IsExclTestCurr
		,	0 -- @BetID
		,	@MaxSequenceId OUTPUT
		,	@TotalTicketAll OUTPUT
		,	@TotalTicketLicensee OUTPUT
		,	@TotalTicketCredit OUTPUT

		SELECT @MaxSequenceId AS MaxSequenceId,@TotalTicketAll AS TotalTicketAll,@TotalTicketLicensee AS TotalTicketLicensee,@TotalTicketCredit AS TotalTicketCredit

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @BalanceUpDay			SMALLDATETIME
		,	@MoveBetsDay			SMALLDATETIME
		,	@IsGetDataFromOrigin	BIT = 0
		,	@IsGetDataFrom14		BIT = 0
		,	@IsGetDataFromBK		BIT = 0;
		
	SET @ToTransDate = DATEADD(SECOND,1,@ToTransDate);
	---====================================================================================

	IF	OBJECT_ID('tempdb..#tmpTrans') IS NOT NULL
	BEGIN
		DROP TABLE #tmpTrans;
	END;

	CREATE TABLE #tmpTrans(
			TransId				BIGINT PRIMARY KEY
		,	CustId				INT
		,	Hdp1				SMALLMONEY
		,	Hdp2				SMALLMONEY
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	BetTeam				NVARCHAR(10)
		,	CurrencyId			TINYINT
		,	CurrencyName		NVARCHAR(100)
		,	Hdp					SMALLMONEY DEFAULT 0
		,	IsLicensee			BIT DEFAULT NULL
		,	BetType				SMALLINT
		,	TicketStatus		SMALLINT
		,	Danger1				TINYINT
		,	Danger2				TINYINT
		,	Danger3				TINYINT
		,	Danger4				TINYINT
		,	Danger5				TINYINT
		,	CustomerClass		SMALLINT
		,	SequenceId			BIGINT
	);
	CREATE NONCLUSTERED INDEX #IX_tmpTickets_SequenceId ON #tmpTrans (
			SequenceId			ASC
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

	CREATE CLUSTERED INDEX #CIX_tmpSupportedSportBettype_SportTypeBettype ON #tmpSupportedSportBettype (
			SportType	ASC
		,	Bettype		ASC
	);


	IF	OBJECT_ID('tempdb..#tmpSuspiciousTrans') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSuspiciousTrans;
	END;

	CREATE TABLE	#tmpSuspiciousTrans(
			TransId					BIGINT NOT NULL
		,	SuspiciousReason		VARCHAR(10)
		,	SuspiciousGroupId		INT
	);

	IF	OBJECT_ID('tempdb..#tmpSuspiciousDistinctTrans') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSuspiciousDistinctTrans;
	END;

	CREATE TABLE	#tmpSuspiciousDistinctTrans(
			TransId					BIGINT PRIMARY KEY NOT NULL
	);

	CREATE NONCLUSTERED INDEX #IX_tmptmpSuspiciousTrans_TransId ON #tmpSuspiciousTrans (
			TransID		ASC
	);

	IF	OBJECT_ID('tempdb..#tmpBUMBData') IS NOT NULL
	BEGIN;
		DROP TABLE	#tmpBUMBData;
	END;

	CREATE TABLE	#tmpBUMBData (
			BUDay	SMALLDATETIME
		,	MBDay	SMALLDATETIME
	);
	--=============================================================================================
	
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

	--====================DEFINE SPORT BETTYPES=================================================================================================================
	-- Soccer
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType,IsDetectMatchMonitor,IsFilterBetID,IsFilterBetTeam,IsFilterHdp,IsOnlyGetHdp1)
	VALUES	(1,1,1,0,0,1,0)
			,(1,3,1,0,0,1,1)
			,(1,7,1,0,0,1,0)
			,(1,8,1,0,0,1,1)
			,(1,2,0,0,0,1,0)
			,(1,12,0,0,0,1,0)
			,(1,413,0,0,1,0,0)
			,(1,414,0,0,1,0,0)
			,(1,6,0,0,1,0,0)
			,(1,126,0,0,1,0,0)
			,(1,5,0,0,1,0,0)
			,(1,15,0,0,1,0,0)
	;
	-- Basketball
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType,IsDetectMatchMonitor,IsFilterBetID,IsFilterBetTeam,IsFilterHdp,IsOnlyGetHdp1)
	VALUES	(2,1,1,0,0,1,0)
			,(2,3,1,0,0,1,1)
			,(2,7,1,0,0,1,0)
			,(2,8,1,0,0,1,1)
			,(2,20,1,0,0,1,0)
			,(2,609,1,1,0,1,0)
			,(2,610,1,1,0,1,1)
			,(2,612,1,1,0,1,0)
	;
	-- E-Sports
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType,IsDetectMatchMonitor,IsFilterBetID,IsFilterBetTeam,IsFilterHdp,IsOnlyGetHdp1)
	VALUES	(43,1,1,0,0,1,0)
			,(43,3,1,0,0,1,1)
			,(43,20,1,0,0,1,0)
	;
	
	IF @ListSuspiciousTransId <> ''
	BEGIN
		INSERT INTO #tmpSuspiciousTrans (TransId,SuspiciousReason,SuspiciousGroupId)
		SELECT	JSON_VALUE(ssk.value, '$.TransId') AS TransId
			,	JSON_VALUE(ssk.value, '$.Reason') AS Reason
			,	JSON_VALUE(ssk.value, '$.GroupId') AS Reason
		FROM OPENJSON (@ListSuspiciousTransId) AS ssk

		INSERT INTO #tmpSuspiciousDistinctTrans
		SELECT DISTINCT tmpTs.TransId 
		FROM #tmpSuspiciousTrans AS tmpTs WITH(NOLOCK);
		
	END;

	IF @IsGetDataFromOrigin = 1 -- Get data from Bettrans
	BEGIN
		IF @TicketType = 1 --GET Suspicious Ticket Only
		BEGIN
			INSERT INTO #tmpTrans (
					TransId
				,	CustId
				,	Hdp1
				,	Hdp2
				,	LiveHomeScore
				,	LiveAwayScore
				,	BetTeam
				,	CurrencyName
				,	CurrencyId
				,	BetType
				,	Hdp
				,	TicketStatus)
			SELECT	b.TransId
				,	b.custid
				,	b.Hdp1
				,	b.Hdp2
				,	b.LiveHomeScore
				,	b.LiveAwayScore
				,	b.BetTeam
				,	e.currency
				,	e.ExchangeId
				,	b.bettype
				,	(CASE	WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 1  THEN	ABS(b.Hdp1) 
							WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 0	 THEN  (CASE WHEN b.BetTeam = 'h'	THEN ABS(b.Hdp2 - b.Hdp1) 
																						 WHEN b.BetTeam = 'a'	THEN ABS(b.Hdp1 - b.Hdp2)  END)													 
							END)  AS Hdp
				,	b.statusID
			FROM #tmpSuspiciousDistinctTrans AS tmpTs WITH(NOLOCK)
				INNER JOIN dbo.bettrans AS b WITH(NOLOCK) ON tmpTs.TransId = b.TransId
				INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN #tmpSupportedSportBettype AS t WITH(NOLOCK) ON m.sporttype = t.SportType AND b.bettype = t.BetType
				INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
			WHERE b.matchid = @MatchID
				AND b.bettype = @BetType
				AND b.liveindicator = @IsLive
				AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
				AND (@BetID = 0 OR (@BetID > 0 AND t.IsFilterBetID = 1 AND b.betid = @BetID))
				AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
		END;

		IF @TicketType = 0 --GET All Ticket
		BEGIN

			INSERT INTO #tmpTrans (
					TransId
				,	CustId
				,	Hdp1
				,	Hdp2
				,	LiveHomeScore
				,	LiveAwayScore
				,	BetTeam
				,	CurrencyName
				,	CurrencyId
				,	BetType
				,	Hdp
				,	TicketStatus				
				,	SequenceId)
			SELECT	b.TransId
				,	b.custid
				,	b.Hdp1
				,	b.Hdp2
				,	b.LiveHomeScore
				,	b.LiveAwayScore
				,	b.BetTeam
				,	e.currency
				,	e.ExchangeId
				,	b.bettype
				,	(CASE	WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 1  THEN	ABS(b.Hdp1) 
							WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 0	 THEN  (CASE WHEN b.BetTeam = 'h'	THEN ABS(b.Hdp2 - b.Hdp1) 
																						 WHEN b.BetTeam = 'a'	THEN ABS(b.Hdp1 - b.Hdp2)  END)													 
							END)  AS Hdp
				,	b.statusID				
				,	SequenceId
			FROM dbo.bettrans AS b WITH(NOLOCK)
				INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN #tmpSupportedSportBettype AS t WITH(NOLOCK) ON m.sporttype = t.SportType AND b.bettype = t.BetType
				INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
			WHERE b.matchid = @MatchID
				AND b.bettype = @BetType
				AND b.liveindicator = @IsLive
				AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
				AND (@BetID = 0 OR (@BetID > 0 AND t.IsFilterBetID = 1 AND b.betid = @BetID))
				AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
		END;
	END;

	IF @IsGetDataFrom14 = 1
	BEGIN
		IF @TicketType = 1 --GET Suspicious Ticket Only
		BEGIN
			INSERT INTO #tmpTrans (
					TransId
				,	CustId
				,	Hdp1
				,	Hdp2
				,	LiveHomeScore
				,	LiveAwayScore
				,	BetTeam
				,	CurrencyName
				,	CurrencyId
				,	BetType
				,	hdp
				,	TicketStatus)
			SELECT	b.TransId
				,	b.custid
				,	b.Hdp1
				,	b.Hdp2
				,	b.LiveHomeScore
				,	b.LiveAwayScore
				,	b.BetTeam
				,	e.currency
				,	e.ExchangeId
				,	b.bettype
				,	(CASE	WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 1  THEN	ABS(b.Hdp1) 
							WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 0	 THEN  (CASE WHEN b.BetTeam = 'h'	THEN ABS(b.Hdp2 - b.Hdp1) 
																						 WHEN b.BetTeam = 'a'	THEN ABS(b.Hdp1 - b.Hdp2)  END)													 
							END)  AS Hdp
				,	b.statusID
			FROM #tmpSuspiciousDistinctTrans AS tmpTs WITH(NOLOCK)
				INNER JOIN dbo.bettrans14 AS b WITH(NOLOCK) ON tmpTs.TransId = b.TransId
				INNER JOIN dbo.match14 AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN #tmpSupportedSportBettype AS t WITH(NOLOCK) ON m.sporttype = t.SportType AND b.bettype = t.BetType
				INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
			WHERE b.matchid = @MatchID
				AND b.bettype = @BetType
				AND b.liveindicator = @IsLive
				AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
				AND (@BetID = 0 OR (@BetID > 0 AND t.IsFilterBetID = 1 AND b.betid = @BetID))
				AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
		END;
	END;

	IF @IsGetDataFromBK = 1
	BEGIN
		IF @TicketType = 1 --GET Suspicious Ticket Only
		BEGIN
			INSERT INTO #tmpTrans (
					TransId
				,	CustId
				,	Hdp1
				,	Hdp2
				,	LiveHomeScore
				,	LiveAwayScore
				,	BetTeam
				,	CurrencyName
				,	CurrencyId
				,	BetType
				,	Hdp
				,	TicketStatus)
			SELECT	b.TransId
				,	b.custid
				,	b.Hdp1
				,	b.Hdp2
				,	b.LiveHomeScore
				,	b.LiveAwayScore
				,	b.BetTeam
				,	e.currency
				,	e.ExchangeId
				,	b.bettype
				,	(CASE	WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 1  THEN	ABS(b.Hdp1) 
							WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 0	 THEN  (CASE WHEN b.BetTeam = 'h'	THEN ABS(b.Hdp2 - b.Hdp1) 
																						 WHEN b.BetTeam = 'a'	THEN ABS(b.Hdp1 - b.Hdp2)  END)													 
							END)  AS Hdp
				,	b.statusID
			FROM #tmpSuspiciousDistinctTrans AS tmpTs WITH(NOLOCK)
				INNER JOIN bodb_Archive.dbo.bettrans_bk AS b WITH(NOLOCK) ON tmpTs.TransId = b.TransId
				INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN #tmpSupportedSportBettype AS t WITH(NOLOCK) ON m.sporttype = t.SportType AND b.bettype = t.BetType
				INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
			WHERE b.matchid = @MatchID
				AND b.bettype = @BetType
				AND b.liveindicator = @IsLive
				AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
				AND (@BetID = 0 OR (@BetID > 0 AND t.IsFilterBetID = 1 AND b.betid = @BetID))
				AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
		END;
	END;

	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET 	t.IsLicensee = 1
		,	t.Danger1 = ISNULL(c.danger,0)
		,	t.Danger2 = ISNULL(c.danger2,0)
		,	t.Danger3 = ISNULL(c.danger3,0)
		,	t.Danger4 = ISNULL(c.Danger4,0)
		,	t.Danger5 = ISNULL(c.Danger5,0)
		,	t.CustomerClass = ISNULL(c.CustomerClass,0)
	FROM #tmpTrans AS t
		INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN dbo.Dep_CustSuper AS cs WITH (NOLOCK) ON cs.custid = c.srecommend;

	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET 	t.IsLicensee = 0
		,	t.Danger1 = ISNULL(c.danger,0)
		,	t.Danger2 = ISNULL(c.danger2,0)
		,	t.Danger3 = ISNULL(c.danger3,0)
		,	t.Danger4 = ISNULL(c.Danger4,0)
		,	t.Danger5 = ISNULL(c.Danger5,0)
		,	t.CustomerClass = ISNULL(c.CustomerClass,0)
	FROM #tmpTrans AS t
		INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN dbo.CustProductStatus AS s WITH (NOLOCK) ON s.custid = c.custid
	WHERE t.IsLicensee IS NULL;

	CREATE INDEX IX_tmpTickets_IsLicensee ON #tmpTrans (IsLicensee, LiveHomeScore, LiveAwayScore, TicketStatus, CurrencyId, CurrencyName, Hdp, BetTeam, Danger1, Danger2, Danger3, Danger4, Danger5);

	/*Return Output*/
	SELECT @MaxSequenceId = (MAX(SequenceId) + 1) FROM #tmpTrans;
	SELECT @TotalTicketAll = COUNT(1) FROM #tmpTrans;
	SELECT @TotalTicketLicensee = COUNT(1) FROM #tmpTrans WHERE IsLicensee = 1;
	SELECT @TotalTicketCredit = COUNT(1) FROM #tmpTrans  WHERE IsLicensee = 0;
	
	SELECT	DISTINCT 
			tmpTs.LiveHomeScore
		,	tmpTs.LiveAwayScore
		,	tmpTs.IsLicensee		
		,	tmpTs.CustomerClass
		,	tmpTs.Danger1
		,	tmpTs.Danger2
		,	tmpTs.Danger3
		,	tmpTs.Danger4
		,	tmpTs.Danger5
		,	tmpTs.CurrencyId
		,	tmpTs.CurrencyName
		,	tmpSt.SuspiciousReason
		,	tmpSt.SuspiciousGroupId
		,	tmpTs.Hdp
		,	tmpTs.Betteam
		,	tmpTs.TicketStatus
	FROM #tmpTrans AS tmpTs
		LEFT JOIN #tmpSuspiciousTrans AS tmpSt ON tmpSt.TransId = tmpTs.TransId
	;

	DROP TABLE IF EXISTS #tmpSupportedSportBettype;
	DROP TABLE IF EXISTS #tmpTrans;
	DROP TABLE IF EXISTS #tmpExcludeTransIds;

END