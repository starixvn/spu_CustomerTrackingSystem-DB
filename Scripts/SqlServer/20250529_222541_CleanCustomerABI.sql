/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
    Created: 20250529@Thomas.Nguyen
	Task: Correct ABI for customers
	DB: DBCUST-CustDB
*/
USE CustDB;
GO
CREATE TABLE #Tmp_CustNeedToUpdateABI(
		CustID INT
);
INSERT INTO #Tmp_CustNeedToUpdateABI (CustID)
SELECT CustID
FROM dbo.Adhoc_HF222541_CustNeedToUpdateABI WITH(NOLOCK);
		
DECLARE @debug_message VARCHAR(500);
DECLARE @__batch TABLE (custid INT);
WHILE  1 = 1
BEGIN
		DELETE FROM @__batch;
		DELETE TOP(2000)
		FROM #Tmp_CustNeedToUpdateABI
		OUTPUT deleted.CustID INTO @__batch(custid);
		
		IF @@ROWCOUNT = 0
			BREAK;

		UPDATE cus WITH (ROWLOCK, UPDLOCK)
		SET cus.danger2 = 0, RepUpdateTime = dbo.f_getdatetime2()
		FROM dbo.custInfo AS cus 
		WHERE EXISTS (SELECT TOP 1 1 FROM @__batch t WHERE cus.custid = t.custid);

		SET @debug_message = CONVERT(VARCHAR(50), GETDATE(), 121);		
		RAISERROR (@debug_message, 0, 1) WITH NOWAIT;
		
		WAITFOR DELAY '00:00:00.100';
END
DROP TABLE #Tmp_CustNeedToUpdateABI;