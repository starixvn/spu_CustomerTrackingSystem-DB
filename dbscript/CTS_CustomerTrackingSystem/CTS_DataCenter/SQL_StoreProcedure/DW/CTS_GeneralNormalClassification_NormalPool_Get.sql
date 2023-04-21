USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_GeneralNormalClassification_NormalPool_Get]    Script Date: 20/04/2023 11:05:2022 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_GeneralNormalClassification_NormalPool_Get]
	@ScannedMaxId BIGINT OUTPUT
AS
/*
	Created: 20230420@Jonas.Huynh
	Task : Insert customers to normal pool for classification
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230420@Jonas.Huynh: Created [Redmine ID: #186678]

	Param's Explanation:
		@ScannedMaxId: This parameter is used to output scanned MaxID

    Script:
		DECLARE @output BIGINT
        EXEC bodb_VR2Model.dbo.CTS_GeneralNormalClassification_NormalPool_Get @ScannedMaxId = @output;
*/
BEGIN
	
	SET NOCOUNT ON;
		
	DECLARE	@BatchSize INT = 20000;

	IF	OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	DROP TABLE	#tmpCustomers;

	CREATE TABLE #tmpCustomers(
		CustId	   INT  PRIMARY KEY
	);

	-- #1: Get Scanned MaxID
	SELECT @ScannedMaxId = MAX(c.ID)
	FROM dbo.CustomerClassification_NormalPool AS c WITH(NOLOCK)

	-- #2: Get top customers by priority
	IF(@ScannedMaxId IS NOT NULL)
	BEGIN
		INSERT INTO #tmpCustomers(CustId)
		SELECT DISTINCT TOP(@BatchSize) b.CustId
		FROM (
				SELECT c.CustId, ROW_NUMBER() OVER(PARTITION BY c.CustId ORDER BY c.[Priority] ASC) AS RowNum
				FROM dbo.CustomerClassification_NormalPool AS c WITH(NOLOCK)
				WHERE c.ID <= @ScannedMaxId
			 ) AS b
		WHERE b.RowNum = 1;
	END

	-- #3: Return dataset
	SELECT CustId AS CustIds
	FROM #tmpCustomers
	
	DROP TABLE #tmpCustomers;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Get] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Get] TO [bodbSPUNet]
GO