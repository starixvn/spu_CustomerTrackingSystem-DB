USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_Realtime_UpdateLastScanTime]     Script Date: 9/1/2022 11:51:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_Realtime_UpdateLastScanTime]
AS
/*
	Created: 20220901@Jonas.Huynh
	Task : Check Customers who have data changed from a range of time
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200901@Jonas.Huynh: Created [Redmine ID: #176992]

	Param's Explanation:
		EXEC [dbo].[CTS_NormalAccountsClassification_BySport_Realtime_UpdateLastScanTime]
*/

BEGIN
	
	SET NOCOUNT ON;

	DECLARE @RealValueId	INT  = 1
		,	@BackUpValueId	SMALLINT = 2;

	DECLARE	@LastScanTime VARCHAR(200);

	SELECT @LastScanTime = [Value]
	FROM dbo.CustomerClassification_Parameter WITH (NOLOCK)
	WHERE DataId = @BackUpValueId;

	UPDATE dbo.CustomerClassification_Parameter WITH (ROWLOCK, UPDLOCK)
	SET [Value] = @LastScanTime
	WHERE DataId = @RealValueId;
END;

GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_BySport_Realtime_UpdateLastScanTime] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_BySport_Realtime_UpdateLastScanTime] TO [bodbSPUNet]
GO
