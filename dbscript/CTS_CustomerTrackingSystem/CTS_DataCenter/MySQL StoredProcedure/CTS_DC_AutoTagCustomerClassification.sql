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
				[20200612@Casey.Huynh][135324]: Enhance SP      
                [20200618@Casey.Huynh]135324]: Enhance SP  
                [20200624@Casey.Huynh]135324]: Chagne Flow and Store more Info
        
		Param's Explanation (filtered by):
                
	*/   
    DECLARE v_remark VARCHAR(50);
    DECLARE v_createdBy INT;
    DECLARE v_LastScannedDate DATETIME;

    SET  v_createdBy = 1027893;
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
        , ActionType		INT DEFAULT 0 # (0: INSERT),  (1: UPDATE)
		, TurnoverRM		DECIMAL(20,4)
		, WinlossRM			DECIMAL(20,4)
		, BetCount			BIGINT
		, ActiveDays		INT	
        
        , PRIMARY KEY	PK_Temp_NewClassification_CTSCustID(CustID, SportGroupID) 
        , INDEX 		IX_Temp_NewClassification_ActionType(ActionType)        
    );     
    
    INSERT INTO Temp_NewClassification(CustID, SportGroupID, CategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT 		tmpTable.CustID
				, tmpTable.SportGroupID
				, tmpTable.CategoryID
				, tmpTable.LastModifiedDate
                , tmpTable.TurnoverRM
                , tmpTable.WinlossRM
                , tmpTable.BetCount
                , tmpTable.ActiveDays
	FROM JSON_TABLE(ip_NewClassification,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId" #0:
			, CategoryID		SMALLINT UNSIGNED	PATH "$.CategoryId"
			, LastModifiedDate	DATETIME			PATH "$.CreatedTime"
            , TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
            , WinlossRM			DECIMAL(20,4)		PATH "$.WinlossRM"
            , BetCount			BIGINT				PATH "$.BetCount"
            , ActiveDays		INT					PATH "$.ActiveDays"		
		 )) as tmpTable;   
	
    #=========GET CTSCustID IF Existing
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;    
    SELECT * FROM Temp_NewClassification;
    UPDATE 		Temp_NewClassification AS tmpCla
    LEFT JOIN	CTS_DataCenter.CTSCustomer AS cus 
					ON tmpCla.CustID = cus.CustID
	SET			tmpCla.CTSCustID = cus.CTSCustID
				, tmpCla.SubscriberID = cus.SubscriberID;
                
    #===================================================================================================    
    UPDATE 		Temp_NewClassification AS tmpCla
    INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS ccl
				ON tmpCla.CustID = ccl.CustID
                AND tmpCla.SportGroupID = ccl.SportGroupID
	INNER JOIN 	CTS_DataCenter.CustomerCategory AS cua
				ON ccl.CategoryID = cua.CategoryID 
					AND cua.IsUsedManually = 0
	SET 		tmpCla.ActionType = 1
	WHERE		tmpCla.CategoryID != ccl.CategoryID
				AND tmpCla.CategoryID !=0;    
    
    /*================================================================================================================
    Update Temp Table: -1: Delete, 3: NOT Insert
		-1: Delete CTSCustomerClassification table with CategoryID = 2:  IF SportGroupID= 0, CategoryID = 0 (AI,Robot...) OR SportGroupID > 0
		 2: Remove From Tem table Category =2: Not Insert New Category If Customer has any Category (both Manual and Auto)*/	
    
       
    UPDATE 		Temp_NewClassification 	AS tmpCla
    INNER JOIN	CTS_DataCenter.CTSCustomerClassification  AS ccl 
				ON tmpCla.CustID = ccl.CustID
	SET			tmpCla.ActionType = (CASE WHEN (ccl.CategoryID = 2 AND tmpCla.CategoryID != 2) THEN -1 
										  WHEN (tmpCla.CategoryID = 2) THEN 2 ELSE tmpCla.ActionType
									 END)
	WHERE		tmpCla.ActionType = 0;
    
    UPDATE		Temp_NewClassification AS tmpCla    
    SET			tmpCla.ActionType = 3
    WHERE		tmpCla.ActionType = 0 AND tmpCla.CategoryID = 0;

    #================================================================================================================
    DELETE 		ccl
    FROM 		CTS_DataCenter.CTSCustomerClassification  AS ccl
    INNER JOIN 	Temp_NewClassification AS tmpCla
				ON tmpCla.CustID = ccl.CustID
	WHERE		ccl.CategoryID = 2 
				AND tmpCla.ActionType = -1;     
    
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
				 CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 
			tmpCla.CustID
			, tmpCla.CTSCustID
			, tmpCla.SubscriberID
			, tmpCla.CategoryID
			, tmpCla.SportGroupID
			, tmpCla.LastModifiedDate
			, v_createdBy
			, tmpCla.LastModifiedDate
			, v_createdBy
            , tmpCla.LastModifiedDate 	AS LastScannedDate
	FROM 	Temp_NewClassification 		AS tmpCla
	WHERE 	tmpCla.ActionType IN (0,-1)
			AND tmpCla.CategoryId != 0;   

    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN 	Temp_NewClassification AS tmpCla 
				ON 	tmpCla.CustID = ccl.CustID		
				AND tmpCla.SportGroupID = ccl.SportGroupID
	INNER JOIN 	CTS_DataCenter.CustomerCategory AS cua
				ON ccl.CategoryID = cua.CategoryID 
                AND cua.IsUsedManually = 0 
 	SET  ccl.CategoryID = tmpCla.CategoryID
        , ccl.LastModifiedDate = tmpCla.LastModifiedDate 
        , ccl.LastModifiedBy = v_createdBy
        , ccl.LastScannedDate = GREATEST(tmpCla.LastModifiedDate,ccl.LastScannedDate)
	WHERE tmpCla.ActionType = 1;
    
    #======= INSERT Customer Classification History
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID
					,SportGroupID ,LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType,  IsAuto, InsertDate)
    SELECT 	tmpCla.CustID
			, tmpCla.CTSCustID
			, tmpCla.CategoryID
            , tmpCla.SportGroupID
            , tmpCla.LastModifiedDate
            , v_createdBy
            , TurnoverRM
            , WinlossRM
            , BetCount
            , ActiveDays
			, tmpCla.ActionType
            , 1
            , CURRENT_DATE() AS InsertDate
	FROM 	Temp_NewClassification AS tmpCla
    WHERE	tmpCla.ActionType IN (-1, 0, 1);     
	

	
END$$
DELIMITER ;
