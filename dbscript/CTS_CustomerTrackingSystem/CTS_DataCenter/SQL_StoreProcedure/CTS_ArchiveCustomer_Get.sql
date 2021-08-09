/*<info serverAlias="DB05-bodb_Customer" executers="bodbSPUNet" viewers="" isFunction="0" isNested="0"></info>*/
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO
ALTER PROCEDURE	CTS_ArchiveCustomer_Get
		@lastArchiveDate	DATETIME
	,	@lastCustId			INT UNSIGNED
	,	@rowSize			INT = 500
    ,	@custType			TINYINT
AS
/*
	Creator:	20210205@CaseyHuynh
	Task:		Get updated Customer_History [Redmine ID: 149941]
	Database:	bodb_CustHistory
	
	Revisions:
		- 20210205@CaseyHuynh: Created [Redmine ID: 149941]

	Developer's Notes:
		- @Example:			NULL		- Explaination [DEFAULT]

	EXEC CTS_ArchiveCustomer_Get '2021-02-03 03:35:51.810',100,150,1	

*/
BEGIN;
	SET NOCOUNT ON;
	DECLARE	@rowCount		INT;
	DECLARE	@maxArchiveDate	DATETIME;
	DECLARE @custIdList		VARCHAR(MAX);

	IF	OBJECT_ID('tempdb..#tmpArchivedCustomers') IS NOT NULL
		DROP TABLE	#tmpArchivedCustomers;
	
	CREATE TABLE #tmpArchivedCustomers (
			ArchivedDate DATETIME
		,	CustId		INT
	);
	
	CREATE CLUSTERED INDEX IX_tmpArchivedCustomers_ArchivedDateCustId ON #tmpArchivedCustomers(
			ArchivedDate	ASC
		,	CustId			ASC
	);

	IF(@custType = 0) --Credit
	BEGIN
		INSERT INTO #tmpArchivedCustomers(ArchivedDate, CustID)
		SELECT		TOP(@rowSize) cus.ArchiveDate
					, cus.CustID
		FROM		bodb_Customer.dbo.CustInfo_Old AS cus WITH(NOLOCK)
		WHERE		cus.ArchiveDate = @lastArchiveDate
					AND cus.CustId > @lastCustId
		ORDER BY	cus.ArchiveDate ASC, cus.CustID ASC;

		SET @rowCount = (SELECT COUNT(1) FROM #tmpArchivedCustomers AS tmpCus)

		IF(@rowCount < @rowSize)
		BEGIN
			INSERT INTO #tmpArchivedCustomers(ArchivedDate, CustID)
			SELECT		TOP(@rowSize - @rowCount) cus.ArchiveDate
					,	cus.CustID
			FROM		bodb_Customer.dbo.CustInfo_Old AS cus WITH(NOLOCK)
			WHERE		cus.ArchiveDate > @lastArchiveDate
			ORDER BY	cus.ArchiveDate, cus.CustID;
		END;
	ELSE IF (@custType = 1) --Licencee

		INSERT INTO #tmpArchivedCustomers(ArchivedDate, CustID)
		SELECT		TOP(@rowSize) cus.ArchivedDate
					, cus.CustID
		FROM		bodb02.dbo.Dep_Customer_Archived AS cus WITH(NOLOCK)
		WHERE		cus.ArchivedDate = @lastArchiveDate
					AND cus.CustId > @lastCustId
		ORDER BY	cus.ArchivedDate ASC, cus.CustID ASC;

		SET @rowCount = (SELECT COUNT(1) FROM #tmpArchivedCustomers AS tmpCus)

		IF(@rowCount < @rowSize)
		BEGIN
			INSERT INTO #tmpArchivedCustomers(ArchivedDate, CustID)
			SELECT		TOP(@rowSize - @rowCount) cus.ArchivedDate
					,	cus.CustID
			FROM		bodb02.dbo.Dep_Customer_Archived AS cus WITH(NOLOCK)
			WHERE		cus.ArchivedDate > @lastArchiveDate
			ORDER BY	cus.ArchivedDate, cus.CustID;
		END;
	END;


	SELECT tmpCus.ArchivedDate, tmpCus.CustID FROM #tmpArchivedCustomers AS tmpCus;
END;
GO