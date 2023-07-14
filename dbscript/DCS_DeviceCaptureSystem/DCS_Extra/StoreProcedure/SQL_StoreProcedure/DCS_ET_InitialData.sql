/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	DCS_FPS_InitRawTransaction
		@BatchSize INT = 1000
AS
/*
	Creator:	20230714@Casey.Huynh
	Task:		Get T
	Database:	DBCTS.bodb02
	
	Revisions:
		-20230714@Casey.Huynh:Created [Redmine ID: 190118]

	Developer's Notes:
		

	exec DCS_FPS_InitRawTransaction 1000
		
*/
BEGIN;
	SET NOCOUNT ON;

	IF	OBJECT_ID('tempdb..#tmpSubscriber') IS NOT NULL
		DROP TABLE	#tmpSubscriber;

	CREATE TABLE #tmpSubscriber(
			SubscriberName	NVARCHAR(50) PRIMARY KEY
		,	ServerName		NVARCHAR(100)
		,	DatabaseName	NVARCHAR(50)	
	);

	INSERT INTO #tmpSubscriber(SubscriberName,ServerName,DatabaseName)
	VALUES('Velki','FPS_DB02\FPS_01','FPS_SUB_Velki')
		, ('CTMax','FPS_DB01\MSSQLSERVERWEB','FPS_SUB_CTMax')
		, ('AgentCTMax','FPS_DB01\MSSQLSERVERWEB','FPS_SUB_AgentCTMax')
		, ('Sky','FPS_DB01\MSSQLSERVERWEB','FPS_SUB_Sky')
		, ('AgentSky','FPS_DB01\MSSQLSERVERWEB','FPS_SUB_AgentSky');

	DECLARE @SubscriberName NVARCHAR(50);

	SET @SubscriberName = (SELECT TOP(1) SubscriberName FROM #tmpSubscriber AS tmp);



	/*
	DECLARE @custIDList VARCHAR(MAX);
	DECLARE @TraceTime SMALLDATETIME;

	SET @TraceTime = DATEADD(minute, -5, GETDATE());

	IF	OBJECT_ID('tempdb..#tmpNewCust') IS NOT NULL
		DROP TABLE	#tmpNewCust;

	CREATE TABLE #tmpNewCust(
		CustId		INT NOT NULL
	,	CreatedDate	SMALLDATETIME
	,	RoleID		TINYINT
	,	UserName2	VARCHAR(50)
	,	PRIMARY KEY (CustId)
	);

	INSERT INTO #tmpNewCust(CustID, CreatedDate, RoleID, UserName2)
	SELECT	TOP (@rowSize) 
			c.CustID
		,	c.CreatDate
		,	c.RoleID
		,	c.UserName2
	FROM	dbo.Customer AS c WITH(NOLOCK)
	WHERE	c.CustID > @LastCustId			
			

	SELECT  @custIDList = COALESCE(@custIDList + ',', '') +  CONVERT(VARCHAR(10),tmpCus.CustID)
	FROM	#tmpNewCust AS tmpCus WITH(NOLOCK)
	WHERE	tmpCus.RoleID BETWEEN 1 AND 4
			AND (tmpCus.UserName2 IS NOT NULL
					OR (tmpCus.UserName2 IS NULL AND tmpCus.CreatedDate < @TraceTime  )
				);

	EXEC CTS_Customer_GetInfoByCustIdList @custIDList;

	SELECT	MAX(CustID) AS LastInsertCustID
	FROM	#tmpNewCust AS tmpCus WITH(NOLOCK)
	WHERE	tmpCus.CreatedDate < @TraceTime;	
	*/

END;
GO