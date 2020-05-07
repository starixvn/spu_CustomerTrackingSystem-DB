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
        , CTSCustID				BIGINT	UNSIGNED
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
	
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    #=========GET CTSCustID IF Existing
    UPDATE 		Temp_Association AS tmp_ass
    INNER JOIN	CTS_DataCenter.CustDCSAccount AS cus 
					ON tmp_ass.AccountID = cus.AccountID
	SET			tmp_ass.CTSCustID = cus.CTSCustID;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    #=======IF CTSCustID Existing 
	INSERT IGNORE INTO 	CTS_DataCenter.AssociationByDevice(CTSCustID, DCSDeviceID, SubscriberID, CreatedTime, InsertTime)
	SELECT 		tmp_ass.CTSCustID 
				, tmp_ass.DeviceID
				, tmp_ass.SubscriberID
				, MIN(tmp_ass.CreatedTime)	
				, CURRENT_TIMESTAMP()	AS InsertTime
	FROM 		Temp_Association 	AS tmp_ass
    WHERE		tmp_ass.CTSCustID IS NOT NULL
    GROUP BY	tmp_ass.CTSCustID, tmp_ass.DeviceID, tmp_ass.SubscriberID; 
	
    UPDATE 		DCS_DataCenter.Association	AS ass
    INNER JOIN	Temp_Association			AS tmp_ass
				ON	ass.AssociationID = tmp_ass.AssociationID
	SET			ass.IsCTSTransformed =	(CASE WHEN tmp_ass.CTSCustID IS NOT NULL 
													THEN 1
											WHEN tmp_ass.CTSCustID IS NULL AND ass.IsCTSTransformed > -4 
													THEN ass.IsCTSTransformed = ass.IsCTSTransformed -1
											END);
    
	#======IF CTSCustID NOT Existing Then update IsCTSTransformed to unsuccess
    UPDATE 		DCS_DataCenter.Association	AS ass
    INNER JOIN	Temp_Association			AS tmp_ass
				ON	ass.AssociationID = tmp_ass.AssociationID
	SET			ass.IsCTSTransformed = (CASE WHEN ass.IsCTSTransformed = -1 THEN -2 ELSE -1 END)
	WHERE 		tmp_ass.CTSCustID IS NULL;  
	
                          
END$$
DELIMITER ;
