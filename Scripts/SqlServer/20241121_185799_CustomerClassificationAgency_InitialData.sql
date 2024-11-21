/*<info serverAlias="DBVR2-bodb_VR2Model" executers="DBCTS-WASAVerse" isFunction="0" isNested="0"></info>*/
/*
    Creator: 	20241121@Jonas.Huynh
    Task:	 	Initialize LastTransTime Customer Classification Agency [Redmine ID: #185799]
    DBName:		bodb_VR2Model
*/

USE [bodb_VR2Model]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- #1. ADD TABLE [CustomerClassificationAgency_InitialData]
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CustomerClassificationAgency_InitialData]') AND type in (N'U'))
DROP TABLE [dbo].[CustomerClassificationAgency_InitialData]
CREATE TABLE [dbo].[CustomerClassificationAgency_InitialData](
		[CustId]		INT PRIMARY KEY
) 
GO

-- #2. Import file into table



-- #3. Get Lastest Trans for Agency
IF	OBJECT_ID('tempdb..#tmpLastTransAgency') IS NOT NULL
	DROP TABLE	#tmpLastTransAgency;

CREATE TABLE #tmpLastTransAgency(
		CustId		  INT PRIMARY KEY
	,	LastTransTime DATETIME NULL
);
GO

INSERT INTO #tmpLastTransAgency(CustId, LastTransTime)
SELECT a.CustId, MAX(l.LastTransTime)
FROM dbo.CustomerClassificationAgency_InitialData AS a
	INNER JOIN bodb02.dbo.custInfo AS c WITH(NOLOCK) ON c.recommend = a.CustId AND c.roleid = 2
	INNER JOIN dbo.CustomerClassification_LatestActiveDay AS l ON l.CustId = c.custid
	LEFT JOIN bodb02.dbo.Dep_CustSuper AS cs WITH(NOLOCK) ON c.Srecommend = cs.custid
WHERE cs.CustID IS NULL
GROUP BY a.CustId;
GO

-- #4. Update Lastest Trans for Agency
UPDATE b WITH(ROWLOCK, UPDLOCK)
SET	   b.LastTransDate = a.LastTransTime,
	   b.LastTransTime = a.LastTransTime,
	   b.CreatedTime = GETDATE()
FROM #tmpLastTransAgency AS a
	INNER JOIN dbo.CustomerClassificationAgency_LatestActiveDay AS b ON b.CustId = a.CustId
WHERE a.LastTransTime > b.LastTransTime;

INSERT INTO dbo.CustomerClassificationAgency_LatestActiveDay(CustId, RoleID, LastTransDate, LastTransTime, CreatedTime)
SELECT a.CustId, 2 AS RoleID, LastTransTime, LastTransTime, GETDATE()
FROM #tmpLastTransAgency AS a
WHERE NOT EXISTS (SELECT 1 FROM dbo.CustomerClassificationAgency_LatestActiveDay AS b WITH(NOLOCK) WHERE b.CustId = a.CustId);


GRANT VIEW DEFINITION ON [dbo].[CustomerClassificationAgency_InitialData] TO [wsv_cts]
GO