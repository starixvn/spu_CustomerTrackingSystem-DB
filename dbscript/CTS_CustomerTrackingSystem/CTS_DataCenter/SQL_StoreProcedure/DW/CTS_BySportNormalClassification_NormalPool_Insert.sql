USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_BySportNormalClassification_NormalPool_Insert]    Script Date: 30/06/2023 11:05:2022 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_BySportNormalClassification_NormalPool_Insert]
		@FunctionId		SMALLINT,
		@Priority		SMALLINT
AS
/*
	Created: 20230630@Jonas.Huynh
	Task : Insert customers to normal pool for classification by sport
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230630@Jonas.Huynh: Created [Redmine ID: #189875]

	Param's Explanation:
        @FunctionId		: Being used to log particular function
		@Priority		: Being used to prioritize group functions
    Script:
        EXEC bodb_VR2Model.dbo.CTS_BySportNormalClassification_NormalPool_Insert @FunctionId = 1, @Priority = 1;
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE	@CurrentTime DATETIME = GETDATE();

	 -- #1: Insert Log
	INSERT INTO dbo.CustomerClassification_BySport_Log(CustId, SportGroup, FunctionId, CreatedTime)
	SELECT	a.CustId
		,	a.SportGroup
		,	@FunctionId
		,	@CurrentTime
	FROM #tmpCustomers AS a;

	-- #2: Insert to normal pool
	INSERT INTO dbo.CustomerClassification_BySport_NormalPool(CustId, SportGroup, [Priority], FunctionId, CreatedTime)
	SELECT	a.CustId
		,	a.SportGroup
		,	@Priority
		,	@FunctionId
		,	@CurrentTime
	FROM #tmpCustomers AS a
		
	DROP TABLE #tmpCustomers;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_BySportNormalClassification_NormalPool_Insert] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_BySportNormalClassification_NormalPool_Insert] TO [bodbSPUNet]
GO