/*<info serverAlias="DBONUSER-ON_USER" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CTS_RobotUserStatus_Get] 
		 @custId				INT
AS
/*
	Created: 20191225@HarveyNguyen
	Task : Get robot user status
	DB: [ON_USER]
	Original:

	Revisions:
		- 20191225@Harvey:	Initial - [Redmine: #126079]

	Param's Explanation:

	EXEC CTS_RobotUserStatus_Get 1397
*/
BEGIN
	SET NOCOUNT ON;

	DECLARE @isRobotUser BIT = 0;

	CREATE TABLE #tempCustomer (
		CustId INT
		,Srecommend INT
		,Mrecommend INT
		,Recommend INT
		)

	CREATE TABLE #tempCustomerAndUpLines (CustId INT)

	INSERT INTO #tempCustomer (
		CustId
		,Srecommend
		,Mrecommend
		,Recommend
		)
	SELECT cust.custid
		,cust.srecommend
		,cust.mrecommend
		,cust.recommend
	FROM bodb02.dbo.Customer cust WITH (NOLOCK)
	WHERE cust.custid = @custId

	INSERT INTO #tempCustomerAndUpLines (CustId)
	SELECT cust.custid
	FROM bodb02.dbo.Customer cust WITH (NOLOCK)
		INNER JOIN #tempCustomer tempCust ON cust.custid = tempCust.Srecommend
	UNION
	SELECT cust.custid
	FROM bodb02.dbo.Customer cust WITH (NOLOCK)
		INNER JOIN #tempCustomer tempCust ON cust.custid = tempCust.Mrecommend
	UNION
	SELECT cust.custid
	FROM bodb02.dbo.Customer cust WITH (NOLOCK)
		INNER JOIN #tempCustomer tempCust ON cust.custid = tempCust.Recommend
	UNION
	SELECT tempCust.CustId
	FROM #tempCustomer tempCust

	IF EXISTS (
			SELECT 1
			FROM #tempCustomerAndUpLines cau
				INNER JOIN dbo.RobotUsers ru WITH (NOLOCK) ON cau.CustId = ru.custid
			WHERE ru.counter > 10
			)
		SET @isRobotUser = 1;

	SELECT @custId 'CustId'
		,@isRobotUser 'IsRobotUser'

	DROP TABLE #tempCustomer;
	DROP TABLE #tempCustomerAndUpLines;


END;
GO
