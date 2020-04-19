/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE CTS_GetMainDbCustomerForUpdateUsername2
						 @CustIds		VARCHAR(MAX)
						,@IsGetCustSub	BIT
AS
/*
	Creator:	20191128@Harvey
	Task:		Get customer - [Redmine: #124592]
	Database:	DBTP.bodb02
	
	Revisions:
		- 20181121@Harvey:	Initial - [Redmine: #124592]
		
	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	exec CTS_GetMainDbCustomerForUpdateUsername2 '27144,27224,27227,1003,1014', 1
		
*/
BEGIN;
	SET NOCOUNT ON;

	CREATE TABLE #tmpCust (CustId BIGINT)

	INSERT INTO #tmpCust
	SELECT val
	FROM dbo.f_SplitString(@CustIds, ',')
	OPTION (MAXRECURSION 0)

	IF @IsGetCustSub = 1
	BEGIN
		SELECT sub.[custid]
			,sub.subaccid 'custsubId' 
			,sub.username
			,sub.username2
			,cust.roleid
			,st.siteid
		FROM [bodb02].[dbo].[custSub] sub WITH (NOLOCK)
			INNER JOIN #tmpCust tmpcust ON sub.subaccid = tmpcust.CustId
			INNER JOIN dbo.Customer cust WITH (NOLOCK) ON sub.custid = cust.custid
			INNER JOIN	dbo.Customer upl WITH (NOLOCK) ON cust.srecommend = upl.custid
			INNER JOIN dbo.Site st WITH (NOLOCK) ON upl.site = st.site
		WHERE cust.UserName2 IS NOT NULL
	END
	ELSE
	BEGIN
		SELECT cust.[custid]
			,cust.username
			,cust.username2
			,cust.roleid
			,st.siteid
		FROM [bodb02].[dbo].[Customer] cust WITH (NOLOCK)
			INNER JOIN #tmpCust tmpcust ON cust.custid = tmpcust.CustId
			INNER JOIN dbo.Customer upl WITH (NOLOCK) ON cust.srecommend = upl.custid
			INNER JOIN dbo.Site st WITH (NOLOCK) ON upl.site = st.site
		WHERE cust.UserName2 IS NOT NULL
	END

	DROP TABLE #tmpCust
END;
GO