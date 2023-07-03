USE [bodb_VR2Model]
GO
/****** Object:  StoredProcedure [dbo].[CTS_BySportNormalClassification_NormalPool_Clear]    Script Date: 4/26/2023 2:12:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CTS_BySportNormalClassification_NormalPool_Clear]
	@CustomersXML	XML,
	@ScannedMaxId	BIGINT
AS
/*
	Created: 20230630@Jonas.Huynh
	Task : Insert customers to normal pool for classification  by sport
	DB: bodb_VR2Model
	Original:

	Revisions:
		- 20230630@Jonas.Huynh: Created [Redmine ID: #189875]

	Param's Explanation:
		@ListCustId	 : This parameter is used to clear processed customer from normal pool
		@ScannedMaxId: This parameter is used to be as a scanned milestone to clear customer from normal pool

    Script:
        EXEC bodb_VR2Model.dbo.CTS_BySportNormalClassification_NormalPool_Clear 
		@ScannedMaxId = 989347,
		@CustomersXML = '@CustomersXML = N'<Root>
								<r CustId="5002646" SportGroup="201"/>
								<r CustId="5002646" SportGroup="201"/>
							</Root>';
																				
*/
BEGIN
	
	SET NOCOUNT ON;
	
	IF OBJECT_ID('tempdb..#tmpCustomers') IS NOT NULL
	BEGIN
		DROP TABLE	#tmpCustomers;
	END

	CREATE TABLE #tmpCustomers(
		CustId			INT,
		SportGroup		INT,
		PRIMARY KEY(CustId, SportGroup)
	);

	-- #1: Get list customers
	INSERT INTO #tmpCustomers(CustId, SportGroup)
	SELECT	T.C.value('./@CustId', 'INT')		AS CustId
		,	T.C.value('./@SportGroup', 'INT')	AS SportGroup
	FROM @CustomersXML.nodes('//r') AS T(C)
	OPTION (OPTIMIZE FOR (@CustomersXML = NULL));

	-- #2: Clear normal pool
	IF(@ScannedMaxId IS NOT NULL)
	BEGIN
		DELETE r WITH (ROWLOCK)
		FROM dbo.CustomerClassification_BySport_NormalPool AS r
			INNER JOIN #tmpCustomers AS c ON c.CustId = r.CustId AND c.SportGroup = r.SportGroup
		WHERE r.ID <= @ScannedMaxId;
	END;
	
	DROP TABLE #tmpCustomers;
END;
GO

GRANT EXECUTE ON [dbo].[CTS_BySportNormalClassification_NormalPool_Clear] TO [bodbSPUNet]
GO
GRANT VIEW DEFINITION ON [dbo].[CTS_BySportNormalClassification_NormalPool_Clear] TO [bodbSPUNet]
GO