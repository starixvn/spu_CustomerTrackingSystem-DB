    select 
        transid,
        transdate ,
        ip,
        D.site,
        b.custid,
        m.leagueid,
        m.matchid,
        m.sporttype,
        bettype,
        b.currency,
        betteam,
        betfrom,
        b.liveindicator as islive,
        b.livehomescore as homescore,
        b.liveawayscore as awayscore,
        pf.Tag as RFM,
        ci.CustomerClass,
        ci.username as  ibcusername
    from dbo.bettrans b with (nolock) 
    inner join match m with (nolock) on b.matchid=m.matchid
    inner join dbo.custinfo ci with(nolock) on b.custid = ci.custid
    inner join Dep_CustSuper D with(nolock) on b.srecommend = d.custid
    left join LicUserProfile pf with(nolock) on b.custid = pf.CustId
    where 
        b.transid > 114760099329
        and b.refno = 100000000000 
        and b.currency <> 20 
        and m.sporttype in (1,2) 
        and b.bettype in (1,3,7,8,609,610) 
		and b.betfrom in ('x','z')
        and b.transdate between '2022-02-15 02:15:15.983' and  '2022-02-16 02:17:39.587'
    order by transid 

--select *
--from f_CTS_TWGroupBetting_GetTimeRange('2022-03-08 02:21:49.120','2022-03-08 03:21:49.120',5)