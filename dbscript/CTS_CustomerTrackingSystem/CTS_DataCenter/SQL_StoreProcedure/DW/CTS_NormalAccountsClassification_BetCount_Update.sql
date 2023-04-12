USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_NormalAccountsClassification_BetCount_Update]    Script Date: 03/04/2023 14:24:2022 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_NormalAccountsClassification_BetCount_Update]
	@CurrentDateTime		DATETIME,
	@IsGeneralFlow			BIT
AS
/*
	Created: 20230403@Jonas.Huynh
	Task : Modify betcount schedule for Normal & Good Member
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230403@Jonas.Huynh: Modify betcount schedule for Normal & Good Member [Redmine ID: #185633]

	Param's Explanation:
		
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @GENERAL_SPORTID		SMALLINT = 200;
	DECLARE @CATEGORY_NORMALMEMBER	INT		 = 202
		,	@CATEGORY_GOODMEMBER	INT		 = 205;

	IF (@IsGeneralFlow = 1)
		BEGIN
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET		b.BetCount = a.BetCount
				,	b.LastScannedDate = @CurrentDateTime
			FROM #tmpBetCount AS a WITH(NOLOCK)
				INNER JOIN dbo.CustomerClassification_BetCount AS b ON b.CustId = a.CustId
			WHERE a.CategoryId IN (@CATEGORY_NORMALMEMBER, @CATEGORY_GOODMEMBER)

			INSERT INTO dbo.CustomerClassification_BetCount(CustId, SportId, BetCount, LastScannedDate)
			SELECT a.CustId, @GENERAL_SPORTID, a.BetCount, @CurrentDateTime
			FROM #tmpBetCount AS a WITH(NOLOCK)
			WHERE a.CategoryId IN (@CATEGORY_NORMALMEMBER, @CATEGORY_GOODMEMBER)
				AND NOT EXISTS 
				( 
					SELECT a.CustId 
					FROM #tmpBetCount AS a
						INNER JOIN dbo.CustomerClassification_BetCount AS b WITH(NOLOCK) ON b.CustId = a.CustId
				);
		END;
	ELSE
		BEGIN
			UPDATE b WITH(ROWLOCK, UPDLOCK)
			SET		b.BetCount = a.BetCount
				,	b.LastScannedDate = @CurrentDateTime
			FROM #tmpBetCount AS a WITH(NOLOCK)
				INNER JOIN dbo.CustomerClassification_BySport_BetCount AS b ON b.CustId = a.CustId AND b.SportId = a.SportId
			WHERE a.CategoryId IN (@CATEGORY_NORMALMEMBER, @CATEGORY_GOODMEMBER)

			INSERT INTO dbo.CustomerClassification_BySport_BetCount(CustId, SportId, BetCount, LastScannedDate)
			SELECT a.CustId, a.SportId, a.BetCount, @CurrentDateTime
			FROM #tmpBetCount AS a WITH(NOLOCK)
			WHERE a.CategoryId IN (@CATEGORY_NORMALMEMBER, @CATEGORY_GOODMEMBER)
				AND NOT EXISTS 
				( 
					SELECT a.CustId, a.SportId 
					FROM #tmpBetCount AS a
						INNER JOIN dbo.CustomerClassification_BySport_BetCount AS b WITH(NOLOCK) ON b.CustId = a.CustId AND b.SportId = a.SportId
				);
		END;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_NormalAccountsClassification_BetCount_Update] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalAccountsClassification_BetCount_Update] TO [bodbSPUNet]
GO

