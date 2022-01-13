/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_Customer_GetNewCustSubInfo
		@QueryType		TINYINT = 1

	,	@LastCustSubId	INT = 0
	,	@rowSize		INT = 500

	,	@CustIdList		VARCHAR(MAX) = ''
AS
/*
	Creator:	20210115@CaseyHuynh
	Task:		Get customer - [Redmine: #148849]
	Database:	DBCTS.bodb02
	
	Revisions:
		-20210115@Casey.Huynh: Created [Redmine ID: 148849]
		-20220122@Long.Luu: Support for case already known list of CustID [Redmine ID: 165607]

	Param Explaination:
		- @QueryType: 1 (default) get by range, 2 get by list CustId

	Example:
		exec CTS_Customer_GetNewCustSubInfo @QueryType=2,@LastCustSubId=0,@rowSize=500,@CustIdList='8';
		
*/
BEGIN;
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#tmpCustomer') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomer;
	END;

	CREATE TABLE #tmpCustomer (
			CustId		INT NOT NULL PRIMARY KEY
	);

	IF (@QueryType = 1)
		BEGIN
			SELECT TOP (@rowSize) 
					sub.custid		AS CustID
				,	sub.subaccid	AS CustSubID
				,	sub.username	AS UserName
				,	sub.username2	AS UserName2
				,	st.siteid		AS SiteID
				,	cust.site		AS 'Site'
				,	cust.roleid		AS RoleID
				,	cust.currency	AS 'CurrencyID'
				,	ex.currency		AS Currency
				,	cust.srecommend AS SRecommend
				,	cust.mrecommend AS MRecommend
				,	cust.recommend	AS Recommend
				,	sub.createdate	AS CreatedDate
			FROM dbo.custSub sub WITH (NOLOCK)
				INNER JOIN dbo.Customer cust WITH (NOLOCK) ON sub.custid = cust.custid
				INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
				INNER JOIN dbo.Site st WITH (NOLOCK) ON cust.site = st.site
			WHERE sub.subaccid > @LastCustSubId
			ORDER BY sub.subaccid;
		END
	ELSE
		BEGIN
			INSERT	INTO #tmpCustomer (CustId)
			SELECT	val AS CustId
			FROM	bodb02.dbo.strSplit(@CustIdList, ',');

			SELECT	sub.custid		AS CustID
				,	sub.subaccid	AS CustSubID
				,	sub.username	AS UserName
				,	sub.username2	AS UserName2
				,	st.siteid		AS SiteID
				,	cust.site		AS 'Site'
				,	cust.roleid		AS RoleID
				,	cust.currency	AS 'CurrencyID'
				,	ex.currency		AS Currency
				,	cust.srecommend AS SRecommend
				,	cust.mrecommend AS MRecommend
				,	cust.recommend	AS Recommend
				,	sub.createdate	AS CreatedDate
			FROM #tmpCustomer AS t WITH(NOLOCK)
				INNER JOIN dbo.custSub sub WITH (NOLOCK) ON sub.custid = t.CustId
				INNER JOIN dbo.Customer cust WITH (NOLOCK) ON sub.custid = cust.custid
				INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
				INNER JOIN dbo.Site st WITH (NOLOCK) ON cust.site = st.site
			ORDER BY sub.subaccid;
		END;

END;

GO