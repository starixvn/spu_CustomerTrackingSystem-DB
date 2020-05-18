/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_CustomerGeneralStatus_Get] 
		 @custIds				VARCHAR(MAX)
AS
/*
	Created: 20190826@Harvey
	Task : Get fraud information for Customer
	DB: bodb02
	Original:

	Revisions:
		-	20190826@Harvey: init SPs											[Redmine: #119205]
		-	20190917@Harvey: Handle for CN88									[Redmine: #125693]
		-	20190917@Terry: Remove Customer Suspiciouses						[Redmine: #125693]
		-	20191223@Harvey: Get Bet Restriction, smart punter information		[Redmine: #125693]
		 

	Param's Explanation:

	EXEC [CTS_CustomerGeneralStatus_Get] '888234'
*/
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #tmpCustomers (CustId INT)

	INSERT INTO #tmpCustomers(CustId)
	SELECT val FROM dbo.f_SplitString(@custIds,',')
	OPTION (maxrecursion 0);

	SELECT	ci.custid
			,ci.username
			,cusSite.isLicensee
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
			,closed -- CN88: locked (closed=1) || MBC: closed (closed=1) Open (closed=0)
			,ci.Enabled -- MBC: = 0 Disabled
			,danger -- original
			,danger2 -- Non live
			,danger3 -- Other sports
			,autosuspend -- Auto Suspend Soccer
			,autosuspend2 -- Auto Suspend Other Sports
			,Abnormal
			,CASE 
				WHEN pa.custid IS NOT NULL AND pa.MaxBet IS NULL
					THEN 1
				ELSE 0
				END 'ProblemAccountWithoutBetLimit'
			,CASE 
				WHEN pa.custid IS NOT NULL AND pa.MaxBet IS NOT NULL
					THEN 1
				ELSE 0
				END 'ProblemAccountWithBetLimit'
			,CASE 
				WHEN brcust.CustID IS NOT NULL
					THEN 1
				ELSE 0
				END 'BetRestrictedAccount'
			,CASE 
				WHEN brcur.ExchangeID IS NOT NULL AND brcust.CustID IS NULL AND brsite.SiteID IS NULL
					THEN 1
				ELSE 0
				END 'BetRestrictedCurrency'
			,CASE 
				WHEN brsite.SiteID IS NOT NULL AND brcust.CustID IS NULL AND brcur.ExchangeID IS NULL
					THEN 1
				ELSE 0
				END 'BetRestrictedSite'
			,CASE 
				WHEN brsite.SiteID IS NOT NULL AND brcur.ExchangeID IS NOT NULL AND brcust.CustID IS NULL
					THEN 1
				ELSE 0
				END 'BetRestrictedSiteAndCurrency'
			,CASE 
				WHEN spl.custid IS NOT NULL
					THEN 1
				ELSE 0
				END 'SmartPunter'
	FROM dbo.custInfo ci WITH (NOLOCK)
		INNER JOIN #tmpCustomers tcust WITH (NOLOCK) ON ci.custid = tcust.CustId
		INNER JOIN dbo.Customer cus WITH (NOLOCK) ON ci.srecommend = cus.custid
		LEFT JOIN dbo.Site cusSite WITH (NOLOCK) ON cus.site = cusSite.site
		LEFT JOIN dbo.CS_CustomerStatus cs WITH (NOLOCK) ON cs.custid = ci.custid
		LEFT JOIN dbo.CS_ProblemAccount pa WITH (NOLOCK) ON ci.custid = pa.custid
		LEFT JOIN dbo.BetRestriction_Customer brcust WITH (NOLOCK) ON ci.custid = brcust.CustID
		LEFT JOIN dbo.BetRestriction_Currency  brcur WITH (NOLOCK) ON ci.currency = brcur.ExchangeID
		LEFT JOIN dbo.BetRestriction_Site brsite WITH (NOLOCK) ON cusSite.siteid = brsite.SiteID
		LEFT JOIN dbo.SmartPunterList spl WITH (NOLOCK) ON ci.custid = spl.custid

END;
