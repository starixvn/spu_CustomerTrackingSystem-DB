DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_GetAllSpecialCustomerClass $$

CREATE PROCEDURE CTS_DC_GetAllSpecialCustomerClass (
	IN		ip_IsGetAllInfo		BIT
)
BEGIN
	/*
		Created:	20200905@Long.Luu
		Task:		Insert special customer class
		DB:			CTS_DataCenter
		Original:

		Revisions:
		   - 20200905@Long.Luu [140996]: created
           
		Param's Explanation (filtered by):
	*/        
           
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    
    IF (ip_IsGetAllInfo = 1) THEN
		SELECT 	s.CTSCustID
			,	s.CustID
			, 	c.UserName
			,	s.RootCTSCustID
			, 	sub.SubscriberName
			, 	s.CustomerClass
			,	u.UserName AS CreatedBy
			,	s.CreatedDate
		FROM CTS_DataCenter.SpecialCustomerClass AS s
			INNER JOIN CTS_DataCenter.CTSCustomer AS c ON s.CTSCustID = c.CTSCustID
			INNER JOIN CTS_Admin.Subscriber AS sub ON s.SubscriberID = sub.SubscriberID
			INNER JOIN CTS_Admin.CTSUser AS u ON s.CreatedBy = u.UserID;
    ELSE
		SELECT CustID
		FROM CTS_DataCenter.SpecialCustomerClass;
    END IF;
    
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    	
END$$
DELIMITER ;