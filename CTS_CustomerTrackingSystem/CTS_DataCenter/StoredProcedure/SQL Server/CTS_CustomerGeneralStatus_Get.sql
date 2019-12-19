/*<info serverAlias="DBTP-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CTS_CustomerGeneralStatus_Get] 
		 @custId				INT
AS
/*
	Created: 20190826@Harvey
	Task : Get fraud information for Customer
	DB: bodb02
	Original:

	Revisions:
		-	20190826@Harvey: init SPs						[Redmine: #119205]
		-	20190917@Harvey: Handle for CN88				[Redmine: #125693]
		-	20190917@Terry: Remove Customer Suspiciouses	[Redmine: #125693]

	Param's Explanation:

	EXEC [CTS_CustomerGeneralStatus_Get] '28625904'
*/
BEGIN
	SET NOCOUNT ON;

	SELECT	ci.custid
			,username
			,CASE 
				WHEN cs.custid IS NULL
					THEN -1
				WHEN cs.InactiveInfo > 0
					THEN 1 --Inactive
				WHEN cs.InactiveInfo = 0
					AND cs.SuspendedInfo > 0
					THEN 2 --Suspended
				WHEN cs.InactiveInfo = 0
					AND cs.SuspendedInfo = 0
					AND cs.ViewOnlyInfo > 0
					THEN 3 --ViewOnly
				ELSE 4 --Active
				END AS [cn88status] 
			,reject -- suspend (reject=1) only for MBC
			,closed -- CN88: locked (closed=1) || MBC: disabled (closed=1) active (closed=0)
			,danger -- original
			,danger2 -- Non live
			,danger3 -- Other sports
			,autosuspend -- Auto Suspend Soccer
			,autosuspend2 -- Auto Suspend Other Sports
			,Abnormal
			,CASE 
				WHEN pa.custid IS NULL
					THEN 0
				ELSE 1
				END 'ProblemAccount'
	FROM dbo.custInfo ci WITH (NOLOCK)
		LEFT JOIN dbo.CS_CustomerStatus cs WITH (NOLOCK) ON cs.custid = ci.custid
		LEFT JOIN dbo.CS_ProblemAccount pa WITH (NOLOCK) ON ci.custid = pa.custid
	WHERE ci.custid = @custId

END;