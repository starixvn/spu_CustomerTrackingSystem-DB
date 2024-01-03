/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CTS_MatchTicketInfo_Get]
		@MatchIds			VARCHAR(MAX) = ''
	,	@MarketList			VARCHAR(10)  = NULL
	,	@BettypeList		VARCHAR(MAX) = NULL
	,	@DangerList			VARCHAR(MAX) = NULL
	
	
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
		
		EXECUTE [dbo].[CTS_MatchTicketInfo_Get] @MatchIds = '77933629,77933630,77933651'--,67089553,77935045,76886100'
		,	@BettypeList='[	{"BetType":1, "BetChoiceType":2, "BetChoiceHome":"h", "BetChoiceAway":"a", "BetID":0}
						,	{"BetType":3, "BetChoiceType":2, "BetChoiceHome":"h", "BetChoiceAway":"a", "BetID":0}
						,	{"BetType":610, "BetChoiceType":2, "BetChoiceHome":"o", "BetChoiceAway":"u", "BetID":0}
						,	{"BetType":126, "BetChoiceType":1}]'
		,	@DangerList = '[{"Danger1":1},{"Danger1":10},{"Danger3":10},{"Danger4":45},{"Danger5":1},{"Danger5":5}]'
		,	@MarketList = '0,1';

		SELECT * FROM Bettrans WHERE MatchID = 77933629 AND Bettype = 1 
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @Today			DATE = GETDATE();

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
		,	BetType				INT
		,	BetChoiceType			TINYINT
		,	BetChoiceHome			NVARCHAR(10)
		,	BetChoiceAway			NVARCHAR(10)
		,	BetIDPattern			NVARCHAR(20)
		,	BetID					BIGINT
	)

	--=================================================================================================

	IF	OBJECT_ID('tempdb..#tmpDanger1') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger1;
	END;

	CREATE TABLE	#tmpDanger1(
			Danger1				TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpDanger2') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger2;
	END;

	CREATE TABLE	#tmpDanger2(
			Danger2				TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpDanger3') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger3;
	END;

	CREATE TABLE	#tmpDanger3(
			Danger3				TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpDanger4') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger4;
	END;

	CREATE TABLE	#tmpDanger4(
			Danger4				TINYINT
	);

	IF	OBJECT_ID('tempdb..#tmpDanger5') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpDanger5;
	END;

	CREATE TABLE	#tmpDanger5(
			Danger5				TINYINT
	);

	--==================================================================================================
	IF	OBJECT_ID('tempdb..#tmpMatchesInfo') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatchesInfo;
	END;

	CREATE TABLE #tmpMatchesInfo (
			MatchId			INT NOT NULL
		,	LiveIndicator	BIT
		,	Bettype			INT NOT NULL
		,	BetChoiceType	TINYINT
		,	TotalAmountHome DECIMAL(20,4) -- IF BetChoiceType = 1  then TOTAL ALL
		,	TotalAmountAway DECIMAL(20,4)  -- IF BetChoiceType = 1 then 0
		,	TotalTicketHome INT -- IF BetChoiceType = 1  then TOTAL ALL
		,	TotalTicketAway INT  -- IF BetChoiceType = 1 then 0
	);

	CREATE CLUSTERED INDEX #CIX_tmpMatchesInfo_MatchIdBettype ON #tmpMatchesInfo (
			MatchId	ASC
		,	Bettype ASC
	);

	--=========Parse Market From @MarketList======================================
	IF @MarketList <> ''
	BEGIN
			INSERT INTO #tmpMarket(LiveIndicator)
			SELECT ssk.value FROM STRING_SPLIT (@MarketList, ',') ssk;
	END
	ELSE
	BEGIN
		INSERT INTO #tmpMarket(LiveIndicator)
		VALUES(NULL);
	END;

	--=========Parse Bettype From @BettypeList======================================
	IF @BettypeList <> ''
	BEGIN
			INSERT INTO #tmpBettype(BetType,BetChoiceType,BetChoiceHome,BetChoiceAway,BetIDPattern,BetID)
			SELECT	j.BetType
				,	j.BetChoiceType
				,	j.BetChoiceHome
				,	j.BetChoiceAway
				,	j.BetIDPattern
				,	j.BetID
			FROM OPENJSON (@BettypeList) WITH (
					BetType			INT				'$.BetType'
				,	BetChoiceType		TINYINT			'$.BetChoiceType'
				,	BetChoiceHome		NVARCHAR(10)	'$.BetChoiceHome'
				,	BetChoiceAway		NVARCHAR(10)	'$.BetChoiceAway'
				,	BetIDPattern		NVARCHAR(20)	'$.BetIDPattern'
				,	BetID				BIGINT			'$.BetID'
				) AS j;
	END
	ELSE
	BEGIN
		INSERT INTO #tmpBettype(BetType,BetChoiceType,BetChoiceHome,BetChoiceAway,BetIDPattern,BetID)
		VALUES(NULL,NULL,NULL,NULL,NULL,NULL);
	END;
	
	--========Parse @Danger From @DangerList=========================================
	INSERT INTO #tmpDanger1 (Danger1)
	SELECT	ISNULL(JSON_VALUE(ssk.value, '$.Danger1'),0) AS Danger1
	FROM OPENJSON (@DangerList) AS ssk;

	IF NOT EXISTS (SELECT 1 FROM #tmpDanger1)
	BEGIN
		INSERT INTO #tmpDanger1 (Danger1)
		VALUES(NULL)
	END;

	INSERT INTO #tmpDanger2 (Danger2)
	SELECT	ISNULL(JSON_VALUE(ssk.value, '$.Danger2'),0) AS Danger2
	FROM OPENJSON (@DangerList) AS ssk;

	IF NOT EXISTS (SELECT 1 FROM #tmpDanger2)
	BEGIN
		INSERT INTO #tmpDanger2(Danger2)
		VALUES(NULL)
	END;

	INSERT INTO #tmpDanger3 (Danger3)
	SELECT	ISNULL(JSON_VALUE(ssk.value, '$.Danger3'),0) AS Danger3
	FROM OPENJSON (@DangerList) AS ssk;

	IF NOT EXISTS (SELECT 1 FROM #tmpDanger3)
	BEGIN
		INSERT INTO #tmpDanger3(Danger3)
		VALUES(NULL)
	END;

	INSERT INTO #tmpDanger4 (Danger4)
	SELECT	ISNULL(JSON_VALUE(ssk.value, '$.Danger4'),0) AS Danger4
	FROM OPENJSON (@DangerList) AS ssk;

	IF NOT EXISTS (SELECT 1 FROM #tmpDanger4)
	BEGIN
		INSERT INTO #tmpDanger4(Danger4)
		VALUES(NULL)
	END;

	INSERT INTO #tmpDanger5 (Danger5)
	SELECT	ISNULL(JSON_VALUE(ssk.value, '$.Danger5'),0) AS Danger5
	FROM OPENJSON (@DangerList) AS ssk;

	IF NOT EXISTS (SELECT 1 FROM #tmpDanger5)
	BEGIN
		INSERT INTO #tmpDanger5(Danger5)
		VALUES(NULL)
	END;

	--==================================================================================================
	IF @MatchIds <> '' --GET Match Info By List MatchID
	BEGIN

		INSERT INTO #tmpMatches (MatchId)
		SELECT ssk.value FROM STRING_SPLIT (@MatchIds, ',') ssk;
		
		INSERT INTO #tmpMatchesInfo (MatchId,LiveIndicator, Bettype,BetChoiceType,TotalAmountHome,TotalAmountAway,TotalTicketHome,TotalTicketAway)
		SELECT	b.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	tmpBt.BetChoiceType
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN b.stake * b.actualrate 
						ELSE b.stake * b.actualrate END) AS TotalAmountHome
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN b.stake * b.actualrate 
						ELSE 0 END) AS TotalAmountAway
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN 1 
						ELSE 1 END) AS TotalTicketHome
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN 1 
						ELSE 0 END) AS TotalTicketAway
		FROM #tmpMatches AS tm WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Bettrans AS b WITH(NOLOCK) ON b.MatchId = tm.matchid
			INNER JOIN #tmpBetType AS tmpBt WITH(NOLOCK) ON b.bettype = ISNULL(tmpBt.BetType,b.bettype) AND tmpBt.betID = b.betid
			INNER JOIN #tmpMarket AS tmpMk WITH(NOLOCK) ON b.liveindicator = ISNULL(tmpMk.LiveIndicator,b.LiveIndicator)
			INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.CustId = b.CustId
			INNER JOIN #tmpDanger1 AS tmpDg1 WITH(NOLOCK) ON c.Danger = ISNULL(tmpDg1.Danger1,c.Danger)
			INNER JOIN #tmpDanger2 AS tmpDg2 WITH(NOLOCK) ON c.Danger2 = ISNULL(tmpDg2.Danger2,c.Danger2)
			INNER JOIN #tmpDanger3 AS tmpDg3 WITH(NOLOCK) ON c.Danger3 = ISNULL(tmpDg3.Danger3,c.Danger3)
			INNER JOIN #tmpDanger4 AS tmpDg4 WITH(NOLOCK) ON c.Danger4 = ISNULL(tmpDg4.Danger4,c.Danger4)
			INNER JOIN #tmpDanger5 AS tmpDg5 WITH(NOLOCK) ON c.Danger5 = ISNULL(tmpDg5.Danger5,c.Danger5)
		GROUP BY b.MatchId, b.LiveIndicator, b.Bettype,tmpBt.BetChoiceType;

		DELETE tm
		FROM #tmpMatches AS tm
		INNER JOIN #tmpMatchesInfo AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;

		INSERT INTO #tmpMatchesInfo (MatchId,LiveIndicator, Bettype,BetChoiceType,TotalAmountHome,TotalAmountAway,TotalTicketHome,TotalTicketAway)
		SELECT	b.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	tmpBt.BetChoiceType
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN b.stake * b.actualrate 
						ELSE b.stake * b.actualrate END) AS TotalAmountHome
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN b.stake * b.actualrate 
						ELSE 0 END) AS TotalAmountAway
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN 1 
						ELSE 1 END) AS TotalTicketHome
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN 1 
						ELSE 0 END) AS TotalTicketAway
		FROM #tmpMatches AS tm WITH(NOLOCK)
			INNER JOIN bodb02.dbo.Bettrans14 AS b WITH(NOLOCK) ON b.MatchId = tm.matchid
			INNER JOIN #tmpBetType AS tmpBt WITH(NOLOCK) ON b.bettype = ISNULL(tmpBt.BetType,b.bettype) AND tmpBt.betID = b.betid
			INNER JOIN #tmpMarket AS tmpMk WITH(NOLOCK) ON b.liveindicator = ISNULL(tmpMk.LiveIndicator,b.LiveIndicator)
			INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.CustId = b.CustId
			INNER JOIN #tmpDanger1 AS tmpDg1 WITH(NOLOCK) ON c.Danger = ISNULL(tmpDg1.Danger1,c.Danger)
			INNER JOIN #tmpDanger2 AS tmpDg2 WITH(NOLOCK) ON c.Danger2 = ISNULL(tmpDg2.Danger2,c.Danger2)
			INNER JOIN #tmpDanger3 AS tmpDg3 WITH(NOLOCK) ON c.Danger3 = ISNULL(tmpDg3.Danger3,c.Danger3)
			INNER JOIN #tmpDanger4 AS tmpDg4 WITH(NOLOCK) ON c.Danger4 = ISNULL(tmpDg4.Danger4,c.Danger4)
			INNER JOIN #tmpDanger5 AS tmpDg5 WITH(NOLOCK) ON c.Danger5 = ISNULL(tmpDg5.Danger5,c.Danger5)
		GROUP BY b.MatchId, b.LiveIndicator, b.Bettype,tmpBt.BetChoiceType;
		
		DELETE tm
		FROM #tmpMatches AS tm
			INNER JOIN #tmpMatchesInfo AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;

		INSERT INTO #tmpMatchesInfo (MatchId,LiveIndicator, Bettype,BetChoiceType,TotalAmountHome,TotalAmountAway,TotalTicketHome,TotalTicketAway)
		SELECT	b.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	tmpBt.BetChoiceType
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN b.stake * b.actualrate 
						ELSE b.stake * b.actualrate END) AS TotalAmountHome
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN b.stake * b.actualrate 
						ELSE 0 END) AS TotalAmountAway
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceHome THEN 1 
						ELSE 1 END) AS TotalTicketHome
			,	SUM(CASE WHEN tmpBt.BetChoiceType = 2 AND b.betteam = tmpBt.BetChoiceAway THEN 1 
						ELSE 0 END) AS TotalTicketAway
		FROM #tmpMatches AS tm WITH(NOLOCK)
			INNER JOIN bodb_Archive.dbo.Bettrans_bk AS b WITH(NOLOCK) ON b.MatchId = tm.matchid
			INNER JOIN #tmpBetType AS tmpBt WITH(NOLOCK) ON b.bettype = ISNULL(tmpBt.BetType,b.bettype) AND tmpBt.betID = b.betid
			INNER JOIN #tmpMarket AS tmpMk WITH(NOLOCK) ON b.liveindicator = ISNULL(tmpMk.LiveIndicator,b.LiveIndicator)
			INNER JOIN bodb02.dbo.CustInfo AS c WITH(NOLOCK) ON c.CustId = b.CustId
			INNER JOIN #tmpDanger1 AS tmpDg1 WITH(NOLOCK) ON c.Danger = ISNULL(tmpDg1.Danger1,c.Danger)
			INNER JOIN #tmpDanger2 AS tmpDg2 WITH(NOLOCK) ON c.Danger2 = ISNULL(tmpDg2.Danger2,c.Danger2)
			INNER JOIN #tmpDanger3 AS tmpDg3 WITH(NOLOCK) ON c.Danger3 = ISNULL(tmpDg3.Danger3,c.Danger3)
			INNER JOIN #tmpDanger4 AS tmpDg4 WITH(NOLOCK) ON c.Danger4 = ISNULL(tmpDg4.Danger4,c.Danger4)
			INNER JOIN #tmpDanger5 AS tmpDg5 WITH(NOLOCK) ON c.Danger5 = ISNULL(tmpDg5.Danger5,c.Danger5)
		GROUP BY b.MatchId, b.LiveIndicator, b.Bettype,tmpBt.BetChoiceType;
	END;
	

	-- Return data
	SELECT	tmpMi.MatchId
		,	tmpMi.LiveIndicator
		,	tmpMi.Bettype
		,	tmpMi.BetChoiceType
		,	tmpMi.TotalAmountHome
		,	tmpMi.TotalAmountAway
		,	tmpMi.TotalTicketHome
		,	tmpMi.TotalTicketAway
	FROM #tmpMatchesInfo AS tmpMi WITH(NOLOCK);

	DROP TABLE #tmpMatches;
	DROP TABLE #tmpMatchesInfo;

END;

GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/