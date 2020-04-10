DELIMITER $$

USE CTS_DataCenter$$

DROP PROCEDURE IF EXISTS CTS_DataCenter.zzzIssueLoginName_Step13_UpdSubID_CTSCust_haifa_4431to104$$

CREATE PROCEDURE CTS_DataCenter.zzzIssueLoginName_Step13_UpdSubID_CTSCust_haifa_4431to104()
BEGIN
	/*
		Created:	20200313@CaseyHuynh
		Task :		Wrong LoginName
	*/
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;  
  
   WHILE EXISTS (	SELECT		ct.CTSCustID
					FROM 		CTS_DataCenter.CTSCustomer ct
					LEFT JOIN 	CTS_DataCenter.zzzIssueLoginName_CTSCustomer_DuplicateNew dp
							ON dp.SubscriberID = 104 AND ct.UserName = dp.UserName AND ct.UserName2 = dp.UserName2
					WHERE	ct.SubscriberID = 4431
					AND dp.SubscriberID IS NULL
					LIMIT 	1)
   DO
		SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        
        UPDATE		CTS_DataCenter.CTSCustomer ct
        LEFT JOIN 	CTS_DataCenter.zzzIssueLoginName_CTSCustomer_DuplicateNew dp
					ON dp.SubscriberID = 104 AND ct.UserName = dp.UserName AND ct.UserName2 = dp.UserName2
        SET		ct.SubscriberID = 104
        WHERE	ct.SubscriberID = 4431
				AND dp.SubscriberID IS NULL
        LIMIT 	2000;

       	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED ;  
        
	END WHILE;
    
	
END$$

DELIMITER ;