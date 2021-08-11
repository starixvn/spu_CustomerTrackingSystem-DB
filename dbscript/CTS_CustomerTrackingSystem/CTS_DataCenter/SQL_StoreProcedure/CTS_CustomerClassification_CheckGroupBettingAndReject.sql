/*<info serverAlias="DBCTS-bodb02" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_CustomerClassification_CheckGroupBettingAndReject]
	@custIdList			VARCHAR(MAX) = ''
AS
/*
	Created: 20210722@Harvey.Nguyen
	Task : New categories/CC for TW group betting detection
	DB: bodb02
	Original:

	Revisions:
		- 20210722@Harvey.Nguyen: Created [Redmine ID: #155956]

	Param's Explanation:
*/
BEGIN
	
	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#tmpCustomerClassification') IS NOT NULL
	BEGIN
		DROP TABLE	CustomerClassification;
	END;

	CREATE TABLE #tmpCustomerClassification (
			CustId				INT NOT NULL PRIMARY KEY		
		,	CateId				TINYINT NULL
		,	TWBetCount			INT		NULL
		,	TWGroupBettingRate	MONEY	NULL
		,	TWTicketRejectRate	MONEY	NULL
		,	TWDesktopUsageRate	MONEY	NULL
	);	

	INSERT INTO #tmpCustomerClassification(CustId)
	SELECT	val AS CustId
	FROM	bodb02.dbo.strSplit(@custIdList, ',');
	
	UPDATE cc
	SET cc.CateId = 8
		, cc.TWDesktopUsageRate = lup.DesktopPer
		, cc.TWTicketRejectRate = lup.RejectPer
	FROM #tmpCustomerClassification cc
	INNER JOIN dbo.LicUserProfile lup WITH (NOLOCK) ON cc.CustId = lup.CustId
	WHERE lup.ParlayPer IS NULL
		AND lup.DesktopPer > 90
		AND lup.RejectPer >= 30;

	UPDATE cc
	SET cc.CateId = 7
		, cc.TWBetCount = lup.TotalBetCount
		, cc.TWGroupBettingRate = lup.GroupBettingPer
	FROM #tmpCustomerClassification cc
	INNER JOIN dbo.LicUserProfile lup WITH (NOLOCK) ON cc.CustId = lup.CustId
	WHERE cc.CateId IS NULL
		AND lup.ParlayPer IS NULL
		AND (
			lup.TotalBetCount <= 30
			AND lup.GroupBettingPer >= 6
			OR lup.TotalBetCount > 30
			AND lup.GroupBettingPer >= 2
			);

	SELECT CustId AS 'CustID'
		,CateId AS 'TaggingID'
		,2 AS 'TaggingType'
		,TWBetCount			
		,TWGroupBettingRate	
		,TWTicketRejectRate	
		,TWDesktopUsageRate	
	FROM #tmpCustomerClassification


END;

