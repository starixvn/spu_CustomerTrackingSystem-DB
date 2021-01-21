/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_Customer_GetNewCustomerInfo
		@LastCustId INT = 0
	,	@rowSize INT = 500
AS
/*
	Creator:	20200118@Casey.Huynh
	Task:		Get New customer - [Redmine: #148849]
	Database:	DBCTS.bodb02
	
	Revisions:
		-2020018@Casey.Huynh:Created [Redmine ID: 148849]

	Developer's Notes:
		

	exec CTS_Customer_GetNewCustomerInfo 10, 10
		
*/
BEGIN;
	SET NOCOUNT ON;

	DECLARE @custIDList VARCHAR(MAX);

	
	SELECT  TOP (@rowSize) @custIDList = COALESCE(@custIDList + ',', '') +  CONVERT(VARCHAR(10),c.CustID)
	FROM	dbo.Customer AS c WITH(NOLOCK)
	WHERE	c.CustID > @LastCustId;

	EXEC CTS_Customer_GetInfoByCustIdList @custIDList
END;
GO