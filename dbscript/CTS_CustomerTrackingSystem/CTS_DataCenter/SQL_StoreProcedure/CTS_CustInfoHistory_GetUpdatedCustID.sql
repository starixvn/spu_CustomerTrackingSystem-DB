/*<info serverAlias="DBCTSC-bodb_CustHistory" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_CustInfoHistory_GetUpdatedCustID
		@lastUpdateTime		DATETIME
	,	@lastCustId			INT
	,	@rowSize			INT = 500
AS
/*
	Creator:	20210104@CaseyHuynh
	Task:		Get updated customer [Redmine ID: 148849]
	Database:	bodb_CustHistory
	
	Revisions:
		- 20210104@CaseyHuynh: Created [Redmine ID: 148849]
		- 20210205@CaseyHuynh: Remove condition for RoleID (1,2,3,4) [Redmine ID: 149941]
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	exec CTS_GetCustomerInfo 0,500,2
		

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

	INSERT INTO #tmpUpdatedCustomers(UpdateTime, CustID, RoleID)
	SELECT		TOP(@rowSize) cih.UpdateTime
				, cih.CustID
				, cih.RoleID
	FROM		bodb_CustHistory.dbo.CustInfo_History AS cih WITH(NOLOCK)
	WHERE		cih.UpdateTime = @lastUpdateTime
				AND cih.CustId > @lastCustId
	ORDER BY	cih.UpdateTime ASC, cih.CustID ASC;

	SET @rowCount = (SELECT COUNT(1) FROM #tmpUpdatedCustomers AS tmpCus)

	IF(@rowCount < @rowSize)
	BEGIN
		INSERT INTO #tmpUpdatedCustomers(UpdateTime, CustID, RoleID)
		SELECT		TOP(@rowSize - @rowCount) cih.UpdateTime
				,	cih.CustID
				,	cih.RoleID
		FROM		bodb_CustHistory.dbo.CustInfo_History AS cih WITH(NOLOCK)
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
			WHERE tmpCus.RoleID IN (1,2,3,4) ) AS tmp;

	SELECT	@custIdList AS CustIdList;
END;
GO