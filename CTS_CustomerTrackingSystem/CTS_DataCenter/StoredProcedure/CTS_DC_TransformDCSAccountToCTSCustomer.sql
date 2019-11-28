DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_TransformDCSAccountToCTSCustomer`(IN ip_AccountList JSON)
BEGIN
/*
		Created:	20191112@Terry
		Task:		Insert CTS Customer
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):                
	*/
	DECLARE vrDepositSubType TINYINT DEFAULT 1;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Account;
    
	CREATE TEMPORARY TABLE Temp_Account 
    (	
		AccountID				BIGINT	UNSIGNED
        , LoginNameWithPrefix	VARCHAR(100)
        , LoginName				VARCHAR(100)
        , SubscriberID			INT
    ); 

	INSERT INTO Temp_Account
				(AccountID,
				LoginNameWithPrefix,
                LoginName,
				SubscriberID)
	SELECT 	tmpTable.AccountID, 
			tmpTable.LoginNameWithPrefix, 
            tmpTable.LoginName, 
			tmpTable.SubscriberID
	FROM JSON_TABLE(ip_AccountList,
		 "$[*]" COLUMNS(
			  AccountID 				BIGINT 			PATH "$.AccountId"
			, LoginNameWithPrefix		VARCHAR(100)	PATH "$.LoginNameWithPrefix" 
            , LoginName					VARCHAR(100)	PATH "$.LoginName" 
			, SubscriberID				INT				PATH "$.SubscriberId"
		 )) as tmpTable;     
    
	# Insert deposited accounts that are not existing in CTSCustomer    
    
    INSERT INTO CTS_DataCenter.CTSCustomer(SubscriberID, UserName2)
    SELECT		acc.SubscriberID
				, LoginNameWithPrefix  
    FROM 		Temp_Account AS acc 
	INNER JOIN	CTS_Admin.Subscriber AS sub 
				ON sub.SubscriberID = acc.SubscriberID
	LEFT JOIN	CTS_DataCenter.CTSCustomer AS cus 
				ON acc.LoginNameWithPrefix = cus.UserName2
                OR acc.LoginName = cus.UserName
    WHERE		sub.SubscriberType = vrDepositSubType 
				AND cus.CTSCustID IS NULL;   
    
   #======================================================= 
        
   # Insert AccountID and CTSCustomerID into CustDCSAccount for credit and deposit accounts  
	INSERT INTO CTS_DataCenter.CustDCSAccount(CTSCustID, AccountID, SubscriberID, InsertTime)
    SELECT  cus.CTSCustID
			, acc.AccountID
			, acc.SubscriberID 
            , NOW()
    FROM Temp_Account as acc 
		INNER JOIN CTS_DataCenter.CTSCustomer As cus 
			ON acc.LoginNameWithPrefix = cus.UserName2 
            OR acc.LoginName = cus.UserName        
		LEFT JOIN CTS_DataCenter.CustDCSAccount AS custAcc 
			ON acc.AccountID = custAcc.AccountID
	WHERE custAcc.AccountID IS NULL;    
    
   #=======================================================
   
   # Return account list that are not inserted into CTSCustomer for credit and deposit accounts 	
    SELECT acc.AccountID
		FROM Temp_Account AS acc 		
			LEFT JOIN CTS_DataCenter.CTSCustomer AS cus 
				ON acc.LoginNameWithPrefix = cus.UserName2 
                OR acc.LoginName = cus.UserName
    WHERE cus.CTSCustID IS NULL;
   
   #=======================================================   
    
END$$
DELIMITER ;
