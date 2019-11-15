DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertCTSCustomerFromDCSAccount`(IN ip_AccountList JSON)
BEGIN
/*
		Created:	20191112@Terry
		Task:		Insert CTS Customer
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):                
	*/

	DROP TEMPORARY TABLE IF EXISTS Temp_Account;
    
	CREATE TEMPORARY TABLE Temp_Account 
    (	
		AccountID				BIGINT	UNSIGNED
        , LoginNameWithPrefix	VARCHAR(100)
        , SubscriberID			INT
    ); 

	INSERT INTO `Temp_Account`
				(`AccountID`,
				`LoginNameWithPrefix`,
				`SubscriberID`)
	SELECT 	tmpTable.AccountID, 
			tmpTable.LoginNameWithPrefix, 
			tmpTable.SubscriberID
	FROM JSON_TABLE(ip_AccountList,
		 "$[*]" COLUMNS(
			  AccountID 				BIGINT 			PATH "$.AccountId"
			, LoginNameWithPrefix		VARCHAR(100)	PATH "$.LoginNameWithPrefix" 
			, SubscriberID				INT				PATH "$.SubscriberId"
		 )) as tmpTable;     
    
	# Insert Null account into CTSCustomer
    INSERT INTO CTS_DataCenter.CTSCustomer(SubscriberID, 
    CustID, 
    CustSubID, 
    UserName, 
    UserName2, 
    Site, 
    RoleID, 
    Currency, 
    CurrencyID, 
    SRecommend, 
    MRecommend, 
    Recommend)
    SELECT acc.SubscriberID,
    0,
    0,
    NULL,
    LoginNameWithPrefix,
    NULL,
    0,
    NULL,
    0,
    0,
    0,
    0
    FROM Temp_Account AS acc 
		LEFT JOIN CTS_DataCenter.CTSCustomer AS cus ON acc.LoginNameWithPrefix = cus.UserName2
    WHERE cus.CTSCustID is null;
   #=======================================================
      
   # Insert AccountID and CTSCustomerID into CustDCSAccount   
	INSERT INTO CTS_DataCenter.CustDCSAccount(CTSCustID, AccountID, SubscriberID, InsertTime)
    SELECT cus.CTSCustID, acc.AccountID, acc.SubscriberID, now()
    FROM Temp_Account as acc 
		INNER JOIN CTS_DataCenter.CTSCustomer As cus ON acc.LoginNameWithPrefix = cus.UserName2
		LEFT JOIN CTS_DataCenter.CustDCSAccount AS custAcc ON acc.AccountID = custAcc.AccountID
	WHERE custAcc.AccountID IS NULL;    
   #=======================================================
    
END$$
DELIMITER ;
SELECT * FROM DCS_DataCenter.Association;