/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_Customer_GetNewCustomerInfo
		@LastCustId INT = 0
	,	@rowSize INT = 500
AS
/*
	Creator:	20200118@Casey.Huynh
	Task:		Get New customer - [Redmine ID: #148849]
	Database:	DBCTS.bodb02
	
	Revisions:
		-2020018@Casey.Huynh:Created [Redmine ID: 148849]
        -20210427@Casey.Huynh: Add RoleID Condition [Redmine ID: 153283]
		-20210506@Casey.Huynh: Add condition By CreatedTime and UserName2 [Redmine ID: 154633]
		-20210514@Casey.Huynh: Remove Hardcode TraceTime [Redmine ID: 154633]
		-20232209@Casey.Huynh: Remove Logic Keep Cust With NULL UserName2 [Redmine 193050]
	Developer's Notes:
		

	exec CTS_Customer_GetNewCustomerInfo 10, 10
		
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE @custIDList VARCHAR(MAX);

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
	WHERE	tmpCus.RoleID BETWEEN 1 AND 4;

	EXEC CTS_Customer_GetInfoByCustIdList @custIDList;

	SELECT	MAX(CustID) AS LastInsertCustID
	FROM	#tmpNewCust AS tmpCus WITH(NOLOCK);	

END;
GO