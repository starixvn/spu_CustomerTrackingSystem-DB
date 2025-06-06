/*<info serverAlias="DBCUST-CustDB" executers="" isFunction="0"></info>*/
/*
    Created: 20250529@Thomas.Nguyen
	Task: Correct ABI for customers
	DB: DBCUST-CustDB
*/
USE CustDB;
GO

UPDATE cus WITH (ROWLOCK, UPDLOCK)
SET cus.danger2 = 0, cus.RepUpdateTime = dbo.f_getdatetime2()
FROM dbo.custInfo AS cus 
WHERE cus.CustID IN (230697374,232322310,232330672,232607423,232611834,232615428,232617850,232632957,232632987,232635836,232635843,232638430,232638441,232642154,232642172,232734068)
AND cus.danger2 = 41;