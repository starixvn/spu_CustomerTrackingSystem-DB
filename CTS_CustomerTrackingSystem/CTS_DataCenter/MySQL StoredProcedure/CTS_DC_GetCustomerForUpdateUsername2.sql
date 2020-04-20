DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_GetCustomerForUpdateUsername2 $$

CREATE PROCEDURE `CTS_DC_GetCustomerForUpdateUsername2`(IN ip_Size INT, IN ip_CustID BIGINT, IN ip_IsUpdateCustsub BOOLEAN)
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

	IF ip_IsUpdateCustsub = 0 THEN
		SELECT CTSCustID
			,CustID
			,CustSubID
		FROM CTSCustomer
		WHERE (UserName2 IS NULL OR SubscriberID IS NULL)
			AND CustID > ip_CustID
			AND CustSubID = 0
		ORDER BY CustID
		LIMIT ip_Size;
	ELSE
		SELECT CTSCustID
			,CustID
			,CustSubID
		FROM CTSCustomer
		WHERE (UserName2 IS NULL OR SubscriberID IS NULL)
			AND CustID > 0
			AND CustSubID > ip_CustID
		ORDER BY CustSubID
		LIMIT ip_Size;
	END IF;

	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;
