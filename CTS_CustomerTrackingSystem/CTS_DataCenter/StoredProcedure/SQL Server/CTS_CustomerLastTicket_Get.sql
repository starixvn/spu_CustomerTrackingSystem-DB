/*<info serverAlias="DBTP-bodb02" executers="bodbSPUNet" isFunction="0" isNested="0"></info>*/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[CTS_CustomerLastTicket_Get] 
		 @custId				INT
AS
/*
	Created: 20191220@Harvey
	Task : Get lastest transaction for Customer
	DB: bodb02
	Original:

	Revisions:
		-	20190826@Harvey: init SPs			(#125888)

	Param's Explanation:

	EXEC [CTS_CustomerLastTicket_Get] 7508205
*/
BEGIN
	SET NOCOUNT ON;

	CREATE TABLE #LastTicketInfo (
		CustId INT
		,TransDate DATETIME
		)

	INSERT INTO #LastTicketInfo (
		CustId
		,TransDate
		)
	SELECT TOP 1 custid
		,transdate
	FROM bettrans WITH (NOLOCK)
	WHERE custid = @custId
	ORDER BY transdate DESC

	IF NOT EXISTS (
			SELECT 1
			FROM #LastTicketInfo
			)
	BEGIN
		INSERT INTO #LastTicketInfo (
			CustId
			,TransDate
			)
		SELECT TOP 1 custid
			,transdate
		FROM bettrans14 WITH (NOLOCK)
		WHERE custid = @custId
		ORDER BY transdate DESC;
	END;

	IF NOT EXISTS (
			SELECT 1
			FROM #LastTicketInfo
			)
	BEGIN
		INSERT INTO #LastTicketInfo (
			CustId
			,TransDate
			)
		SELECT TOP 1 custid
			,transdate
		FROM bodb_Archive.dbo.bettrans_bk WITH (NOLOCK)
		WHERE custid = @custId
		ORDER BY transdate DESC;
	END;

	SELECT CustId
		,TransDate
	FROM #LastTicketInfo

	DROP TABLE #LastTicketInfo;
END;