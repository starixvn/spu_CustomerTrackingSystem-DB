/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	CTS_Customer_GetNotNULLUserName2ByXML
	@custXML	XML
AS
/*
	Creator:	20210115@CaseyHuynh
	Task:		Get customer - [Redmine: #148849]
	Database:	DBCTS.bodb02
	
	Revisions:
		-20210115@Casey.Huynh: Created [Redmine ID: 148849]

	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	exec CTS_Customer_GetNewCustSubInfo 10,10
		
*/
BEGIN;
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#tmpInputCustId') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpInputCust;
	END;

	CREATE TABLE #tmpInputCust (
		CustID		INT
		,	CustSubID	INT
	);

	INSERT INTO #tmpInputCust(CustID, CustSubID)
	SELECT	T.C.value('./@CustId', 'INT') AS CustId
			, T.C.value('./@CustSubID', 'INT') AS CustSubID
	FROM @custXML.nodes('//Customer') AS T(C)
	OPTION (OPTIMIZE FOR (@custXML = NULL));

	SELECT	tmpCus.CustID
		,	tmpCus.CustSubID
		,	cus.UserName2
	FROM	dbo.Customer AS cus WITH (NOLOCK)
	INNER JOIN #tmpInputCust AS tmpCus WITH(NOLOCK) ON cus.CustID = tmpCus.CustID
	WHERE	cus.username2 IS NOT NULL AND tmpCus.CustSubID = 0
	UNION
	SELECT	tmpCus.CustID
		,	tmpCus.CustSubID
		,	cusSub.UserName2
	FROM	dbo.CustSub AS cusSub WITH (NOLOCK)
	INNER JOIN #tmpInputCust AS tmpCus WITH(NOLOCK) ON cusSub.subaccid = tmpCus.CustSubID
	WHERE	cusSub.username2 IS NOT NULL AND tmpCus.CustSubID > 0
	;
END;
GO