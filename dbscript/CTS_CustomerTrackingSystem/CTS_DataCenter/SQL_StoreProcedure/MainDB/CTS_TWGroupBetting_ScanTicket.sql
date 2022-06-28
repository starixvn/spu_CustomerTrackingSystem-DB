/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[CTS_TWGroupBetting_ScanTicket]
		@BatchSize		INT,
		@Step			INT,
		@LastTransID	BIGINT,
		@MaxTransID		BIGINT OUTPUT
AS
/*
	Created: 20220314@Harvey.Nguyen
	Task : Caculate TW Group betting %
	DB	 : DBCTS.bodb02

	Revisions:
		- 20220314@Harvey.Nguyen: Scan ticket				[Redmine ID: #169671]
		- 20220613@Harvey.Nguyen: Remove credit tickets		[Redmine ID: #169671]
		- 20220617@Harvey.Nguyen: Fix bug wrong inner join	[Redmine ID: #169671]

	Params Explaination:
		EXECUTE [dbo].[CTS_TWGroupBetting_ScanTicket] '2022-02-15 23:10:15.983','2022-02-16 02:15:20.983',10900
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @GBTicketXMLString VARCHAR(MAX)
		,	@FromTime		DATETIME
		,	@ToTime			DATETIME
		,	@ServerName	VARCHAR(20);

	SET @ServerName = @@SERVERNAME;

	IF OBJECT_ID('tempdb..#TmpTicketForScanning') IS NOT NULL
		DROP TABLE #TmpTicketForScanning;

	CREATE TABLE #TmpTicketForScanning (
		Transid BIGINT
		,Transdate DATETIME
		,Custid INT
		,Leagueid INT
		,Matchid INT
		,Sporttype SMALLINT
		,Bettype SMALLINT
		,Currency TINYINT
		,Betteam NVARCHAR(10)
		,BetFrom NVARCHAR(1)
		,Liveindicator BIT
		,RFM INT
		,CustomerClass SMALLINT
		,RuleId TINYINT
		,IsBigLeague BIT
		,GroupId INT
		);

	CREATE INDEX IX_TicketForScanning_Transid
		ON #TmpTicketForScanning (Transid);

	IF OBJECT_ID('tempdb..#TmpSuspectTicket') IS NOT NULL
		DROP TABLE #TmpSuspectTicket;

	CREATE TABLE #TmpSuspectTicket (
		Transid BIGINT 
		,Transdate DATETIME
		,Custid INT
		,Leagueid INT
		,Matchid INT
		,Sporttype SMALLINT
		,Bettype SMALLINT
		,Currency TINYINT
		,Betteam NVARCHAR(10)
		,BetFrom NVARCHAR(1)
		,Liveindicator BIT
		,RFM INT
		,CustomerClass SMALLINT
		,RuleId TINYINT
		,IsBigLeague BIT
		,GroupId INT
		);

	CREATE INDEX IX_TmpSuspectTicket_Transid
		ON #TmpSuspectTicket (Transid);

	CREATE NONCLUSTERED INDEX #IX_SuspectTicket_RuleId ON #TmpSuspectTicket (
			RuleId		ASC
	);

	IF OBJECT_ID('tempdb..#TmpTicketCountViolation') IS NOT NULL
		DROP TABLE #TmpTicketCountViolation;

	CREATE TABLE #TmpTicketCountViolation (
		RuleId TINYINT
		,Betteam NVARCHAR(10)
		,MatchId INT
		,TicketCount INT
		,IsViolateRFM BIT
		,IsViolateCC BIT
		,IsViolateBetFrom BIT
		,GroupId INT
		);

	IF OBJECT_ID('tempdb..#TmpBigLeague') IS NOT NULL
		DROP TABLE #TmpBigLeague;

	CREATE TABLE #TmpBigLeague (
		LeagueId	INT
		,Sporttype	TINYINT
		);

	IF OBJECT_ID('tempdb..#TempTrans') IS NOT NULL
	DROP TABLE #TempTrans;

	CREATE TABLE #TempTrans (
		GroupId		INT
		,TransId	BIGINT
		,Transdate	DATETIME
		)

	INSERT INTO #TempTrans
	SELECT TOP (@BatchSize) ROW_NUMBER() OVER (ORDER BY b.transid ASC)
		,b.transid
		,b.transdate
	FROM bettrans AS b WITH (NOLOCK)
	INNER JOIN match AS m WITH (NOLOCK) ON b.matchid = m.matchid
	INNER JOIN Dep_CustSuper AS dCust WITH (NOLOCK) ON  dCust.custid = b.srecommend
	WHERE b.transid > @LastTransID
			AND b.refno = 100000000000
			AND b.currency <> 20
			AND m.sporttype IN (1,2)
			AND b.bettype IN (1,3,7,8,609,610)
	ORDER BY b.transid ASC;

	SELECT @FromTime = DATEADD(MINUTE, -1, MIN(transdate))
	FROM #TempTrans;

	SELECT @ToTime = DATEADD(MINUTE, 1, MAX(transdate))
	FROM #TempTrans;

	INSERT INTO #TmpBigLeague
	SELECT leagueid
		,sporttype
	FROM dbo.league WITH (NOLOCK)
	WHERE sporttype = 1
		AND leagueid IN (3,4,5,43,1837);

	INSERT INTO #TmpBigLeague
	SELECT leagueid
		,sporttype
	FROM dbo.league WITH (NOLOCK)
	WHERE sporttype = 2
		AND leagueid IN (56038,56053,95746,86331,56046,56049,78717,7391,44735,11548,63021,44721,44737,11550,81263,52821,88529,93817,102499,82879,82880,82881,101655,82883,82884,82885,82886,82783,82864,82784,101684,82786,82787,82788,82865,82789,82866,82790,101685,82792,82793,82794,82867,82795,82868,82796,101686,82798,82799,82800,82869,82801,82870,82802,101687,82804,82805,82806,82871,82807,82872,82808,101688,82810,82811,82812,82873,82757,96709,56054,56069,99367,99352,56062,99366,56065,56066,56067,56071,99232,99321,99329,99326,99327,99324,99328,99325,56027,24567,75146,48649,93818,102501,7390,7361,7363,44719,95440,104895,95441,104897,93816,102500,99520,99518,82862,82918,55716,83031,83089,83114,82779,82778,101700,101701,64977,95442,104898,95443,104899,99368,99926,82229,92117,100569,92558,99331,99970,99444,100003,100505,99438,100096,99528,95432,103857,95444,104896,95445,104900,99519);

	;WITH cte_raw AS (
		SELECT b.transid
			,b.transdate
			,b.custid
			,m.leagueid
			,m.matchid
			,m.sporttype
			,b.bettype
			,b.currency
			,b.betteam
			,b.betfrom
			,b.liveindicator AS islive
			,pf.Tag AS RFM
			,ci.CustomerClass
			,CASE 
				WHEN bl.LeagueId IS NOT NULL
					THEN 1
				ELSE 0
				END 'IsBigLeague'
		FROM dbo.bettrans AS b WITH (NOLOCK)
		INNER JOIN Dep_CustSuper AS dCust WITH (NOLOCK) ON  dCust.custid = b.srecommend
		INNER JOIN match AS m WITH (NOLOCK) ON b.matchid = m.matchid
		INNER JOIN dbo.custinfo AS ci WITH (NOLOCK) ON b.custid = ci.custid
		LEFT JOIN LicUserProfile AS pf WITH (NOLOCK) ON b.custid = pf.CustId
		LEFT JOIN #TmpBigLeague AS bl WITH (NOLOCK) ON m.leagueid = bl.LeagueId
		WHERE b.transid > @LastTransID
			AND b.refno = 100000000000
			AND b.currency <> 20
			AND m.sporttype IN (1,2)
			AND b.bettype IN (1,3,7,8,609,610)
			AND b.transdate BETWEEN @FromTime AND @ToTime
	)
	INSERT INTO #TmpTicketForScanning
	SELECT b.transid
		,b.transdate
		,b.custid
		,b.leagueid
		,b.matchid
		,b.sporttype
		,b.bettype
		,b.currency
		,b.betteam
		,b.betfrom
		,b.islive
		,b.RFM
		,b.CustomerClass
		,gbr.ruleid
		,b.IsBigLeague
		,trans.GroupId
	FROM cte_raw AS b
	INNER JOIN #TempTrans trans ON b.transdate BETWEEN DATEADD(SECOND,-@Step,trans.Transdate) AND trans.Transdate
	CROSS APPLY [dbo].[SPU_GroupBettingRule] AS gbr
	ORDER BY b.transid ASC;
                                  
	SELECT @MaxTransID = MAX(Transid)
	FROM #TempTrans;
	
	INSERT INTO #TmpSuspectTicket
	SELECT tfs.*
	FROM #TmpTicketForScanning AS tfs WITH (NOLOCK)
	INNER JOIN SPU_GroupBettingGroupingRule AS gr WITH (NOLOCK) ON tfs.RuleId = gr.RuleId
		AND tfs.IsBigLeague = gr.IsBigLeague
		AND tfs.Bettype = gr.Bettype
		AND tfs.Liveindicator = gr.IsLive
		AND tfs.Sporttype = gr.Sporttype;
                                        
	INSERT INTO #TmpTicketCountViolation (
		RuleId
		,Betteam
		,Matchid
		,TicketCount
		,GroupId
		)
	SELECT st.RuleId
		,st.Betteam
		,st.Matchid
		,COUNT(1) 'TicketCount'
		,st.GroupId
	FROM #TmpSuspectTicket AS st WITH (NOLOCK)
	INNER JOIN SPU_GroupBettingRule AS gbr WITH (NOLOCK) ON st.RuleId = gbr.RuleId
	GROUP BY st.Betteam
		,st.Matchid
		,st.RuleId
		,st.GroupId
		,gbr.TicketCountLimit
	HAVING COUNT(1) > gbr.TicketCountLimit;

	-- Check RFM
	UPDATE tcv
	SET tcv.IsViolateRFM = tempTable.IsViolatedRFM
	FROM #TmpTicketCountViolation tcv
	INNER JOIN (
		SELECT tcv.RuleId
			,tcv.Betteam
			,tcv.MatchId
			,CASE 
				WHEN (
						tfs.RuleId IN (1,2,13,15,17)
						AND COUNT(tfs.Transid) * 100 / tcv.TicketCount >= gbr.RFMLimitPercent
						)
					OR (
						tfs.RuleId NOT IN (1,2,13,15,17)
						AND COUNT(tfs.Transid) * 100 / tcv.TicketCount > gbr.RFMLimitPercent
						)
					THEN 1
				ELSE 0
				END 'IsViolatedRFM'
			,tcv.GroupId
		FROM #TmpSuspectTicket tfs
		INNER JOIN #TmpTicketCountViolation AS tcv ON tfs.RuleId = tcv.RuleId AND tfs.Matchid= tcv.MatchId
			AND tfs.Betteam = tcv.Betteam AND tfs.GroupId = tcv.GroupId
		INNER JOIN dbo.SPU_GroupBettingRule AS gbr ON tfs.RuleId = gbr.RuleId
		WHERE tfs.RFM > gbr.RFMLimitValue
		GROUP BY tcv.RuleId
			,tcv.Betteam
			,tcv.MatchId
			,tcv.GroupId
			,tcv.TicketCount
			,gbr.RFMLimitPercent
			,tfs.RuleId
		) tempTable ON tempTable.RuleId = tcv.RuleId AND tempTable.Betteam = tcv.Betteam AND tempTable.GroupId = tcv.GroupId AND tempTable.MatchId = tcv.MatchId ;

	-- Check CC
	UPDATE tcv
	SET tcv.IsViolateCC = tempTable.IsViolateCC
	FROM #TmpTicketCountViolation tcv
	INNER JOIN (
		SELECT tcv.RuleId
			,tcv.Betteam
			,tcv.MatchId
			,CASE 
				WHEN (
						tfs.RuleId IN (6,8,12,14,16)
						AND COUNT(tfs.Transid) * 100 / tcv.TicketCount >= gbr.CustClassLimitPercent
						)
					OR (
						tfs.RuleId NOT IN (6,8,12,14,16)
						AND COUNT(tfs.Transid) * 100 / tcv.TicketCount > gbr.CustClassLimitPercent
						)
					THEN 1
				ELSE 0
				END 'IsViolateCC'
			,tcv.GroupId
		FROM #TmpSuspectTicket AS tfs
		INNER JOIN #TmpTicketCountViolation AS tcv ON tfs.RuleId = tcv.RuleId AND tfs.Matchid= tcv.MatchId
			AND tfs.Betteam = tcv.Betteam AND tfs.GroupId = tcv.GroupId
		INNER JOIN dbo.SPU_GroupBettingRule AS gbr ON tfs.RuleId = gbr.RuleId
		WHERE tfs.CustomerClass NOT IN (1,2)
		GROUP BY tcv.RuleId
			,tcv.Betteam
			,tcv.MatchId
			,tcv.GroupId
			,tcv.TicketCount
			,gbr.CustClassLimitPercent
			,tfs.RuleId
		) tempTable ON tempTable.RuleId = tcv.RuleId AND tempTable.Betteam = tcv.Betteam AND tempTable.GroupId = tcv.GroupId AND tempTable.MatchId = tcv.MatchId;

	-- Check BetFrom
	UPDATE tcv
	SET tcv.IsViolateBetFrom = tempTable.IsViolateBetFrom
	FROM #TmpTicketCountViolation tcv
	INNER JOIN (
		SELECT tcv.RuleId
			,tcv.Betteam
			,tcv.MatchId
			,CASE 
				WHEN (
						tfs.RuleId IN (6,8,12,14,16)
						AND COUNT(tfs.Transid) * 100 / tcv.TicketCount >= gbr.BetFromLimitPercent
						)
					OR (
						tfs.RuleId NOT IN (6,8,12,14,16)
						AND COUNT(tfs.Transid) * 100 / tcv.TicketCount > gbr.BetFromLimitPercent
						)
					THEN 1
				ELSE 0
				END 'IsViolateBetFrom'
			,tcv.GroupId
		FROM #TmpSuspectTicket AS tfs
		INNER JOIN #TmpTicketCountViolation AS tcv ON tfs.RuleId = tcv.RuleId AND tfs.Matchid= tcv.MatchId
			AND tfs.Betteam = tcv.Betteam AND tfs.GroupId = tcv.GroupId
		INNER JOIN dbo.SPU_GroupBettingRule AS gbr ON tfs.RuleId = gbr.RuleId
		WHERE tfs.BetFrom IN ('x','z')
		GROUP BY tcv.RuleId
			,tcv.Betteam
			,tcv.MatchId
			,tcv.GroupId
			,tcv.TicketCount
			,gbr.BetFromLimitPercent
			,tfs.RuleId
		) tempTable ON tempTable.RuleId = tcv.RuleId AND tempTable.Betteam = tcv.Betteam AND tempTable.GroupId = tcv.GroupId AND tempTable.MatchId = tcv.MatchId;

	-- Delete existing ticket in last run
	DELETE st
	FROM #TmpSuspectTicket AS st
	INNER JOIN dbo.SPU_GroupBettingTicket gbt WITH (NOLOCK) ON st.Transid = gbt.TransId;

	SET @GBTicketXMLString = (SELECT DISTINCT st.Custid AS 'CustId'
												,st.Transid AS 'TransId'
												,CONVERT(DATE,st.Transdate) AS 'TransDate'
									FROM #TmpSuspectTicket st WITH (NOLOCK)
									INNER JOIN #TmpTicketCountViolation AS tcv WITH (NOLOCK) ON st.RuleId = tcv.RuleId AND st.Betteam = tcv.Betteam AND st.GroupId = tcv.GroupId
									WHERE (tcv.IsViolateBetFrom = 1
										OR tcv.IsViolateRFM = 1
										OR tcv.IsViolateCC = 1)
									FOR XML RAW('TWGroupBettingTicket'), ROOT);

	EXEC CTS_TWGroupBetting_SyncDataGroupBettingTicket @GBTicketXMLString;		

	IF @ServerName = 'DB061'
	BEGIN
		EXEC DB06.bodb02.dbo.CTS_TWGroupBetting_SyncDataGroupBettingTicket @GBTicketXMLString;		
	END
	ELSE IF @ServerName = 'DB062'
	BEGIN 
		EXEC DB061.bodb02.dbo.CTS_TWGroupBetting_SyncDataGroupBettingTicket @GBTicketXMLString;
	END

	DROP TABLE #TmpSuspectTicket
	DROP TABLE #TempTrans;
	DROP TABLE #TmpTicketForScanning;
	DROP TABLE #TmpTicketCountViolation;
	DROP TABLE #TmpBigLeague;
END
