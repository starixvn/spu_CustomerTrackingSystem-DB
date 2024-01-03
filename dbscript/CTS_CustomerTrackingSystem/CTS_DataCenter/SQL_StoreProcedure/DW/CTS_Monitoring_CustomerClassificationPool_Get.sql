USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_Monitoring_CustomerClassificationPool_Get]    ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_Monitoring_CustomerClassificationPool_Get]
	@GeneralPoolCount BIGINT OUTPUT,
	@BySportPoolCount BIGINT OUTPUT
AS
/*
	Created: 20240102@Jonas.Huynh
	Task : Enhance job monitoring
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20240102@Jonas.Huynh: Created [Redmine ID: #197999]

	Param's Explanation:

    Script:
        EXEC bodb_VR2Model.dbo.[CTS_Monitoring_CustomerClassificationPool_Get];
*/
BEGIN
	
	SET NOCOUNT ON;

	SELECT @NextScannedDateTime = COUNT(1)
	FROM [dbo].[CustomerClassification_NormalPool] WITH (NOLOCK);
	
	SELECT @BySportPoolCount = COUNT(1)
	FROM [dbo].[CustomerClassification_BySport_NormalPool] WITH (NOLOCK);
END;
GO

GRANT EXECUTE ON [dbo].[CTS_Monitoring_CustomerClassificationPool_Get] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_Monitoring_CustomerClassificationPool_Get] TO [bodbSPUNet]
GO