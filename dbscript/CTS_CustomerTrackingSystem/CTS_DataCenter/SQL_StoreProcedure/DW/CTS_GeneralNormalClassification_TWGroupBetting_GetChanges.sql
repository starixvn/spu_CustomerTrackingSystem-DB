GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_GeneralNormalClassification_TWGroupBetting_GetChanges]
		@NextScannedDateTime DATETIME2 OUTPUT
AS
/*
	Created: 	20231030@Victoria.Le
	Task : 		Get List Custs to classify New Group Betting - CC2300
	DB: 		bodb_VR2Model
	Original:	
	Revisions:
		- 20231030@Victoria.Le: 	Initial Writing  [Redmine ID: #195060]

*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @BatchSize INT = 20000;
	DECLARE	@LastJobScannedTime DATETIME2;
	DECLARE	@MaxServiceScannedTime DATETIME2;
	DECLARE @LastJobScannedTime_ParamId TINYINT = 7;
	
	IF	OBJECT_ID('tempdb..#tmpCustScanned') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustScanned;
	END;

	CREATE TABLE #tmpCustScanned(
			CustId		  			INT PRIMARY KEY
		,	LastJobScannedTime		DATETIME
	);
	
	-- Get Last Job Scanned Datetime
	SELECT @LastJobScannedTime = CONVERT(DATETIME2, [Value], 121)
	FROM dbo.CustomerClassification_Parameter WITH(NOLOCK)
	WHERE DataId = @LastJobScannedTime_ParamId;
	
	INSERT INTO #tmpCustScanned (CustId, LastJobScannedTime)
	SELECT TOP(@BatchSize) cs.CustId, cs.LastJobScannedTime
	FROM dbo.CustomerClassification_ScannedNewCust AS cs WITH (NOLOCK)
	WHERE cs.LastJobScannedTime >= @LastJobScannedTime 
		AND cs.IsServiceScanned = 0
	ORDER BY cs.LastJobScannedTime ASC;
	
	SELECT @MaxServiceScannedTime = MAX(LastJobScannedTime) FROM #tmpCustScanned;
	
	SET @NextScannedDateTime = ISNULL(@MaxServiceScannedTime,@LastJobScannedTime);

	SELECT CustId
	FROM #tmpCustScanned;

	DROP TABLE IF EXISTS #tmpCustScanned;
	
END;