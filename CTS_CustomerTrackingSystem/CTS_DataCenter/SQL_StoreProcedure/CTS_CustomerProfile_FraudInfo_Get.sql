/*<info serverAlias="DBFS-bodb_FraudSensor" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_CustomerProfile_FraudInfo_Get] 
		 @custId				INT
AS
/*
	Created: 20191219@CaseyHuynh
	Task : GET Customer Fraud Info (Classification, FraudCases)
	DB: [bodb_FraudSensor]
	Original:

	Revisions:
		- 20191220@CaseyHuynh:	Initial - [Redmine: #125531]

	Param's Explanation:
*/
BEGIN
	SET NOCOUNT ON;

	--Return Classification---
	SELECT	sc.Custid
			, sc.IsDelinquent
			, sc.IsHedge
			, sc.IsDirty
	FROM	dbo.SuspiciousCustomer AS sc WITH (NOLOCK)
	WHERE	sc.Custid = @custId;

	--Return Classification---
	SELECT		DISTINCT fc.FraudCaseId, fc.FraudCaseName
	FROM		dbo.SuspiciousInfo	AS sc WITH (NOLOCK)
	INNER JOIN	dbo.FraudCase		AS fc WITH (NOLOCK)
				ON	sc.FraudCaseId = fc.FraudCaseId
	WHERE	sc.Custid = @custId;

END;
GO
