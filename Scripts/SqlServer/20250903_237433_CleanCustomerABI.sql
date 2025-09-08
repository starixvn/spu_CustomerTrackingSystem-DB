/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
    Created: 20250903@Thomas.Nguyen
	Task: Correct ABI for customers
	DB: DBCUST-CustDB
*/
USE CustDB;
GO
CREATE TABLE #Tmp_CustNeedToUpdateABI(
		CustID INT
	,	danger2 TINYINT
);
INSERT INTO #Tmp_CustNeedToUpdateABI (CustID, danger2)
SELECT CustID
	,	danger2
FROM dbo.Adhoc_HF237433_CustNeedToUpdateABI WITH(NOLOCK);
		
DECLARE @debug_message VARCHAR(500);
DECLARE @__batch TABLE (custid INT,	danger2 TINYINT);
WHILE  1 = 1
BEGIN
		DELETE FROM @__batch;
		DELETE TOP(2000)
		FROM #Tmp_CustNeedToUpdateABI
		OUTPUT deleted.CustID, deleted.danger2
		INTO @__batch(custid, danger2);
		
		IF @@ROWCOUNT = 0
			BREAK;

		UPDATE cus WITH (ROWLOCK, UPDLOCK)
		SET cus.danger2 = 0, cus.RepUpdateTime = dbo.f_getdatetime2()
		FROM dbo.custInfo AS cus 
		WHERE EXISTS (SELECT TOP 1 1 FROM @__batch t WHERE cus.custid = t.custid AND cus.danger2 = t.danger2);

		SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121);		
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT;
		
		WAITFOR DELAY '00:00:00.100';
END
DROP TABLE #Tmp_CustNeedToUpdateABI;