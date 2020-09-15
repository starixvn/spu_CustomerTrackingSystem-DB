DELIMITER $$
USE CTS_DataCenter$$
DROP PROCEDURE IF EXISTS CTS_DC_CustInfo_GetByCTSCustID $$

CREATE PROCEDURE CTS_DC_CustInfo_GetByCTSCustID(IN ip_CTSCustID BIGINT UNSIGNED)
BEGIN
	/*
		Created:	20191217@Marcus
		Task :		Get LastLoginTime 
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    
	SELECT  	cus.CustID,	cus.SubscriberID, sub.SubscriberName
				, cus.CustSubID, cus.LastLoginTime, cus.UserName
                , cus.UserName2, cus.CreatedDate, cus.RoleID
	FROM		CTS_DataCenter.CTSCustomer AS cus
	INNER JOIN  CTS_Admin.Subscriber AS sub 
				ON cus.SubscriberID	= sub.SubscriberID
	WHERE   	cus.CTSCustID 		= ip_CTSCustID;
	 
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;