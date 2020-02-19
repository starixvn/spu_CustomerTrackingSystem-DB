/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_GetCustSubInfo
						 @maxCustId INT = 0
						,@rowSize INT = 500
						,@numberOfBatch INT = 1
AS
/*
	Creator:	20191128@Harvey
	Task:		Get customer - [Redmine: #124592]
	Database:	DBCTS.bodb02
	
	Revisions:
		- 20181121@Harvey:	Initial - [Redmine: #124592]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	exec CTS_GetCustSubInfo 0,500,2
		
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE @totalRow INT = @rowSize * @numberOfBatch
			,@currentBatch TINYINT = 1

	CREATE TABLE #tempCustomer (
		 BatchId	TINYINT
		,CustId		INT
		,CustSubId	INT
		,Username	VARCHAR(30)
		,Username2	VARCHAR(50)
		,SiteId			INT
		,Site		VARCHAR(10)
		,RoleId		TINYINT
		,CurrencyId TINYINT
		,Currency	VARCHAR(50)
		,Srecommend INT
		,Mrecommend INT
		,Recommend	INT
		,CreatedDate	DATETIME
		)

	INSERT INTO #tempCustomer
	(	 CustId		
		,CustSubId
		,Username	
		,Username2
		,SiteId
		,Site		
		,RoleId		
		,CurrencyId 
		,Currency	
		,Srecommend 
		,Mrecommend 
		,Recommend	
		,CreatedDate
	)
	SELECT TOP (@totalRow) sub.custid
		,sub.subaccid
		,sub.username
		,sub.username2
		,st.siteid
		,upl.site
		,cust.roleid
		,cust.currency 'currencyid'
		,ex.currency
		,cust.srecommend
		,cust.mrecommend
		,cust.recommend
		,sub.createdate
	FROM dbo.custSub sub WITH (NOLOCK)
		INNER JOIN dbo.Customer cust WITH (NOLOCK) ON sub.custid = cust.custid
		INNER JOIN	dbo.Customer upl WITH (NOLOCK) ON cust.srecommend = upl.custid
		INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
		INNER JOIN dbo.Site st WITH (NOLOCK) ON cust.site = st.site
	WHERE sub.subaccid > @maxCustId
	ORDER BY sub.subaccid

	WHILE @currentBatch <= @numberOfBatch
	BEGIN	
		UPDATE TOP (@rowSize) tcust
		SET BatchId = @currentBatch
		FROM #tempCustomer tcust
		WHERE BatchId IS NULL

		SET @currentBatch += 1		
	END

	SELECT BatchId
		,CustId
		,CustSubId
		,Username
		,Username2
		,SiteId
		,Site
		,RoleId
		,CurrencyId
		,Currency
		,Srecommend
		,Mrecommend
		,Recommend
		,CreatedDate
	FROM #tempCustomer

END;
GO