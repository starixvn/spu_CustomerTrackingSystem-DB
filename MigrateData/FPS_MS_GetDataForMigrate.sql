/*<info serverAlias="FPSADMIN-FPS_MiddleService" executers="fpsWinService" viewers="" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE FPS_MS_GetDataForMigrate 
	@pageSize INT
AS
/*
	Created: 20200121@Harvey.nguyen
	Task: Get data for migration service
	  DB: FPS_MiddleService
  
	Revisions:
		- 20200121@Harvey: init SPs  (#127512)

	Param's Explanation:  

	exec FPS_MS_GetDataForMigrate 500
	
*/
BEGIN
	SET NOCOUNT ON

	SELECT TOP (@pageSize)
		TransId
		,SubTransId
		,LoginName
		,SubName
		,TransTime
		,CreatedDate
		,DeviceCode
		,IP
		,ActionName
		,ActionResult
	INTO #tempTrans
	FROM [uat].[CTSMigrateTrans] mt WITH (NOLOCK)

	INSERT INTO uat.CTSMigrateTrans_Complete(
		TransId
		,SubTransId
		,LoginName
		,SubName
		,TransTime
		,CreatedDate
		,DeviceCode
		,IP
		,ActionName
		,ActionResult
		)
	SELECT 
		TransId
		,SubTransId
		,LoginName
		,SubName
		,TransTime
		,CreatedDate
		,DeviceCode
		,IP
		,ActionName
		,ActionResult
	FROM #tempTrans mt WITH (NOLOCK)

	DELETE trans
	FROM uat.CTSMigrateTrans trans
		INNER JOIN #tempTrans ttrans on trans.TransId = ttrans.TransId


	SELECT 
		TransId
		,SubTransId
		,LoginName
		,SubName
		,TransTime
		,CreatedDate
		,DeviceCode
		,IP
		,ActionName
		,ActionResult 
	FROM #tempTrans

	DROP TABLE #tempTrans
END

/*
/*
select em.CentralPoint , em.EviCode, em.Comment
from FPS_EVI.dbo.EvidenceMaster em with (nolock)
where em.ItemType = 0
*/
/*
	Creator:	20190113@Harvey.Nguyen
	Task:		Statistic for FPS Transaction
	Server:		DBFRAUD

	Notes:
		- Run this script on FPS_MiddleService, it will run on all Subs
*/
SET NOCOUNT ON;
DECLARE @serverName VARCHAR(100)
	,@dbName VARCHAR(100)
	,@subId INT = 1
	,@subName NVARCHAR(50) = '12bet'							-- Use this if you want to run only 1 specific subscriber
	,@openQuery NVARCHAR(max)
	,@debugText NVARCHAR(200)
	,@startTimeTotal DATETIME
	,@endTimeTotal DATETIME
	,@transId BIGINT;

CREATE TABLE #ctsTrans (
	SubTransID		BIGINT
	,LoginName		NVARCHAR(50)
	,SubscriberId	INT
	,TransTime		DATETIME
	,CreatedDate	DATETIME
	,DeviceID		INT
	,IP				NVARCHAR(20)
	,ActionName		NVARCHAR(50)
	,ActionResult	NVARCHAR(100)
)


CREATE TABLE #runningSubs (
	SubscriberID INT
	,DbName VARCHAR(100)
	,ServerName VARCHAR(100)
	)

INSERT INTO #runningSubs (
	SubscriberID
	,DbName
	,ServerName
	)
SELECT sub.SubscriberID
	,ser.DbName
	,ser.ServerName
FROM [FPS_ADMIN].[dbo].[Subscribers] sub WITH (NOLOCK)
INNER JOIN [FPS_ADMIN].[dbo].[SubDBServers] ser WITH (NOLOCK) ON sub.SubscriberID = ser.SubscriberId
WHERE sub.IsActive = 1
	 AND sub.SubscriberName = @subName					-- Use this if you want to run only 1 specific subscriber

WHILE 0 = 0
BEGIN
	SET @startTimeTotal = GETDATE()

	SELECT TOP (1) @subId = SubscriberID
		,@dbName = DbName
		,@serverName = ServerName
	FROM #runningSubs
	WHERE SubscriberID > @subId
	ORDER BY SubscriberID

	IF @@ROWCOUNT = 0
		BREAK;

	SET @debugText = @dbName + ' is running...'

	RAISERROR (@debugText,0,0) WITH NOWAIT
	SET @transId = 277067387;

	WHILE 0 = 0
	BEGIN
		SET @openQuery = '  INSERT INTO #ctsTrans
						SELECT *
						FROM OPENQUERY(' + @serverName + ', ''' + '
						SELECT TOP (1000)
							trans.TransID
							,acc.UserName ''''LoginName''''
							,trans.SubscriberID
							,trans.TransDate ''''TransTime''''
							,GETDATE() ''''CreatedDate''''
							,trans.DeviceID
							,trans.IP
							,trans.ActionName
							,trans.ActionResult
						FROM ' + @dbName + '.[dbo].Transactions trans WITH (NOLOCK)
							INNER JOIN ' + @dbName + '.[dbo].Accounts acc WITH (NOLOCK) ON trans.AccountID = acc.AccountID
						WHERE trans.TransID < ' + CONVERT(VARCHAR, @transId) + '
						ORDER BY trans.TransID DESC '')'

		EXEC sp_executesql @openQuery;
		IF @@ROWCOUNT = 0
			BREAK;

		WITH cteRowNumber
		AS (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY trans.LoginName ORDER BY dd.CreatedDate DESC
					) AS RowNo
				,trans.SubTransID
				,trans.LoginName
				,trans.SubscriberId
				,trans.TransTime
				,trans.CreatedDate
				,dd.DeviceCode
				,trans.ip
				,trans.ActionName
				,trans.ActionResult
			FROM #ctsTrans trans
			INNER JOIN FPS_DEV.dbo.DevDetail dd WITH (NOLOCK) ON trans.DeviceID = dd.DeviceID
		)

		INSERT INTO [uat].[CTSMigrateTrans]
		SELECT cte.SubTransID
			,cte.LoginName
			,sub.SubscriberName
			,cte.TransTime
			,cte.CreatedDate
			,cte.DeviceCode
			,cte.ip
			,cte.ActionName
			,cte.ActionResult
		FROM cteRowNumber cte
			INNER JOIN FPS_ADMIN.dbo.Subscribers sub WITH (NOLOCK) ON sub.SubscriberID = cte.SubscriberId
		WHERE cte.RowNo = 1
		ORDER BY cte.SubTransID

		SET @debugText = CONVERT(VARCHAR, @@ROWCOUNT) + ' rows are inserted'

		RAISERROR (@debugText,0,0) WITH NOWAIT

		SELECT @transId = MIN(SubTransID)
		FROM #ctsTrans

		TRUNCATE TABLE #ctsTrans
	END

	SET @debugText = @dbName + ' run successfully!'

	RAISERROR (@debugText,0,0) WITH NOWAIT

	SET @endTimeTotal = GETDATE()
	SET @debugText = 'Elapsed time: ' + CAST(DATEDIFF(MINUTE, @startTimeTotal, @endTimeTotal) AS VARCHAR(20)) + ' minute(s)'

	RAISERROR (@debugText,0,0)
	WITH NOWAIT
END;

DROP TABLE #runningSubs
DROP TABLE #ctsTrans
*/