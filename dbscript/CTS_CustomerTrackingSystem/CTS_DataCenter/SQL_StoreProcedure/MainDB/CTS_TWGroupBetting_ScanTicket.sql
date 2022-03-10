IF	OBJECT_ID('tempdb..#TicketForScanning') IS NOT NULL
	DROP TABLE	#TicketForScanning;
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
	,Liveindicator BIT
	,RFM INT
	,CustomerClass SMALLINT
	,RuleId	TINYINT
	,IsBigLeague BIT
	)

IF	OBJECT_ID('tempdb..#TicketCountViolation') IS NOT NULL
	DROP TABLE #TicketCountViolation;
CREATE TABLE #TicketCountViolation (
	RuleId TINYINT
	,Betteam NVARCHAR(10)
	,TicketCount INT
	,TicketCountLimit TINYINT
	)

IF	OBJECT_ID('tempdb..#BigLeague') IS NOT NULL
	DROP TABLE #BigLeague;
CREATE TABLE #BigLeague(
	LeagueId	INT,
	Sporttype	TINYINT
)

insert into #BigLeague
select leagueid, sporttype from dbo.league with (nolock)
where sporttype = 1 and leagueid in (3,4,5,43,1837)

insert into #BigLeague
select leagueid, sporttype from dbo.league with (nolock)
where sporttype = 2 and leagueid in (56038,56053,95746,86331,56046,56049,78717,7391,44735,11548,63021,44721,44737,11550,81263,52821,88529,93817,102499,82879,82880,82881,101655,82883,82884,82885,82886,82783,82864,82784,101684,82786,82787,82788,82865,82789,82866,82790,101685,82792,82793,82794,82867,82795,82868,82796,101686,82798,82799,82800,82869,82801,82870,82802,101687,82804,82805,82806,82871,82807,82872,82808,101688,82810,82811,82812,82873,82757,96709,56054,56069,99367,99352,56062,99366,56065,56066,56067,56071,99232,99321,99329,99326,99327,99324,99328,99325,56027,24567,75146,48649,93818,102501,7390,7361,7363,44719,95440,104895,95441,104897,93816,102500,99520,99518,82862,82918,55716,83031,83089,83114,82779,82778,101700,101701,64977,95442,104898,95443,104899,99368,99926,82229,92117,100569,92558,99331,99970,99444,100003,100505,99438,100096,99528,95432,103857,95444,104896,95445,104900,99519)


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
	,b.liveindicator AS islive
	,pf.Tag AS RFM
	,ci.CustomerClass
	,gbr.ruleid
	,CASE WHEN bl.LeagueId IS NOT NULL THEN 1 ELSE 0 END 'IsBigLeague'
FROM dbo.bettrans b WITH (NOLOCK)
INNER JOIN match m WITH (NOLOCK) ON b.matchid = m.matchid
INNER JOIN dbo.custinfo ci WITH (NOLOCK) ON b.custid = ci.custid
LEFT JOIN LicUserProfile pf WITH (NOLOCK) ON b.custid = pf.CustId
LEFT JOIN #BigLeague bl WITH (NOLOCK) ON m.leagueid = bl.LeagueId
CROSS APPLY [dbo].[SPU_GroupBettingRule] gbr
WHERE b.transid > 114760099329
	AND b.refno = 100000000000
	AND b.currency <> 20
	AND m.sporttype IN (1,2)
	AND b.bettype IN (1,3,7,8,609,610)
	AND b.betfrom IN ('x','z')
	AND b.transdate BETWEEN '2022-02-15 02:15:15.983' AND '2022-02-16 02:17:39.587'
ORDER BY transid

SELECT tfs.*
INTO #SuspectTicket
FROM #TicketForScanning tfs
INNER JOIN SPU_GroupBettingGroupingRule gr ON tfs.RuleId = gr.RuleId --AND tfs.RuleId = 1
	AND tfs.IsBigLeague = gr.IsBigLeague
	AND tfs.Bettype = gr.Bettype
	AND tfs.Liveindicator = gr.IsLive
	AND tfs.Sporttype = gr.Sporttype

INSERT INTO #TicketCountViolation
SELECT st.RuleId
	,st.Betteam
	,count(1) 'TicketCount'
	,gbr.TicketCountLimit
FROM #SuspectTicket st
INNER JOIN SPU_GroupBettingRule gbr ON st.RuleId = gbr.RuleId
GROUP BY st.Betteam
	,st.RuleId
	,gbr.TicketCountLimit
HAVING count(1) > gbr.TicketCountLimit

-------- DEV----------

select tcv.RuleId,tcv.Betteam,tcv.TicketCount,COUNT(tfs.Transid) 'ViolatedTicket', COUNT(tfs.Transid)*100/tcv.TicketCount 'Percent'
from #SuspectTicket tfs 
inner join #TicketCountViolation tcv on tfs.RuleId = tcv.RuleId and tfs.Betteam = tcv.Betteam
inner join dbo.SPU_GroupBettingRule gbr on tfs.RuleId = gbr.RuleId 
--where tfs.RFM > gbr.RFMLimitValue
group by tcv.RuleId,tcv.Betteam,tcv.TicketCount, gbr.RFMLimitPercent
having COUNT(tfs.Transid)*100/tcv.TicketCount > gbr.RFMLimitPercent

select * from #TicketCountViolation
select * from #TicketForScanning

DROP TABLE #SuspectTicket
/*
select *
from f_CTS_TWGroupBetting_GetTimeRange('2022-03-08 02:21:49.120','2022-03-08 03:21:49.120',5)
*/
