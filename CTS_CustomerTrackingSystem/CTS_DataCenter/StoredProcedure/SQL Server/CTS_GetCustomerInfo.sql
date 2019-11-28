/*<info serverAlias="DBTP-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
CREATE PROCEDURE	CTS_GetCustomerInfo
						 @maxCustId INT = 0
						,@rowSize INT = 500
AS
/*
	Creator:	20191128@Harvey
	Task:		Get customer - [Redmine: #124592]
	Database:	DBTP.bodb02
	
	Revisions:
		- 20181121@Harvey:	Initial - [Redmine: #124592]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	exec CTS_GetCustomerInfo 0,500
		
*/
BEGIN;
	SET NOCOUNT ON;

	SELECT TOP (@rowSize) cust.custid
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

END;
GO