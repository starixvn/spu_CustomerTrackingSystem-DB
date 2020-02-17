DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_GetCustomerForUpdateUsername2 $$

CREATE PROCEDURE `CTS_DC_GetCustomerForUpdateUsername2`(IN ip_Size INT, IN ip_CTSCustID BIGINT, IN ip_IsUpdateCustsub BOOLEAN)
BEGIN
	/*
		Created:	20200112@Harvey
		Task:		Get customer from CTS Customer for updating username2
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):         
        
        CALL CTS_DC_GetCustomerForUpdateUsername2 (500,0,1)
	*/	   
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT CTSCustID
		,CustID
		,CustSubID
	FROM CTSCustomer
	WHERE UserName2 IS NULL
		AND CTSCustID > ip_CTSCustID
        AND (ip_IsUpdateCustsub = 0 OR CustSubID > 0)
	ORDER BY CTSCustID
    LIMIT ip_Size;

	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;
