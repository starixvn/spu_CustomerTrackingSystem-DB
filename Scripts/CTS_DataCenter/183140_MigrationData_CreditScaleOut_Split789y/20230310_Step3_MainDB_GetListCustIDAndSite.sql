/*<info serverAlias="DBCTS-bodb02" executers="" viewers="" isFunction="0"></info>*/

/*
	Creator:	20230310@Victoria.le
	Task:	 	Scale out - Split 789y Site

	 Revisions:
		- 20230310@Victoria.le: 	STEP 3: GET List CustID and Site [Redmine ID: #183140]
								
*/

/**************************
PART 1: Customer - Headline
***************************/
IF	OBJECT_ID('tempdb..#tmp_Cust_Headline') IS NOT NULL
BEGIN
	DROP TABLE #tmp_Cust_Headline;
END;

CREATE TABLE #tmp_Cust_Headline (
		custid			INT PRIMARY KEY
	,	roleid			TINYINT
	,	headline		VARCHAR(30)
	,	newSite			VARCHAR(10)
	,	srecommend		INT
	,	ssite			VARCHAR(10)	NULL
	,	mrecommend		INT
	,	msite			VARCHAR(10) NULL
	,	recommend		INT
	,	asite			VARCHAR(10) NULL
	
	,	INDEX IX_tmp_Cust_Headline_Super (srecommend)
	,	INDEX IX_tmp_Cust_Headline_Master (mrecommend)
	,	INDEX IX_tmp_Cust_Headline_Agent (recommend)
	
);

IF	OBJECT_ID('tempdb..#tmp_Cust') IS NOT NULL
BEGIN
	DROP TABLE #tmp_Cust;
END;

CREATE TABLE #tmp_Cust 
(
		custid			INT PRIMARY KEY
	,	roleid			TINYINT
	,	oldSite			VARCHAR(10)
	,	newSite			VARCHAR(10)
	
	,	INDEX IX_tmp_Cust_CustID_RoleID (custid,roleid)
);

IF	OBJECT_ID('tempdb..#tmp_Cust_Super') IS NOT NULL
BEGIN
	DROP TABLE #tmp_Cust_Super;
END;

CREATE TABLE #tmp_Cust_Super (custid INT PRIMARY KEY);

IF	OBJECT_ID('tempdb..#tmp_Cust_Master') IS NOT NULL
BEGIN
	DROP TABLE #tmp_Cust_Master;
END;

CREATE TABLE #tmp_Cust_Master (custid INT PRIMARY KEY);

IF	OBJECT_ID('tempdb..#tmp_Cust_Agent') IS NOT NULL
BEGIN
	DROP TABLE #tmp_Cust_Agent;
END;

CREATE TABLE #tmp_Cust_Agent (custid INT PRIMARY KEY);

IF	OBJECT_ID('tempdb..#tmp_Cust_Member') IS NOT NULL
BEGIN
	DROP TABLE #tmp_Cust_Member;
END;

CREATE TABLE #tmp_Cust_Member (custid INT PRIMARY KEY);


IF	OBJECT_ID('tempdb..#tmp_Cust_Dummy') IS NOT NULL
BEGIN
	DROP TABLE #tmp_Cust_Dummy;
END;

CREATE TABLE #tmp_Cust_Dummy 
(
		custid			INT PRIMARY KEY
	,	roleid			TINYINT
	,	newSite			VARCHAR(10)
	
	-- ,	INDEX IX_tmp_Cust_Dummy_CustID_RoleID (custid,roleid)
);

IF	OBJECT_ID('tempdb..#tmp_Cust_Result') IS NOT NULL
BEGIN
	DROP TABLE #tmp_Cust_Result;
END;

CREATE TABLE #tmp_Cust_Result 
(
		custid			INT PRIMARY KEY
	,	roleid			TINYINT
	,	newSite			VARCHAR(10)
);


------------------ Headline
INSERT INTO #tmp_Cust_Headline 
(
		custid
	, 	roleid
	,	srecommend
	,	mrecommend
	,	recommend
	, 	headline
	, 	newSite
)
SELECT  c.custid
	,	c.roleid
	,	c.srecommend
	,	c.mrecommend
	,	c.recommend
	,	ch.username	
	,	CASE	WHEN ch.username='ZU01'		THEN 'yUT'              -- Group 1
				WHEN ch.username='ET789HL'	THEN 'y789'             -- Group 3
				WHEN ch.username IN ('BC1','SD67','DTF233','8U01','V3901','8K01','DTE113','DTE131','ET889HL','DTE249','XU1','9S')
											THEN 'y889'             -- Group 2
				ELSE 'yOther'										-- Group 4
		END 
FROM CustDB.dbo.CustAccount AS ca WITH (NOLOCK)					
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = ca.custid						
	LEFT JOIN CustDB.dbo.CustGroupHeadline AS h WITH (NOLOCK) ON h.GroupID = ca.groupID				
	LEFT JOIN CustDB.dbo.Customer AS ch WITH (NOLOCK) ON ch.custid = h.CustID				
WHERE c.site='789y'
	AND c.currency <> 20				
	-- AND c.currency = 20
	AND ca.groupID <> 0
	-- AND ch.username is not null
;
	
------------------ Site
-- Super
UPDATE tmp
SET tmp.ssite = CASE WHEN tmp.roleid = 4 THEN tmp.newSite
					 ELSE c.site
				END
FROM #tmp_Cust_Headline AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.srecommend;
	
-- Master
UPDATE tmp
SET tmp.msite = CASE WHEN tmp.roleid = 3 THEN tmp.newSite
					 ELSE c.site
				END
FROM #tmp_Cust_Headline AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.mrecommend;
	
-- Agent
UPDATE tmp
SET tmp.asite = CASE WHEN tmp.roleid = 2 THEN tmp.newSite
					 ELSE c.site
				END
FROM #tmp_Cust_Headline AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.recommend;	

------------------ DISTINCT
INSERT INTO #tmp_Cust_Super (custid)
SELECT DISTINCT custid
FROM #tmp_Cust_Headline
WHERE roleid = 4;

INSERT INTO #tmp_Cust_Master (custid)
SELECT DISTINCT custid
FROM #tmp_Cust_Headline
WHERE roleid = 3;

INSERT INTO #tmp_Cust_Agent (custid)
SELECT DISTINCT custid
FROM #tmp_Cust_Headline
WHERE roleid = 2;

INSERT INTO #tmp_Cust_Member (custid)
SELECT DISTINCT custid
FROM #tmp_Cust_Headline
WHERE roleid = 1;

------------------ Downline
-- Supper
INSERT INTO #tmp_Cust
(
		custid			
	,	roleid			
	,	oldSite			
	,	newSite			
)
SELECT 	c.custid
	, 	c.roleid
	, 	c.site
	, 	tmp.newSite
FROM #tmp_Cust_Headline AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.srecommend = tmp.custid
	LEFT JOIN #tmp_Cust_Master AS tmpM ON tmpM.custid = c.custid
	LEFT JOIN #tmp_Cust_Agent AS tmpA ON tmpA.custid = c.custid
	LEFT JOIN #tmp_Cust_Member AS tmpMM ON tmpMM.custid = c.custid
WHERE tmp.roleid = 4
	AND (	c.roleid = 4
		OR (c.roleid = 3 AND tmpM.custid IS NULL)
		OR (c.roleid = 2 AND tmpA.custid IS NULL)
		OR (c.roleid = 1 AND tmpMM.custid IS NULL));

-- Master
INSERT INTO #tmp_Cust
(
		custid			
	,	roleid			
	,	oldSite			
	,	newSite			
)
SELECT 	c.custid
	, 	c.roleid
	, 	c.site
	, 	tmp.newSite
FROM #tmp_Cust_Headline AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.mrecommend = tmp.custid
	LEFT JOIN #tmp_Cust_Agent AS tmpA ON tmpA.custid = c.custid
	LEFT JOIN #tmp_Cust_Member AS tmpMM ON tmpMM.custid = c.custid
WHERE tmp.roleid = 3
	AND (	c.roleid = 3
		OR (c.roleid = 2 AND tmpA.custid IS NULL)
		OR (c.roleid = 1 AND tmpMM.custid IS NULL));

-- Agent
INSERT INTO #tmp_Cust
(
		custid			
	,	roleid			
	,	oldSite			
	,	newSite			
)
SELECT 	c.custid
	, 	c.roleid
	, 	c.site
	, 	tmp.newSite
FROM #tmp_Cust_Headline AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.recommend = tmp.custid
	LEFT JOIN #tmp_Cust_Member AS tmpMM ON tmpMM.custid = c.custid
WHERE tmp.roleid = 2
	AND (	c.roleid = 2
		OR (c.roleid = 1 AND tmpMM.custid IS NULL));

-- Member
INSERT INTO #tmp_Cust
(
		custid			
	,	roleid			
	,	oldSite			
	,	newSite			
)
SELECT 	c.custid
	, 	c.roleid
	, 	c.site
	, 	tmp.newSite
FROM #tmp_Cust_Headline AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.custid
WHERE tmp.roleid = 1;

------------------ Dummy - Upline
-- Super
INSERT INTO #tmp_Cust_Dummy
(
		custid			
	,	roleid	
	,	newSite
)
SELECT DISTINCT
		tmp1.srecommend
	,	4
	,	CASE 
			WHEN tmp1.ssite = '789y' THEN 'yOther'
			ELSE tmp1.ssite 
		END
FROM #tmp_Cust_Headline AS tmp1
	LEFT JOIN #tmp_Cust_Super AS tmpS ON tmpS.custid = tmp1.srecommend
WHERE tmpS.custid IS NULL
	AND ISNULL(tmp1.srecommend,0) <> 0;
							
-- Master 
INSERT INTO #tmp_Cust_Dummy
(
		custid			
	,	roleid				
	,	newSite
)
SELECT DISTINCT
		tmp1.mrecommend
	,	3
	,	CASE 
			WHEN tmp1.msite = '789y' THEN 'yOther'
			ELSE tmp1.msite 
		END
FROM #tmp_Cust_Headline AS tmp1
	LEFT JOIN #tmp_Cust_Master AS tmpM ON tmpM.custid = tmp1.mrecommend
	LEFT JOIN #tmp_Cust_Super AS tmpS ON tmpS.custid = tmp1.srecommend
WHERE tmpM.custid IS NULL AND tmpS.custid IS NULL
	AND ISNULL(tmp1.mrecommend,0) <> 0;

-- Agent
INSERT INTO #tmp_Cust_Dummy
(
		custid			
	,	roleid				
	,	newSite
)
SELECT DISTINCT
		tmp1.recommend
	,	2
	,	CASE 
			WHEN tmp1.asite = '789y' THEN 'yOther'
			ELSE tmp1.asite 
		END
FROM #tmp_Cust_Headline AS tmp1
	LEFT JOIN #tmp_Cust_Agent AS tmpA ON tmpA.custid = tmp1.recommend
	LEFT JOIN #tmp_Cust_Master AS tmpM ON tmpM.custid = tmp1.mrecommend
	LEFT JOIN #tmp_Cust_Super AS tmpS ON tmpS.custid = tmp1.srecommend
WHERE tmpA.custid IS NULL AND tmpM.custid IS NULL  AND tmpS.custid IS NULL 
	AND ISNULL(tmp1.recommend,0) <> 0;

------------------ Result
INSERT INTO #tmp_Cust_Result (custid, roleid, newSite)
SELECT custid, roleid, newSite
FROM #tmp_Cust
UNION
SELECT custid, roleid, newSite
FROM #tmp_Cust_Dummy
WHERE newSite IN ('y789','y889','yUT','yOther');

SELECT * FROM #tmp_Cust_Result;

/**************************
PART 2: Customer - NonHeadline
***************************/
IF	OBJECT_ID('tempdb..#tmp_Cust_NonHeadLine') IS NOT NULL
BEGIN
	DROP TABLE #tmp_Cust_NonHeadLine;
END;

CREATE TABLE #tmp_Cust_NonHeadLine
(
		custid			INT PRIMARY KEY
	,	roleid			TINYINT
	,	newSite			VARCHAR(10)
);

INSERT INTO #tmp_Cust_NonHeadLine 
(
		custid
	,	roleid
	,	newSite
)
SELECT 	c.custid
	,	c.roleid
	,	'yOther' AS newSite
FROM CustDB.dbo.Customer AS c WITH (NOLOCK)
	LEFT JOIN #tmp_Cust_Result AS tmp ON tmp.custid = c.custid
WHERE c.site = '789y'
	AND c.currency <> 20
	AND tmp.custid IS NULL;


/**************************
PART 3: Check Consistency - Will be run when MainDB finish migration data
***************************/
/*
------------------ Temporary table
-- Check count
DROP TABLE IF EXISTS #tmp_Cust_Result_CC_Site;

SELECT newSite,COUNT(1) AS CC
INTO #tmp_Cust_Result_CC_Site
FROM #tmp_Cust_Result
GROUP BY newSite;

DROP TABLE IF EXISTS #tmp_Cust_Result_CC_Site_RoleId;

SELECT newSite,roleid,COUNT(1) AS CC
INTO #tmp_Cust_Result_CC_Site_RoleId
FROM #tmp_Cust_NonHeadLine
GROUP BY newSite,roleid;

-- Checksum
DROP TABLE IF EXISTS #tmp_Cust_Result_CS_Site;

SELECT newSite,CHECKSUM_AGG( CHECKSUM(custid,roleid,newSite)) AS CS
INTO #tmp_Cust_Result_CS_Site
FROM #tmp_Cust_Result
GROUP BY newSite;

DROP TABLE IF EXISTS #tmp_Cust_Result_CS_Site_RoleId;

SELECT newSite,roleid,CHECKSUM_AGG( CHECKSUM(custid,roleid,newSite)) AS CS
INTO #tmp_Cust_Result_CS_Site_RoleId
FROM #tmp_Cust_NonHeadLine
GROUP BY newSite,roleid;

------------------ Base table
-- Check count
DROP TABLE IF EXISTS #Cust_Result_CC_Site;

SELECT c.site,COUNT(1) AS CC
INTO #Cust_Result_CC_Site
FROM #tmp_Cust_Result AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.custid
GROUP BY c.site;

DROP TABLE IF EXISTS #Cust_Result_CC_Site_RoleId;

SELECT c.site,c.roleid,COUNT(1) AS CC
INTO #Cust_Result_CC_Site_RoleId
FROM #tmp_Cust_NonHeadLine AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.custid
GROUP BY c.site,c.roleid;

-- Checksum
DROP TABLE IF EXISTS #Cust_Result_CS_Site;

SELECT c.site,CHECKSUM_AGG( CHECKSUM(c.custid, c.site)) AS CS
INTO #Cust_Result_CS_Site
FROM #tmp_Cust_Result AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.custid
GROUP BY c.site;

DROP TABLE IF EXISTS #Cust_Result_CS_Site_RoleId;

SELECT c.site,c.roleid,CHECKSUM_AGG( CHECKSUM(c.custid, c.site)) AS CS
INTO #Cust_Result_CS_Site_RoleId
FROM #tmp_Cust_NonHeadLine AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.custid
GROUP BY c.site,c.roleid;

------------------ Comparation
-- Check count
SELECT *
FROM #tmp_Cust_Result_CC_Site AS tmp
	LEFT JOIN #Cust_Result_CC_Site AS b ON tmp.newSite = b.site
WHERE tmp.newSite IS NULL
	OR b.site IS NULL
	OR b.CC <> tmp.CC;
	
SELECT *
FROM #tmp_Cust_Result_CC_Site_RoleId AS tmp
	LEFT JOIN #Cust_Result_CC_Site_RoleId AS b ON tmp.newSite = b.site AND b.roleid = tmp.roleid
WHERE tmp.newSite IS NULL
	OR b.site IS NULL
	OR b.CC <> tmp.CC;
	

-- Checksum
SELECT *
FROM #tmp_Cust_Result_CS_Site AS tmp
	LEFT JOIN #Cust_Result_CS_Site AS b ON tmp.newSite = b.site
WHERE tmp.newSite IS NULL
	OR b.site IS NULL
	OR b.CS <> tmp.CS;

SELECT *
FROM #tmp_Cust_Result_CS_Site_RoleId AS tmp
	LEFT JOIN #Cust_Result_CS_Site_RoleId AS b ON tmp.newSite = b.site AND b.roleid = tmp.roleid
WHERE tmp.newSite IS NULL
	OR b.site IS NULL
	OR b.CS <> tmp.CS;

-- Diff Site
SELECT c.custid, c.site, tmp.newSite
FROM #tmp_Cust_Result AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.custid
WHERE tmp.newSite <> c.site;

SELECT c.custid, c.site, tmp.newSite
FROM #tmp_Cust_NonHeadLine AS tmp
	INNER JOIN CustDB.dbo.Customer AS c WITH (NOLOCK) ON c.custid = tmp.custid
WHERE tmp.newSite <> c.site;
*/




