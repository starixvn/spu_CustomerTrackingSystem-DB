/*<info serverAlias="DBVR2-bodb_VR2Model" executers="wsv_cts" isFunction="0" isNested="0"></info>*/
USE [bodb_VR2Model]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_NormalClassificationAgency_BetCount_Update]
	@CurrentDateTime		DATETIME
AS
/*
	Created: 20241003@Jonas.Huynh
	Task : Modify betcount schedule for Normal & Good Member
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20241003@Jonas.Huynh: Created [Redmine ID: #185799]
	
	Param's Explanation:
		
*/
BEGIN
	
	SET NOCOUNT ON;
	
	DECLARE @CATEGORY_NEW		INT	= 140100;

	DELETE a WITH(ROWLOCK)
	FROM #tmpBetCount AS a
	WHERE a.CategoryId NOT IN (@CATEGORY_NEW);

	UPDATE b WITH(ROWLOCK, UPDLOCK)
	SET		b.BetCount = a.BetCount
		,	b.LastScannedDate = @CurrentDateTime
	FROM #tmpBetCount AS a WITH(NOLOCK)
		INNER JOIN dbo.CustomerClassificationAgency_BetCount AS b ON b.CustId = a.CustId
	WHERE a.BetCount > b.BetCount;

	INSERT INTO dbo.CustomerClassificationAgency_BetCount(CustId, RoleId, BetCount, LastScannedDate)
	SELECT a.CustId, a.RoleId, a.BetCount, @CurrentDateTime
	FROM #tmpBetCount AS a WITH(NOLOCK) 
	WHERE NOT EXISTS (SELECT 1 FROM dbo.CustomerClassificationAgency_BetCount AS b WITH(NOLOCK) WHERE b.CustId = a.CustId);
END;
GO

GRANT EXECUTE ON [dbo].[CTS_NormalClassificationAgency_BetCount_Update] TO [wsv_cts]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_NormalClassificationAgency_BetCount_Update] TO [wsv_cts]
GO

