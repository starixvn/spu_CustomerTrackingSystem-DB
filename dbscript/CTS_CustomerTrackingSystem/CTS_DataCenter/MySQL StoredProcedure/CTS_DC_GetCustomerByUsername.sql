DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_GetCustomerByUsername` $$

CREATE PROCEDURE `CTS_DataCenter`.`CTS_DC_GetCustomerByUsername`(
	IN 	ip_Username 		VARCHAR(50)
)
BEGIN
	/*
		Created:	20200416@Long.Luu
		Task :		Get CTSCustomer by Username
		DB:			CTS_DataCenter
		Original:

		Revisions:
        - 20200416@Long.Luu: Created [Redmine ID: #131506]
		
		Param's Explanation (filtered by):
	*/
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT CTSCustID, SubscriberID
    FROM CTS_DataCenter.CTSCustomer 
    WHERE Username = ip_Username; 
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;
