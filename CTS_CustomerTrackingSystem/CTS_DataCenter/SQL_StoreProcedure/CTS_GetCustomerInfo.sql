/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_GetCustomerInfo
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

	exec CTS_GetCustomerInfo 0,500,2
		
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE @totalRow INT = @rowSize * @numberOfBatch
			,@currentBatch TINYINT = 1

	CREATE TABLE #tempCustomer (
		 BatchId		TINYINT
		,CustId			INT
		,Username		VARCHAR(30)
		,Username2		VARCHAR(50)
		,SiteId			INT
		,Site			VARCHAR(10)
		,RoleId			TINYINT
		,CurrencyId		TINYINT
		,Currency		VARCHAR(50)
		,Srecommend		INT
		,Mrecommend		INT
		,Recommend		INT
		,CreatedDate	DATETIME
		)

	INSERT INTO #tempCustomer
	(	 CustId		
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
	SELECT TOP (@totalRow) cust.custid
		,cust.username
		,cust.username2
		,CASE WHEN cust.roleid = 1 THEN st.siteid ELSE st2.siteid END 'siteid'
		,upl.site
		,cust.roleid
		,cust.currency 'currencyid'
		,ex.currency
		,cust.srecommend
		,cust.mrecommend
		,cust.recommend
		,cust.creatdate
	FROM dbo.Customer cust WITH (NOLOCK)
		INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
		LEFT JOIN	dbo.Customer upl WITH (NOLOCK) ON cust.recommend = upl.custid
		LEFT JOIN dbo.Site st WITH (NOLOCK) ON upl.site = st.site
		LEFT JOIN dbo.Site st2 WITH (NOLOCK) ON cust.site = st2.site
	WHERE cust.custid > @maxCustId
	ORDER BY cust.custid

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