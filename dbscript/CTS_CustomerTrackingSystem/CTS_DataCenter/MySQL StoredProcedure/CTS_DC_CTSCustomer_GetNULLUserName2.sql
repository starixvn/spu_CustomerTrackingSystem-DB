DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_CTSCustomer_GetNULLUserName2 $$

CREATE PROCEDURE `CTS_DC_CTSCustomer_GetNULLUserName2`(
	IN ip_PreCTSCustID JSON
    , IN ip_Size INT DEFAULT 500)
BEGIN
	/*
		Created:	20200118@CaseyHuynh
		Task:		GET CTSCustID NULL
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200421@Harvey:	Get customer for update SubscriberID - [Redmine: #132705]
        
		Param's Explanation (filtered by):         
        
        CALL CTS_DC_GetCustomerForUpdateUsername2 (500,0,1)
	*/	  
	
	SELECT 		cus.CustID
			,	cus.CustSubID
	FROM 		CTS_DataCenter.CTSCustomer AS cus
	WHERE 		cus.UserName2 IS NULL
				AND cus.CTSCustID > ip_PreCTSCustID
    ORDER BY	cus.CTSCustID 
    LIMIT 		ip_Size;
    
    
    
END$$
DELIMITER ;
