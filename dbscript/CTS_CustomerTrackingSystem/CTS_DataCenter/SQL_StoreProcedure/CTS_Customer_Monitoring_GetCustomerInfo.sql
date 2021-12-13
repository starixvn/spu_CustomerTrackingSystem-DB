/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE OR ALTER PROCEDURE CTS_Customer_Monitoring_GetCustomerInfo
		@FromDate	DATETIME
	,	@ToDate		DATETIME
	,	@rowSize	INT = 500
AS
/*
	Creator:	20211210@Harvey.Nguyen
	Task:		Get customer for monitor service - [Redmine ID: #165607]
	Database:	DBCTS.bodb02
	
	Revisions:
		-
	Developer's Notes:
		

	exec CTS_Customer_Monitoring_GetCustomerInfo 10, 10
		
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE @custIDList VARCHAR(MAX);

	IF	OBJECT_ID('tempdb..#tmpNewCust') IS NOT NULL
		DROP TABLE	#tmpNewCust;

	CREATE TABLE #tmpNewCust(
		CustId		INT NOT NULL
	,	RoleID		TINYINT
	,	PRIMARY KEY (CustId)
	);

	INSERT INTO #tmpNewCust(CustID, RoleID)
	SELECT	TOP (@rowSize) 
			c.CustID
		,	c.RoleID
	FROM	dbo.Customer AS c WITH(NOLOCK)
	WHERE	c.creatdate >= @FromDate AND c.creatdate < @ToDate		
			

	SELECT  @custIDList = COALESCE(@custIDList + ',', '') +  CONVERT(VARCHAR(10),tmpCus.CustID)
	FROM	#tmpNewCust AS tmpCus WITH(NOLOCK)
	WHERE	tmpCus.RoleID BETWEEN 1 AND 4;

	EXEC CTS_Customer_GetInfoByCustIdList @custIDList;	

END;
GO