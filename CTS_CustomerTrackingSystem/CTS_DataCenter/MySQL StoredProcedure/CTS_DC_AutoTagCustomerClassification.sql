DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_AutoTagCustomerClassification`(IN ip_NewClassification JSON)
sp: BEGIN
	/*
		Created:	20200505@Terry.Nguyen
		Task:		Auto tag for Customer Classification
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
                
	*/   
    DECLARE v_remark VARCHAR(50);
    DECLARE v_createdBy INT;
    
    SET v_remark = 'Auto tag customer classification';
    SET v_createdBy = 1027893;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;
    
	CREATE TEMPORARY TABLE Temp_NewClassification 
    (	  
		  CustID			BIGINT
        , CTSCustID			BIGINT DEFAULT 0
        , SportID			INT
		, OldSportID		INT DEFAULT 0
        , CategoryID		INT
        , SubscriberID		INT DEFAULT 0
        , Action			INT DEFAULT 0 # 0: INSERT - 1: UPDATE
    ); 
    
    INSERT INTO Temp_NewClassification
				(CustID,
                SportID,
				CategoryID)                
	SELECT 	
			tmpTable.CustID,
			tmpTable.SportID, 
			tmpTable.CategoryID
	FROM JSON_TABLE(ip_NewClassification,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT 			PATH "$.CustId"
			, SportID 			INT 			PATH "$.SportId"
			, CategoryID		INT				PATH "$.CategoryId" 			
		 )) as tmpTable;   
  
    #=========GET CTSCustID IF Existing
    UPDATE 		Temp_NewClassification AS tmp_class
    INNER JOIN	CTS_DataCenter.CTSCustomer AS cus 
					ON tmp_class.CustID = cus.CustID
	SET			tmp_class.CTSCustID = cus.CTSCustID
				,tmp_class.SubscriberID = cus.SubscriberID;
    #===================================
        
    UPDATE Temp_NewClassification AS tmp_class
    INNER JOIN CTS_DataCenter.CTSCustomerClassification cus
				ON tmp_class.CTSCustID = cus.CTSCustID
                AND tmp_class.SubscriberID = cus.SubscriberID
				AND tmp_class.SportID = cus.SportGroupID
                AND tmp_class.CategoryID = cus.CategoryID
	SET 
			Action = 1
		, 	OldSportID = cus.SportGroupID;
    #======================================
    
    #======= INSERT NEW Customer Classification
    INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy)
		SELECT 
			 temp.CTSCustID
			, temp.SubscriberID
			, temp.CategoryID
			, temp.SportID
			, v_remark
			, current_time()
			, v_createdBy
			, current_time()
			, v_createdBy
		FROM Temp_NewClassification temp
		WHERE temp.Action = 0;
    
    #======= UPDATE Customer Classification
   
    UPDATE CTS_DataCenter.CTSCustomerClassification cus
    INNER JOIN Temp_NewClassification tmp_class 
		ON tmp_class.CTSCustID = cus.CTSCustID
		AND tmp_class.SubscriberID = cus.SubscriberID	
		AND tmp_class.SportID = cus.SportGroupID
		AND tmp_class.CategoryID = cus.CategoryID
 	SET cus.Remark = v_remark
        , cus.CreatedDate = current_time() 
        , cus.CreatedBy = v_createdBy
        , cus.LastModifiedDate = current_time() 
        , cus.LastModifiedBy = v_createdBy
	WHERE tmp_class.Action = 1;
    
    #======= INSERT Customer Classification History
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CTSCustID, SubscriberID, CategoryID, SportGroupID, OldSportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy)
		SELECT 
			 temp.CTSCustID
			, temp.SubscriberID
			, temp.CategoryID
			, temp.SportID
            , temp.OldSportID
			, v_remark
			, current_time()
			, v_createdBy
			, current_time()
			, v_createdBy
		FROM Temp_NewClassification temp
		WHERE temp.Action = 1;
	
    #==========================================
  
END$$
DELIMITER ;
