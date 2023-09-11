/*<info serverAlias="DBVR2-bodb_VR2Model" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_GeneralNormalClassification_NormalPool_Get]    Script Date: 20/04/2023 11:05:2022 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_GeneralNormalClassification_NormalPool_Get]
	@ScannedMaxId BIGINT OUTPUT
AS
/*
	Created: 20230420@Jonas.Huynh
	Task : Insert customers to normal pool for classification
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230420@Jonas.Huynh: Created [Redmine ID: #186678]
		- 20230816@Jonas.Huynh: Tagging Classification [Redmine ID: #191400]
	
	Param's Explanation:
		@ScannedMaxId: This parameter is used to output scanned MaxID

    Script:
		DECLARE @output BIGINT
        EXEC bodb_VR2Model.dbo.CTS_GeneralNormalClassification_NormalPool_Get @ScannedMaxId = @output;
*/
BEGIN
	
	SET NOCOUNT ON;
		
	DECLARE	@BatchSize INT = 20000;

	DECLARE @FunctionId_Realtime	   TINYINT = 1,
			@FunctionId_ScanTagging    TINYINT = 100;

	DECLARE @ScanTaggingType_NotExist  TINYINT = 0,
			@ScanTaggingType_Exist	   TINYINT = 1,
			@ScanTaggingType_ExistOnly TINYINT = 2;

	IF	OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	DROP TABLE	#tmpCustomers;

	CREATE TABLE #tmpCustomers(
		Id					BIGINT PRIMARY KEY IDENTITY(1,1),
		CustId				INT UNIQUE NOT NULL,
		IsCheckBetCount		BIT DEFAULT(0),
		ScanTaggingType  	TINYINT DEFAULT(0)
	);

	-- #1: Get Scanned MaxID
	SELECT @ScannedMaxId = MAX(c.ID)
	FROM dbo.CustomerClassification_NormalPool AS c WITH(NOLOCK);

	-- #2: Get top customers by priority
	IF(@ScannedMaxId IS NOT NULL)
	BEGIN
		INSERT INTO #tmpCustomers(CustId, IsCheckBetCount, ScanTaggingType)
		SELECT TOP(@BatchSize) c.CustId,
			   CASE WHEN SUM(CASE WHEN c.FunctionId = @FunctionId_ScanTagging THEN @FunctionId_Realtime ELSE c.FunctionId END) = (COUNT(c.CustId) * @FunctionId_Realtime) THEN 1 ELSE 0 END,
			   CASE WHEN SUM(c.FunctionId) = (COUNT(c.CustId) * @FunctionId_ScanTagging) THEN @ScanTaggingType_ExistOnly 
					WHEN SUM(CASE WHEN c.FunctionId = @FunctionId_ScanTagging THEN @FunctionId_ScanTagging ELSE 0 END) > 1 THEN @ScanTaggingType_Exist 
					ELSE @ScanTaggingType_NotExist END
		FROM dbo.CustomerClassification_NormalPool AS c WITH(NOLOCK)
		WHERE c.ID <= @ScannedMaxId
			AND NOT EXISTS (SELECT 1 FROM dbo.CustomerClassification AS cc WITH (NOLOCK) WHERE cc.IsApplied = 0 AND cc.CustId = c.CustId)
		GROUP BY c.CustId
		ORDER BY Min(c.Priority) ASC, Min(c.ID) ASC;
	END

	-- #3: Return dataset
	SELECT CustId			 AS CustId, 
		   IsCheckBetCount	 AS IsCheckBetCount,
		   ScanTaggingType   AS ScanTaggingType
	FROM #tmpCustomers;
	
	DROP TABLE #tmpCustomers;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Get] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Get] TO [bodbSPUNet]
GO