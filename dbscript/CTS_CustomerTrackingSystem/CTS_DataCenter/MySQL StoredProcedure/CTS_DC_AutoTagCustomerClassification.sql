USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_AutoTagCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_AutoTagCustomerClassification`(IN ip_NewClassification JSON)
BEGIN
	/*
		Created:	20200505@Terry.Nguyen212121
		Task:		Auto tag for Customer Classification
		DB:			CTS_DataCenter
		Original:

		Revisions:
				[20200612@Casey.Huynh][135324]: Enhance SP      
                [20200618@Casey.Huynh][135324]: Enhance SP  
                [20200701@Casey.Huynh][135324]: Chagne Flow and Store more Info
				[20200903@Irena.Vo][137550]: Ignore Main category with ActionType = -1. 
                [20200903@Irena.Vo][141042]: Enhance get IsUsedManually = 0 for update category
                [20200908@Irena.Vo][141020]: Enhance exclude VVIP Customers, Pin Category 
		Param's Explanation (filtered by):
                
	*/   
    DECLARE     lv_CreatedBy INT DEFAULT 10278938;
    
	### PERFORMANCE: START
    DECLARE		lv_ExecKey		BIGINT	UNSIGNED;
	DECLARE		lv_SPName		VARCHAR(200)  DEFAULT 'CTS_DC_AutoTagCustomerClassification' ;
    DECLARE		lv_StepID		INT;
	DECLARE 	lv_Notes	 		VARCHAR(500);
	DECLARE 	lv_StartTime		TIMESTAMP(4);
	DECLARE		lv_EndTime 		TIMESTAMP(4);
	DECLARE		lv_Duration 		BIGINT;	
    DECLARE		lv_LogTotalRecord	INT;
    DECLARE		lv_FromID		BIGINT;
    DECLARE		lv_ToID			BIGINT;

    SET		lv_ExecKey = CRC32((UUID_Short()));    
    SET		lv_Notes = ''; # CONCAT('Input: ',ip_NoOfAssociation,'_', ip_NoOfBatch) ;		
    SET 	lv_StepID = 1;
    
    SET 	lv_StartTime = CURRENT_TIMESTAMP(4);	
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(lv_ExecKey, lv_StepID, lv_SPName,  lv_Notes, lv_StartTime);
	### PERFORMANCE: END
    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification 
    (	  CustID			BIGINT UNSIGNED        
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
        , PRIMARY KEY	PK_Temp_NewClassification_CustID_SportGroupID(CustID, SportGroupID) 
        , INDEX 		IX_Temp_NewClassification_ActionType(ActionType)        
    );     
    
    INSERT INTO Temp_NewClassification(CustID, SportGroupID, CategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT 		  temp.CustID
				, temp.SportGroupID
				, temp.CategoryID
				, temp.LastModifiedDate
                , temp.TurnoverRM
                , temp.WinlossRM
                , temp.BetCount
                , temp.ActiveDays
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
		 )) AS temp;   
	
    #=========GET CTSCustID IF Existing
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    SET SQL_SAFE_UPDATES = 0;
    
	-- Ignore VVIP, Pin Category before
    SET lv_Notes = CONCAT(lv_Notes, ' 1.', CURRENT_TIME());    
    DELETE temp
    FROM Temp_NewClassification AS temp
        INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID
	WHERE sc.CreatedFromFunction IN (11, 21);
    
    -- Ignore existed customer has Problem Category before
    SET lv_Notes = CONCAT(lv_Notes, ' 2.', CURRENT_TIME());    
    DELETE temp
    FROM Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
	WHERE cc.ParentID = 50;
    
    -- Remove invalid category
    SET lv_Notes = CONCAT(lv_Notes, ' 3.', CURRENT_TIME());    
    DELETE temp
    FROM Temp_NewClassification AS temp
    WHERE temp.CategoryID = 0;
    
    -- Update info ctscustid , subscriberid
    SET lv_Notes = CONCAT(lv_Notes, ' 4.', CURRENT_TIME());       
    UPDATE 	Temp_NewClassification AS temp 
		INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
    
    #===================================================================================================    
	SET lv_Notes = CONCAT(lv_Notes, ' 5.', CURRENT_TIME());
    UPDATE 		Temp_NewClassification AS temp
		INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID AND temp.SportGroupID = cate.SportGroupID
	SET 		temp.ActionType =  (CASE WHEN temp.CategoryID != cate.CategoryID THEN 1
										 WHEN temp.CategoryID = cate.CategoryID THEN 4 END)		
	WHERE		temp.CategoryID !=0;  
    /*================================================================================================================
    Update Temp Table: -1: Delete, 3: NOT Insert
		-1: Delete CTSCustomerClassification table with CategoryID = 2:  IF SportGroupID= 0, CategoryID = 0 (AI,Robot...) OR SportGroupID > 0
		 2: Remove From Tem table Category =2: Not Insert New Category If Customer has any Category (both Manual and Auto)*/	
    
    SET lv_Notes = CONCAT(lv_Notes, ' 6.', CURRENT_TIME());    
    UPDATE 		   Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
	SET			temp.ActionType = (CASE WHEN (cate.CategoryID = 2 AND temp.CategoryID != 2) THEN -1 
										WHEN (temp.CategoryID = 2) THEN 2 ELSE temp.ActionType
									 END)
	WHERE		temp.ActionType = 0 AND cc.ParentID = 1;    

    #================================================================================================================
	SET lv_Notes = CONCAT(lv_Notes, ' 7.', CURRENT_TIME());
    DELETE 		cate
    FROM 		CTS_DataCenter.CTSCustomerClassification  AS cate
		INNER JOIN 	Temp_NewClassification AS temp ON temp.CustID = cate.CustID
	WHERE		cate.CategoryID = 2 AND temp.ActionType = -1;     
                
    SET lv_Notes = CONCAT(lv_Notes, ' 8.', CURRENT_TIME());
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification
    (CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID,CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT    temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, temp.CategoryID
			, temp.SportGroupID
			, temp.LastModifiedDate
			, lv_CreatedBy
			, temp.LastModifiedDate
			, lv_CreatedBy
            , DATE(temp.LastModifiedDate)
	FROM 	Temp_NewClassification 		AS temp
	WHERE 	temp.ActionType IN (0,-1)
			AND temp.CategoryId != 0;   
            
	SET lv_Notes = CONCAT(lv_Notes, ' 9.', CURRENT_TIME());
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN 	Temp_NewClassification AS temp 
				ON 	temp.CustID = cate.CustID		
				AND temp.SportGroupID = cate.SportGroupID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
 	SET  cate.CategoryID = temp.CategoryID
        , cate.LastModifiedDate = temp.LastModifiedDate 
        , cate.LastModifiedBy = lv_CreatedBy
        , cate.LastScannedDate = GREATEST(DATE(temp.LastModifiedDate),cate.LastScannedDate)
	WHERE temp.ActionType = 1 AND cc.IsUsedManually = 0; -- get this item so that update correct category
    
    #======= INSERT Customer Classification History
    SET lv_Notes = CONCAT(lv_Notes, ' 10.', CURRENT_TIME());   
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate,LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType,  IsAuto, InsertDate)
    SELECT 	  temp.CustID
			, temp.CTSCustID
			, temp.CategoryID
            , temp.SportGroupID
            , temp.LastModifiedDate
            , lv_CreatedBy
            , TurnoverRM
            , WinlossRM
            , BetCount
            , ActiveDays
			, temp.ActionType
            , 1
            , CURRENT_DATE()
	FROM 	Temp_NewClassification AS temp
    WHERE	temp.ActionType IN (-1, 0, 1);   
    
    ### PERFORMANCE
	SET lv_Notes = CONCAT(lv_Notes, ' 11.', CURRENT_TIME());
	SET		lv_EndTime = CURRENT_TIMESTAMP(4);
	SELECT 	Count(1), Min(temp.CustID), Max(temp.CustID)
    INTO	lv_LogTotalRecord, lv_FromID, lv_ToID
    FROM	Temp_NewClassification AS temp;    
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = lv_EndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, lv_StartTime, lv_EndTime)
            , z.TotalRecord = lv_LogTotalRecord
            , z.FromID = lv_FromID
            , z.ToID		= lv_ToID
            , z.Notes = lv_Notes
    WHERE	z.ExecKey = lv_ExecKey AND z.StepID = lv_StepID ;    
    
    ### PERFORMANCE: END 
    
    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;