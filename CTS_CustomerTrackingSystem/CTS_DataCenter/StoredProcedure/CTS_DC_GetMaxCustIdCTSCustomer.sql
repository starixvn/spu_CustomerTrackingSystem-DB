DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_GetMaxCustIdCTSCustomer $$

CREATE PROCEDURE CTS_DC_GetMaxCustIdCTSCustomer ()
BEGIN
	/*
		Created:	2019@Harvey
		Task:		Insert Customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_DC_GetMaxCustIdCTSCustomer
	*/

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT MAX(custid) AS 'MaxCustId'
FROM CTS_DataCenter.CTSCustomer;
    
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;