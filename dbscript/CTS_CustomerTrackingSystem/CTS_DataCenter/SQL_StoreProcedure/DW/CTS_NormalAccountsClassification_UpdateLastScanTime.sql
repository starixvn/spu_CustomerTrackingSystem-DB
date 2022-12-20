USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_UpdateLastScanTime]    Script Date: 9/3/2020 2:19:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_UpdateLastScanTime]
	@IsGeneralCategory		BIT = 0
AS
/*
	Created: 20200901@Long.Luu
	Task : 
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20200901@Long.Luu: Created [Redmine ID: #137550]

	Param's Explanation:
*/

BEGIN
	
	SET NOCOUNT ON;

	DECLARE @RealValueId	INT  = 1
		,	@BackUpValueId	SMALLINT = 2;

	DECLARE	@LastScanTime DATETIME;

	IF (@IsGeneralCategory = 1)
	BEGIN
		SET @RealValueId = 3
		SET @BackUpValueId = 4;
	END;

	SELECT @LastScanTime = [Value]
	FROM dbo.CustomerClassification_Parameter WITH (NOLOCK)
	WHERE DataId = @BackUpValueId;

	UPDATE dbo.CustomerClassification_Parameter WITH (ROWLOCK, UPDLOCK)
	SET [Value] = @LastScanTime
	WHERE DataId = @RealValueId;
END;

