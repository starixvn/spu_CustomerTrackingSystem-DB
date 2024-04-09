/*<info serverAlias="DBVR2-bodb_VR2Model" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_Archive]    Script Date: 11/23/2022 11:48:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_Archive]
AS
/*
	Created: 20221123@Jonas.Huynh
	Task : Archive Customer Classification BySport
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20201123@Jonas.Huynh: Created
		- 20240327@Jonas.Huynh: EC2024 - Resolve Locking [Redmine ID: #200842]

	Param's Explanation:
	Example: 
		exec [dbo].[CTS_NormalAccountsClassification_BySport_Archive]
*/

BEGIN
	
	SET NOCOUNT ON;

	DECLARE @BATCHSIZE					INT		= 1000000;
	DECLARE @ROWCOUNT					INT		= 1000000;
	DECLARE @BYSPORT_LASTSCANNEDROW		TINYINT = 2;

	DECLARE @From30Date					DATE	= DATEADD(DAY, - 30, GETDATE());
	DECLARE @LastScannedRow				BIGINT;

	SELECT @LastScannedRow = CAST(CAST([Value] AS BIGINT) AS ROWVERSION) 
	FROM dbo.CustomerClassification_Parameter WITH(NOLOCK) WHERE [DataId] = @BYSPORT_LASTSCANNEDROW;

	WHILE @ROWCOUNT = @BATCHSIZE
		BEGIN
			DELETE TOP(@BATCHSIZE) c WITH(ROWLOCK)
			FROM dbo.CustomerClassification_BySport AS c
			WHERE c.[RowVersion] <= @LastScannedRow AND c.CreatedDate < @From30Date

			SET @ROWCOUNT = @@ROWCOUNT;
		END;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_BySport_Archive] TO [wsv_cts]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_BySport_Archive] TO [wsv_cts]
GO
