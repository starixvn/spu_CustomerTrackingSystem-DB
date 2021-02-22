/*<info serverAlias="DBCTSC-bodb_CustHistory" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_CustomerHistory_GetUpdatedCustID
		@lastUpdateTime		DATETIME
	,	@lastCustId			INT
	,	@rowSize			INT = 500
AS
/*
	Creator:	20210205@CaseyHuynh
	Task:		Get updated Customer_History [Redmine ID: 149941]
	Database:	bodb_CustHistory
	
	Revisions:
		- 20210205@CaseyHuynh: Created [Redmine ID: 149941]

	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	EXEC CTS_CustomerHistory_GetUpdatedCustID '2021-02-03 03:35:51.810',0,10	

*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE	@rowCount		INT;
	DECLARE	@maxUpdateTime	DATETIME;
	DECLARE @custIdList		VARCHAR(MAX);

	IF	OBJECT_ID('tempdb..#tmpUpdatedCustomers') IS NOT NULL
		DROP TABLE	#tmpUpdatedCustomers;
	
	CREATE TABLE #tmpUpdatedCustomers (
			UpdateTime	DATETIME
		,	CustId		INT
		,	RoleID		TINYINT
	);
	
	CREATE CLUSTERED INDEX IX_tmpUpdatedCustomers_UpdateTimeCustId ON #tmpUpdatedCustomers(
			UpdateTime		ASC
		,	CustId			ASC
	);

	INSERT INTO #tmpUpdatedCustomers(UpdateTime, CustID)
	SELECT		TOP(@rowSize) cih.UpdateTime
				, cih.CustID
	FROM		bodb_CustHistory.dbo.Customer_History AS cih WITH(NOLOCK)
	WHERE		cih.UpdateTime = @lastUpdateTime
				AND cih.CustId > @lastCustId
	ORDER BY	cih.UpdateTime ASC, cih.CustID ASC;

	SET @rowCount = (SELECT COUNT(1) FROM #tmpUpdatedCustomers AS tmpCus)

	IF(@rowCount < @rowSize)
	BEGIN
		INSERT INTO #tmpUpdatedCustomers(UpdateTime, CustID)
		SELECT		TOP(@rowSize - @rowCount) cih.UpdateTime
				,	cih.CustID
				,	cih.RoleID
		FROM		bodb_CustHistory.dbo.Customer_History AS cih WITH(NOLOCK)
		WHERE		cih.UpdateTime > @lastUpdateTime
		ORDER BY	cih.UpdateTime, cih.CustID;
	END;

	SET  @maxUpdateTime = (SELECT	MAX(tmpCus1.UpdateTime)	FROM #tmpUpdatedCustomers AS tmpCus1)

	SELECT	@maxUpdateTime AS LastUpdatedTime
			, MAX(tmpCus.CustId) AS LastCustId
	FROM	#tmpUpdatedCustomers AS tmpCus
	WHERE	tmpCus.UpdateTime = @maxUpdateTime;

	SELECT	@custIdList = COALESCE(@custIdList + ',', '') +  CONVERT(VARCHAR(12), tmp.CustId)
	FROM	(SELECT DISTINCT tmpCus.CustId
			FROM  #tmpUpdatedCustomers AS tmpCus
			WHERE tmpCus.RoleID IN (1,2,3,4)) AS tmp;

	SELECT	@custIdList AS CustIdList;
END;
GO