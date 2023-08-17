/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_TicketDetails_Info]
		@MatchID					INT = 0
	,	@BetType					SMALLINT = 0
	,	@IsLive						BIT = 0
	,	@IsExclTestCurr				BIT = 0
	,	@BetID						BIGINT = 0
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
		- 20230601@Victoria.Le:			Initial Writing [Redmine ID: #185793]		
		- 20230721@Victoria.Le:			Get CurrencyName from table Exchange [Redmine ID: #191422]
		- 20230724@Victoria.Le:			Add condition BetID with BetType = Quarter X HDP/OU/MoneyLine [Redmine ID: #191703]
		- 20230724@Victoria.Le:			Bettype Selection - Return interdependence of columns  [Redmine ID: #191401]

	Params Explaination:

	Example:
		DECLARE @MaxSequenceId BIGINT,@TotalTicketAll BIGINT,@TotalTicketLicensee BIGINT,@TotalTicketCredit BIGINT;
		EXEC [dbo].[CTS_TicketDetails_Info] 
			70095972 -- @MatchID
		,	7 -- @BetType
		,	1 -- @IsLive
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

	IF	OBJECT_ID('tempdb..#tmpSupportedSportBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSupportedSportBettype;
	END;

	CREATE TABLE	#tmpSupportedSportBettype(
			SportType			SMALLINT
		,	BetType				SMALLINT
		,	IsFilterBetID		BIT
		,	IsOnlySuspicious	BIT
		,	IsFilterBetTeam		BIT
		,	IsFilterHdp			BIT
		,	IsOnlyGetHdp1		BIT
	);

	IF	OBJECT_ID('tempdb..#tmpTickets') IS NOT NULL
	BEGIN
		DROP TABLE #tmpTickets;
	END;

	CREATE TABLE #tmpTickets(
			SequenceId			BIGINT PRIMARY KEY
		,	TransId				BIGINT
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
	);

	-- Soccer
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType,IsOnlySuspicious,IsFilterBetID,IsFilterBetTeam,IsFilterHdp,IsOnlyGetHdp1)
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
	;
	-- Basketball
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType,IsOnlySuspicious,IsFilterBetID,IsFilterBetTeam,IsFilterHdp,IsOnlyGetHdp1)
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
	INSERT INTO #tmpSupportedSportBettype(SportType,BetType,IsOnlySuspicious,IsFilterBetID,IsFilterBetTeam,IsFilterHdp,IsOnlyGetHdp1)
	VALUES	(43,1,1,0,0,1,0)
			,(43,3,1,0,0,1,1)
			,(43,20,1,0,0,1,0)
	;

	INSERT INTO #tmpTickets (
		SequenceId
	,	TransId
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
	SELECT b.SequenceId
	,	b.TransId
	,	b.custid
	,	b.Hdp1
	,	b.Hdp2
	,	b.LiveHomeScore
	,	b.LiveAwayScore
	,	b.BetTeam
	,	e.currency
	,	e.ExchangeId
	,	b.bettype
	,	ABS(CASE WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 1  THEN	b.Hdp1
				 WHEN t.IsFilterHdp = 1 AND t.IsOnlyGetHdp1 = 0	 THEN  (CASE WHEN b.BetTeam = 'h'	THEN (b.Hdp2 - b.Hdp1)
																			 WHEN b.BetTeam = 'a'	THEN (b.Hdp1 - b.Hdp2) END) END)
	,	b.statusID
	FROM dbo.bettrans AS b WITH(NOLOCK)
		INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
		INNER JOIN #tmpSupportedSportBettype AS t WITH(NOLOCK) ON m.sporttype = t.SportType AND b.bettype = t.BetType
		INNER JOIN dbo.Exchange AS e WITH (NOLOCK) ON e.ExchangeId = b.currency
	WHERE b.matchid = @MatchID
		AND b.bettype = @BetType
		AND b.liveindicator = @IsLive
		AND (@IsExclTestCurr = 0 OR (@IsExclTestCurr = 1 AND b.Currency NOT IN (20,27,28)))
		AND (@BetID = 0 OR (@BetID > 0 AND t.IsFilterBetID = 1 AND b.betid = @BetID));

	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET 	t.IsLicensee = 1
		,	t.Danger1 = ISNULL(c.danger,0)
		,	t.Danger2 = ISNULL(c.danger2,0)
		,	t.Danger3 = ISNULL(c.danger3,0)
		,	t.Danger4 = ISNULL(c.Danger4,0)
		,	t.Danger5 = ISNULL(c.Danger5,0)
	FROM #tmpTickets AS t
		INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN dbo.Dep_CustSuper AS cs WITH (NOLOCK) ON cs.custid = c.srecommend;

	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET 	t.IsLicensee = 0
		,	t.Danger1 = ISNULL(c.danger,0)
		,	t.Danger2 = ISNULL(c.danger2,0)
		,	t.Danger3 = ISNULL(c.danger3,0)
		,	t.Danger4 = ISNULL(c.Danger4,0)
		,	t.Danger5 = ISNULL(c.Danger5,0)
	FROM #tmpTickets AS t
		INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN dbo.CustProductStatus AS s WITH (NOLOCK) ON s.custid = c.custid
	WHERE t.IsLicensee IS NULL;

	CREATE INDEX IX_tmpTickets_IsLicensee ON #tmpTickets (IsLicensee, LiveHomeScore, LiveAwayScore, TicketStatus, CurrencyId, CurrencyName, Hdp, BetTeam, Danger1, Danger2, Danger3, Danger4, Danger5);

	SELECT DISTINCT 
			IsLicensee, LiveHomeScore, LiveAwayScore, TicketStatus, CurrencyId, CurrencyName, Hdp, BetTeam, Danger1, Danger2, Danger3, Danger4, Danger5
	FROM #tmpTickets;

	/*Return Output*/
	SELECT @MaxSequenceId = (MAX(SequenceId) + 1) FROM #tmpTickets;
	SELECT @TotalTicketAll = COUNT(1) FROM #tmpTickets;
	SELECT @TotalTicketLicensee = COUNT(1) FROM #tmpTickets WHERE IsLicensee = 1;
	SELECT @TotalTicketCredit = COUNT(1) FROM #tmpTickets  WHERE IsLicensee = 0;

	DROP TABLE IF EXISTS #tmpSupportedSportBettype;
	DROP TABLE IF EXISTS #tmpTickets;

END