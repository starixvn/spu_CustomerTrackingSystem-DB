IF OBJECT_ID('tempdb..#TimeRange') IS NOT NULL
	DROP TABLE #TimeRange;
CREATE TABLE #TimeRange (
	FromTime DATETIME
	,ToTime DATETIME
)

IF OBJECT_ID('tempdb..#TicketForScanning') IS NOT NULL
	DROP TABLE #TicketForScanning;

CREATE TABLE #TicketForScanning (
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
	,FromTime DATETIME
	,ToTime DATETIME
	)

IF OBJECT_ID('tempdb..#TicketCountViolation') IS NOT NULL
	DROP TABLE #TicketCountViolation;

CREATE TABLE #TicketCountViolation (
	RuleId TINYINT
	,Betteam NVARCHAR(10)
	,TicketCount INT
	,IsViolateRFM BIT
	,IsViolateCC BIT
	,IsViolateBetFrom BIT
	,FromTime DATETIME
	,ToTime DATETIME
	)

IF OBJECT_ID('tempdb..#BigLeague') IS NOT NULL
	DROP TABLE #BigLeague;

CREATE TABLE #BigLeague (
	LeagueId	INT
	,Sporttype	TINYINT
	)

INSERT INTO #TimeRange (FromTime, ToTime)
SELECT FromTime, ToTime
FROM f_CTS_TWGroupBetting_GetTimeRange('2022-02-15 23:10:15.983','2022-02-16 02:15:20.983',10900)

INSERT INTO #BigLeague
SELECT leagueid
	,sporttype
FROM dbo.league WITH (NOLOCK)
WHERE sporttype = 1
	AND leagueid IN (3,4,5,43,1837)

INSERT INTO #BigLeague
SELECT leagueid
	,sporttype
FROM dbo.league WITH (NOLOCK)
WHERE sporttype = 2
	AND leagueid IN (56038,56053,95746,86331,56046,56049,78717,7391,44735,11548,63021,44721,44737,11550,81263,52821,88529,93817,102499,82879,82880,82881,101655,82883,82884,82885,82886,82783,82864,82784,101684,82786,82787,82788,82865,82789,82866,82790,101685,82792,82793,82794,82867,82795,82868,82796,101686,82798,82799,82800,82869,82801,82870,82802,101687,82804,82805,82806,82871,82807,82872,82808,101688,82810,82811,82812,82873,82757,96709,56054,56069,99367,99352,56062,99366,56065,56066,56067,56071,99232,99321,99329,99326,99327,99324,99328,99325,56027,24567,75146,48649,93818,102501,7390,7361,7363,44719,95440,104895,95441,104897,93816,102500,99520,99518,82862,82918,55716,83031,83089,83114,82779,82778,101700,101701,64977,95442,104898,95443,104899,99368,99926,82229,92117,100569,92558,99331,99970,99444,100003,100505,99438,100096,99528,95432,103857,95444,104896,95445,104900,99519)
	
INSERT INTO #TicketForScanning
SELECT transid
	,transdate
	,b.custid
	,m.leagueid
	,m.matchid
	,m.sporttype
	,bettype
	,b.currency
	,betteam
	,b.betfrom
	,b.liveindicator AS islive
	,pf.Tag AS RFM
	,ci.CustomerClass
	,gbr.ruleid
	,CASE 
		WHEN bl.LeagueId IS NOT NULL
			THEN 1
		ELSE 0
		END 'IsBigLeague'
	,tr.FromTime
	,tr.ToTime
FROM dbo.bettrans b WITH (NOLOCK)
INNER JOIN match m WITH (NOLOCK) ON b.matchid = m.matchid
INNER JOIN dbo.custinfo ci WITH (NOLOCK) ON b.custid = ci.custid
LEFT JOIN LicUserProfile pf WITH (NOLOCK) ON b.custid = pf.CustId
LEFT JOIN #BigLeague bl WITH (NOLOCK) ON m.leagueid = bl.LeagueId
CROSS APPLY [dbo].[SPU_GroupBettingRule] gbr
CROSS APPLY #TimeRange tr
WHERE b.transid > 114760099329
	AND b.refno = 100000000000
	AND b.currency <> 20
	AND m.sporttype IN (1,2)
	AND b.bettype IN (1,3,7,8,609,610)
	AND b.transdate BETWEEN tr.FromTime AND tr.ToTime
ORDER BY transid

SELECT tfs.*
INTO #SuspectTicket
FROM #TicketForScanning tfs WITH (NOLOCK)
INNER JOIN SPU_GroupBettingGroupingRule gr WITH (NOLOCK) ON tfs.RuleId = gr.RuleId
	AND tfs.IsBigLeague = gr.IsBigLeague
	AND tfs.Bettype = gr.Bettype
	AND tfs.Liveindicator = gr.IsLive
	AND tfs.Sporttype = gr.Sporttype

INSERT INTO #TicketCountViolation (
	RuleId
	,Betteam
	,TicketCount
	,FromTime
	,ToTime
	)
SELECT st.RuleId
	,st.Betteam
	,COUNT(1) 'TicketCount'
	,st.FromTime
	,st.ToTime
FROM #SuspectTicket st WITH (NOLOCK)
INNER JOIN SPU_GroupBettingRule gbr WITH (NOLOCK) ON st.RuleId = gbr.RuleId
GROUP BY st.Betteam
	,st.RuleId
	,st.FromTime
	,st.ToTime
	,gbr.TicketCountLimit
HAVING COUNT(1) > gbr.TicketCountLimit

-- Check RFM
UPDATE tcv
SET tcv.IsViolateRFM = tempTable.IsViolatedRFM
FROM #TicketCountViolation tcv
INNER JOIN (
	SELECT tcv.RuleId
		,tcv.Betteam
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
		,tcv.FromTime
		,tcv.ToTime
	FROM #SuspectTicket tfs
	INNER JOIN #TicketCountViolation tcv ON tfs.RuleId = tcv.RuleId
		AND tfs.Betteam = tcv.Betteam
	INNER JOIN dbo.SPU_GroupBettingRule gbr ON tfs.RuleId = gbr.RuleId
	WHERE tfs.RFM > gbr.RFMLimitValue
	GROUP BY tcv.RuleId
		,tcv.Betteam
		,tcv.FromTime
		,tcv.ToTime
		,tcv.TicketCount
		,gbr.RFMLimitPercent
		,tfs.RuleId
	) tempTable ON tempTable.RuleId = tcv.RuleId AND tempTable.Betteam = tcv.Betteam AND tempTable.FromTime = tcv.FromTime AND tempTable.ToTime = tcv.ToTime

-- Check CC
UPDATE tcv
SET tcv.IsViolateCC = tempTable.IsViolateCC
FROM #TicketCountViolation tcv
INNER JOIN (
	SELECT tcv.RuleId
		,tcv.Betteam
		,CASE 
			WHEN (
					tfs.RuleId IN (6,8,12,14,16)
					AND COUNT(tfs.Transid) * 100 / tcv.TicketCount >= gbr.CustClassLimitPercent
					)
				OR (
					tfs.RuleId NOT IN (6,8,12,14,16
						)
					AND COUNT(tfs.Transid) * 100 / tcv.TicketCount > gbr.CustClassLimitPercent
					)
				THEN 1
			ELSE 0
			END 'IsViolateCC'
		,tcv.FromTime
		,tcv.ToTime
	FROM #SuspectTicket tfs
	INNER JOIN #TicketCountViolation tcv ON tfs.RuleId = tcv.RuleId
		AND tfs.Betteam = tcv.Betteam
	INNER JOIN dbo.SPU_GroupBettingRule gbr ON tfs.RuleId = gbr.RuleId
	WHERE tfs.CustomerClass NOT IN (1,2)
	GROUP BY tcv.RuleId
		,tcv.Betteam
		,tcv.FromTime
		,tcv.ToTime
		,tcv.TicketCount
		,gbr.CustClassLimitPercent
		,tfs.RuleId
	) tempTable ON tempTable.RuleId = tcv.RuleId AND tempTable.Betteam = tcv.Betteam AND tempTable.FromTime = tcv.FromTime AND tempTable.ToTime = tcv.ToTime

-- Check BetFrom
UPDATE tcv
SET tcv.IsViolateBetFrom = tempTable.IsViolateBetFrom
FROM #TicketCountViolation tcv
INNER JOIN (
	SELECT tcv.RuleId
		,tcv.Betteam
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
		,tcv.FromTime
		,tcv.ToTime
	FROM #SuspectTicket tfs
	INNER JOIN #TicketCountViolation tcv ON tfs.RuleId = tcv.RuleId
		AND tfs.Betteam = tcv.Betteam
	INNER JOIN dbo.SPU_GroupBettingRule gbr ON tfs.RuleId = gbr.RuleId
	WHERE tfs.BetFrom IN ('x','z')
	GROUP BY tcv.RuleId
		,tcv.Betteam
		,tcv.FromTime
		,tcv.ToTime
		,tcv.TicketCount
		,gbr.BetFromLimitPercent
		,tfs.RuleId
	) tempTable ON tempTable.RuleId = tcv.RuleId AND tempTable.Betteam = tcv.Betteam AND tempTable.FromTime = tcv.FromTime AND tempTable.ToTime = tcv.ToTime

-- Delete existing ticket in last run
DELETE st
FROM #SuspectTicket st WITH (NOLOCK)
INNER JOIN dbo.SPU_GroupBettingTicket gbt WITH (NOLOCK) ON st.Transid = gbt.TransId

TRUNCATE TABLE dbo.SPU_GroupBettingTicket

INSERT INTO SPU_GroupBettingTicket (
	CustId
	,TransId
	)
SELECT DISTINCT st.Custid
			,st.Transid
FROM #SuspectTicket st WITH (NOLOCK)
INNER JOIN #TicketCountViolation tcv WITH (NOLOCK) ON st.RuleId = tcv.RuleId AND st.Betteam = tcv.Betteam AND st.FromTime = tcv.FromTime AND st.ToTime = tcv.ToTime
WHERE (tcv.IsViolateBetFrom = 1
	OR tcv.IsViolateRFM = 1
	OR tcv.IsViolateCC = 1)

DROP TABLE #SuspectTicket
DROP TABLE #TimeRange;
DROP TABLE #TicketForScanning;
DROP TABLE #TicketCountViolation;
DROP TABLE #BigLeague;





