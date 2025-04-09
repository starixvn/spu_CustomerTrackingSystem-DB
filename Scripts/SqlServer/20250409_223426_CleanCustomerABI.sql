/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
    Created: 20250404@Thomas.Nguyen
	Task: Correct ABI for customers
	DB: DBCUST-CustDB
*/
USE CustDB;
GO

CREATE TABLE #Tmp_CustNeedToUpdateABI(
		ID INT IDENTITY (1,1) PRIMARY KEY
	,	CustID INT
);

INSERT INTO #Tmp_CustNeedToUpdateABI (CustID)
SELECT CustID
FROM dbo.Adhoc_CustNeedToUpdateABI WITH(NOLOCK);

CREATE NONCLUSTERED INDEX IX_Tmp_CustNeedToUpdateABI_CustID ON #Tmp_CustNeedToUpdateABI (CustID);

DECLARE @StartRow INT 
		, @StopRow INT 
		, @MaxRow INT  -- the total rows
		, @Threshold INT;  -- the number of each batch
		
DECLARE @debug_message VARCHAR(500);
SET @MaxRow = (SELECT MAX(ID) FROM #Tmp_CustNeedToUpdateABI);
SET @Threshold = 2000;

IF @Threshold >= @MaxRow
	SET @Threshold = @MaxRow;

-- SET for first batch
SELECT @StartRow = 1, @StopRow = @Threshold;

WHILE (@MaxRow IS NOT NULL)
BEGIN
		PRINT @StartRow;
		PRINT @StopRow;
		
		UPDATE cus WITH (ROWLOCK, UPDLOCK)
		SET cus.danger2 = 0
		FROM dbo.custInfo AS cus 
			INNER JOIN #Tmp_CustNeedToUpdateABI AS tmp ON cus.CustID = tmp.CustID
		WHERE tmp.ID BETWEEN @StartRow AND @StopRow;

		SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121);		
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT;
		
		IF @StopRow = @MaxRow BREAK;

		WAITFOR DELAY '00:00:00.100';

		SET @StartRow = @StopRow + 1;
		SET @StopRow = @StopRow + @Threshold;
		IF @StopRow >= @MaxRow
			SET @StopRow = @MaxRow;

END

DROP TABLE #Tmp_CustNeedToUpdateABI;
