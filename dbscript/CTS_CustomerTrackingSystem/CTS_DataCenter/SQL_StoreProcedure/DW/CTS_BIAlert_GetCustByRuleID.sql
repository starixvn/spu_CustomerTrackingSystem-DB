/*<info serverAlias="DBVR2-bodb_VR2Model" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
USE [bodb_VR2Model]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_BIAlert_GetCustByRuleID]
		@RuleID					INT
	,	@CaptureDate			DATE
	,	@BatchSize				INT = 5
    ,	@TotalCust              INT 	OUTPUT
	,	@FromDate               DATE 	OUTPUT
	,	@ToDate                 DATE 	OUTPUT
AS
/*
	Created: 20251128@Thomas.Nguyen
	Task : Get Cust By Rule ID
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20251128@Thomas.Nguyen : Created [Redmine ID: #243564]

	Param's Explanation:

	Example:
		DECLARE @TotalCust INT
			,	@FromDate DATE
			,	@ToDate DATE 
	EXEC CTS_BIAlert_GetCustByRuleID_xpre @RuleID = 1, @CaptureDate = '2025-11-25',@BatchSize = 5, @TotalCust = @TotalCust OUTPUT, @FromDate = @FromDate OUTPUT, @ToDate = @ToDate OUTPUT;

	SELECT @TotalCust, @FromDate, @ToDate;

*/
BEGIN
	
	SET NOCOUNT ON;

	CREATE TABLE #Temp_Cust(
		CustID INT
	);

	INSERT INTO #Temp_Cust(CustID)
	SELECT TOP(@BatchSize) ar.CustID
	FROM dbo.AlertSystem_ResultOutput AS ar WITH(NOLOCK)
	WHERE ar.RuleID = @RuleID AND ar.CaptureDate = @CaptureDate
	ORDER BY ar.HouseWL ASC;

	SELECT	@TotalCust = COUNT(DISTINCT CustID)
		,	@FromDate = MIN(ar.FromDate)
		,	@ToDate = MAX(ar.ToDate)
	FROM dbo.AlertSystem_ResultOutput AS ar WITH(NOLOCK)
	WHERE ar.RuleID = @RuleID AND ar.CaptureDate = @CaptureDate;

	SELECT	tmp.CustID
		,	cus.UserName
	FROM #Temp_Cust AS tmp
		INNER JOIN bodb02.dbo.Customer AS cus WITH(NOLOCK) ON tmp.CustID = cus.CustID;

END;
