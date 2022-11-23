USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BySport_Archive]    Script Date: 11/23/2022 11:48:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_NormalAccountsClassification_BySport_Archive]
AS
/*
	Created: 20221123@Jonas.Huynh
	Task : Archive Customer Classification BySport
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20201123@Jonas.Huynh: Created

	Param's Explanation:
	Example: 
		exec [dbo].[CTS_NormalAccountsClassification_BySport_Archive]
*/

BEGIN
	
	SET NOCOUNT ON;

	DECLARE @From30Date		DATE = DATEADD(DAY, - 30, GETDATE());
	DECLARE @BatchSize		INT = 1000000
		,	@RowCount		INT = 1000000;

	WHILE @RowCount = @BatchSize
		BEGIN
			DELETE TOP(@BatchSize) c WITH(ROWLOCK)
			FROM dbo.CustomerClassification_BySport AS c
			WHERE c.IsApplied = 1 AND c.CreatedDate < @From30Date

			SET @RowCount = @@ROWCOUNT;
		END;
END;

GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_BySport_Archive] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_BySport_Archive] TO [bodbSPUNet]
GO
