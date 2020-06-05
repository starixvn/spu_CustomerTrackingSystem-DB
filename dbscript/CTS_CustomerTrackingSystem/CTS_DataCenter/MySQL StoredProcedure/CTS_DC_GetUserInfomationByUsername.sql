DELIMITER $$
DROP procedure IF EXISTS `CTS_DC_GetUserInfomationByUsername`;
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetUserInfomationByUsername`(IN ip_username VARCHAR(50))
BEGIN
	/*
		Created:	20191112@Terry
		Task:		Get User Info by Username from CTS Customer
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200601@Harvey: add code for searching with username2
        
		Param's Explanation (filtered by):                
	*/	 
  
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
       SELECT 
			ctsCus.CTSCustID
            , ctsCus.CustId
			, ctsCus.UserName
			, ctsCus.UserName2  
            , ctsCus.LastLoginTime AS 'LastLogin'
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
            , null as SubscriberName            
        FROM CTS_DataCenter.CTSCustomer AS ctsCus
        WHERE ctsCus.Username = ip_original_username OR ctsCus.RegisterName = ip_original_username;
END$$
DELIMITER ;
