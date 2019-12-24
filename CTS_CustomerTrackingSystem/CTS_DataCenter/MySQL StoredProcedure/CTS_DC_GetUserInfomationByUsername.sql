DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DC_GetUserInfomationByUsername$$
CREATE DEFINER=`fps`@`%` PROCEDURE CTS_DC_GetUserInfomationByUsername (IN ip_username VARCHAR(50))
BEGIN
	/*
		Created:	20191112@Terry
		Task:		Get User Info by Username from CTS Customer
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):                
	*/
		SET @LastLogin = CURRENT_TIMESTAMP();
    
		SELECT 
			ctsCus.CTSCustID
			, ctsCus.UserName
			, ctsCus.UserName2  
            , @LastLogin AS 'LastLogin'
            , ctsCus.CurrencyID
            , ctsCus.Currency
            , ctsCus.RoleID
            , CASE ctsCus.RoleID 
				WHEN 1 THEN 'Member'
                WHEN 2 THEN 'Agent'
                WHEN 3 THEN 'Master'
                WHEN 4 THEN 'Super'
			  END RoleName
            , ctsCus.SubscriberID
            , sub.SubscriberName            
        FROM CTS_DataCenter.CTSCustomer AS ctsCus
			INNER JOIN CTS_Admin.Subscriber AS sub ON ctsCus.SubscriberID = sub.SubscriberID
        WHERE  ctsCus.Username like CONCAT(ip_username, '%') OR ctsCus.Username2 like CONCAT(ip_username, '%')
        LIMIT 50;
END$$
DELIMITER ;