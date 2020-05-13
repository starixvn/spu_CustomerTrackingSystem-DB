DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_GetMaxCustIdCTSCustomer $$

CREATE PROCEDURE CTS_DC_GetMaxCustIdCTSCustomer (IN ip_IsCustSub BOOLEAN)
BEGIN
	/*
		Created:	2019@Harvey
		Task:		Insert Customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_DC_GetMaxCustIdCTSCustomer (0)
	*/

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

IF ip_IsCustSub = 0 THEN
	SELECT 
		CASE
			WHEN MAX(custid) IS NULL THEN 0
			ELSE MAX(custid)
		END AS 'MaxCustId'
	FROM CTS_DataCenter.CTSCustomer;
ELSE
	SELECT 
		CASE
			WHEN MAX(CustSubID) IS NULL THEN 0
			ELSE MAX(CustSubID)
		END AS 'MaxCustId'
	FROM CTS_DataCenter.CTSCustomer;
END IF;
    
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;