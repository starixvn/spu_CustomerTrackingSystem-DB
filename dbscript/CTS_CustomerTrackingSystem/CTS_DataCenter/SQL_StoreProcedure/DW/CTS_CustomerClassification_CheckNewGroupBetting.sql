/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_CustomerClassification_CheckNewGroupBetting]
		@custIdList			VARCHAR(MAX) = ''
AS
/*
	Created: 	20231030@Victoria.Le
	Task : 		New category/CC for new TW group betting detect
	DB: 		bodb_VR2Model
	Original:	
	Revisions:
		- 20231030@Victoria.Le: 	Initial Writing  [Redmine ID: #195060]

*/
BEGIN
	
	SET NOCOUNT ON;
	
	IF OBJECT_ID('tempdb..#tmpCustomer') IS NOT NULL
	BEGIN
		DROP TABLE #tmpCustomer;
	END;

	CREATE TABLE #tmpCustomer (CustId INT NOT NULL PRIMARY KEY);
	
	IF OBJECT_ID('tempdb..#tmpCustomerGroupBetting') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomerGroupBetting;
	END;

	CREATE TABLE #tmpCustomerGroupBetting (
			CustId				INT PRIMARY KEY	
		,	GBTicketCount		INT 
		,	SportType			INT
		,	JobScannedType		TINYINT		
	);
	
	INSERT INTO #tmpCustomer(CustId)
	SELECT ssk.value
	FROM STRING_SPLIT(@custIdList, ',') ssk;
	
	INSERT INTO #tmpCustomerGroupBetting (CustId, GBTicketCount, SportType, JobScannedType)
	SELECT cs.CustId, cs.GBTicketCount, cs.SportType, cs.JobScannedType
	FROM #tmpCustomer AS c
		INNER JOIN dbo.CustomerClassification_ScannedNewCust AS cs WITH (NOLOCK) ON cs.CustId = c.CustId
	WHERE cs.JobScannedType > 0;
	
	UPDATE cs WITH (UPDLOCK, ROWLOCK)
	SET 	cs.IsServiceScanned = (CASE WHEN cgb.CustId IS NOT NULL THEN 1 ELSE 0 END)
		,	cs.LastServiceScannedTime = GETDATE()
	FROM dbo.CustomerClassification_ScannedNewCust AS cs
		LEFT JOIN #tmpCustomer AS c ON c.CustId = cs.CustId
		LEFT JOIN #tmpCustomerGroupBetting AS cgb ON cgb.CustId = cs.CustId
	;
	
	SELECT 	cgb.CustId AS 'CustID'
		,	9 AS 'TaggingID'
		,	2 AS 'TaggingType'
		,	cgb.GBTicketCount AS 'First5TWGBTicketCount'
		,	cgb.SportType AS 'SportType'
	FROM #tmpCustomerGroupBetting AS cgb
	WHERE cgb.JobScannedType = 2;
	
	DROP TABLE IF EXISTS #tmpCustomer;
	DROP TABLE IF EXISTS #tmpCustomerGroupBetting;
	
END;