/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DELIMITER $$

USE CTS_DataCenter $$

DROP PROCEDURE IF EXISTS CTS_DC_CTSCustomer_UpdateSubscriberSite$$

CREATE PROCEDURE CTS_DC_CTSCustomer_UpdateSubscriberSite(IN ip_SubscriberSite JSON)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20191220@CaseyHuynh
		Task :		Update SubscriberID Mapping by Subsc
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200911@Casey.Huynh: Created [Redmine ID: 148849]
		Param's Explanation (filtered by):
	*/
     DECLARE vl_flag INT DEFAULT 1;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustSub;
    CREATE TEMPORARY TABLE Temp_CustSub
    (
		CTSCustID 			BIGINT
        , SiteName 			VARCHAR(50)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        , RoleMapping			TINYINT
    );   
	
  
   WHILE vl_flag = 1 
   DO		
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
			SET vl_flag = 0;
		END IF;

  END WHILE;
END$$

DELIMITER ;