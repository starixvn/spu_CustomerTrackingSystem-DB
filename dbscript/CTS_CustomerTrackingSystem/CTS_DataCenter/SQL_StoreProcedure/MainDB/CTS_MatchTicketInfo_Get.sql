/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
USE [bodb02]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_MatchTicketInfo_Get]
		@MatchIds			VARCHAR(MAX) = ''
	,	@MarketList			VARCHAR(10)  = ''
	,	@BettypeList		VARCHAR(MAX) = '[]' --JSON
	,	@DangerList			VARCHAR(MAX) = '[]' --JSON
	
	
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
						,	{"BetType":610, "BetChoiceType":2, "BetChoiceHome":"o", "BetChoiceAway":"u", "BetID":801}
						,	{"BetType":126, "BetChoiceType":1}]'
		,	@DangerList =  '[{"Danger1":0},{"Danger1":10},{"Danger3":10},{"Danger4":45},{"Danger5":1},{"Danger5":5}]'
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

	--==================================================================================================
	IF	OBJECT_ID('tempdb..#tmpMatchesInfo') IS NOT NULL
	BEGIN
		DROP TABLE #tmpMatchesInfo;
	END;

	CREATE TABLE #tmpMatchesInfo (
			MatchId			INT NOT NULL
		,	LiveIndicator	BIT
		,	Bettype			INT NOT NULL
		,	BetID			BIGINT
		,	BetChoiceType	TINYINT
		,	TotalAmountHome DECIMAL(20,4) -- IF BetChoiceType = 1  then TOTAL ALL
		,	TotalAmountAway DECIMAL(20,4)  -- IF BetChoiceType = 1 then 0
		,	TotalTicketHome INT -- IF BetChoiceType = 1  then TOTAL ALL
		,	TotalTicketAway INT  -- IF BetChoiceType = 1 then 0
	);

	CREATE CLUSTERED INDEX #CIX_tmpMatchesInfo_MatchIdBettype ON #tmpMatchesInfo (
			MatchId	ASC
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
	IF @MatchIds <> '' --GET Match Info By List MatchID
	BEGIN

		INSERT INTO #tmpMatches (MatchId)
		SELECT ssk.value FROM STRING_SPLIT (@MatchIds, ',') ssk;
		
		INSERT INTO #tmpMatchesInfo (MatchId,LiveIndicator, Bettype, BetID, BetChoiceType,TotalAmountHome,TotalAmountAway,TotalTicketHome,TotalTicketAway)
		SELECT	b.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	ISNULL(tmpBt.BetID,0)
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
		WHERE EXISTS (	SELECT 1 
						FROM  #tmpDanger AS tmpDg WITH(NOLOCK) 
						WHERE  c.Danger = ISNULL(tmpDg.Danger1,c.Danger)
								AND c.Danger2 = ISNULL(tmpDg.Danger2,c.Danger)
								AND c.Danger3 = ISNULL(tmpDg.Danger3,c.Danger)
								AND c.Danger4 = ISNULL(tmpDg.Danger4,c.Danger)
								AND c.Danger5 = ISNULL(tmpDg.Danger5,c.Danger))
		GROUP BY b.MatchId, b.LiveIndicator, b.Bettype, tmpBt.BetID, tmpBt.BetChoiceType;

		DELETE tm
		FROM #tmpMatches AS tm
		INNER JOIN #tmpMatchesInfo AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;

		INSERT INTO #tmpMatchesInfo (MatchId,LiveIndicator, Bettype, BetID, BetChoiceType,TotalAmountHome,TotalAmountAway,TotalTicketHome,TotalTicketAway)
		SELECT	b.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	ISNULL(tmpBt.BetID,0)
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
		WHERE EXISTS (	SELECT 1 
						FROM  #tmpDanger AS tmpDg WITH(NOLOCK) 
						WHERE  c.Danger = ISNULL(tmpDg.Danger1,c.Danger)
								AND c.Danger2 = ISNULL(tmpDg.Danger2,c.Danger)
								AND c.Danger3 = ISNULL(tmpDg.Danger3,c.Danger)
								AND c.Danger4 = ISNULL(tmpDg.Danger4,c.Danger)
								AND c.Danger5 = ISNULL(tmpDg.Danger5,c.Danger))
		GROUP BY b.MatchId, b.LiveIndicator, b.Bettype, tmpBt.BetID, tmpBt.BetChoiceType;
		
		DELETE tm
		FROM #tmpMatches AS tm
			INNER JOIN #tmpMatchesInfo AS m WITH(NOLOCK) ON tm.MatchId = m.matchid;
		
		INSERT INTO #tmpMatchesInfo (MatchId,LiveIndicator, Bettype, BetID, BetChoiceType,TotalAmountHome,TotalAmountAway,TotalTicketHome,TotalTicketAway)
		SELECT	b.MatchId
			,	b.LiveIndicator
			,	b.Bettype
			,	ISNULL(tmpBt.BetID,0)
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

END;

GO
/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/