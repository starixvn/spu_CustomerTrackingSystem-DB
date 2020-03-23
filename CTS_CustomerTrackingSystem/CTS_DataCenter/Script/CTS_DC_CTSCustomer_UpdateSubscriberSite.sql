DELIMITER $$

USE CTS_DataCenter$$

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateSubscriberSite_Haifa_BBIN$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_CTSCustomer_UpdateSubscriberSite_Haifa_BBIN()
BEGIN
	/*
		Created:	20200313@CaseyHuynh
		Task :		Update SubscriberID of Haifa from 
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/


   WHILE EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomer WHERE SubscriberID = 4431)  
   DO
        UPDATE 	CTS_DataCenter.CTSCustomer
        SET  	SubscriberID = 104
        WHERE 	SubscriberID = 4431
        LIMIT	10000;        
	END WHILE;
END$$

DELIMITER ;