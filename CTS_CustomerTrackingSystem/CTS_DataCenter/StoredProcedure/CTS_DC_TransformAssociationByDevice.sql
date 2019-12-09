DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_TransformAssociationByDevice$$
CREATE PROCEDURE CTS_DataCenter.CTS_DC_TransformAssociationByDevice(IN ip_AssociationList JSON)
BEGIN
/*
		Created:	20191115@Terry.Nguyen
		Task:		Transform Association By Device from DCS.Assocation
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
                
	*/    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    
	CREATE TEMPORARY TABLE Temp_Association 
    (	AssociationID			BIGINT	UNSIGNED
		,  AccountID			BIGINT	UNSIGNED
        , DeviceID				BIGINT	UNSIGNED
        , SubscriberID			INT
        , CreatedTime			TIMESTAMP(4)
    ); 
    
    INSERT INTO Temp_Association
				(
                AssociationID,
                AccountID,
				DeviceID,
				SubscriberID,
                CreatedTime)                
	SELECT 	
			tmpTable.AssociationID,
			tmpTable.AccountID, 
			tmpTable.DeviceID, 
			tmpTable.SubscriberID,
            tmpTable.CreatedTime
	FROM JSON_TABLE(ip_AssociationList,
		 "$[*]" COLUMNS(
			  AssociationID 			BIGINT 			PATH "$.AssociationId"
			, AccountID 				BIGINT 			PATH "$.AccountId"
			, DeviceID					BIGINT			PATH "$.DeviceId" 
			, SubscriberID				INT				PATH "$.SubscriberId"
            , CreatedTime				TIMESTAMP(4)	PATH "$.CreatedTime"
		 )) as tmpTable;   
         
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByDevice;
    CREATE TEMPORARY TABLE Temp_AssociationByDevice 
    (	
		  CTSCustID				BIGINT	UNSIGNED
        , DCSDeviceID			BIGINT	UNSIGNED
        , SubscriberID			INT
        , CreatedTime			TIMESTAMP(4)
    ); 
    INSERT INTO 	Temp_AssociationByDevice(CTSCustID, DCSDeviceID, SubscriberID, CreatedTime)
	SELECT 			cus.CTSCustID, 
					tmpAss.DeviceID AS DCSDeviceID, 
					tmpAss.SubscriberID, 
					MIN(tmpAss.CreatedTime) AS CreatedTime
	FROM 			Temp_Association AS tmpAss 
	INNER JOIN 		CTS_DataCenter.CustDCSAccount AS cus 
					ON tmpAss.AccountID = cus.AccountID        
	GROUP BY 		cus.CTSCustID, tmpAss.DeviceID, tmpAss.SubscriberID;           
          
    INSERT IGNORE INTO 	CTS_DataCenter.AssociationByDevice(CTSCustID, DCSDeviceID, SubscriberID, CreatedTime, InsertTime)
	SELECT 			tmpAssDe.CTSCustID 
					, tmpAssDe.DCSDeviceID
					, tmpAssDe.SubscriberID
					, tmpAssDe.CreatedTime
					, CURRENT_TIMESTAMP(4) AS InsertTime
	FROM 			Temp_AssociationByDevice AS tmpAssDe;
	/*LEFT JOIN  		CTS_DataCenter.AssociationByDevice AS AssDe 
					ON tmpAssDe.CTSCustID		= AssDe.CTSCustID 
						AND tmpAssDe.DCSDeviceID	= AssDe.DCSDeviceID
	WHERE			AssDe.CTSAssDevID IS NULL;  */   
    
	SELECT 		tmpAss.AssociationId
				, cus.CTSCustID AS CustId
                , tmpAss.DeviceID 
    FROM 		Temp_Association tmpAss 
	INNER JOIN	CTS_DataCenter.CustDCSAccount cus 
				ON tmpAss.AccountID = cus.AccountID
	INNER JOIN	Temp_AssociationByDevice tmpAssD 
				ON cus.CTSCustID = tmpAssD.CTSCustID 
                AND tmpAssD.DCSDeviceID = tmpAss.DeviceID;     
                          
END$$
DELIMITER ;
