/*<info serverAlias="DBCTS-bodb02" executers="wsv_cts" isFunction="0" isNested="0"></info>*/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CTS_MatchMonitorParlay_Details_GetTicket]
		@ViewMode				TINYINT = 1
	,	@EventDate				DATETIME = '1900-09-22'
	,	@ListRefno				VARCHAR(MAX)
	,	@MatchID				INT = 0
	,	@IsLive					BIT = 1
	,	@ListSportBettype		VARCHAR(MAX)
	,	@FromTransDate			DATETIME = NULL
	,	@ToTransDate			DATETIME = NULL	
	,	@ListScore				VARCHAR(MAX) = NULL
	,	@IsLicensee				BIT = NULL
	,	@ListCustomerClass		VARCHAR(MAX) = NULL	
	,	@ListDanger				VARCHAR(MAX) = NULL
	,	@ListCurrency			VARCHAR(MAX) = NULL
	,	@ListReason				VARCHAR(MAX) = NULL
	,	@ListAGroup				VARCHAR(MAX) = NULL
	,	@ListMGroup				VARCHAR(MAX) = NULL	
	,	@ListHDPBetTeam			VARCHAR(MAX) = NULL
	,	@CustAmountRM			MONEY = 0	
	,	@ListStatus				VARCHAR(50) = NULL
	--============================================================
	,	@LastScannedSequenceID		BIGINT = 0
	,	@LastTransDate				DATETIME = NULL	
	,	@BatchSize					INT = 500	
	,	@IsExclTestCurr				BIT = 0

	,	@MinSequenceId				BIGINT = NULL OUTPUT
	,	@MinTransDate				DATETIME = NULL OUTPUT
	,	@TotalTicket				INT = NULL OUTPUT
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
		
		@ViewMode	: TINYINT (Match Monitor Details Page map TicketType)
			@ViewMode=0: Ticket Type = 'All Ticket'			
			@ViewMode=1: Ticket Type = 'Suspicious Ticket'

		@ListSportBettype: JSON
			,@ListSportBettype='[	{"SportTypeID":1, "BetTypeID":1, "BetChoiceType":2}
								,	{"SportTypeID":2, "BetTypeID":3, "BetChoiceType":2}
								,	{"SportTypeID":2, "BetTypeID":609, "BetChoiceType":2}]'	
		@IsLicensee: 1: Licensee ELS 0, (Match Monitor Details Page map Site)

	Example:
		
		DECLARE @MaxSequenceId BIGINT,@TotalTicketAll BIGINT, @TotalTicketLicensee BIGINT,@TotalTicketCredit BIGINT;
		EXEC CTS_MatchMonitorParlay_Details_GetTicket
				 @ViewMode = 1
			, @EventDate = '2024-09-09'
			, @ListRefno = '[	{"Refno":18489152651919360,"Reason":5,"AGroup":1,"MGroup":0}
							,	{"Refno":18489155067838464,"Reason":5,"AGroup":1,"MGroup":0}
							]'
			, @MatchID = 83679714
			, @IsLive = 0
			, @ListSportBettype = '[{"SportTypeID":1,"BetTypeID":3,"BetChoiceType":2,"BetChoiceHome":"h","BetChoiceAway":"a","BetIDPattern":null,"BetID":0
										, "BetChoiceHomeFullName":"Home", "BetChoiceAwayFullName":"Away"
									}]'
			, @FromTransDate = NULL
			, @ToTransDate = NULL
			, @ListScore = NULL
			, @IsLicensee = NULL
			, @ListCustomerClass = NULL
			, @ListDanger = NULL
			, @ListCurrency = NULL
			, @ListReason = NULL
			, @ListAGroup = NULL
			, @ListMGroup = NULL
			, @ListHDPBetTeam = NULL
			, @CustAmountRM = NULL
			, @ListStatus = NULL

			, @LastScannedSequenceID = NULL
			, @LastTransDate = NULL
			, @BatchSize = NULL
			, @IsExclTestCurr = NULL

		SELECT @MaxSequenceId AS MaxSequenceId,@TotalTicketAll AS TotalTicketAll,@TotalTicketLicensee AS TotalTicketLicensee,@TotalTicketCredit AS TotalTicketCredit

*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @BalanceUpDay			SMALLDATETIME
		,	@MoveBetsDay			SMALLDATETIME
		,	@IsGetDataFromOrigin	BIT = 0
		,	@IsGetDataFrom14		BIT = 0
		,	@IsGetDataFromBK		BIT = 0
		,	@IsFilter				BIT = 0
		;

	DECLARE @tmpBUMBData AS TABLE (BUDay DATETIME,	MBDay DATETIME);
	
	DECLARE @DBSource_Orig	TINYINT = 1
		,	@DBSource_14	TINYINT = 2
		,	@DBSource_BK	TINYINT = 3

	DECLARE @Order_MainTicket		TINYINT = 0
		,	@Order_SubMainMatch		TINYINT = 1
		,	@Order_SubOtherMatch	TINYINT = 2
	--==================================================================
	IF	OBJECT_ID('tempdb..#tmpInputRefno') IS NOT NULL
	BEGIN
		DROP TABLE #tmpInputRefno;
	END;

	CREATE TABLE #tmpInputRefno(
			Refno		BIGINT NOT NULL 
		,	Reason		VARCHAR(50) DEFAULT '0'
		,	AGroup		INT
		,	MGroup		INT
	);

	IF	OBJECT_ID('tempdb..#tmpSportBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSportBettype;
	END;

	CREATE TABLE	#tmpSportBettype(
			SportTypeID				SMALLINT
		,	BetTypeID				INT
		,	BetChoiceType			TINYINT
		,	BetChoiceHome			NVARCHAR(10)
		,	BetChoiceAway			NVARCHAR(10)
		,	BetChoiceHomeFullName	NVARCHAR(10)
		,	BetChoiceAwayFullName	NVARCHAR(10)
		,	BetIDPattern			NVARCHAR(20)
		,	BetID					BIGINT
	);
	
	SET @ToTransDate = DATEADD(SECOND,1,@ToTransDate);

	IF	OBJECT_ID('tempdb..#tmpMainTicket') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMainTicket;
	END;

	CREATE TABLE #tmpMainTicket(
			Refno			BIGINT
		,	TransID			BIGINT
		,	TransDate		DATETIME
		,	Combinition		SMALLINT -- 2: Double, 3: Trible
		,	TicketType		SMALLINT
		,	Amount			MONEY				
		,	BetFrom			NVARCHAR(4)
		,	Reason			VARCHAR(50) DEFAULT '0'
		,	ListReason		VARCHAR(MAX)
		,	AGroup			INT  DEFAULT 0
		,	MGroup			INT  DEFAULT 0			
		,	Odds			MONEY

		,	CustID			INT
		,	UserName		NVARCHAR(50)
		,	IsLicensee		BIT
		,	CurrencyName	NVARCHAR(100)
		,	CurrencyID		TINYINT		
		,	Danger1			TINYINT
		,	Danger2			TINYINT
		,	Danger3			TINYINT
		,	Danger4			TINYINT
		,	Danger5			TINYINT
		,	CustomerClass	SMALLINT


	);
	
	IF	OBJECT_ID('tempdb..#tmpSubTicket') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSubTicket;
	END;

	CREATE TABLE #tmpSubTicket(			
			Refno				BIGINT
		,	DBSource			TINYINT			--1: Bettransm , 2: Bettrans14, 3: Bettrans_bk
		,	TransID				BIGINT
		,	CustID				INT
		,	OrderTicket			TINYINT
		,	MatchID				INT
		,	EventDate			DATETIME
		,	EventStatus			NVARCHAR(50)
		,	GlobalShowTime			DATETIME
		,	HomeID				INT
		,	AwayID				INT
		,	LeagueID			INT
		,	LeagueName			NVARCHAR(500)
		,	IsMajorLeague		BIT
		,	SportType			SMALLINT
		,	BetType				SMALLINT
		,	BetteamGroup		NVARCHAR(10)
		,	BetTeam				NVARCHAR(10)
		,	BetChoiceHome		NVARCHAR(10)
		,	BetChoiceAway		NVARCHAR(10)
		,	BetID				BIGINT
		,	Odds				SMALLMONEY
		,	Hdp1				SMALLMONEY
		,	Hdp2				SMALLMONEY
		,	LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	LiveIndicator		BIT
		,	TicketStatus		VARCHAR(50)
		
	);	

	IF	OBJECT_ID('tempdb..#tmpMainTicketOdds') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpMainTicketOdds;
	END;

	CREATE TABLE #tmpMainTicketOdds(
			Refno	BIGINT
		,	Odds	SMALLMONEY
	);

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

	--==================================================================
	IF @ListSportBettype <> ''
		BEGIN
			INSERT INTO #tmpSportBettype(SportTypeID, BetTypeID,BetChoiceType,BetChoiceHome,BetChoiceAway,BetChoiceHomeFullName, BetChoiceAwayFullName, BetIDPattern,BetID)
			SELECT	j.SportTypeID
				,	j.BetTypeID
				,	j.BetChoiceType
				,	j.BetChoiceHome
				,	j.BetChoiceAway
				,	j.BetChoiceHomeFullName
				,	j.BetChoiceAwayFullName
				,	j.BetIDPattern
				,	j.BetID
			FROM OPENJSON (@ListSportBettype) WITH (
					SportTypeID					SMALLINT		'$.SportTypeID'
				,	BetTypeID					INT				'$.BetTypeID'
				,	BetChoiceType				TINYINT			'$.BetChoiceType'
				,	BetChoiceHome				NVARCHAR(10)	'$.BetChoiceHome'
				,	BetChoiceAway				NVARCHAR(10)	'$.BetChoiceAway'
				,	BetChoiceHomeFullName		NVARCHAR(10)	'$.BetChoiceHomeFullName'
				,	BetChoiceAwayFullName		NVARCHAR(10)	'$.BetChoiceAwayFullName'
				,	BetIDPattern				NVARCHAR(20)	'$.BetIDPattern'
				,	BetID						BIGINT			'$.BetID'
				) AS j;
				
			CREATE NONCLUSTERED INDEX IX_tmpSportBettype_Group ON #tmpSportBettype(SportTypeID, BetTypeID);
			
		END;
	
	IF @ListRefno IS NOT NULL
	BEGIN
		INSERT INTO #tmpInputRefno (Refno,Reason,AGroup,MGroup)
		SELECT	j.Refno
			,	j.Reason
			,	j.AGroup
			,	j.MGroup
		FROM OPENJSON (@ListRefno) WITH (
				Refno		BIGINT		'$.Refno'
			,	Reason		VARCHAR(50) '$.Reason'
			,	AGroup		INT			'$.AGroup'
			,	MGroup		INT			'$.MGroup'
			) AS j;
				
		CREATE CLUSTERED INDEX CIX_tmpTransIds_Group ON #tmpInputRefno (Refno, Reason);		
	END	
	ELSE 
	BEGIN
		SET @ListRefno = ''
	END;

	IF @ViewMode = 1 -- Get Fraud Ticket Only from bk, 14, org
	BEGIN

		--================Get From Orgin---================
		INSERT INTO #tmpMainTicket(Refno,TransID,TransDate,Combinition,TicketType,Amount,BetFrom,Reason,ListReason,AGroup,MGroup,CustID,CurrencyName,CurrencyID)
		SELECT	bt.Refno
			,	bt.TransID
			,	bt.TransDate
			,	CASE WHEN CAST(bt.BetCheck AS INT) & 2 = 2 THEN 2 -- Combo 2 bit 2
					 WHEN CAST(bt.BetCheck AS INT) & 4 = 4 THEN 3 -- Combo 3 bit 3 
				END AS Combinition
			,	2 AS TicketType
			,	bt.Stake * bt.ActualRate AS Amount
			,	bt.BetFrom
			,	rn.Reason
			,	rn.Reason AS ListReason
			,	rn.AGroup
			,	rn.MGroup
			,	bt.CustID
			,	e.Currency AS CurrencyName
			,	e.ExchangeId AS CurrencyID
		FROM #tmpInputRefno AS rn WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettrans bt WITH(NOLOCK) on rn.Refno = bt.Refno
			INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = bt.currency
		WHERE (@FromTransDate IS NULL OR (bt.TransDate >= @FromTransDate AND bt.TransDate < @ToTransDate));
		
		INSERT INTO #tmpSubTicket(Refno,DBSource,TransID,CustID,OrderTicket,BetType,BetTeam,BetId,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,LiveIndicator,TicketStatus,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType)
		SELECT 	b.refno
			,	@DBSource_Orig AS DBSource
			,	b.TransID
			,	b.CustID
			,	(CASE WHEN b.MatchID = @MatchID THEN @Order_SubMainMatch 
					 ELSE @Order_SubOtherMatch	END) AS  OrderTicket
			,	b.BetType
			,	b.BetTeam
			,	b.BetCheck AS BetId
			,	b.Odds
			,	b.Hdp1
			,	b.Hdp2
			,	b.LiveHomeScore
			,	b.LiveAwayScore
			,	b.LiveIndicator
			,	b.Status AS TicketStatus
			,	m.MatchId
			,	m.EventDate
			,	m.EventStatus
			,	m.GlobalShowTime
			,	m.HomeId
			,	m.AwayId
			,	m.LeagueId
			,	m.SportType
		FROM	#tmpInputRefno AS rn WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettransm b WITH(NOLOCK) on rn.Refno = b.Refno	
			INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid

		--================Get From 14======================
		INSERT INTO #tmpMainTicket(Refno,TransID,TransDate,Combinition,TicketType,Amount,BetFrom,Reason,ListReason,AGroup,MGroup,CustID,CurrencyName,CurrencyID)
		SELECT	bt.Refno
			,	bt.TransID
			,	bt.TransDate
			,	CASE WHEN CAST(bt.BetCheck AS INT) & 2 = 2 THEN 2 -- Combo 2 bit 2
					 WHEN CAST(bt.BetCheck AS INT) & 4 = 4 THEN 3 -- Combo 3 bit 3 
				END AS Combinition
			,	2 AS TicketType
			,	bt.Stake * bt.ActualRate AS Amount
			,	bt.BetFrom
			,	rn.Reason
			,	rn.Reason AS ListReason
			,	rn.AGroup
			,	rn.MGroup
			,	bt.CustID
			,	e.Currency AS CurrencyName
			,	e.ExchangeId AS CurrencyID
		FROM #tmpInputRefno AS rn WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettrans14 bt WITH(NOLOCK) on rn.Refno = bt.Refno
			INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = bt.currency
			LEFT JOIN #tmpMainTicket AS mt WITH(NOLOCK) ON mt.Refno = rn.Refno
		WHERE (@FromTransDate IS NULL OR (bt.TransDate >= @FromTransDate AND bt.TransDate < @ToTransDate));
		INSERT INTO #tmpSubTicket(Refno,DBSource,TransID,CustID,OrderTicket,BetType,BetTeam,BetId,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,LiveIndicator,TicketStatus,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType)
		SELECT 	b.refno
			,	@DBSource_14 AS DBSource
			,	b.TransID
			,	b.CustID
			,	(CASE WHEN b.MatchID = @MatchID THEN @Order_SubMainMatch 
					 ELSE @Order_SubOtherMatch	END) AS  OrderTicket
			,	b.BetType
			,	b.BetTeam
			,	b.BetCheck AS BetId
			,	b.Odds
			,	b.Hdp1
			,	b.Hdp2
			,	b.LiveHomeScore
			,	b.LiveAwayScore
			,	b.LiveIndicator
			,	b.Status AS TicketStatus
			,	m.MatchId
			,	m.EventDate
			,	m.EventStatus
			,	m.GlobalShowTime
			,	m.HomeId
			,	m.AwayId
			,	m.LeagueId
			,	m.SportType
		FROM	#tmpInputRefno AS rn WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettransm14 b WITH(NOLOCK) on rn.Refno = b.Refno	
			INNER JOIN bodb02.dbo.match14 AS m WITH(NOLOCK) ON b.matchid = m.matchid
			LEFT JOIN #tmpSubTicket AS st WITH(NOLOCK) ON st.Refno = rn.Refno
		WHERE st.Refno IS NULL; 

		--================Get From BK=======================
		INSERT INTO #tmpMainTicket(Refno,TransID,TransDate,Combinition,TicketType,Amount,BetFrom,Reason,ListReason,AGroup,MGroup,CustID,CurrencyName,CurrencyID)
		SELECT	bt.Refno
			,	bt.TransID
			,	bt.TransDate
			,	CASE WHEN CAST(bt.BetCheck AS INT) & 2 = 2 THEN 2 -- Combo 2 bit 2
					 WHEN CAST(bt.BetCheck AS INT) & 4 = 4 THEN 3 -- Combo 3 bit 3 
				END AS Combinition
			,	2 AS TicketType
			,	bt.Stake * bt.ActualRate AS Amount
			,	bt.BetFrom
			,	rn.Reason
			,	rn.Reason AS ListReason
			,	rn.AGroup
			,	rn.MGroup
			,	bt.CustID
			,	e.Currency AS CurrencyName
			,	e.ExchangeId AS CurrencyID
		FROM #tmpInputRefno AS rn WITH(NOLOCK)
			INNER JOIN bodb_Archive.dbo.bettrans_bk bt WITH(NOLOCK) on rn.Refno = bt.Refno
			INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = bt.currency
			LEFT JOIN #tmpMainTicket AS mt WITH(NOLOCK) ON mt.Refno = rn.Refno
		WHERE (@FromTransDate IS NULL OR (bt.TransDate >= @FromTransDate AND bt.TransDate < @ToTransDate));

		INSERT INTO #tmpSubTicket(Refno,DBSource,TransID,CustID,OrderTicket,BetType,BetTeam,BetId,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,LiveIndicator,TicketStatus,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType)
		SELECT 	b.refno
			,	@DBSource_bk AS DBSource
			,	b.TransID
			,	b.CustID
			,	(CASE WHEN b.MatchID = @MatchID THEN @Order_SubMainMatch 
					 ELSE @Order_SubOtherMatch	END) AS  OrderTicket
			,	b.BetType
			,	b.BetTeam
			,	b.BetCheck AS BetId
			,	b.Odds
			,	b.Hdp1
			,	b.Hdp2
			,	b.LiveHomeScore
			,	b.LiveAwayScore
			,	b.LiveIndicator
			,	b.Status AS TicketStatus
			,	m.MatchId
			,	m.EventDate
			,	m.EventStatus
			,	m.GlobalShowTime
			,	m.HomeId
			,	m.AwayId
			,	m.LeagueId
			,	m.SportType
		FROM	#tmpInputRefno AS rn WITH(NOLOCK)
			INNER JOIN bodb_Archive.dbo.bettrans_bk b WITH(NOLOCK) on rn.Refno = b.Refno	
			INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON b.matchid = m.matchid
			LEFT JOIN #tmpSubTicket AS st WITH(NOLOCK) ON st.Refno = rn.Refno
		WHERE st.Refno IS NULL; 
		
		INSERT INTO #tmpMainTicketOdds(Refno, Odds)
		SELECT st.Refno
			,  EXP(SUM(LOG(st.Odds))) AS ProductOdds	
		FROM #tmpSubTicket AS st WITH(NOLOCK)
		GROUP BY st.Refno

		/*RETURN DATA*/
		INSERT INTO #tmpSubTicket(Refno,DBSource,TransId,OrderTicket,Odds)
		SELECT 	mt.refno
			,	0 AS DBSource
			,	mt.TransID AS TransIdm
			,	@Order_MainTicket AS  OrderTicket
			,	mo.Odds
		FROM #tmpMainTicket AS mt WITH(NOLOCK)
			INNER JOIN #tmpMainTicketOdds AS mo WITH(NOLOCK) ON mt.Refno = mo.Refno
		
	
	END;

	IF @ViewMode = 0 --Get ALL Ticket from orig
	BEGIN
		INSERT INTO #tmpMainTicket(Refno,TransID,TransDate,Combinition,TicketType,Amount,BetFrom,Reason,ListReason,AGroup,MGroup,CustID,CurrencyName,CurrencyID)
		SELECT	bt.Refno
			,	bt.TransID
			,	bt.TransDate
			,	CASE WHEN CAST(bt.BetCheck AS INT) & 2 = 2 THEN 2 -- Combo 2 bit 2
					 WHEN CAST(bt.BetCheck AS INT) & 4 = 4 THEN 3 -- Combo 3 bit 3 
				END AS Combinition
			,	2 AS TicketType
			,	bt.Stake * bt.ActualRate AS Amount
			,	bt.BetFrom
			,	rn.Reason
			,	rn.Reason AS ListReason
			,	rn.AGroup
			,	rn.MGroup
			,	bt.CustID
			,	e.Currency AS CurrencyName
			,	e.ExchangeId AS CurrencyID
		FROM #tmpInputRefno AS rn WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettrans bt WITH(NOLOCK) on rn.Refno = bt.Refno
			INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = bt.currency
		WHERE (@FromTransDate IS NULL OR (bt.TransDate >= @FromTransDate AND bt.TransDate < @ToTransDate));
		
		INSERT INTO #tmpSubTicket(Refno,DBSource,TransID,CustID,OrderTicket,BetType,BetTeam,BetId,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,LiveIndicator,TicketStatus,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType)
		SELECT 	b.refno
			,	@DBSource_Orig AS DBSource
			,	b.TransID
			,	b.CustID
			,	(CASE WHEN b.MatchID = @MatchID THEN @Order_SubMainMatch 
					 ELSE @Order_SubOtherMatch	END) AS  OrderTicket
			,	b.BetType
			,	b.BetTeam
			,	b.BetCheck AS BetId
			,	b.Odds
			,	b.Hdp1
			,	b.Hdp2
			,	b.LiveHomeScore
			,	b.LiveAwayScore
			,	b.LiveIndicator
			,	b.Status AS TicketStatus
			,	m.MatchId
			,	m.EventDate
			,	m.EventStatus
			,	m.GlobalShowTime
			,	m.HomeId
			,	m.AwayId
			,	m.LeagueId
			,	m.SportType
		FROM	#tmpInputRefno AS rn WITH(NOLOCK)
			INNER JOIN bodb02.dbo.bettransm b WITH(NOLOCK) on rn.Refno = b.Refno	
			INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid					
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
	,	t.UserName		= c.UserName
	FROM #tmpMainTicket AS t
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN bodb02.dbo.Dep_CustSuper AS cs WITH (NOLOCK) ON cs.custid = c.srecommend;

	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET t.IsLicensee	= 0
	,	t.Danger1		= c.danger
	,	t.Danger2		= c.danger2
	,	t.Danger3		= c.danger3
	,	t.Danger4		= c.Danger4
	,	t.Danger5		= c.Danger5
	,	t.CustomerClass	= c.CustomerClass
	,	t.UserName		= c.UserName
	FROM #tmpMainTicket AS t
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN bodb02.dbo.CustProductStatus AS s WITH (NOLOCK) ON s.custid = c.custid
	WHERE t.IsLicensee IS NULL;
	
	----==================FILTERS=========================		
	IF (@ListScore IS NOT NULL) OR (@IsLicensee IS NOT NULL) OR (@ListCustomerClass <> '') OR (@ListDanger IS NOT NULL)
		OR (@ListCurrency IS NOT NULL) OR (@ListReason <> '') OR (@ListAGroup <> '') OR (@ListMGroup <> '') OR (@ListHDPBetTeam IS NOT NULL)
		OR (@ListStatus IS NOT NULL) OR (@CustAmountRM > 0) OR (@CustAmountRM > 0)
	BEGIN
		SET @IsFilter = 1;
	END;
	
	IF (@IsFilter = 1)
	BEGIN
		GOTO CHECK_FILTER;
	END;
	
	CHECK_FILTER:
		IF (@IsFilter = 1)
		BEGIN
			--====================Fitler By Score==================	
			IF (@ListScore IS NOT NULL)
			BEGIN
				WITH CTE_Score AS (
					SELECT cas.LiveHomeScore, cas.LiveAwayScore
					FROM STRING_SPLIT(@ListScore, ',') ssk
						CROSS APPLY (SELECT	LiveHomeScore = xDim.value('/x[1]','varchar(max)')
										,	LiveAwayScore = xDim.value('/x[2]','varchar(max)')
									From (SELECT CAST('<x>' + REPLACE(REPLACE(ssk.value,'-',''),'  ','</x><x>')+'</x>' AS XML) AS xDim) AS s
									) AS cas
				)
				DELETE t
				FROM #tmpSubTicket AS t
					LEFT JOIN CTE_Score AS s ON s.LiveHomeScore = t.LiveHomeScore AND s.LiveAwayScore = t.LiveAwayScore
				WHERE s.LiveHomeScore IS NULL;

			END;

			--========================Fitler By Site(IsLicensee)==================
			IF (@IsLicensee IS NOT NULL)
			BEGIN
				DELETE t
				FROM #tmpMainTicket AS t
				WHERE t.IsLicensee != @IsLicensee;
			END;

			--========================Fitler By CustomerClass==================
			IF (@ListCustomerClass <> '')
			BEGIN
				WITH CTE_CC AS (
					SELECT ssk.value AS CustomerClass FROM STRING_SPLIT(@ListCustomerClass, ',') AS ssk
				)
				DELETE t
				FROM #tmpMainTicket AS t
					LEFT JOIN CTE_CC AS c ON c.CustomerClass = ISNULL(t.CustomerClass,0)
				WHERE c.CustomerClass IS NULL;
			END;

			--========================Fitler By Danger==================		
			IF (@ListDanger IS NOT NULL)
			BEGIN
				DECLARE @tmpSupportedDanger AS TABLE (Danger1 TINYINT, Danger2 TINYINT, Danger3 TINYINT, Danger4 TINYINT, Danger5 TINYINT);
			
				INSERT INTO @tmpSupportedDanger (Danger1,Danger2,Danger3,Danger4,Danger5)
				SELECT	ISNULL(JSON_VALUE(ssk.value, '$.Danger1'),0) AS Danger1
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger2'),0) AS Danger2
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger3'),0) AS Danger3
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger4'),0) AS Danger4
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger5'),0) AS Danger5
				FROM OPENJSON (@ListDanger) AS ssk;
				
				IF NOT EXISTS (SELECT 1 FROM @tmpSupportedDanger AS t WHERE t.Danger1 = 0 AND t.Danger2 = 0 AND t.Danger3 = 0 AND t.Danger4 = 0 AND t.Danger5 = 0)
				BEGIN
					DELETE t
					FROM #tmpMainTicket AS t
						LEFT JOIN @tmpSupportedDanger AS d1 ON d1.Danger1 = t.Danger1 AND t.Danger1 > 0
						LEFT JOIN @tmpSupportedDanger AS d2 ON d2.Danger2 = t.Danger2 AND t.Danger2 > 0
						LEFT JOIN @tmpSupportedDanger AS d3 ON d3.Danger3 = t.Danger3 AND t.Danger3 > 0
						LEFT JOIN @tmpSupportedDanger AS d4 ON d4.Danger4 = t.Danger4 AND t.Danger4 > 0
						LEFT JOIN @tmpSupportedDanger AS d5 ON d5.Danger5 = t.Danger5 AND t.Danger5 > 0
					WHERE d1.Danger1 IS NULL 
						AND d2.Danger2 IS NULL 
						AND d3.Danger3 IS NULL
						AND d4.Danger4 IS NULL
						AND d5.Danger5 IS NULL;
				END
				ELSE
				BEGIN
					DELETE t
					FROM #tmpMainTicket AS t
						LEFT JOIN @tmpSupportedDanger AS d1 ON d1.Danger1 = t.Danger1 AND t.Danger1 > 0
						LEFT JOIN @tmpSupportedDanger AS d2 ON d2.Danger2 = t.Danger2 AND t.Danger2 > 0
						LEFT JOIN @tmpSupportedDanger AS d3 ON d3.Danger3 = t.Danger3 AND t.Danger3 > 0
						LEFT JOIN @tmpSupportedDanger AS d4 ON d4.Danger4 = t.Danger4 AND t.Danger4 > 0
						LEFT JOIN @tmpSupportedDanger AS d5 ON d5.Danger5 = t.Danger5 AND t.Danger5 > 0
					WHERE NOT (t.Danger1 = 0 AND t.Danger2 = 0 AND t.Danger3 = 0 AND t.Danger4 = 0 AND t.Danger5 = 0)
						AND d1.Danger1 IS NULL 
						AND d2.Danger2 IS NULL 
						AND d3.Danger3 IS NULL
						AND d4.Danger4 IS NULL
						AND d5.Danger5 IS NULL;
				END;

			END;

			--========================Filter By Currency==================	
			IF (@ListCurrency IS NOT NULL)
			BEGIN
				WITH CTE_Currency AS (
					SELECT ssk.value AS CurrencyId FROM STRING_SPLIT(@ListCurrency, ',') AS ssk
				)
				DELETE t
				FROM #tmpMainTicket AS t
					LEFT JOIN CTE_Currency AS curr ON curr.CurrencyId = t.CurrencyId
				WHERE curr.CurrencyId IS NULL;
			END;

			--========================Fitler By Reason==================
			IF (@ListReason <> '')
			BEGIN
				DECLARE @tmpSupportedReason AS TABLE (Reason VARCHAR(50) DEFAULT '0' PRIMARY KEY);
				
				IF	OBJECT_ID('tempdb..#tmpTransIdReason') IS NOT NULL
				BEGIN
					DROP TABLE #tmpTransIdReason;
				END;

				CREATE TABLE #tmpTransIdReason(
						TransId			BIGINT NOT NULL PRIMARY KEY
					,	ListReason		VARCHAR(MAX)
					,	MinReason		VARCHAR(50) DEFAULT '0'	
				);
			
				INSERT INTO @tmpSupportedReason (Reason)
				SELECT ssk.value FROM STRING_SPLIT(@ListReason, ',') ssk;				
				
				--Delete Dup ticket 
				INSERT INTO #tmpTransIdReason(TransID, ListReason, MinReason)
				SELECT	tmpTr.TransID
					,	STRING_AGG(tmpRs.Reason, ',') WITHIN GROUP (ORDER BY tmpRs.Reason) AS Reason
					,	MIN(tmpRs.Reason)
				FROM #tmpMainTicket AS tmpTr WITH(NOLOCK)
					LEFT JOIN @tmpSupportedReason AS tmpRs ON tmpRs.Reason = tmpTr.Reason
				GROUP BY TransID;

				UPDATE tmpTk
				SET	tmpTk.ListReason = tmpTr.ListReason
				,	tmpTk.Reason = CASE WHEN tmpTr.MinReason = tmpTk.Reason THEN tmpTr.MinReason ELSE '-1' END
				FROM #tmpMainTicket AS tmpTk
					INNER JOIN #tmpTransIdReason AS tmpTr ON tmpTk.TransId = tmpTr.TransID
				
				--Delete ticket is not in Reason Filter
				DELETE t
				FROM #tmpMainTicket AS t
					LEFT JOIN @tmpSupportedReason AS c ON c.Reason = ISNULL(t.Reason,'0')
				WHERE c.Reason IS NULL;				

			END;

			--========================Fitler By AGroup==================
			IF @ListAGroup <> ''
			BEGIN
				WITH CTE_AGroup AS (
					SELECT ssk.value AS AGroup FROM STRING_SPLIT(@ListAGroup, ',') AS ssk
				)
				DELETE t
				FROM #tmpMainTicket AS t
					LEFT JOIN CTE_AGroup AS c ON c.AGroup = ISNULL(t.AGroup,0)
				WHERE c.AGroup IS NULL;
			END;

			--========================Fitler By MGroup==================
			IF @ListMGroup <> ''
			BEGIN
				WITH CTE_MGroup AS (
					SELECT ssk.value AS MGroup FROM STRING_SPLIT(@ListMGroup, ',') AS ssk
				)
				DELETE t
				FROM #tmpMainTicket AS t
					LEFT JOIN CTE_MGroup AS c ON c.MGroup = ISNULL(t.MGroup,0)
				WHERE c.MGroup IS NULL;
			END;

			--========================Fitler By HDP(Betteam)==================	
			IF (@ListHDPBetTeam IS NOT NULL)
			BEGIN
				IF EXISTS (	SELECT 1 
							FROM #tmpSportBettype AS st WITH(NOLOCK) 
							WHERE st.BetChoiceType = 1) --Filter Betteam
				BEGIN
					WITH CTE_BetTeam AS (
						SELECT ssk.value AS BetTeam FROM STRING_SPLIT(@ListHDPBetTeam, ',') AS ssk
					)
					DELETE t
					FROM #tmpSubTicket AS t
						LEFT JOIN CTE_BetTeam AS bt ON bt.BetTeam = t.BetTeam
					WHERE bt.BetTeam IS NULL;
				
				END
				ELSE IF EXISTS (SELECT 1 
								FROM #tmpSportBettype AS st WITH(NOLOCK) 
								WHERE st.BetChoiceType = 2) --Filter Hdp
				BEGIN
					WITH CTE_Hdp AS (
						SELECT ssk.value AS Hdp FROM STRING_SPLIT(@ListHDPBetTeam, ',') AS ssk
					)
					DELETE t
					FROM #tmpSubTicket AS t
						LEFT JOIN CTE_Hdp AS h ON h.Hdp = t.Hdp
					WHERE h.Hdp IS NULL;
				END;
			END;	

			--========================Fitler By Status==================	
			IF (@ListStatus IS NOT NULL)
			BEGIN
				WITH CTE_Status AS (
					SELECT ssk.value AS StatusID FROM STRING_SPLIT(@ListStatus, ',') AS ssk
				)
				DELETE t
				FROM #tmpSubTicket AS t
					LEFT JOIN CTE_Status AS s ON s.StatusID = t.TicketStatus
				WHERE s.StatusID IS NULL;
			END;		

			--========================Cust Amount(RM)==================	
			IF (@CustAmountRM > 0)
			BEGIN
				IF	OBJECT_ID('tempdb..#tmpCustAmount') IS NOT NULL
				BEGIN
					DROP TABLE	#tmpCustAmount;
				END;

				CREATE TABLE	#tmpCustAmount(
						CustId			INT
					,	BetteamGroup	NVARCHAR(10)
				);
			
				INSERT INTO #tmpCustAmount(CustId, BetteamGroup)
				SELECT	mt.CustId
					,	st.BetteamGroup
				FROM #tmpMainTicket AS mt WITH(NOLOCK)
					INNER JOIN #tmpSubTicket AS st WITH(NOLOCK) ON st.Refno = mt.Refno
				GROUP BY mt.CustId, st.BetteamGroup
				HAVING SUM(mt.Amount) >= @CustAmountRM;

				CREATE CLUSTERED INDEX CIX_tmpCustAmount_Group ON #tmpCustAmount (CustID, BetteamGroup);

				DELETE tmpTk
				FROM #tmpSubTicket AS tmpTk WITH(NOLOCK)
					LEFT JOIN #tmpCustAmount AS tmpCa WITH(NOLOCK) ON tmpCa.CustId = tmpTk.CustId and tmpCa.BetteamGroup = tmpTk.BetteamGroup
				WHERE tmpCa.CustId IS NULL;
			END;

			
			
		END;
		--RETURN DATA--
	

		SELECT	st.CustId
			,	mt.CustomerClass
			,	mt.Danger1
			,	mt.Danger2
			,	mt.Danger3
			,	mt.Danger4
			,	mt.Danger5

			--	CHOICE------------
			,	(CASE WHEN st.BetTeam = sb.BetChoiceHome THEN 10
						WHEN st.BetTeam = sb.BetChoiceAway THEN 20
						ELSE NULL END) AS ChoiceOrder
			,	st.OrderTicket
			,	st.Refno
			,	mt.Combinition
			,	st.TransId AS TransID			
			,	st.MatchId
			,	h.TeamName AS HomeName
			,	a.TeamName AS AwayName
			,	bt.typenamee AS BettypeName
			,	CASE WHEN sb.BetTypeID IS NULL THEN st.Betteam ELSE sb.BetChoiceAwayFullName END AS Betteam
			,	s.SportName AS SportType
			,	l.LeagueName
			,	st.GlobalShowTime
			------------------------------
			,	st.Odds
			,	st.Odds AS MalayOdds
			,	mt.CurrencyName
			,	ABS(CASE WHEN sb.BetChoiceType = 2 THEN st.Hdp1 - st.Hdp2 END) AS HDP
			,	st.LiveHomeScore
			,	st.LiveAwayScore
			,	mt.TransDate
			,	mt.BetFrom
			,	mt.AGroup
			,	mt.MGroup
			,	mt.Reason
			,	ISNULL(mt.ListReason,mt.Reason) AS ListReason
			
	FROM  #tmpMainTicket AS mt WITH(NOLOCK)
		INNER JOIN #tmpSubTicket AS st WITH(NOLOCK) ON st.Refno = mt.Refno
		LEFT JOIN #tmpSportBettype AS sb WITH(NOLOCK) ON sb.SportTypeID = st.SportType AND sb.BetTypeID = st.BetType
		LEFT JOIN bodb02.dbo.Team AS h WITH(NOLOCK) ON h.TeamID = st.HomeID
		LEFT JOIN bodb02.dbo.Team AS a WITH(NOLOCK) ON a.TeamID = st.AwayID
		LEFT JOIN bodb02.dbo.League AS l WITH(NOLOCK) ON l.LeagueID = st.LeagueID
		LEFT JOIN bodb02.dbo.Sports AS s WITH(NOLOCK) ON s.SportType = st.SportType
		LEFT JOIN bodb02.dbo.Bettype AS bt WITH(NOLOCK) ON st.bettype = bt.typeID
	ORDER BY mt.Refno ASC, OrderTicket ASC, MatchID DESC;		
END
/*
	IF (@QueryType = 2) --Get Date for MM Monitor
		BEGIN --Get Ticket for MM Details Report 
			----==================GET Trans==================
			IF @IsGetDataFromBK = 1
			BEGIN
				IF (@ListRefno <> '' AND @ViewMode = 1) 
				BEGIN
					INSERT INTO #tmpSubTicket(TransID, Refno, TransIdm,TransDate,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetteamGroup,BetTeam,BetChoiceHome,BetChoiceAway
						,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup, OddsType, IsCashout)
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
						,	(CASE WHEN st.BetChoiceType = 2 THEN b.Betteam ELSE '1' END) AS BetteamGroup
						,	b.betteam
						,	st.BetChoiceHome
						,	st.BetChoiceAway
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
						,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS HDP
						,	b.BetFrom
						,	ISNULL(tmpTs.Reason,'0')
						,	ISNULL(tmpTs.AGroup,0)
						,	ISNULL(tmpTs.MGroup,0)
						,	b.oddstype
					FROM #tmpInputRefno AS tmpTs WITH(NOLOCK)
						INNER JOIN bodb_Archive.dbo.bettrans_bk AS bt WITH(NOLOCK) ON bt.Refno = tmpTs.Refno
						INNER JOIN bodb_Archive.dbo.Bettransm AS b WITH(NOLOCK) ON b.refno = tmpTs.Refno
						INNER JOIN bodb_Archive.dbo.match_bk AS m WITH(NOLOCK) ON b.matchid = m.matchid
						INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID 
						INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
					WHERE (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate))
					;
				END;
			END;

			IF	@IsGetDataFrom14 = 1
			BEGIN
				IF (@ListRefno <> '' AND @ViewMode = 1) 
				BEGIN
					INSERT INTO #tmpSubTicket(TransId,TransDate,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetteamGroup,BetTeam,BetChoiceHome,BetChoiceAway
						,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup, OddsType, IsCashout)
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
						,	(CASE WHEN st.BetChoiceType = 2 THEN b.Betteam ELSE '1' END) AS BetteamGroup
						,	b.betteam
						,	st.BetChoiceHome
						,	st.BetChoiceAway
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
						,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS HDP
						,	b.BetFrom
						,	ISNULL(tmpTs.Reason,'0')
						,	ISNULL(tmpTs.AGroup,0)
						,	ISNULL(tmpTs.MGroup,0)
						,	b.oddstype
						,	CASE WHEN b.betdaqid = -2 THEN 1 ELSE 0 END AS IsCashout
					FROM #tmpInputRefno AS tmpTs WITH(NOLOCK)
						INNER JOIN bodb02.dbo.bettrans14 AS b WITH(NOLOCK) ON b.TransId = tmpTs.TransId
						INNER JOIN bodb02.dbo.match14 AS m WITH(NOLOCK) ON b.matchid = m.matchid
						INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID 
						INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
					WHERE (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate))
					;
				END;
			END;

			IF	@IsGetDataFromOrigin = 1
			BEGIN
				IF (@ListRefno <> '' AND @ViewMode = 1) 
				BEGIN
					INSERT INTO #tmpSubTicket(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetteamGroup,BetTeam,BetChoiceHome,BetChoiceAway
						,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup, OddsType, IsCashout)
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
						,	(CASE WHEN st.BetChoiceType = 2 THEN b.Betteam ELSE '1' END) AS BetteamGroup
						,	b.betteam
						,	st.BetChoiceHome
						,	st.BetChoiceAway
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
						,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS HDP
						,	b.BetFrom
						,	ISNULL(tmpTs.Reason,'0')
						,	ISNULL(tmpTs.AGroup,0)
						,	ISNULL(tmpTs.MGroup,0)
						,	b.oddstype
						,	CASE WHEN b.betdaqid = -2 THEN 1 ELSE 0 END AS IsCashout
					FROM #tmpInputRefno AS tmpTs WITH(NOLOCK)
						INNER JOIN bodb02.dbo.bettrans AS b WITH(NOLOCK) ON b.TransId = tmpTs.TransId
						INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
						INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID 
						INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
					WHERE (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
				END
				ELSE IF (@ViewMode = 0)
				BEGIN	
					IF (@CustAmountRM > 0) 
					BEGIN	

						INSERT INTO #tmpSubTicket(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetteamGroup,BetTeam,BetChoiceHome,BetChoiceAway
							,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup, OddsType, IsCashout)
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
								,	(CASE WHEN st.BetChoiceType = 2 THEN b.Betteam ELSE '1' END) AS BetteamGroup
								,	b.betteam
								,	st.BetChoiceHome
								,	st.BetChoiceAway
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
								,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS HDP
								,	b.BetFrom
							,	ISNULL(tmpTs.Reason,'0')
							,	ISNULL(tmpTs.AGroup,0)
							,	ISNULL(tmpTs.MGroup,0)
								,	b.oddstype
								,	CASE WHEN b.betdaqid = -2 THEN 1 ELSE 0 END AS IsCashout
							FROM bodb02.dbo.bettrans AS b WITH(NOLOCK)
								INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
								INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID AND b.BetID = st.BetID
								INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency	
								LEFT JOIN #tmpInputRefno AS tmpTs WITH(NOLOCK) ON b.TransId = tmpTs.TransId
							WHERE	b.sequenceid < @LastScannedSequenceID								
								AND b.matchid = @MatchID
								AND b.liveindicator = @IsLive
								AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
								AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
					END;

					IF (@CustAmountRM <= 0) 
					BEGIN
						IF (@BatchSize = 0) ---GET TotalTicket
						BEGIN
							INSERT INTO #tmpSubTicket(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetteamGroup,BetTeam,BetChoiceHome,BetChoiceAway
								,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup, OddsType, IsCashout)
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
								,	(CASE WHEN st.BetChoiceType = 2 THEN b.Betteam ELSE '1' END) AS BetteamGroup
								,	b.betteam
								,	st.BetChoiceHome
								,	st.BetChoiceAway
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
								,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS HDP
								,	b.BetFrom
							,	ISNULL(tmpTs.Reason,'0')
							,	ISNULL(tmpTs.AGroup,0)
							,	ISNULL(tmpTs.MGroup,0)
								,	b.oddstype
								,	CASE WHEN b.betdaqid = -2 THEN 1 ELSE 0 END AS IsCashout
							FROM bodb02.dbo.bettrans AS b WITH(NOLOCK)
								INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
								INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID AND b.BetID = st.BetID
								INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
								LEFT JOIN #tmpInputRefno AS tmpTs WITH(NOLOCK) ON b.TransId = tmpTs.TransId
							WHERE	b.sequenceid < @LastScannedSequenceID							
								AND b.matchid = @MatchID	
								AND b.liveindicator = @IsLive
								AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
								AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate));
						END
						ELSE IF (@BatchSize > 0) --- GET Ticket Details 
						BEGIN
							INSERT INTO #tmpSubTicket(SequenceId,TransId,TransDate,MatchId,EventDate,EventStatus,GlobalShowTime,HomeId,AwayId,LeagueId,SportType,BetType,CustId,BetteamGroup,BetTeam,BetChoiceHome,BetChoiceAway
								,BetId,Stake,OrgStake,Odds,Hdp1,Hdp2,LiveHomeScore,LiveAwayScore,TicketStatus, LiveIndicator, CurrencyName,CurrencyId,Hdp,BetFrom, Reason, AGroup, MGroup, OddsType, IsCashout)
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
								,	(CASE WHEN st.BetChoiceType = 2 THEN b.Betteam ELSE '1' END) AS BetteamGroup
								,	b.betteam
								,	st.BetChoiceHome
								,	st.BetChoiceAway
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
								,	ABS(CASE WHEN st.BetChoiceType = 2 THEN b.Hdp1 - b.Hdp2 END) AS HDP
								,	b.BetFrom							
							,	ISNULL(tmpTs.Reason,'0')
							,	ISNULL(tmpTs.AGroup,0)
							,	ISNULL(tmpTs.MGroup,0)
								,	b.oddstype
								,	CASE WHEN b.betdaqid = -2 THEN 1 ELSE 0 END AS IsCashout
							FROM bodb02.dbo.bettrans AS b WITH(NOLOCK)
								INNER JOIN bodb02.dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
								INNER JOIN bodb02.dbo.league AS l WITH(NOLOCK) ON l.leagueid = m.leagueid
								INNER JOIN #tmpSportBettype AS st WITH(NOLOCK) ON m.sporttype = st.SportTypeID AND b.bettype = st.BetTypeID AND b.BetID = st.BetID 
								INNER JOIN bodb02.dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
								LEFT JOIN #tmpInputRefno AS tmpTs WITH(NOLOCK) ON b.TransId = tmpTs.TransId
							WHERE	b.sequenceid < @LastScannedSequenceID
								AND b.matchid = @MatchID
								AND b.liveindicator = @IsLive
								AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
								AND (@FromTransDate IS NULL OR (b.TransDate >= @FromTransDate AND b.TransDate < @ToTransDate))
							ORDER BY b.sequenceid DESC;

							SET @MinSequenceId = (SELECT MIN(SequenceId) FROM #tmpSubTicket);
						END 
					END;
					
				END;
			END;
			
			----==================UPDATE Malay Odds==================
			UPDATE t WITH(ROWLOCK, UPDLOCK)
			SET t.MalayOdds = CASE 
								-- Decimal
								WHEN t.oddstype = 1 THEN (CASE
															WHEN ot.OddsType IS NOT NULL THEN (CASE 
																								WHEN t.odds <= 2 THEN (t.odds - 1)
																								WHEN t.odds > 2 THEN -(1/NULLIF((t.odds - 1),0)) END)
															ELSE (CASE 
																	WHEN t.odds <= 1 THEN t.odds
																	WHEN t.odds > 1 THEN -(1/NULLIF(t.odds,0)) END) END)
								-- Hong Kong
								WHEN t.oddstype = 2 THEN (CASE	
															WHEN t.odds <= 1 THEN t.odds
															WHEN t.odds > 1 THEN -(1/NULLIF(t.odds,0)) END)
								-- Indonesia
								WHEN t.oddstype = 3 THEN -(1/NULLIF(t.odds,0))
								-- Malaysian & Myanmar
								WHEN t.oddstype IN (4,6) THEN t.odds
								-- US
								WHEN t.oddstype = 5 THEN -(1/NULLIF(t.odds,0))
							END
			FROM #tmpSubTicket AS t
				LEFT JOIN bodb02.dbo.f_Set_OddsTypeBettypes() AS ot ON ot.BetType = t.BetType;
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
	FROM #tmpSubTicket AS t
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN bodb02.dbo.Dep_CustSuper AS cs WITH (NOLOCK) ON cs.custid = c.srecommend;

	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET t.IsLicensee	= 0
	,	t.Danger1		= c.danger
	,	t.Danger2		= c.danger2
	,	t.Danger3		= c.danger3
	,	t.Danger4		= c.Danger4
	,	t.Danger5		= c.Danger5
	,	t.CustomerClass	= c.CustomerClass
	FROM #tmpSubTicket AS t
		INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN bodb02.dbo.CustProductStatus AS s WITH (NOLOCK) ON s.custid = c.custid
	WHERE t.IsLicensee IS NULL;
	
	----==================FILTERS=========================		
	IF (@ListScore IS NOT NULL) OR (@IsLicensee IS NOT NULL) OR (@ListCustomerClass <> '') OR (@ListDanger IS NOT NULL)
		OR (@ListCurrency IS NOT NULL) OR (@ListReason <> '') OR (@ListAGroup <> '') OR (@ListMGroup <> '') OR (@ListHDPBetTeam IS NOT NULL)
		OR (@ListStatus IS NOT NULL) OR (@CustAmountRM > 0) OR (@CustAmountRM > 0)
	BEGIN
		SET @IsFilter = 1;
	END;
	
	IF (@IsFilter = 1)
	BEGIN
		GOTO CHECK_FILTER;
	END;
	
	CHECK_FILTER:
		IF (@IsFilter = 1)
		BEGIN
			--====================Fitler By Score==================	
			IF (@ListScore IS NOT NULL)
			BEGIN
				WITH CTE_Score AS (
					SELECT cas.LiveHomeScore, cas.LiveAwayScore
					FROM STRING_SPLIT(@ListScore, ',') ssk
						CROSS APPLY (SELECT	LiveHomeScore = xDim.value('/x[1]','varchar(max)')
										,	LiveAwayScore = xDim.value('/x[2]','varchar(max)')
									From (SELECT CAST('<x>' + REPLACE(REPLACE(ssk.value,'-',''),'  ','</x><x>')+'</x>' AS XML) AS xDim) AS s
									) AS cas
				)
				DELETE t
				FROM #tmpSubTicket AS t
					LEFT JOIN CTE_Score AS s ON s.LiveHomeScore = t.LiveHomeScore AND s.LiveAwayScore = t.LiveAwayScore
				WHERE s.LiveHomeScore IS NULL;

			END;

			--========================Fitler By Site(IsLicensee)==================
			IF (@IsLicensee IS NOT NULL)
			BEGIN
				DELETE t
				FROM #tmpSubTicket AS t
				WHERE t.IsLicensee != @IsLicensee;
			END;

			--========================Fitler By CustomerClass==================
			IF (@ListCustomerClass <> '')
			BEGIN
				WITH CTE_CC AS (
					SELECT ssk.value AS CustomerClass FROM STRING_SPLIT(@ListCustomerClass, ',') AS ssk
				)
				DELETE t
				FROM #tmpSubTicket AS t
					LEFT JOIN CTE_CC AS c ON c.CustomerClass = ISNULL(t.CustomerClass,0)
				WHERE c.CustomerClass IS NULL;
			END;

			--========================Fitler By Danger==================		
			IF (@ListDanger IS NOT NULL)
			BEGIN
				DECLARE @tmpSupportedDanger AS TABLE (Danger1 TINYINT, Danger2 TINYINT, Danger3 TINYINT, Danger4 TINYINT, Danger5 TINYINT);
			
				INSERT INTO @tmpSupportedDanger (Danger1,Danger2,Danger3,Danger4,Danger5)
				SELECT	ISNULL(JSON_VALUE(ssk.value, '$.Danger1'),0) AS Danger1
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger2'),0) AS Danger2
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger3'),0) AS Danger3
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger4'),0) AS Danger4
					,	ISNULL(JSON_VALUE(ssk.value, '$.Danger5'),0) AS Danger5
				FROM OPENJSON (@ListDanger) AS ssk;
				
				IF NOT EXISTS (SELECT 1 FROM @tmpSupportedDanger AS t WHERE t.Danger1 = 0 AND t.Danger2 = 0 AND t.Danger3 = 0 AND t.Danger4 = 0 AND t.Danger5 = 0)
				BEGIN
					DELETE t
					FROM #tmpSubTicket AS t
						LEFT JOIN @tmpSupportedDanger AS d1 ON d1.Danger1 = t.Danger1 AND t.Danger1 > 0
						LEFT JOIN @tmpSupportedDanger AS d2 ON d2.Danger2 = t.Danger2 AND t.Danger2 > 0
						LEFT JOIN @tmpSupportedDanger AS d3 ON d3.Danger3 = t.Danger3 AND t.Danger3 > 0
						LEFT JOIN @tmpSupportedDanger AS d4 ON d4.Danger4 = t.Danger4 AND t.Danger4 > 0
						LEFT JOIN @tmpSupportedDanger AS d5 ON d5.Danger5 = t.Danger5 AND t.Danger5 > 0
					WHERE d1.Danger1 IS NULL 
						AND d2.Danger2 IS NULL 
						AND d3.Danger3 IS NULL
						AND d4.Danger4 IS NULL
						AND d5.Danger5 IS NULL;
				END
				ELSE
				BEGIN
					DELETE t
					FROM #tmpSubTicket AS t
						LEFT JOIN @tmpSupportedDanger AS d1 ON d1.Danger1 = t.Danger1 AND t.Danger1 > 0
						LEFT JOIN @tmpSupportedDanger AS d2 ON d2.Danger2 = t.Danger2 AND t.Danger2 > 0
						LEFT JOIN @tmpSupportedDanger AS d3 ON d3.Danger3 = t.Danger3 AND t.Danger3 > 0
						LEFT JOIN @tmpSupportedDanger AS d4 ON d4.Danger4 = t.Danger4 AND t.Danger4 > 0
						LEFT JOIN @tmpSupportedDanger AS d5 ON d5.Danger5 = t.Danger5 AND t.Danger5 > 0
					WHERE NOT (t.Danger1 = 0 AND t.Danger2 = 0 AND t.Danger3 = 0 AND t.Danger4 = 0 AND t.Danger5 = 0)
						AND d1.Danger1 IS NULL 
						AND d2.Danger2 IS NULL 
						AND d3.Danger3 IS NULL
						AND d4.Danger4 IS NULL
						AND d5.Danger5 IS NULL;
				END;

			END;

			--========================Filter By Currency==================	
			IF (@ListCurrency IS NOT NULL)
			BEGIN
				WITH CTE_Currency AS (
					SELECT ssk.value AS CurrencyId FROM STRING_SPLIT(@ListCurrency, ',') AS ssk
				)
				DELETE t
				FROM #tmpSubTicket AS t
					LEFT JOIN CTE_Currency AS curr ON curr.CurrencyId = t.CurrencyId
				WHERE curr.CurrencyId IS NULL;
			END;

			--========================Fitler By Reason==================
			IF (@ListReason <> '')
			BEGIN
				DECLARE @tmpSupportedReason AS TABLE (Reason VARCHAR(50) DEFAULT '0' PRIMARY KEY);
				
				IF	OBJECT_ID('tempdb..#tmpTransIdReason') IS NOT NULL
				BEGIN
					DROP TABLE #tmpTransIdReason;
				END;

				CREATE TABLE #tmpTransIdReason(
						TransId			BIGINT NOT NULL PRIMARY KEY
					,	ListReason		VARCHAR(MAX)
					,	MinReason		VARCHAR(50) DEFAULT '0'	
				);
			
				INSERT INTO @tmpSupportedReason (Reason)
				SELECT ssk.value FROM STRING_SPLIT(@ListReason, ',') ssk;				
				
				--Delete Dup ticket 
				INSERT INTO #tmpTransIdReason(TransID, ListReason, MinReason)
				SELECT	tmpTr.TransID
					,	STRING_AGG(tmpRs.Reason, ',') WITHIN GROUP (ORDER BY tmpRs.Reason) AS Reason
					,	MIN(tmpRs.Reason)
				FROM #tmpInputRefno AS tmpTr WITH(NOLOCK)
					LEFT JOIN @tmpSupportedReason AS tmpRs ON tmpRs.Reason = tmpTr.Reason
				GROUP BY TransID;

				UPDATE tmpTk
				SET	tmpTk.ListReason = tmpTr.ListReason
				,	tmpTk.Reason = CASE WHEN tmpTr.MinReason = tmpTk.Reason THEN tmpTr.MinReason ELSE '-1' END
				FROM #tmpSubTicket AS tmpTk
					INNER JOIN #tmpTransIdReason AS tmpTr ON tmpTk.TransId = tmpTr.TransID
				
				--Delete ticket is not in Reason Filter
				DELETE t
				FROM #tmpSubTicket AS t
					LEFT JOIN @tmpSupportedReason AS c ON c.Reason = ISNULL(t.Reason,'0')
				WHERE c.Reason IS NULL;				

			END;

			--========================Fitler By AGroup==================
			IF @ListAGroup <> ''
			BEGIN
				WITH CTE_AGroup AS (
					SELECT ssk.value AS AGroup FROM STRING_SPLIT(@ListAGroup, ',') AS ssk
				)
				DELETE t
				FROM #tmpSubTicket AS t
					LEFT JOIN CTE_AGroup AS c ON c.AGroup = ISNULL(t.AGroup,0)
				WHERE c.AGroup IS NULL;
			END;

			--========================Fitler By MGroup==================
			IF @ListMGroup <> ''
			BEGIN
				WITH CTE_MGroup AS (
					SELECT ssk.value AS MGroup FROM STRING_SPLIT(@ListMGroup, ',') AS ssk
				)
				DELETE t
				FROM #tmpSubTicket AS t
					LEFT JOIN CTE_MGroup AS c ON c.MGroup = ISNULL(t.MGroup,0)
				WHERE c.MGroup IS NULL;
			END;

			--========================Fitler By HDP(Betteam)==================	
			IF (@ListHDPBetTeam IS NOT NULL)
			BEGIN
				IF EXISTS (	SELECT 1 
							FROM #tmpSportBettype AS st WITH(NOLOCK) 
							WHERE st.BetChoiceType = 1) --Filter Betteam
				BEGIN
					WITH CTE_BetTeam AS (
						SELECT ssk.value AS BetTeam FROM STRING_SPLIT(@ListHDPBetTeam, ',') AS ssk
					)
					DELETE t
					FROM #tmpSubTicket AS t
						LEFT JOIN CTE_BetTeam AS bt ON bt.BetTeam = t.BetTeam
					WHERE bt.BetTeam IS NULL;
				
				END
				ELSE IF EXISTS (SELECT 1 
								FROM #tmpSportBettype AS st WITH(NOLOCK) 
								WHERE st.BetChoiceType = 2) --Filter Hdp
				BEGIN
					WITH CTE_Hdp AS (
						SELECT ssk.value AS Hdp FROM STRING_SPLIT(@ListHDPBetTeam, ',') AS ssk
					)
					DELETE t
					FROM #tmpSubTicket AS t
						LEFT JOIN CTE_Hdp AS h ON h.Hdp = t.Hdp
					WHERE h.Hdp IS NULL;
				END;
			END;	

			--========================Fitler By Status==================	
			IF (@ListStatus IS NOT NULL)
			BEGIN
				WITH CTE_Status AS (
					SELECT ssk.value AS StatusID FROM STRING_SPLIT(@ListStatus, ',') AS ssk
				)
				DELETE t
				FROM #tmpSubTicket AS t
					LEFT JOIN CTE_Status AS s ON s.StatusID = t.TicketStatus
				WHERE s.StatusID IS NULL;
			END;		

			--========================Cust Amount(RM)==================	
			IF (@CustAmountRM > 0)
			BEGIN
				IF	OBJECT_ID('tempdb..#tmpCustAmount') IS NOT NULL
				BEGIN
					DROP TABLE	#tmpCustAmount;
				END;

				CREATE TABLE	#tmpCustAmount(
						CustId			INT
					,	BetteamGroup	NVARCHAR(10)
				);
			
				INSERT INTO #tmpCustAmount(CustId, BetteamGroup)
				SELECT	tmpTk.CustId
					,	tmpTk.BetteamGroup
				FROM #tmpSubTicket AS tmpTk WITH(NOLOCK)
				GROUP BY tmpTk.CustId, tmpTk.BetteamGroup
				HAVING SUM(tmpTk.Stake) >= @CustAmountRM;

				CREATE CLUSTERED INDEX CIX_tmpCustAmount_Group ON #tmpCustAmount (CustID, BetteamGroup);

				DELETE tmpTk
				FROM #tmpSubTicket AS tmpTk WITH(NOLOCK)
					LEFT JOIN #tmpCustAmount AS tmpCa WITH(NOLOCK) ON tmpCa.CustId = tmpTk.CustId and tmpCa.BetteamGroup = tmpTk.BetteamGroup
				WHERE tmpCa.CustId IS NULL;
			END;

		END;
		
	--====================RETURN DATA================================================
	IF (@QueryType = 2 AND @BatchSize = 0)
		BEGIN					
			SET @TotalTicket = (SELECT COUNT(1) FROM #tmpSubTicket);
		END
	ELSE --Return Ticket Details
		BEGIN
			SELECT	tmpTk.SequenceId
				,	tmpTk.TransId
				,	tmpTk.TransDate
				,	tmpTk.MatchId
				,	tmpTk.EventDate
				,	tmpTk.EventStatus
				,	tmpTk.GlobalShowTime
				,	tmpTk.HomeId
				,	tmpTk.AwayId
				,	tmpTk.LeagueId
				,	tmpTk.LeagueName
				,	tmpTk.IsMajorLeague
				,	tmpTk.SportType
				,	tmpTk.BetType
				,	tmpTk.CustId
				,	tmpTk.BetTeam
				,	(CASE WHEN tmpTk.BetTeam = tmpTk.BetChoiceHome THEN 10
						 WHEN tmpTk.BetTeam = tmpTk.BetChoiceAway THEN 20
						 ELSE NULL END) AS ChoiceOrder
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
				,	tmpTk.MalayOdds
			FROM #tmpSubTicket AS tmpTk WITH(NOLOCK);
		END;
	
	DROP TABLE IF EXISTS #tmpSportBettype;
	DROP TABLE IF EXISTS #tmpSubTicket;
	DROP TABLE IF EXISTS #tmpInputRefno;
	DROP TABLE IF EXISTS #tmpTransIdReason;
	DROP TABLE IF EXISTS #tmpCustAmount;
	*/
