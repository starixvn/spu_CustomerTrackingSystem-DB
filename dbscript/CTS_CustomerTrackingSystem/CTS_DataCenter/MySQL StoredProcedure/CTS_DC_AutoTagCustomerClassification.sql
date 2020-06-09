DELIMITER $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_AutoTagCustomerClassification$$
CREATE DEFINER=`fps`@`%` PROCEDURE CTS_DataCenter.CTS_DC_AutoTagCustomerClassification(IN ip_NewClassification JSON)
BEGIN
	/*
		Created:	20200505@Terry.Nguyen
		Task:		Auto tag for Customer Classification
		DB:			CTS_DataCenter
		Original:

		Revisions:
				20200604@CaseyHuynh: Enhance SP
        
		Param's Explanation (filtered by):
                
	*/   
    DECLARE v_remark VARCHAR(50);
    DECLARE v_createdBy INT;
    DECLARE v_LastScannedDate DATETIME;

    SET v_createdBy = 1027893;
	SET  v_LastScannedDate = CURRENT_DATE();
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification 
    (	  
		  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED
        , CategoryID		SMALLINT UNSIGNED
		, LastModifiedDate	DATETIME
        , CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , SubscriberID		INT DEFAULT 0
        , OldCategoryID		SMALLINT UNSIGNED
        
        , ActionType			INT DEFAULT 0 # 0: INSERT - 1: UPDATE
        
        , PRIMARY KEY	PK_Temp_NewClassification_CTSCustID(CustID, SportGroupID) 
        , INDEX IX_Temp_NewClassification_ActionType(ActionType)
    );     
    
    INSERT INTO Temp_NewClassification(CustID, SportGroupID, CategoryID, LastModifiedDate)
	SELECT 		tmpTable.CustID
				, tmpTable.SportGroupID
				, tmpTable.CategoryID
				, tmpTable.LastModifiedDate
	FROM JSON_TABLE(ip_NewClassification,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId" #0:
			, CategoryID		SMALLINT UNSIGNED	PATH "$.CategoryId"
			, LastModifiedDate	DATETIME			PATH "$.CreatedTime"
		 )) as tmpTable;   

    #=========GET CTSCustID IF Existing
    UPDATE 		Temp_NewClassification AS tmpCla
    LEFT JOIN	CTS_DataCenter.CTSCustomer AS cus 
					ON tmpCla.CustID = cus.CustID
	SET			tmpCla.CTSCustID = cus.CTSCustID
				, tmpCla.SubscriberID = cus.SubscriberID;
    #==========================================================       
    
    UPDATE 		Temp_NewClassification AS tmpCla
    INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS ccl
				ON tmpCla.CustID = ccl.CustID
                AND tmpCla.SportGroupID = ccl.SportGroupID
	INNER JOIN 	CTS_DataCenter.CustomerCategory AS cua
				ON ccl.CategoryID = cua.CategoryID AND cua.IsUsedManually = 0
	SET 		tmpCla.ActionType = (CASE WHEN (tmpCla.CategoryID != ccl.CategoryID) THEN 1 #OR tmpCla.CategoryID = 0 
									ELSE 0 END)
				, tmpCla.OldCategoryID = ccl.CategoryID;
	
    #=========================================================
    #=====Remove New Member Category IF SportGroupID= -1(AI,Robot...) OR SportGroupID >0
    DELETE 		tmpCla
    FROM 		Temp_NewClassification AS tmpCla
    INNER JOIN 	CTS_DataCenter.CTSCustomerClassification  AS ccl
				ON tmpCla.CustID = ccl.CustID
	WHERE		tmpCla.CategoryID = 2;
    
    DELETE 		ccl
    FROM 		CTS_DataCenter.CTSCustomerClassification  AS ccl
    INNER JOIN 	Temp_NewClassification AS tmpCla
				ON tmpCla.CustID = ccl.CustID
	WHERE		ccl.CategoryID = 2; 
    
    INSERT  IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 
			temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, temp.CategoryID
			, temp.SportGroupID
			, LastModifiedDate
			, v_createdBy
			, LastModifiedDate
			, v_createdBy
            , LastModifiedDate
	FROM 	Temp_NewClassification AS temp
	WHERE 	temp.ActionType = 0
			AND temp.CategoryId != 0
	ON DUPLICATE KEY UPDATE   LastModifiedDate = temp.LastModifiedDate;
    
    #======= UPDATE Customer Classification   
    UPDATE 		CTS_DataCenter.CTSCustomerClassification ccl
    INNER JOIN 	Temp_NewClassification tmpCla 
				ON 	tmpCla.CustID = ccl.CustID		
				AND tmpCla.SportGroupID = ccl.SportGroupID
	INNER JOIN 	CTS_DataCenter.CustomerCategory AS cua
				ON ccl.CategoryID = cua.CategoryID AND cua.IsUsedManually = 0 
 	SET  ccl.CategoryID = tmpCla.CategoryID
        , ccl.LastModifiedDate = tmpCla.LastModifiedDate 
        , ccl.LastModifiedBy = v_createdBy
	WHERE tmpCla.ActionType = 1;
    
    #======= INSERT Customer Classification History
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID
					,SportGroupID ,LastModifiedDate, LastModifiedBy, IsAuto)
    SELECT 	CustID
			, CTSCustID
			, CategoryID
            , SportGroupID
            , LastModifiedDate
            , v_createdBy
            , 1 AS IsByAuto
	FROM 	Temp_NewClassification AS tmpCla; 
    #WHERE	tmpCla.ActionType = 1;
    #==========================================
  
END$$
DELIMITER ;
