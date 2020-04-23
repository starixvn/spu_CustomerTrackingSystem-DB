DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.Issue_CTSCustomer_3_InsertCTSCustomerMissing$$

CREATE PROCEDURE CTS_DataCenter.Issue_CTSCustomer_3_InsertCTSCustomerMissing(IN ip_CTSCustID BIGINT UNSIGNED)
BEGIN
	/*
		Created:	20200421@CaseyHuynh	
		Task :		Insert Missint CTSCustomer 
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
	DECLARE i INT;
    DECLARE n INT;
    DECLARE k INT;
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
    SELECT 	MIN(CTSCustID), MAX(CTSCustID)
    INTO	i, n
    FROM	CTS_DataCenter.zzzIssueCustMissing_CustDCSAccount AS ms
    WHERE	ms.SubscriberType IN (1,2);
    
	
	WHILE (i < n)
    DO
				SET k = (SELECT MAX(bt.CTSCustID) FROM ( SELECT ms.CTSCustID
												 FROM 	CTS_DataCenter.zzzIssueCustMissing_CustDCSAccount AS ms
												 WHERE	ms.CTSCustID >= i AND NewCTSCustID = -1
												 LIMIT	1000
												) AS bt);
												
		INSERT IGNORE INTO	CTS_DataCenter.CTSCustomer(CTSCustID, SubscriberID, UserName, UserName2, LastLoginTime)
		SELECT	ms.CTSCustID
				, ms.SubscriberID
				, ms.LoginName AS UserName
				, ms.LoginNameWithPrefix
				, MAX(ac.LastLoginTime)
		FROM 		CTS_DataCenter.zzzIssueCustMissing_CustDCSAccount AS ms
		INNER JOIN	DCS_DataCenter.Account AS ac
					ON ms.AccountID = ac.AccountID
		WHERE		ms.SubscriberType IN (1,2)
					AND NewCTSCustID = -1
		GROUP BY 	ms.CTSCustID
					, ms.SubscriberID
					, ms.LoginNameWithPrefix
					, ms.LoginName; 
		
		
		SET i = k;
    END WHILE;
	
	 
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$
DELIMITER ;