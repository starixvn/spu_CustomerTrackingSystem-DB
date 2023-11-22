GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_GeneralNormalClassification_TWGroupBetting_Preprocess]
		@ListCustId		VARCHAR(MAX)
AS
/*
	Created: 	20231030@Victoria.Le
	Task : 		Insert custIds to Normal Classification pool
	DB: 		bodb_VR2Model

	Revisions:
		- 20231030@Victoria.Le: 	Initial Writing  [Redmine ID: #195060]

	Param's Explanation:

	Example:
		
        
*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE	@FunctionId				SMALLINT = 8;

	DECLARE	@Priority				SMALLINT,
			@Priority_GroupId		TINYINT = 1,
			@Priority_ActionUnknown SMALLINT = 9999;

	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers (CustId INT PRIMARY KEY);

	-- #1: Get Customers
    INSERT INTO  #tmpCustomers (CustId) 
	SELECT DISTINCT CAST(value AS INT) CustId 
	FROM STRING_SPLIT(@ListCustId, ',');

	-- #2: Get priority
	SELECT @Priority = ISNULL(p.[Priority], @Priority_ActionUnknown)  
	FROM dbo.CustomerClassification_Priority AS p WITH(NOLOCK)
	WHERE p.GroupId = @Priority_GroupId AND p.FunctionId = @FunctionId;

	-- #3: Insert Normal Classification Pool
	EXEC dbo.CTS_GeneralNormalClassification_NormalPool_Insert @FunctionId = @FunctionId, @Priority = @Priority;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_GeneralNormalClassification_RealTime_Preprocess] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_GeneralNormalClassification_RealTime_Preprocess] TO [bodbSPUNet]
GO