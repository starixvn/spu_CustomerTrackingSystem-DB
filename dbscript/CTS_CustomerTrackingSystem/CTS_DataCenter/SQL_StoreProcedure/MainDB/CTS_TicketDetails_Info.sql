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

	Params Explaination:

	Example:
		DECLARE @MaxSequenceId BIGINT,@TotalTicketAll BIGINT,@TotalTicketLicensee BIGINT,@TotalTicketCredit BIGINT;
		EXEC [dbo].[CTS_TicketDetails_Info] 
			70095972
		,	7
		,	1
		,	@MaxSequenceId OUTPUT
		,	@TotalTicketAll OUTPUT
		,	@TotalTicketLicensee OUTPUT
		,	@TotalTicketCredit OUTPUT

		SELECT @MaxSequenceId AS MaxSequenceId,@TotalTicketAll AS TotalTicketAll,@TotalTicketLicensee AS TotalTicketLicensee,@TotalTicketCredit AS TotalTicketCredit

*/
BEGIN
	SET NOCOUNT ON;

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
		,	Hdp					SMALLMONEY
		,	IsLicensee			BIT DEFAULT NULL
		,	INDEX IX_tmpTickets_IsLicensee (IsLicensee)
	);

	IF	OBJECT_ID('tempdb..#tmpHDP') IS NOT NULL
	BEGIN
		DROP TABLE #tmpHDP;
	END;

	CREATE TABLE #tmpHDP(
			Hdp					SMALLMONEY PRIMARY KEY
		,	IsLicensee			BIT DEFAULT 0
		,	IsCredit			BIT DEFAULT 0
	);

	IF	OBJECT_ID('tempdb..#tmpScore') IS NOT NULL
	BEGIN
		DROP TABLE #tmpScore;
	END;

	CREATE TABLE #tmpScore(
			LiveHomeScore		SMALLINT
		,	LiveAwayScore		SMALLINT
		,	IsLicensee			BIT DEFAULT 0
		,	IsCredit			BIT DEFAULT 0
		,	PRIMARY KEY (LiveHomeScore,LiveAwayScore)
	);

	IF	OBJECT_ID('tempdb..#tmpCurrency') IS NOT NULL
	BEGIN
		DROP TABLE #tmpCurrency;
	END;

	CREATE TABLE #tmpCurrency(
			CurrencyId			TINYINT	PRIMARY KEY
		,	CurrencyName		NVARCHAR(100)
		,	IsLicensee			BIT DEFAULT 0
		,	IsCredit			BIT DEFAULT 0
	);

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
		,	Hdp)
	SELECT	b.SequenceId
		,	b.TransId
		,	b.custid
		,	b.Hdp1
		,	b.Hdp2
		,	b.LiveHomeScore
		,	b.LiveAwayScore
		,	b.BetTeam
		,	b.CurrencyName
		,	b.currency
		,	ABS(CASE WHEN @BetType IN (3,8,610)	THEN Hdp1
						 ELSE (CASE	WHEN b.BetTeam = 'h'	THEN (b.Hdp2 - b.Hdp1)
									WHEN b.BetTeam = 'a'	THEN (b.Hdp1 - b.Hdp2)
								END)
						 END)
	FROM dbo.bettrans AS b WITH(NOLOCK, INDEX=IX_sequenceid)
		INNER JOIN dbo.match AS m WITH(NOLOCK) ON b.matchid = m.matchid
	WHERE b.matchid = @MatchID
		AND b.bettype = @BetType
		AND b.liveindicator = @IsLive;

	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET t.IsLicensee = 1
	FROM #tmpTickets AS t
		INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN dbo.Dep_CustSuper AS cs WITH (NOLOCK) ON cs.custid = c.srecommend;

	UPDATE t WITH(ROWLOCK, UPDLOCK)
	SET t.IsLicensee = 0
	FROM #tmpTickets AS t
		INNER JOIN dbo.custInfo AS c WITH(NOLOCK) ON t.CustId = c.custid
		INNER JOIN dbo.CustProductStatus AS s WITH (NOLOCK) ON s.custid = c.custid
	WHERE t.IsLicensee IS NULL;

	INSERT INTO #tmpHDP (Hdp)
	SELECT DISTINCT Hdp
	FROM #tmpTickets;

	WITH CTE_HDP_Licensee AS
	(	SELECT DISTINCT Hdp
		FROM #tmpTickets
		WHERE IsLicensee = 1
	), CTE_HDP_Credit AS
	(	SELECT DISTINCT Hdp
		FROM #tmpTickets
		WHERE IsLicensee = 0
	)
	UPDATE t
	SET		t.IsLicensee = CASE WHEN lic.HDP IS NOT NULL THEN 1 ELSE 0 END
		,	t.IsCredit = CASE WHEN cre.HDP IS NOT NULL THEN 1 ELSE 0 END
	FROM #tmpHDP AS t
		LEFT JOIN CTE_HDP_Licensee AS lic ON t.Hdp = lic.Hdp
		LEFT JOIN CTE_HDP_Credit AS cre ON t.Hdp = cre.Hdp
	;

	IF (@IsLive = 1)
	BEGIN
		INSERT INTO #tmpScore (LiveHomeScore, LiveAwayScore)
		SELECT DISTINCT LiveHomeScore, LiveAwayScore
		FROM #tmpTickets;

		WITH CTE_Score_Licensee AS
		(
			SELECT DISTINCT LiveHomeScore, LiveAwayScore
			FROM #tmpTickets
			WHERE IsLicensee = 1
		), CTE_Score_Credit AS
		(
			SELECT DISTINCT LiveHomeScore, LiveAwayScore
			FROM #tmpTickets
			WHERE IsLicensee = 0
		)
		UPDATE t
		SET		t.IsLicensee = CASE WHEN lic.LiveHomeScore IS NOT NULL AND lic.LiveAwayScore  IS NOT NULL THEN 1 ELSE 0 END
			,	t.IsCredit = CASE WHEN cre.LiveHomeScore IS NOT NULL AND cre.LiveAwayScore  IS NOT NULL THEN 1 ELSE 0 END
		FROM #tmpScore AS t
			LEFT JOIN CTE_Score_Licensee AS lic ON t.LiveHomeScore = lic.LiveHomeScore AND t.LiveAwayScore = lic.LiveAwayScore
			LEFT JOIN CTE_Score_Credit AS cre ON t.LiveHomeScore = cre.LiveHomeScore AND t.LiveAwayScore = cre.LiveAwayScore
		;
	END;

	INSERT INTO #tmpCurrency (CurrencyId,CurrencyName)
	SELECT DISTINCT CurrencyId,CurrencyName
	FROM #tmpTickets;

	WITH CTE_Curr_Licensee AS
	(
		SELECT DISTINCT CurrencyId,CurrencyName
		FROM #tmpTickets
		WHERE IsLicensee = 1
	), CTE_Curr_Credit AS
	(
		SELECT DISTINCT CurrencyId,CurrencyName
		FROM #tmpTickets
		WHERE IsLicensee = 0
	)
	UPDATE t
	SET		t.IsLicensee = CASE WHEN lic.CurrencyId IS NOT NULL THEN 1 ELSE 0 END
		,	t.IsCredit = CASE WHEN cre.CurrencyId IS NOT NULL THEN 1 ELSE 0 END
	FROM #tmpCurrency AS t
		LEFT JOIN CTE_Curr_Licensee AS lic ON t.CurrencyId = lic.CurrencyId 
		LEFT JOIN CTE_Curr_Credit AS cre ON t.CurrencyId = cre.CurrencyId 
	;

	SELECT * FROM #tmpHDP;
	SELECT * FROM #tmpScore;
	SELECT * FROM #tmpCurrency;

	/*Return Output*/
	SELECT @MaxSequenceId = (MAX(SequenceId) + 1) FROM #tmpTickets;
	SELECT @TotalTicketAll = COUNT(1) FROM #tmpTickets;
	SELECT @TotalTicketLicensee = COUNT(1) FROM #tmpTickets WHERE IsLicensee = 1;
	SELECT @TotalTicketCredit = COUNT(1) FROM #tmpTickets  WHERE IsLicensee = 0;

	DROP TABLE IF EXISTS #tmpTickets;
	DROP TABLE IF EXISTS #tmpHDP;
	DROP TABLE IF EXISTS #tmpScore;
	DROP TABLE IF EXISTS #tmpCurrency;

END