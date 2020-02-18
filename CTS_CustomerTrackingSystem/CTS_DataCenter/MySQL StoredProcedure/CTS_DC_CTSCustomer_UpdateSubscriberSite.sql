DELIMITER $$

USE CTS_DataCenter$$

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_UpdateSubscriberSite_01 $$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_CTSCustomer_UpdateSubscriberSite_01()
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
		CTSCustID 			BIGINT
        , SiteName 			VARCHAR(50)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        , RoleMapping			TINYINT
    );   

   WHILE vr_i = 1 DO		
        TRUNCATE TABLE Temp_CustSub;
        
        
        INSERT INTO Temp_CustSub(CTSCustID, SiteName, RoleMapping)
        SELECT		c.CTSCustID
					, c.Site
                    , CASE WHEN c.RoleID = 1 THEN 1 ELSE 2 END AS RoleMapping
        FROM 		CTS_DataCenter.CTSCustomer AS c
		WHERE		c.SubscriberID IS NULL
        LIMIT		1000;    

        
		IF (SELECT 1 FROM Temp_CustSub LIMIT 1) THEN
			           
			UPDATE		CTS_DataCenter.CTSCustomer AS c
			INNER JOIN	Temp_CustSub	AS tempCust
						ON c.CTSCustID = tempCust.CTSCustID
			INNER JOIN	CTS_DataCenter.MappingSubscriberSite As ms
					ON	ms.SiteName = tempCust.SiteName
						AND ( ( ms.MappingType > 0 AND tempCust.RoleMapping = ms.MappingType)
								OR ms.MappingType IN (0,-1)
							)
			SET			c.SubscriberID = ms.SubscriberID;
			ELSE 
				SET vr_i = 0;
		END IF;

  END WHILE;
END$$

DELIMITER ;