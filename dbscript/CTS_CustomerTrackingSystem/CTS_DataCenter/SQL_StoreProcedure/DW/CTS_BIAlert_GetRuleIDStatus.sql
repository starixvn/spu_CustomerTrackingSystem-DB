/*<info serverAlias="DBVR2-bodb_VR2Model" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
USE [bodb_VR2Model]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_BIAlert_GetRuleIDStatus]
	    @RuleID					INT
	,   @CheckDate				DATE
AS
/*
	Created: 20251128@Thomas.Nguyen
	Task : Get Rule ID Status
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20251128@Thomas.Nguyen : Created [Redmine ID: #243564]

	Param's Explanation:
        StatusID: 0 - Running, 1 - Success, 2 - Failed
	Example:
		EXEC CTS_BIAlert_GetRuleIDStatus @RuleID = 1, @CheckDate = '2025-11-25';

*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @RuleIDStatus BIT = 0;

	IF EXISTS (
		SELECT TOP 1 1 
		FROM dbo.AlertSystem_DataRuleStatus WITH(NOLOCK) 
		WHERE RuleID = @RuleID AND StatusID = 1 
            AND ((FinishTime >= @CheckDate AND FinishTime < DATEADD(DAY, 1, @CheckDate)) OR FinishTime > @CheckDate)
	)
	BEGIN
		SET @RuleIDStatus = 1;
	END;

	SELECT @RuleIDStatus AS RuleIDStatus;
END;
