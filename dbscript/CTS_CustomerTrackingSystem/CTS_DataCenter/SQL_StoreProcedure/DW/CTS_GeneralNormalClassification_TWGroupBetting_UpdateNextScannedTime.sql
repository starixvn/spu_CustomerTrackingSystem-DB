GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_GeneralNormalClassification_TWGroupBetting_UpdateNextScannedTime]
		@NextScannedDateTime DATETIME2 OUTPUT
AS
/*
	Created: 	20231030@Victoria.Le
	Task : 		Update TWGroupBetting NextScannedTime
	DB: 		bodb_VR2Model
	Original:	
	Revisions:
		- 20231030@Victoria.Le: 	Initial Writing  [Redmine ID: #195060]

*/
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @LastJobScannedTime_ParamId TINYINT = 7;
	DECLARE	@LastJobScannedTime DATETIME2;

	SELECT @LastJobScannedTime = CONVERT(DATETIME2, [Value], 121)
	FROM dbo.CustomerClassification_Parameter WITH(NOLOCK)
	WHERE DataId = @LastJobScannedTime_ParamId;

	IF (@NextScannedDatetime IS NOT NULL AND @NextScannedDatetime > @LastJobScannedTime)
		BEGIN
			UPDATE dbo.CustomerClassification_Parameter WITH(ROWLOCK, UPDLOCK)
			SET [Value] = CONVERT(VARCHAR(200), @NextScannedDateTime)
			WHERE DataId = @LastJobScannedTime_ParamId;

		END;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_GeneralNormalClassification_TWGroupBetting_UpdateNextScannedTime] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_GeneralNormalClassification_TWGroupBetting_UpdateNextScannedTime] TO [bodbSPUNet]
GO