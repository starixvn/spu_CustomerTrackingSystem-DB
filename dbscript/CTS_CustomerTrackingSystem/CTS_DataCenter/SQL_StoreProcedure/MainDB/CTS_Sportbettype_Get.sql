/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_SportBettype_Get]
		@ProductId INT
	,	@SporttypeList VARCHAR(MAX) = NULL
	,	@BettypeList VARCHAR(MAX) = NULL

AS
/*
	Created: 20231226@Casey.Huynh
	Task : CTS_SportBettype_Get 
	DB	 : bodb02

	Revisions:
		- 20231226@Casey.Huynh:	Create [Redmine ID: #196361]		

	Params Explaination:		

	Example:
		EXEC CTS_SportBettype_Get @ProductID=1, @BettypeList='1,2,3,6,7,8,12,126,413,414,20,609,610,612'
		EXEC CTS_SportBettype_Get 1, null
		EXEC CTS_SportBettype_Get @ProductID=1, @BettypeList='1,2,3,6,7,8,12,126,413,414,20,609,610,612', @SporttypeList = '1,8'
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @IsFilterBettype BIT = 0;

	IF	OBJECT_ID('tempdb..#tmpBettype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpBettype;
	END;

	CREATE TABLE	#tmpBettype(
		BettypeId	INT
	);

	CREATE NONCLUSTERED INDEX #IX_tmpBettype_BettypeId ON #tmpBettype (
			BettypeId		ASC
	);

	
	IF	OBJECT_ID('tempdb..#tmpSporttype') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpSporttype;
	END;

	CREATE TABLE	#tmpSporttype(
		SporttypeId	INT
	);

	CREATE NONCLUSTERED INDEX #IX_tmpSporttype_BettypeId ON #tmpSporttype (
			SporttypeId		ASC
	);


	IF (@BettypeList IS NOT NULL)
		BEGIN
			INSERT INTO #tmpBettype (BettypeId)
			SELECT ssk.value FROM STRING_SPLIT(@BettypeList, ',') ssk;
		END
	ELSE
		BEGIN
			INSERT INTO #tmpBettype (BettypeId)
			VALUES(NULL);
		END;


	IF (@SporttypeList IS NOT NULL)
		BEGIN
			INSERT INTO #tmpSporttype (SporttypeId)
			SELECT ssk.value FROM STRING_SPLIT(@SporttypeList, ',') ssk;
		END
	ELSE
		BEGIN
			INSERT INTO #tmpSporttype(SporttypeId)
			VALUES(NULL);
		END;

	SELECT	s.SportType
		,	s.SportName
		,	b.Typeid
		,	b.Typenamee
	FROM (	SELECT DISTINCT sb.SportType, sb.BetType 
			FROM dbo.SportBettypeMatrix AS sb WITH(NOLOCK)
				INNER JOIN #tmpBettype AS tmpBt ON sb.BetType = ISNULL(tmpBt.BettypeId,sb.BetType)
				INNER JOIN #tmpSporttype AS tmpSt ON sb.SportType = ISNULL(tmpSt.SporttypeId,sb.Sporttype)
			WHERE sb.ProductID = ISNULL(sb.ProductID, @ProductID)
				AND sb.SportType NOT IN (27, 154) --Exclude Cricket and Horse Racing Fixed Odds
				AND sb.IsTest = 0
		) AS tmp
		INNER JOIN dbo.Sports AS s WITH(NOLOCK) ON tmp.SportType = s.SportType
		INNER JOIN dbo.Bettype AS b WITH(NOLOCK) ON tmp.Bettype = b.typeid
	ORDER BY s.SportType, b.Typeid;

END