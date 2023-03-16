/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
	Creator:	20230310@victoria.le
	Task:	 	Scale out - Split 789y Site

	 Revisions:
		- 20230310@Victoria.le: 	STEP 3: GET List CustID and Site [Redmine ID: #183140]
								
*/

/**************************
PART 1: Customer - Headline
***************************/
IF	OBJECT_ID('tempdb..#Cust_Headline') IS NOT NULL
	DROP TABLE	#Cust_Headline;

CREATE TABLE #Cust_Headline (
		custid			INT 
	,	roleid			TINYINT
	,	headline		VARCHAR(100)
	,	newSite			VARCHAR(50)
	,	isfinished		BIT DEFAULT(0))

IF	OBJECT_ID('tempdb..#tblCust_Super') IS NOT NULL
	DROP TABLE	#tblCust_Super

CREATE TABLE #tblCust_Super (
		custid			INT PRIMARY KEY
	,	roleid			TINYINT
	,	oldSite			VARCHAR(10)
	,	isDummy			BIT DEFAULT(0)
	,	newSite			VARCHAR(50)
)

IF	OBJECT_ID('tempdb..#tblCust_Master') IS NOT NULL
	DROP TABLE	#tblCust_Master

CREATE TABLE #tblCust_Master (
		custid			INT PRIMARY KEY
	,	roleid			TINYINT
	,	oldSite			VARCHAR(10)
	,	isDummy			BIT DEFAULT(0)
	,	newSite			VARCHAR(50)
)

IF	OBJECT_ID('tempdb..#tblCust_Agent') IS NOT NULL
	DROP TABLE	#tblCust_Agent

CREATE TABLE #tblCust_Agent (
		custid			INT PRIMARY KEY
	,	roleid			TINYINT
	,	oldSite			VARCHAR(10)
	,	isDummy			BIT DEFAULT(0)
	,	newSite			VARCHAR(50)
)

IF	OBJECT_ID('tempdb..#tblCust_Member') IS NOT NULL
	DROP TABLE	#tblCust_Member;

CREATE TABLE #tblCust_Member (
		custid			INT PRIMARY KEY
	,	roleid			TINYINT
	,	oldSite			VARCHAR(10)
	,	isDummy			BIT DEFAULT(0)
	,	newSite			VARCHAR(50)
)

IF	OBJECT_ID('tempdb..#tblCust') IS NOT NULL
	DROP TABLE	#tblCust;

CREATE TABLE #tblCust
(
		CustID			INT PRIMARY KEY
	,	SiteName		VARCHAR(50)
)

-- ---------------------------------------------
INSERT INTO #Cust_Headline (custid, roleid, headline, newSite)
SELECT  ca.custid	,	cu.roleid	,	ch.username headline	,	CASE	WHEN ch.username='ZU01'				THEN 'yUT'              -- Group 1
				WHEN ch.username='ET789HL'			THEN 'y789'             -- Group 3
				WHEN ch.username IN ('BC1','SD67','DTF233','8U01','V3901','8K01','DTE113','DTE131','ET889HL','DTE249','XU1','9S')
                                                    THEN 'y889'             -- Group 2
				ELSE 'yOther'												-- Group 4		END AS newSite FROM custAccount ca WITH (NOLOCK)						INNER JOIN customer  c WITH (NOLOCK) ON c.custid=ca.custid					INNER JOIN custinfo cu WITH (NOLOCK) ON cu.custid=ca.custid					LEFT JOIN CustGroupHeadline h WITH (NOLOCK) ON h.GroupID = ca.groupID					LEFT JOIN Customer ch WITH (NOLOCK) ON ch.custid = h.CustID				WHERE c.site='789y'--WHERE ch.username IN (	'ZU01' -- yUT--						,'ET789HL' -- y789--						,'BC1','SD67','DTF233','8U01','V3901','8K01','DTE113','DTE131','ET889HL','DTE249','XU1','9S' -- y889--						,'SBZU','JWL','TSUS','EVAUSD','etus','LOKUS','SDD','SPUS','KKKUSD','SBWU','HEU','SCV','789US','BBBU','ABS','CT','PZZ','SQE','SA-US$789y' -- yOther --					)	AND c.currency <> 20				
	AND ca.groupID <> 0

------------------ Super
INSERT INTO #tblCust_Super (custid, roleid, newSite)
SELECT	c.custid, c.roleid, tmp.newSite
FROM #Cust_Headline AS tmp
	INNER JOIN custInfo AS c WITH(NOLOCK) ON c.srecommend = tmp.custid
WHERE tmp.roleid = 4

------------------ Master
INSERT INTO #tblCust_Master (custid, roleid, newSite)
SELECT	c.custid, c.roleid, tmp.newSite
FROM #Cust_Headline AS tmp
	INNER JOIN custInfo AS c WITH(NOLOCK) ON c.mrecommend = tmp.custid
WHERE tmp.roleid = 3

INSERT INTO #tblCust_Master (custid, roleid, oldSite, isDummy, newSite)
SELECT DISTINCT 
		c.srecommend
	,	4
	,	CASE 
			WHEN tmp2.custid IS NOT NULL THEN tmp2.newSite
			ELSE c.site
		END
	,	1
	,	tmp1.newSite
FROM #tblCust_Master AS tmp1
	INNER JOIN Customer AS c WITH(NOLOCK) ON c.custid = tmp1.custid
	LEFT JOIN #tblCust_Super AS tmp2 ON tmp2.custid = c.srecommend

------------------ Agent 
INSERT INTO #tblCust_Agent (custid, roleid,newSite)
SELECT	c.custid, c.roleid, tmp.newSite
FROM #Cust_Headline AS tmp
	INNER JOIN custInfo AS c WITH(NOLOCK) ON c.recommend = tmp.custid
WHERE tmp.roleid = 2

INSERT INTO #tblCust_Agent (custid, roleid, oldSite, isDummy, newSite)
SELECT DISTINCT 
		c.srecommend
	,	4
	,	CASE 
			WHEN tmp2.custid IS NOT NULL THEN tmp2.newSite
			ELSE c.site
		END
	,	1
	,	tmp1.newSite
FROM #tblCust_Agent AS tmp1
	INNER JOIN Customer AS c WITH(NOLOCK) ON c.custid = tmp1.custid
	LEFT JOIN #tblCust_Super AS tmp2 ON tmp2.custid = c.srecommend
UNION ALL
SELECT DISTINCT 
		c.mrecommend
	,	3
	,	CASE 
			WHEN tmp2.custid IS NOT NULL THEN tmp2.newSite
			ELSE c.site
		END
	,	1
	,	tmp1.newSite
FROM #tblCust_Agent AS tmp1
	INNER JOIN Customer AS c WITH(NOLOCK) ON c.custid = tmp1.custid
	LEFT JOIN #tblCust_Master AS tmp2 ON tmp2.custid = c.mrecommend

------------------ Member 
INSERT INTO #tblCust_Member (custid, roleid,newSite)
SELECT	c.custid, c.roleid, tmp.newSite
FROM #Cust_Headline AS tmp
	INNER JOIN custInfo AS c WITH(NOLOCK) ON c.custid = tmp.custid
WHERE tmp.roleid = 1

INSERT INTO #tblCust_Member (custid, roleid, oldSite, isDummy,newSite)
SELECT DISTINCT 
		c.srecommend
	,	4
	,	CASE 
			WHEN tmp2.custid IS NOT NULL THEN tmp2.newSite
			ELSE c.site
		END
	,	1
	,	tmp1.newSite
FROM #tblCust_Member AS tmp1
	INNER JOIN Customer AS c WITH(NOLOCK) ON c.custid = tmp1.custid
	LEFT JOIN #tblCust_Super AS tmp2 ON tmp2.custid = c.srecommend
UNION ALL
SELECT DISTINCT 
		c.mrecommend
	,	3
	,	CASE 
			WHEN tmp2.custid IS NOT NULL THEN tmp2.newSite
			ELSE c.site
		END
	,	1
	,	tmp1.newSite
FROM #tblCust_Member AS tmp1
	INNER JOIN Customer AS c WITH(NOLOCK) ON c.custid = tmp1.custid
	LEFT JOIN #tblCust_Master AS tmp2 ON tmp2.custid = c.mrecommend
UNION ALL
SELECT DISTINCT 
		c.recommend
	,	2
	,	CASE 
			WHEN tmp2.custid IS NOT NULL THEN tmp2.newSite
			ELSE c.site
		END
	,	1
	,	tmp1.newSite
FROM #tblCust_Member AS tmp1
	INNER JOIN Customer AS c WITH(NOLOCK) ON c.custid = tmp1.custid
	LEFT JOIN #tblCust_Agent AS tmp2 ON tmp2.custid = c.recommend

------------------------------------------------------------------------------------
INSERT INTO #tblCust (CustID,SiteName)
SELECT	tmp2.custid AS CustID
	,	CASE 
			WHEN tmp2.isDummy = 1 AND tmp2.oldSite = '789y' THEN 'yOther' 
			ELSE tmp2.newSite 
		END AS SiteName
FROM #tblCust_Member AS tmp2 
WHERE NOT (tmp2.isDummy = 1 AND tmp2.oldSite <> '789y')
--FOR JSON AUTO
UNION ALL
SELECT	tmp2.custid AS CustID
	,	CASE 
			WHEN tmp2.isDummy = 1 AND tmp2.oldSite='789y' THEN 'yOther' 
			ELSE tmp2.newSite 
		END AS SiteName
FROM  #tblCust_Agent AS tmp2 
WHERE NOT (tmp2.isDummy = 1 AND tmp2.oldSite <> '789y')
--FOR JSON AUTO
UNION ALL
SELECT	tmp2.custid AS CustID
	,	CASE 
			WHEN tmp2.isDummy = 1 AND tmp2.oldSite = '789y' THEN 'yOther' 
			ELSE tmp2.newSite 
		END AS SiteName
FROM #tblCust_Master AS tmp2 
WHERE NOT (tmp2.isDummy=1 AND tmp2.oldSite <> '789y')
--FOR JSON AUTO
UNION ALL
SELECT	tmp2.custid AS CustID
	,	CASE 
			WHEN tmp2.isDummy = 1 AND tmp2.oldSite = '789y' THEN 'yOther' 
			ELSE tmp2.newSite 
		END AS SiteName
FROM #tblCust_Super AS tmp2 
WHERE NOT (tmp2.isDummy = 1 AND tmp2.oldSite <> '789y')
--FOR JSON AUTO
--ORDER BY 2

SELECT * FROM #tblCust

/**************************
PART 2: Customer - NonHeadline
***************************/

SELECT	c.custid AS CustID
	,	'yOther' AS SiteName
FROM customer c WITH (NOLOCK)					INNER JOIN custinfo cu WITH (NOLOCK) ON cu.custid=c.custid	
	LEFT JOIN #tblCust AS tmp ON tmp.CustID = cu.custid
WHERE c.site='789y'						AND c.currency<>20
	AND tmp.CustID IS NULL

