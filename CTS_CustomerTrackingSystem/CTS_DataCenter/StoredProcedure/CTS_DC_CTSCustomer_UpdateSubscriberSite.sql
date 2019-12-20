DELIMITER $$

USE CTS_DataCenter$$

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateSubscriberSite $$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_CTSCustomer_UpdateSubscriberSite()
BEGIN
	/*
		Created:	20191220@CaseyHuynh
		Task :		Update SubscriberID Mapping
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
     DECLARE vr_i INT DEFAULT 1;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustSub;
    CREATE TEMPORARY TABLE Temp_CustSub
    (
		CTSCustID 		BIGINT
        , SubscriberID 	INT
    );
    
    
   

    WHILE vr_i = 1 DO
		
        TRUNCATE TABLE Temp_CustSub;
        
        INSERT INTO Temp_CustSub(CTSCustID, SubscriberID)
        SELECT		c.CTSCustID, ms.SubscriberID
        FROM 		CTS_DataCenter.CTSCustomer AS c
		INNER JOIN	CTS_DataCenter.MappingSubscriberSite As ms
					ON	c.Site = ms.SiteName
					AND	(Case when c.RoleID = 1 Then 1 Else -1 End) = ms.RoleIDMapping
		WHERE	c.SubscriberID IS NULL
        LIMIT 1000;
        
		IF (SELECT 1 FROM Temp_CustSub LIMIT 1) THEN
			UPDATE		CTS_DataCenter.CTSCustomer AS c
			INNER JOIN	Temp_CustSub	AS tempCust
						ON c.CTSCustID = tempCust.CTSCustID
			SET			c.SubscriberID = tempCust.SubscriberID;
			ELSE 
				SET vr_i = 0;
		END IF;
              
        
    END WHILE;
END$$

DELIMITER ;