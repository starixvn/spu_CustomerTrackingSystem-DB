/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	CTS_Customer_GetNotNULLUserName2ByCustIDList
	@custIdList			VARCHAR(MAX) = ''
AS
/*
	Creator:	20210115@CaseyHuynh
	Task:		Get customer - [Redmine: #148849]
	Database:	DBCTS.bodb02
	
	Revisions:
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	exec CTS_Customer_GetNewCustSubInfo 10,10
		
*/
BEGIN;
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#tmpInputCustId') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpInputCustId;
	END;

	CREATE TABLE #tmpInputCustId (
		CustId			INT NOT NULL PRIMARY KEY
	);

	INSERT INTO #tmpInputCustId
	SELECT	val AS CustId
	FROM	bodb02.dbo.strSplit(@custIdList, ',');

	SELECT	cus.CustID
		,	cus.UserName2
	FROM	dbo.Customer AS cus WITH (NOLOCK)
	INNER JOIN #tmpInputCustId AS tmpCus WITH(NOLOCK) ON cus.CustID = tmpCus.CustID
	WHERE	cus.username2 IS NOT NULL;
END;
GO