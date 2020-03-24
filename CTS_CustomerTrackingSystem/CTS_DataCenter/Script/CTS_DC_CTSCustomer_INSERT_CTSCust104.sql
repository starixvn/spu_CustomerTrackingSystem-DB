DELIMITER $$

USE CTS_DataCenter$$

DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_CTSCustomer_DELETEHaifaCustomer$$

CREATE PROCEDURE CTS_DataCenter.CTS_DC_CTSCustomer_DELETEHaifaCustomer()
BEGIN
	/*
		Created:	20200313@CaseyHuynh
		Task :		Update SubscriberID of Haifa from 
		DB:			CTS_DataCenter
		Original:

		Revisions:
		Param's Explanation (filtered by):
	*/
   
   DROP TEMPORARY TABLE IF EXISTS Temp_HaifaCTSCustID;
   CREATE TEMPORARY TABLE Temp_HaifaCTSCustID
   (
		DelCTSCustID	BIGINT
   );
	
   WHILE EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomer WHERE SubscriberID = 4431)  
   DO
		INSERT INTO Temp_HaifaCTSCustID(DelCTSCustID)
        SELECT 	CTSCustID
        FROM 	CTS_DataCenter.CTSCustomer
        WHERE 	SubscriberID IN (4431, 104)
        LIMIT	10000;
        
        
        INSERT INTO CTS_DataCenter.CTSCustomer_DELETE_HAIFA4431
		(CTSCustID,
		SubscriberID,
		CustID,
		CustSubID,
		UserName,
		UserName2,
		SiteID,
		Site,
		RoleID,
		Currency,
		CurrencyID,
		SRecommend,
		MRecommend,
		Recommend,
		LastLoginTime,
		CreatedDate)
        SELECT
        CTSCustID,
		SubscriberID,
		CustID,
		CustSubID,
		UserName,
		UserName2,
		SiteID,
		Site,
		RoleID,
		Currency,
		CurrencyID,
		SRecommend,
		MRecommend,
		Recommend,
		LastLoginTime,
		CreatedDate
        FROM		CTS_DataCenter.CTSCustomer AS cur
        INNER JOIN	CTS_DataCenter.Temp_HaifaCTSCustID  AS del
					ON cur.CTSCustID = DelCTSCustID;					

        DELETE 		cur
        FROM  		CTS_DataCenter.CTSCustomer AS cur
        INNER JOIN 	CTS_DataCenter.Temp_HaifaCTSCustID  AS del
					ON cur.CTSCustID = DelCTSCustID;

        
	END WHILE;
END$$

DELIMITER ;