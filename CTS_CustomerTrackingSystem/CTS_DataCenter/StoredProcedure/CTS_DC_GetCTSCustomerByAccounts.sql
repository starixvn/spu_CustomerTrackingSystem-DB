DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetCTSCustomerByAccounts`(IN ip_AssociationList JSON)
BEGIN
/*
		Created:	20191115@Terry.Nguyen
		Task:		Get CTSCustomer by Account
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
                
	*/
    
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    
	CREATE TEMPORARY TABLE Temp_Association 
    (	    
		AssociationID	        BIGINT	UNSIGNED
		,AccountID				BIGINT	UNSIGNED
        , DeviceID				BIGINT	UNSIGNED
        , SubscriberID			INT
        , CreatedTime			TIMESTAMP(4)
    ); 
    
    INSERT INTO Temp_Association
				(AssociationID,
                AccountID,
				DeviceID,
				SubscriberID,
                CreatedTime)                
	SELECT 	tmpTable.AccountID, 
			tmpTable.DeviceID, 
			tmpTable.SubscriberID,
            tmpTable.CreatedTime
	FROM JSON_TABLE(ip_AssociationList,
		 "$[*]" COLUMNS(
			AssociationID 				BIGINT 			PATH "$.AssociationId"
			, AccountID 				BIGINT 			PATH "$.AccountId"
			, DeviceID					BIGINT			PATH "$.DeviceId" 
			, SubscriberID				INT				PATH "$.SubscriberId"
            , CreatedTime				TIMESTAMP(4)	PATH "$.CreatedTime"
		 )) as tmpTable;   
    
    SELECT cus.CTSCustID AS CustID, ass.DeviceID as DeviceID, ass.SubscriberID, MIN(ass.CreatedTime) As CreatedTime, ass.AssociationId
		FROM Temp_Association AS ass 
		INNER JOIN CTS_DataCenter.CustDCSAccount AS cus ON ass.AccountID = cus.AccountID        
		GROUP BY cus.CTSCustID, ass.DeviceID, ass.SubscriberID;
END$$
DELIMITER ;
