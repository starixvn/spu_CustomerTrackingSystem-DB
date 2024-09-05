/*<info serverAlias="DBCTS-bodb02" executers="wsv_cts" isFunction="0" isNested="0"></info>*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CTS_MatchMonitorParlay_Details_GetFilter]
		@ViewMode					TINYINT = 0
	,	@MatchID					INT = 0
	,	@EventDate					DATETIME = '1900-09-22'
	,	@ListSportBettype			VARCHAR(MAX)
	,	@IsLive						BIT = 0
	,	@ListSuspiciousTransIdm		VARCHAR(MAX) = ''
	
	,	@IsExclTestCurr				BIT = 0
	,	@FromTransDate				DATETIME = NULL
	,	@ToTransDate				DATETIME = NULL

	,	@MaxSequenceId				BIGINT		OUTPUT
	,	@TotalTicketAll				BIGINT		OUTPUT
	,	@TotalTicketLicensee		BIGINT		OUTPUT
	,	@TotalTicketCredit			BIGINT		OUTPUT

AS
/*
	Created: 20240822@Casey.Huynh
	Task : CTS - Match Monitor Parlay, Get New Ticket
	DB	 : bodb02

	Revisions:
		- 20240822@Casey.Huynh: Created [Redmine ID: 152883]

	Params Explaination:

		@ListSuspiciousTransIdm: format JSON Get trans from table Bettransm
			@ListSuspiciousTransIdm = '[{"TransId":1, "Reason":'HED', "GroupId":1},{"TransId":1, "Reason":'GB', "GroupId":1},{"TransId":2, "Reason":'GB', "GroupId":1},{"TransId":3, "Reason":'HED', "Group":1}]'
		
		@ViewMode	: TINYINT
			@ViewMode=0: Ticket Type = 'All-MatchMonitor'			
			@ViewMode=1: Ticket Type = 'Suspicious'
			@ViewMode=2: Ticket Type = 'All-Danger Monitor'

		@ListSportBettype: JSON
			,@ListSportBettype='[	{"SportTypeID":1, "BetTypeID":1, "BetChoiceType":2}
								,	{"SportTypeID":2, "BetTypeID":3, "BetChoiceType":2}
								,	{"SportTypeID":2, "BetTypeID":609, "BetChoiceType":2}]'	

	Example:
		DECLARE @MaxSequenceId BIGINT,@TotalTicketAll BIGINT, @TotalTicketLicensee BIGINT,@TotalTicketCredit BIGINT;
		EXEC CTS_MatchMonitorParlay_Details_GetFilter
			@ViewMode = 0
			, @MatchID = 83551981
			, @EventDate = NULL
			, @ListSportBettype = '[{"SportTypeID":1,"BetTypeID":1,"BetChoiceType":2,"BetChoiceHome":"h","BetChoiceAway":"a","BetIDPattern":null,"BetID":0}]'
			, @IsLive = 0
			, @ListSuspiciousTransIdm = '[{"TransId":280213141093089280,"Reason":"GB","GroupId":1},{"TransId":280213141093089281,"Reason":"GB","GroupId":2}]'

			, @IsExclTestCurr = 0
			, @FromTransDate = NULL
			, @ToTransDate = NULL

			, @MaxSequenceId = @MaxSequenceId OUTPUT
			, @TotalTicketAll = @TotalTicketAll OUTPUT
			, @TotalTicketLicensee = @TotalTicketLicensee OUTPUT
			, @TotalTicketCredit = @TotalTicketCredit OUTPUT

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
	DECLARE @tmpBUMBData AS TABLE (BUDay DATETIME,	MBDay DATETIME);
	---====================================================================================
	
	IF	OBJECT_ID('tempdb..#tmpTransm') IS NOT NULL
	BEGIN
		DROP TABLE #tmpTransm;
	END;

	CREATE TABLE #tmpTransm(
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
		,	TransDate			DATETIME
		,	Refno				BIGINT
	);
	CREATE NONCLUSTERED INDEX #IX_tmpTickets_SequenceId ON #tmpTransm (
			SequenceId			ASC
	);

	CREATE NONCLUSTERED INDEX #IX_tmpTickets_TransDate ON #tmpTransm (
			TransDate			ASC
	);

	IF	OBJECT_ID('tempdb..#tmpSuspiciousTrans') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSuspiciousTrans;
	END;

	CREATE TABLE	#tmpSuspiciousTrans(
			TransId					BIGINT NOT NULL
		,	SuspiciousReason		VARCHAR(50)
		,	SuspiciousGroupId		INT
	);

	CREATE NONCLUSTERED INDEX #IX_tmptmpSuspiciousTrans_TransId ON #tmpSuspiciousTrans (
			TransID		ASC
	);

	IF	OBJECT_ID('tempdb..#tmpSuspiciousDistinctTrans') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSuspiciousDistinctTrans;
	END;

	CREATE TABLE	#tmpSuspiciousDistinctTrans(
			TransId					BIGINT PRIMARY KEY NOT NULL
	);

	IF	OBJECT_ID('tempdb..#tmpSportBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSportBettype;
	END;

	CREATE TABLE #tmpSportBettype(
			SportTypeID				SMALLINT
		,	BetTypeID				INT
		,	BetChoiceType			TINYINT
		,	BetIDPattern			NVARCHAR(20)
		,	BetID					NVARCHAR(50)
	);

	CREATE NONCLUSTERED INDEX #IX_tmpSportBettype_SportTypeBettype ON #tmpSportBettype (
			SportTypeID	ASC
		,	BetTypeID		ASC
	);

	--==============================================================================================
	
	--=======GET BALANCE UP/ MOVE BET DAY===========================================================
	INSERT INTO @tmpBUMBData(BUDay,MBDay)
	EXECUTE bodb02.dbo.Age_SelBalanceUpDay;
	
	SELECT	TOP(1) @BalanceUpDay	= BUDay , @MoveBetsDay	= MBDay FROM @tmpBUMBData ;

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
	IF @ListSportBettype <> ''
	BEGIN

		INSERT INTO #tmpSportBettype(SportTypeID,BetTypeID,BetChoiceType,BetIDPattern,BetID)
		SELECT	j.SportTypeID
			,	j.BetTypeID
			,	j.BetChoiceType
			,	j.BetIDPattern
			,	(CASE WHEN j.BetID = 0 THEN NULL ELSE CONVERT(NVARCHAR(50),j.BetID) END)
		FROM OPENJSON (@ListSportBettype) WITH (
				SportTypeID			SMALLINT		'$.SportTypeID'
			,	BetTypeID			INT				'$.BetTypeID'
			,	BetChoiceType		TINYINT			'$.BetChoiceType'
			,	BetIDPattern		NVARCHAR(20)	'$.BetIDPattern'
			,	BetID				BIGINT			'$.BetID'
			) AS j;

	END;
	
	--========================================================================================
	IF @ListSuspiciousTransIdm <> ''
	BEGIN

		INSERT INTO #tmpSuspiciousTrans (TransId,SuspiciousReason,SuspiciousGroupId)
		SELECT	j.TransID
			,	j.Reason
			,	j.GroupId
		FROM OPENJSON (@ListSuspiciousTransIdm) WITH (
				TransID		BIGINT '$.TransId'
			,	Reason		VARCHAR(50) '$.Reason'
			,	GroupId		INT '$.GroupId'
			) AS j;

		INSERT INTO #tmpSuspiciousDistinctTrans
		SELECT DISTINCT tmpTs.TransId 
		FROM #tmpSuspiciousTrans AS tmpTs WITH(NOLOCK);
		
	END;
	
	IF @ViewMode = 1 --GET Suspicious Ticket Only
	BEGIN
		IF @IsGetDataFromOrigin = 1
		BEGIN
			INSERT INTO #tmpTransm (
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
				,	Refno
			)
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
				,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS HDP
				,	b.statusID
				,	b.Refno
			FROM #tmpSuspiciousDistinctTrans AS tmpTs WITH(NOLOCK)				
				INNER JOIN bodb02.dbo.bettransm AS b WITH(NOLOCK) ON tmpTs.TransId = b.TransId
				INNER JOIN bodb02.dbo.bettrans AS bt WITH(NOLOCK) ON b.refno = bt.refno
				INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID AND b.BetCheck = ISNULL(st.BetID,b.BetCheck)
				INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = bt.currency
			WHERE b.matchid = @MatchID
				AND b.liveindicator = @IsLive
				AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND bt.Currency NOT IN (20,27,28)))
				AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
		END;
		
		IF @IsGetDataFrom14 = 1
		BEGIN
			INSERT INTO #tmpTransm (
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
				,	TicketStatus
				,	Refno
				)
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
				,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS Hdp
				,	b.statusID
				,	b.Refno
			FROM #tmpSuspiciousDistinctTrans AS tmpTs WITH(NOLOCK)
				INNER JOIN bodb02.dbo.bettransm14 AS b WITH(NOLOCK) ON tmpTs.TransId = b.TransId
				INNER JOIN bodb02.dbo.bettrans AS bt WITH(NOLOCK) ON b.refno = bt.refno
				INNER JOIN bodb02.dbo.match14 AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID AND b.BetCheck = ISNULL(st.BetID,b.BetCheck)
				INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = bt.currency
			WHERE b.matchid = @MatchID
				AND b.liveindicator = @IsLive
				AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND bt.Currency NOT IN (20,27,28)))
				AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
		END;
		
		IF @IsGetDataFromBK = 1
		BEGIN
			INSERT INTO #tmpTransm (
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
				,	Refno
			)
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
				,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS Hdp
				,	b.statusID
				,	b.Refno
			FROM #tmpSuspiciousDistinctTrans AS tmpTs WITH(NOLOCK)
				INNER JOIN bodb_Archive.dbo.bettransm AS b WITH(NOLOCK) ON tmpTs.TransId = b.TransId
				INNER JOIN bodb02.dbo.bettrans AS bt WITH(NOLOCK) ON b.refno = bt.refno
				INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON b.matchid = m.matchid
				INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID AND b.BetCheck = ISNULL(st.BetID,b.BetCheck)
				INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = bt.currency
			WHERE b.matchid = @MatchID
				AND b.liveindicator = @IsLive
				AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND bt.Currency NOT IN (20,27,28)))
				AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
		END;

	END;
	
	IF @ViewMode = 0 --GET All Ticket - MM
	BEGIN
		SELECT @MaxSequenceId = (MAX(SequenceId) + 1) FROM bodb02.dbo.Bettrans WITH(NOLOCK);

		INSERT INTO #tmpTransm (
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
			,	SequenceId
			,	Refno
		)
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
			,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS Hdp
			,	b.statusID				
			,	SequenceId
			,	b.Refno
		FROM bodb02.dbo.bettransm AS b WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettrans AS bt WITH(NOLOCK) ON b.refno = bt.refno
			INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
			INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID AND b.BetCheck = ISNULL(st.BetID,b.BetCheck)
			INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = bt.currency
		WHERE b.matchid = @MatchID
			AND b.liveindicator = @IsLive
			AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND bt.Currency NOT IN (20,27,28)))
			AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate))
			AND bt.SequenceId < @MaxSequenceId
	END;
	
	
	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET 	t.IsLicensee = 1
		,	t.Danger1 = ISNULL(c.danger,0)
		,	t.Danger2 = ISNULL(c.danger2,0)
		,	t.Danger3 = ISNULL(c.danger3,0)
		,	t.Danger4 = ISNULL(c.Danger4,0)
		,	t.Danger5 = ISNULL(c.Danger5,0)
		,	t.CustomerClass = ISNULL(c.CustomerClass,0)
	FROM #tmpTransm AS t
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
	FROM #tmpTransm AS t
		INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN dbo.CustProductStatus AS s WITH (NOLOCK) ON s.custid = c.custid
	WHERE t.IsLicensee IS NULL;
	
	CREATE NONCLUSTERED INDEX IX_tmpTrans_IsLicensee ON #tmpTransm (IsLicensee) INCLUDE (LiveHomeScore,LiveAwayScore,CustomerClass,Danger1,Danger2,Danger3,Danger4,Danger5,CurrencyId,CurrencyName,Hdp,Betteam,TicketStatus);
	
	/*Return Output*/

	SELECT @TotalTicketAll = COUNT(1) FROM #tmpTransm;
	SELECT @TotalTicketLicensee = COUNT(1) FROM #tmpTransm WHERE IsLicensee = 1;
	SELECT @TotalTicketCredit = COUNT(1) FROM #tmpTransm  WHERE IsLicensee = 0;
	
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
	FROM #tmpTransm AS tmpTs
		LEFT JOIN #tmpSuspiciousTrans AS tmpSt ON tmpSt.TransId = tmpTs.TransId
	;
	
	DROP TABLE IF EXISTS #tmpSportBettype;
	DROP TABLE IF EXISTS #tmpTransm;
	DROP TABLE IF EXISTS #tmpSuspiciousTrans;
END;