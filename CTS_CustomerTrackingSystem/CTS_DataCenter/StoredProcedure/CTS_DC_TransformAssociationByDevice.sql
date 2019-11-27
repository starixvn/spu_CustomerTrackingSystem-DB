DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_TransformAssociationByDevice`(IN ip_AssociationList JSON)
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
    INSERT INTO Temp_AssociationByDevice
		SELECT cus.CTSCustID, 
		ass.DeviceID as DCSDeviceID, 
		ass.SubscriberID, 
		MIN(ass.CreatedTime) As CreatedTime
			FROM Temp_Association AS ass 
			INNER JOIN CTS_DataCenter.CustDCSAccount AS cus ON ass.AccountID = cus.AccountID        
			GROUP BY cus.CTSCustID, ass.DeviceID, ass.SubscriberID;         
          
    INSERT INTO  CTS_DataCenter.AssociationByDevice
		(`CTSCustID`,
		`DCSDeviceID`,
		`SubscriberID`,
		`CreatedTime`,
		`InsertTime`)
		SELECT 	tmpAssDe.CTSCustID, 
				tmpAssDe.DCSDeviceID,
                tmpAssDe.SubscriberID,
                tmpAssDe.CreatedTime,
                NOW()
                FROM Temp_AssociationByDevice AS tmpAssDe
                LEFT JOIN  CTS_DataCenter.AssociationByDevice AS AssDe 
					ON tmpAssDe.CTSCustID = AssDe.CTSCustID AND tmpAssDe.DCSDeviceID = AssDe.DCSDeviceID
				WHERE AssDe.CTSAssDevID is null;     
    
	SELECT 		tmpAss.AssociationId, cus.CTSCustID AS CustId, tmpAss.DeviceID 
    FROM 		Temp_Association tmpAss 
	INNER JOIN	CTS_DataCenter.CustDCSAccount cus 
				ON tmpAss.AccountID = cus.AccountID
	INNER JOIN	Temp_AssociationByDevice tmpAssD 
				ON cus.CTSCustID = tmpAssD.CTSCustID 
                AND tmpAssD.DCSDeviceID = tmpAss.DeviceID;     
                          
END$$
DELIMITER ;
