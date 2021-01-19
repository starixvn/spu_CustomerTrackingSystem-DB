/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_Customer_GetNewCustSubInfo
						 @LastCustSubId INT = 0
						,@rowSize INT = 500
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

	SELECT TOP (@rowSize) 
			sub.custid AS CustID
		,	sub.subaccid AS CustSubID
		,	sub.username AS UserName
		,	sub.username2 AS UserName2
		,	st.siteid AS SiteID
		,	cust.site AS 'Site'
		,	cust.roleid AS RoleID
		,	cust.currency AS 'CurrencyID'
		,	ex.currency AS Currency
		,	cust.srecommend AS Srecommend
		,	cust.mrecommend AS Mrecommend
		,	cust.recommend AS Recommend
		,	sub.createdate AS CreatedDate
	FROM dbo.custSub sub WITH (NOLOCK)
		INNER JOIN dbo.Customer cust WITH (NOLOCK) ON sub.custid = cust.custid
		INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
		INNER JOIN dbo.Site st WITH (NOLOCK) ON cust.site = st.site
	WHERE sub.subaccid > @LastCustSubId
	ORDER BY sub.subaccid

END;
GO