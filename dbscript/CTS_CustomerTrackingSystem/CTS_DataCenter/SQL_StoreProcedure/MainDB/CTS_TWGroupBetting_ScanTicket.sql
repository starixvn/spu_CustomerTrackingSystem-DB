/*<info serverAlias="DBCTS-WASAVerse" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_ScanTicket]
		@BatchSize				INT,
		@Step					INT,
		@LastSequenceId			BIGINT,
		@LastTransSec			BIGINT,
		@SkipTransCount			INT,

		@LastSequenceId_New		BIGINT	OUTPUT,
		@LastTransSec_New		BIGINT	OUTPUT,
		@SkipTransCount_New		INT		OUTPUT
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Caculate TW Group betting %
	DB	 : DBCTS.WASAVerse

	Revisions:
		- 20220314@Harvey.Nguyen: Scan ticket								[Redmine ID: #169671]
		- 20220613@Harvey.Nguyen: Remove credit tickets						[Redmine ID: #169671]
		- 20220617@Harvey.Nguyen: Fix bug wrong inner join					[Redmine ID: #169671]
		- 20220711@Harvey.Nguyen: Change solution to scan on each ticket	[Redmine ID: #169671]
		- 20220801@Harvey.Nguyen: Enhance performance						[Redmine ID: #169671]
		- 20220831@Harvey.Nguyen: Update for Scale out DB Trans				[Redmine ID: #176472]
		- 20221122@Long.Luu:	  Exclude WC Leagues						[Redmine ID: #181229]
		- 20230417@Casey.Huynh: Change betfrom datatype	to NVARCHAR(4)		[Redmine ID: #187030]
		- 20230626@Victoria.Le: Add new columns	RulesType,IsRule1[tag by %RFM],IsRule2[tag by %CC],IsRule3[tag by %Betfrom]
																			[Redmine ID: #189505]
		- 20230719@Long.Luu:	  Addup Big Leagues for Soccer				[Redmine ID: #191399]
		- 20230811@Long.Luu:	  Addup Big Leagues for Soccer				[Redmine ID: #192614]
		- 20230829@Long.Luu:	  Addup Normal Account CC 4000				[Redmine ID: #192976]
		- 20231010@Long.Luu:	  Addup Big Leagues for Soccer				[Redmine ID: #1925163]
		- 20231030@Victoria.Le:	  New Group Betting - CC 2300 - Call SP from DW to send list fraud tickets [Redmine ID: #195060]
		- 20231123@Victoria.Le:	  Comment out the above code [Call SP from DW] and wait to update rule from BI TW team [Redmine ID: #195060]
		- 20231206@Victoria.Le:	  Remove - Comment out the above code [Call SP from DW] [Redmine ID: #197958]
		- 20240130@Victoria.Le:	  Change tables - TWGB Migrate data from bodb02 to WASAVerse [Redmine ID: #191955]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_ScanTicket] '2022-02-15 23:10:15.983','2022-02-16 02:15:20.983',10900
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @GBTicketXMLString VARCHAR(MAX)
		,	@ServerName		VARCHAR(20)
		,	@CutOffDate		DATETIME = '2022-01-01';
	
	SELECT @BatchSize += @SkipTransCount;

	IF OBJECT_ID('tempdb..#TmpRawTicket') IS NOT NULL
        DROP TABLE #TmpRawTicket;

    CREATE TABLE #TmpRawTicket (
			GroupId			INT		IDENTITY(1,1)
		,	SequenceId		BIGINT	PRIMARY KEY NONCLUSTERED
		,	Transid			BIGINT
		,	TransdateSec	INT
        ,	Custid			INT
        ,	Matchid			INT
        ,	Sporttype		SMALLINT
        ,	Bettype			SMALLINT
        ,	Betteam			NVARCHAR(10)
        ,	BetFrom			NVARCHAR(4)
        ,	Liveindicator	BIT
        ,	RFM				INT
        ,	CustomerClass	SMALLINT
        ,	IsBigLeague		BIT
		,	IsWCLeague		BIT DEFAULT 0
    );

	IF OBJECT_ID('tempdb..#TmpSuspectTicket') IS NOT NULL
		DROP TABLE #TmpSuspectTicket;

	CREATE TABLE #TmpSuspectTicket (
			Transid				BIGINT
		,	TransdateSec		INT
		,	Custid				INT
		,	Matchid				INT
		,	Sporttype			SMALLINT
		,	Bettype				SMALLINT
		,	Betteam				NVARCHAR(10)
		,	BetFrom				NVARCHAR(4)
		,	Liveindicator		BIT
		,	RFM					INT
		,	CustomerClass		SMALLINT
		,	RuleId				TINYINT
		,	IsBigLeague			BIT
		,	GroupId				INT
		,	TicketCount			INT
		,	IsViolateRFM		BIT
		,	IsViolateCC			BIT
		,	IsViolateBetFrom	BIT
	);

	IF OBJECT_ID('tempdb..#TmpBigLeague') IS NOT NULL
		DROP TABLE #TmpBigLeague;

	CREATE TABLE #TmpBigLeague (
			LeagueId	INT PRIMARY KEY
		,	Sporttype	TINYINT
	);

	INSERT INTO #TmpBigLeague (LeagueId,Sporttype)
	SELECT	*, 1 -- Soccer
	FROM (VALUES (3),(4),(5),(43),(1837),(356),(9540),(71697),(846),(27909),(57328),(99),(247),(130083),(126481)) AS X(a);

	INSERT INTO #TmpBigLeague (LeagueId,Sporttype)
	SELECT	*, 2 -- Basketball
	FROM (VALUES (56038),(56053),(95746),(86331),(56046),(56049),(78717),(7391),(44735),(11548),(63021),(44721),(44737),(11550),(81263),(52821),(88529),(93817),(102499),(82879),(82880),(82881),(101655),(82883),(82884),(82885),(82886),(82783),(82864),(82784),(101684),(82786),(82787),(82788),(82865),(82789),(82866),(82790),(101685),(82792),(82793),(82794),(82867),(82795),(82868),(82796),(101686),(82798),(82799),(82800),(82869),(82801),(82870),(82802),(101687),(82804),(82805),(82806),(82871),(82807),(82872),(82808),(101688),(82810),(82811),(82812),(82873),(82757),(96709),(56054),(56069),(99367),(99352),(56062),(99366),(56065),(56066),(56067),(56071),(99232),(99321),(99329),(99326),(99327),(99324),(99328),(99325),(56027),(24567),(75146),(48649),(93818),(102501),(7390),(7361),(7363),(44719),(95440),(104895),(95441),(104897),(93816),(102500),(99520),(99518),(82862),(82918),(55716),(83031),(83089),(83114),(82779),(82778),(101700),(101701),(64977),(95442),(104898),(95443),(104899),(99368),(99926),(82229),(92117),(100569),(92558),(99331),(99970),(99444),(100003),(100505),(99438),(100096),(99528),(95432),(103857),(95444),(104896),(95445),(104900),(99519)) AS X(a);

	IF OBJECT_ID('tempdb..#Tmp_WCLeagues') IS NOT NULL
		DROP TABLE #Tmp_WCLeagues;

	CREATE TABLE #Tmp_WCLeagues (
			LeagueId	INT PRIMARY KEY
	);

	INSERT INTO #Tmp_WCLeagues(LeagueId)
	SELECT DISTINCT LeagueId
	FROM bodb02.dbo.league WITH(NOLOCK)
	WHERE ProgramID = '2022' AND DisplayMode = 2;

	INSERT INTO #TmpRawTicket (SequenceId, Transid, TransdateSec, Custid, Matchid, Sporttype, Bettype, Betteam, BetFrom, Liveindicator, IsBigLeague, IsWCLeague, RFM)
	SELECT	TOP(@BatchSize)
				b.sequenceid
			,	b.transid
			,	DATEDIFF(SECOND, @CutOffDate, b.transdate) AS TransdateSec
			,	b.custid
			,	m.matchid
			,	m.sporttype
			,	b.bettype
			,	b.betteam
			,	b.betfrom
			,	b.liveindicator AS islive
			,	CASE 
					WHEN bl.LeagueId IS NOT NULL
						THEN 1
					ELSE 0
				END 'IsBigLeague'
			,	CASE 
					WHEN wc.LeagueId IS NOT NULL
						THEN 1
					ELSE 0
				END 'IsWCLeague'
			, pf.Tag
	FROM bodb02.dbo.bettrans AS b WITH(NOLOCK, INDEX=IX_sequenceid)
		INNER JOIN bodb02.dbo.Dep_CustSuper AS dCust WITH (NOLOCK) ON  dCust.custid = b.srecommend
		INNER JOIN bodb02.dbo.match AS m WITH (NOLOCK) ON b.matchid = m.matchid
		LEFT JOIN bodb02.dbo.LicUserProfile AS pf WITH (NOLOCK) ON b.Custid = pf.CustId
		LEFT JOIN #TmpBigLeague AS bl WITH (NOLOCK) ON m.leagueid = bl.LeagueId
		LEFT JOIN #Tmp_WCLeagues AS wc WITH(NOLOCK) ON m.leagueid = wc.LeagueId
	WHERE b.sequenceid > @LastSequenceId
		AND b.refno = 100000000000
		AND b.currency <> 20
		AND m.sporttype IN (1,2)
		AND b.bettype IN (1,3,7,8,609,610)
	ORDER BY b.sequenceid ASC;		

	CREATE CLUSTERED INDEX #CIX_TmpRawTicket_Transdate ON #TmpRawTicket (TransdateSec ASC);
	CREATE NONCLUSTERED INDEX IX_TmpRawTicket_CustID ON #TmpRawTicket (Custid ASC);
	CREATE NONCLUSTERED INDEX IX_TmpRawTicket_IsWCLeague ON #TmpRawTicket (IsWCLeague ASC);

	SET @SkipTransCount_New = 0;
	;WITH cte_stats AS (
		SELECT TOP(@Step) TransdateSec
			, COUNT(1) AS BetCount
			, MIN(SequenceId) AS MaxSequenceId
			, ROW_NUMBER() OVER (ORDER BY TransdateSec DESC) AS Rid
		FROM #TmpRawTicket
		GROUP BY TransdateSec
	)
	SELECT @LastSequenceId_New = MaxSequenceId
		, @LastTransSec_New = CASE WHEN Rid = 1 Then TransdateSec ELSE @LastTransSec_New END
		, @SkipTransCount_New += BetCount
	FROM cte_stats;

	DELETE FROM #TmpRawTicket WITH(ROWLOCK)
	WHERE IsWCLeague = 1;

	---  less rows than #TmpSuspectTicket
	UPDATE t WITH(UPDLOCK, ROWLOCK)
	SET t.CustomerClass = ci.CustomerClass
	FROM #TmpRawTicket t
	INNER JOIN bodb02.dbo.custinfo ci WITH (NOLOCK) ON ci.custid = t.Custid;

	INSERT INTO #TmpSuspectTicket (Transid, TransdateSec, Custid, Matchid, Sporttype, Bettype, Betteam, BetFrom, Liveindicator, RFM, CustomerClass, RuleId, IsBigLeague, GroupId)
    SELECT	rawTrans.Transid 
        ,	rawTrans.TransdateSec
        ,	rawTrans.Custid
        ,	rawTrans.Matchid
		,	rawTrans.Sporttype
        ,	rawTrans.Bettype
        ,	rawTrans.Betteam
        ,	rawTrans.BetFrom
        ,	rawTrans.Liveindicator
        ,	rawTrans.RFM
        ,	rawTrans.CustomerClass
        ,	gr.RuleId
        ,	rawTrans.IsBigLeague
        ,	scannedTicket.GroupId
    FROM #TmpRawTicket AS scannedTicket WITH (NOLOCK)
		INNER JOIN #TmpRawTicket AS rawTrans WITH (NOLOCK) ON scannedTicket.TransdateSec > @LastTransSec AND 
			rawTrans.TransdateSec BETWEEN scannedTicket.TransdateSec - @Step AND scannedTicket.TransdateSec
		INNER JOIN dbo.TWGroupBettingGroupingRule AS gr WITH (NOLOCK) ON rawTrans.IsBigLeague = gr.IsBigLeague
			AND rawTrans.Bettype = gr.Bettype
			AND rawTrans.Liveindicator = gr.IsLive
			AND rawTrans.Sporttype = gr.Sporttype;

	--- speed up perf index creation 
	CREATE CLUSTERED INDEX CIX_TmpSuspectTicket_TransdateSec ON #TmpSuspectTicket (TransdateSec DESC);
	CREATE NONCLUSTERED INDEX IX_SuspectTicket_RuleId ON #TmpSuspectTicket (RuleId	ASC, GroupID ASC);
	CREATE NONCLUSTERED INDEX IX_SuspectTicket_Transid ON #TmpSuspectTicket (Transid	ASC);

	;WITH cte_filtered1 AS (
		SELECT	st.RuleId
			,	st.Betteam
			,	st.Matchid
			,	st.Bettype
			,	COUNT(1) AS 'TicketCount'
			,	st.GroupId
		FROM #TmpSuspectTicket AS st WITH (NOLOCK)
			INNER JOIN dbo.TWGroupBettingRule AS gbr WITH (NOLOCK) ON st.RuleId = gbr.RuleId
		GROUP BY st.RuleId
			,	st.Betteam
			,	st.Matchid
			,	st.Bettype
			,	st.GroupId
			,	gbr.TicketCountLimit
		HAVING COUNT(1) > gbr.TicketCountLimit
	)
	UPDATE t 
	SET t.TicketCount = f.TicketCount
	FROM cte_filtered1 AS f
		INNER JOIN #TmpSuspectTicket AS t WITH(UPDLOCK, ROWLOCK) ON t.RuleId = f.RuleId AND t.GroupId = f.GroupId 
		AND t.Matchid = f.MatchId AND t.Bettype = f.Bettype	AND t.Betteam = f.Betteam 
	;

	DELETE #TmpSuspectTicket WITH(ROWLOCK)
	WHERE TicketCount IS NULL;
    
	
	-- Check BetFrom
	;WITH tempTable AS (
		SELECT	tfs.RuleId
			,	tfs.Betteam
			,	tfs.MatchId
			,	tfs.Bettype
			,	CASE 
					WHEN (
							tfs.RuleId IN (6,8,12,14,16)
							AND COUNT(tfs.Transid) * 100 / tfs.TicketCount >= gbr.BetFromLimitPercent
							)
						OR (
							tfs.RuleId NOT IN (6,8,12,14,16)
							AND COUNT(tfs.Transid) * 100 / tfs.TicketCount > gbr.BetFromLimitPercent
							)
						THEN 1
					ELSE 0
				END AS 'IsViolateBetFrom'
			,tfs.GroupId
		FROM #TmpSuspectTicket AS tfs
			INNER JOIN dbo.TWGroupBettingRule AS gbr WITH (NOLOCK) ON tfs.RuleId = gbr.RuleId
		WHERE tfs.BetFrom IN ('x','z')
		GROUP BY tfs.RuleId
			,	tfs.Betteam
			,	tfs.MatchId
			,	tfs.Bettype
			,	tfs.GroupId
			,	tfs.TicketCount
			,	gbr.BetFromLimitPercent
	)
	UPDATE tfs
	SET tfs.IsViolateBetFrom = tempTable.IsViolateBetFrom
	FROM #TmpSuspectTicket AS tfs WITH(UPDLOCK, ROWLOCK)
		INNER JOIN tempTable ON tempTable.RuleId = tfs.RuleId AND tempTable.Betteam = tfs.Betteam 
				AND tempTable.GroupId = tfs.GroupId AND tempTable.MatchId = tfs.MatchId AND tempTable.Bettype = tfs.Bettype;
	
	-- Check RFM
	;WITH tempTable AS (
		SELECT	tfs.RuleId
			,	tfs.Betteam
			,	tfs.MatchId
			,	tfs.Bettype
			,	CASE 
					WHEN (
							tfs.RuleId IN (1,2,13,15,17)
							AND COUNT(tfs.Transid) * 100 / tfs.TicketCount >= gbr.RFMLimitPercent
							)
						OR (
							tfs.RuleId NOT IN (1,2,13,15,17)
							AND COUNT(tfs.Transid) * 100 / tfs.TicketCount > gbr.RFMLimitPercent
							)
						THEN 1
					ELSE 0
				END AS 'IsViolatedRFM'
			,	tfs.GroupId
		FROM #TmpSuspectTicket AS tfs WITH(NOLOCK)
			INNER JOIN dbo.TWGroupBettingRule AS gbr WITH(NOLOCK) ON tfs.RuleId = gbr.RuleId
		WHERE tfs.RFM > gbr.RFMLimitValue
		GROUP BY tfs.RuleId
			,	tfs.Betteam
			,	tfs.MatchId
			,	tfs.Bettype
			,	tfs.GroupId
			,	tfs.TicketCount
			,	gbr.RFMLimitPercent
	)
	UPDATE tfs
	SET tfs.IsViolateRFM = tempTable.IsViolatedRFM
	FROM #TmpSuspectTicket AS tfs WITH(UPDLOCK, ROWLOCK)
		INNER JOIN tempTable ON tempTable.RuleId = tfs.RuleId AND tempTable.Betteam = tfs.Betteam AND tempTable.GroupId = tfs.GroupId 
			AND tempTable.MatchId = tfs.MatchId AND tempTable.Bettype = tfs.Bettype;

	-- Check CC
	;WITH tempTable AS (
		SELECT	tfs.RuleId
			,	tfs.Betteam
			,	tfs.MatchId
			,	tfs.Bettype
			,	CASE 
					WHEN (
							tfs.RuleId IN (6,8,12,14,16)
							AND COUNT(tfs.Transid) * 100 / tfs.TicketCount >= gbr.CustClassLimitPercent
							)
						OR (
							tfs.RuleId NOT IN (6,8,12,14,16)
							AND COUNT(tfs.Transid) * 100 / tfs.TicketCount > gbr.CustClassLimitPercent
							)
						THEN 1
					ELSE 0
				END 'IsViolateCC'
			,	tfs.GroupId
		FROM #TmpSuspectTicket AS tfs WITH(NOLOCK)
			INNER JOIN dbo.TWGroupBettingRule AS gbr WITH (NOLOCK) ON tfs.RuleId = gbr.RuleId
		WHERE tfs.CustomerClass NOT IN (201,2101,2201,2001,202,2102,2202,2002,4000)
		GROUP BY tfs.RuleId
			,	tfs.Betteam
			,	tfs.MatchId
			,	tfs.Bettype
			,	tfs.GroupId
			,	tfs.TicketCount
			,	gbr.CustClassLimitPercent
	)
	UPDATE tfs
	SET tfs.IsViolateCC = tempTable.IsViolateCC
	FROM #TmpSuspectTicket AS tfs WITH(UPDLOCK, ROWLOCK)
		INNER JOIN tempTable ON tempTable.RuleId = tfs.RuleId AND tempTable.Betteam = tfs.Betteam 
			AND tempTable.GroupId = tfs.GroupId AND tempTable.MatchId = tfs.MatchId AND tempTable.Bettype = tfs.Bettype;

	-- Delete existing ticket in dbo.TWGroupBettingTicket
	DELETE st WITH(ROWLOCK)
	FROM #TmpSuspectTicket AS st
	INNER JOIN dbo.TWGroupBettingTicket gbt WITH (NOLOCK) ON st.Transid = gbt.TransId;
								
	WITH CTE_1 AS
	(
		SELECT 	tfs.Custid AS 'CustId'
			,	tfs.Transid AS 'TransId'
			,	CONVERT(DATE, DATEADD(SECOND, tfs.TransdateSec, @CutOffDate)) AS 'TransDate'
			,	RuleId AS 'RuleId'
			,	IsViolateRFM AS 'IsViolateRFM'
			,	IsViolateCC AS 'IsViolateCC'
			,	IsViolateBetFrom AS 'IsViolateBetFrom'
			,	(ISNULL(CONVERT(SMALLINT,IsViolateRFM),0) + ISNULL(CONVERT(SMALLINT,IsViolateCC),0) + ISNULL(CONVERT(SMALLINT,IsViolateBetFrom),0)) AS 'SumIsViolate'
		FROM #TmpSuspectTicket AS tfs WITH (NOLOCK)
		WHERE (tfs.IsViolateBetFrom = 1 OR tfs.IsViolateRFM = 1 OR tfs.IsViolateCC = 1)
				
	), CTE_2 AS
	(
		SELECT 	CustId,TransId,TransDate,RuleId,IsViolateRFM,IsViolateCC,IsViolateBetFrom
			,	ROW_NUMBER() OVER (PARTITION BY CustId,TransId,TransDate,RuleId ORDER BY SumIsViolate DESC) AS RN
		FROM CTE_1
	)
	SELECT @GBTicketXMLString = (SELECT CustId,TransId,TransDate,RuleId,IsViolateRFM,IsViolateCC,IsViolateBetFrom
								 FROM CTE_2
								 WHERE RN = 1
								 FOR XML RAW('TWGroupBettingTicket'), ROOT);

	EXEC dbo.CTS_TWGroupBetting_SyncDataGroupBettingTicket @GBTicketXMLString, @LastSequenceId_New;		

	-- EXEC DBVR2.bodb_VR2Model.dbo.CTS_TWGB_UpdateDWData @GBTicketXMLString;		


	DROP TABLE #TmpSuspectTicket
	DROP TABLE #TmpBigLeague;
END;