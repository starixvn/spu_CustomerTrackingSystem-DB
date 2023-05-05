USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_GeneralNormalClassification_NormalPool_Insert]    Script Date: 20/04/2023 11:05:2022 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_GeneralNormalClassification_NormalPool_Insert]
	@ListCustId		VARCHAR(MAX),
	@FunctionId		SMALLINT
AS
/*
	Created: 20230420@Jonas.Huynh
	Task : Insert customers to normal pool for classification
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230420@Jonas.Huynh: Created [Redmine ID: #186678]

	Param's Explanation:
        @ListCustId:	This parameter is used to insert customer into normal pool for classification
        @FunctionId:	Being used to log info, map priority

    Script:
        EXEC bodb_VR2Model.dbo.CTS_GeneralNormalClassification_NormalPool_Insert @ListCustId = '1,2,3',
                                                                                 @FunctionId = 1;
*/
BEGIN
	
	SET NOCOUNT ON;
		
	DECLARE	@CurrentTime DATETIME = GETDATE();
	DECLARE @Priority	 SMALLINT;

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers (CustID INT PRIMARY KEY);

	-- #1: Get Customers
    INSERT INTO  #tmpCustomers (CustID) 
	SELECT DISTINCT CAST(val AS INT) CustID 
	FROM bodb02.dbo.SPU_StrSplit(@ListCustId, ',');

	 -- #2: Insert Log
	INSERT INTO dbo.CustomerClassification_Log(CustId, FunctionId, CreatedTime)
	SELECT	a.CustId
		,	@FunctionId
		,	@CurrentTime
	FROM #tmpCustomers AS a;

	-- #3: Get priority by FunctionId
	SELECT @Priority = p.[Priority]
	FROM dbo.CustomerClassification_Priority AS p WITH(NOLOCK)
	WHERE p.GoupId = 1 AND p.FunctionId = @FunctionId 

	-- #4: Insert to normal pool
	INSERT INTO dbo.CustomerClassification_NormalPool(CustId, [Priority], FunctionId, CreatedTime)
	SELECT	a.CustId
		,	@Priority
		,	@FunctionId
		,	@CurrentTime
	FROM #tmpCustomers AS a
		
	DROP TABLE #tmpCustomers;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Insert] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_GeneralNormalClassification_NormalPool_Insert] TO [bodbSPUNet]
GO