DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetUserInfomationByUsername`(IN ip_username VARCHAR(50), IN ip_original_username VARCHAR(50))
BEGIN
	/*
		Created:	20191112@Terry
		Task:		Get User Info by Username from CTS Customer
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):                
	*/	 
    /*
		DROP TABLE IF EXISTS tmpCustomer;
		CREATE TEMPORARY TABLE tmpCustomer(
			CTSCustID		BIGINT,
            CustId			BIGINT,
            UserName		VARCHAR(50),
            UserName2		VARCHAR(50),
            LastLogin		DATETIME,
            CurrencyID		INT,
            Currency		VARCHAR(10),
            RoleID			TINYINT(4),
            RoleName		VARCHAR(10),
            SubscriberID	INT,
            SubscriberName	VARCHAR(50)
        );
        
        SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
        INSERT INTO tmpCustomer
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
			#INNER JOIN CTS_Admin.Subscriber AS sub ON ctsCus.SubscriberID = sub.SubscriberID
        WHERE       
            Match(ctsCus.UserName, ctsCus.UserName2) AGAINST(ip_username IN BOOLEAN MODE)
            OR (ctsCus.UserName Like CONCAT(ip_original_username, '%') OR ctsCus.UserName2 Like CONCAT(ip_original_username, '%'))
        LIMIT 50;
       
       UPDATE tmpCustomer cus       
       INNER JOIN CTS_Admin.Subscriber sub ON cus.SubscriberID = sub.SubscriberID
       SET cus.SubscriberName = sub.SubscriberName;
       
       SELECT CTSCustID
            , CustId
			, UserName
			, UserName2  
            , LastLogin
            , CurrencyID
            , Currency
            , RoleID
            , RoleName
            , SubscriberID
            , SubscriberName
		FROM tmpCustomer;
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
        WHERE ctsCus.Username = ip_original_username OR ctsCus.Username2 = ip_original_username;
        
END$$
DELIMITER ;
