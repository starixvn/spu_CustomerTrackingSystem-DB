/*<info serverAlias="DBTP-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

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
	Database:	DBTP.bodb02
	
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
		 BatchId	TINYINT
		,CustId		INT
		,Username	VARCHAR(30)
		,Username2	VARCHAR(50)
		,Site		VARCHAR(10)
		,RoleId		TINYINT
		,CurrencyId TINYINT
		,Currency	VARCHAR(50)
		,Srecommend INT
		,Mrecommend INT
		,Recommend	INT
		)

	INSERT INTO #tempCustomer
	(	 CustId		
		,Username	
		,Username2	
		,Site		
		,RoleId		
		,CurrencyId 
		,Currency	
		,Srecommend 
		,Mrecommend 
		,Recommend	
	)
	SELECT TOP (@totalRow) cust.custid
		,cust.username
		,cust.username2
		,cust.site
		,cust.roleid
		,cust.currency 'currencyid'
		,ex.currency
		,cust.srecommend
		,cust.mrecommend
		,cust.recommend
	FROM dbo.Customer cust WITH (NOLOCK)
		INNER JOIN dbo.Exchange ex WITH (NOLOCK) ON cust.currency = ex.exchangeid
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
		,Site
		,RoleId
		,CurrencyId
		,Currency
		,Srecommend
		,Mrecommend
		,Recommend
	FROM #tempCustomer

END;
GO