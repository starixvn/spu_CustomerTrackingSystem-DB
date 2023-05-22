USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_GeneralNormalClassification_NormalPool_Clear]    Script Date: 4/26/2023 2:12:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_GeneralNormalClassification_NormalPool_Clear]
	@ListCustId		VARCHAR(MAX),
	@ScannedMaxId	BIGINT
AS
/*
	Created: 20230421@Jonas.Huynh
	Task : Insert customers to normal pool for classification
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230420@Jonas.Huynh: Created [Redmine ID: #186678]

	Param's Explanation:
		@ListCustId	 : This parameter is used to clear processed customer from normal pool
		@ScannedMaxId: This parameter is used to be as a scanned milestone to clear customer from normal pool

    Script:
        EXEC bodb_VR2Model.dbo.CTS_GeneralNormalClassification_NormalPool_Clear @ListCustId = '1,2,3',
																				@ScannedMaxId = 989347;
*/
BEGIN
	
	SET NOCOUNT ON;
	
	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers (CustId INT PRIMARY KEY);

	-- #1: Get Customers
    INSERT INTO  #tmpCustomers (CustID) 
	SELECT DISTINCT CAST(value AS INT) CustID 
	FROM STRING_SPLIT(@ListCustId, ',');

	-- #2: Clear normal pool
	IF(@ScannedMaxId IS NOT NULL)
	BEGIN
		DELETE r WITH (ROWLOCK)
		FROM dbo.CustomerClassification_NormalPool AS r
			INNER JOIN #tmpCustomers AS c ON c.CustId = r.CustId
		WHERE r.ID <= @ScannedMaxId;
	END;
	
	DROP TABLE #tmpCustomers;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Clear] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Clear] TO [bodbSPUNet]
GO