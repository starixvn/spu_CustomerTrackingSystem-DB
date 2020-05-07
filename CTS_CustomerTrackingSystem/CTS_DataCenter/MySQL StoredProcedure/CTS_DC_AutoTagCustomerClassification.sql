DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_AutoTagCustomerClassification`(IN ip_NewClassification JSON)
BEGIN
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
    SET v_createdBy = 8;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;
    
	CREATE TEMPORARY TABLE Temp_NewClassification 
    (	  
		  CustID			BIGINT
        , CTSCustID			BIGINT DEFAULT 0
        , SportID			INT      
        , CategoryID		INT
        , SubscriberID		INT DEFAULT 0
        , GroupID			INT DEFAULT 0
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
    
    #=========ARRANGE
   
    UPDATE Temp_NewClassification SET GroupID = CASE 
													WHEN CategoryID = 2 THEN 1 # New Member
													WHEN CategoryID IN (3, 5) THEN 2 # VIP, VVIP
                                                    WHEN CategoryID IN (6, 7) THEN 3 # Smart Punter, High Risk Punter
                                                    WHEN CategoryID = 0 THEN 4 # DELETE ALL CATEGORY
                                                    ELSE 5 # ANOTHER CATEGORY
												END
	WHERE CustID = CustID AND SportID = SportID;

	#===========DELETE NEW MEMBER CATEGORY
    SET SQL_SAFE_UPDATES = 0;
    
   DELETE cus FROM CTS_DataCenter.CTSCustomerClassification cus 
        INNER JOIN Temp_NewClassification tmp ON 
					tmp.CTSCustID = cus.CTSCustID 
					AND tmp.SubscriberID = cus.SubscriberID 
                    AND tmp.SportID = cus.SportGroupID 
		WHERE tmp.GroupID  = 4 AND cus.CategoryID = 2;
        
    SET SQL_SAFE_UPDATES = 1;
    #===========INSERT FOR Smart Punter, High Risk Punter
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    
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
	WHERE temp.GroupID = 3 
    ON DUPLICATE KEY UPDATE 
		Remark = v_remark
        , CreatedDate = current_time()
        , CreatedBy = v_createdBy
        , LastModifiedDate = current_time()
        , LastModifiedBy = v_createdBy;
    
    SELECT ROW_COUNT() INTO @rowCount;
    
    IF  @rowCount != 0 THEN
		#=========== DELETE VIP, VVIP
		DELETE cus FROM CTS_DataCenter.CTSCustomerClassification cus 
        INNER JOIN Temp_NewClassification tmp ON 
					tmp.CTSCustID = cus.CTSCustID 
					AND tmp.SubscriberID = cus.SubscriberID 
		WHERE cus.CategoryID IN (3, 5);	
    ELSE
		#===========INSERT FOR VIP, VVIP
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
		WHERE temp.GroupID = 2 
		ON DUPLICATE KEY UPDATE 
			Remark = v_remark
			, CreatedDate = current_time()
			, CreatedBy = v_createdBy
			, LastModifiedDate = current_time()
			, LastModifiedBy = v_createdBy;
    END IF;
    
	# ==============INSERT FOR NORMAL CASE
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
		WHERE temp.GroupID = 5 
		ON DUPLICATE KEY UPDATE 
			Remark = v_remark
			, CreatedDate = current_time()
			, CreatedBy = v_createdBy
			, LastModifiedDate = current_time()
			, LastModifiedBy = v_createdBy;
    
    #=========INSERT NEW MEMBER
     
    IF NOT EXISTS(SELECT 1 FROM Temp_NewClassification temp 
				INNER JOIN CTS_DataCenter.CTSCustomerClassification cusClass ON 
					temp.CTSCustID = cusClass.CTSCustID 
					AND temp.SubscriberID = cusClass.SubscriberID 
					AND temp.SportID = cusClass.SportGroupID
				WHERE temp.GroupID = 1) THEN
                
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
         WHERE temp.GroupID = 1;
    END IF;
    
    INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(13, 'CTS_DC_AutoTagCustomerClassification', CONCAT('Auto tag CTSCustomerClassification: ','CreatedBy_', v_createdBy,')'), CURRENT_TIME(), v_createdBy);
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    #=============================================
END$$
DELIMITER ;
