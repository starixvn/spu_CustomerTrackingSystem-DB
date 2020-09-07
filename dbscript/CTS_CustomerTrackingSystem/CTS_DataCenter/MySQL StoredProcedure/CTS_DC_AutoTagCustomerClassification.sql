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
                [20200618@Casey.Huynh]135324]: Enhance SP  
                [20200701@Casey.Huynh]135324]: Chagne Flow and Store more Info
				[20200903@Irena.Vo][137550]: Ignore Main category with ActionType = -1. 
                [20200903@Irena.Vo][141042]: Enhance get IsUsedManually = 0 for update category
		Param's Explanation (filtered by):
                
	*/   
    DECLARE v_remark VARCHAR(50);
    DECLARE v_createdBy INT;
    DECLARE v_LastScannedDate DATETIME;
    
	### PERFORMANCE: START
    DECLARE		vrExecKey		BIGINT	UNSIGNED;
	DECLARE		vrSPName		VARCHAR(200)  DEFAULT 'CTS_DC_AutoTagCustomerClassification' ;
    DECLARE		vrStepID		INT;
	DECLARE 	vrNotes	 		VARCHAR(500);
	DECLARE 	vrStartTime		TIMESTAMP(4);
	DECLARE		vrEndTime 		TIMESTAMP(4);
	DECLARE		vrDuration 		BIGINT;	
    DECLARE		vrLgTotalRecord	INT;
    DECLARE		vrFromID		BIGINT;
    DECLARE		vrToID			BIGINT;

    SET		vrExecKey = CRC32((UUID_Short()));    
    SET		vrNotes = '';# CONCAT('Input: ',ip_NoOfAssociation,'_', ip_NoOfBatch) ;		
    SET 	vrStepID = 1;
    
    SET 	vrStartTime = CURRENT_TIMESTAMP(4);	
    
    INSERT INTO DCS_DataCenter.zzTracePerformance (ExecKey, StepID, SPName, Notes, StartTime)
    VALUES(vrExecKey, vrStepID, vrSPName,  vrNotes, vrStartTime);
	### PERFORMANCE: END
    
    SET  v_createdBy = 10278938;
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
    SET SQL_SAFE_UPDATES = 0;
    
    -- Ignore existed customer has Problem Category & Main Category before
    SET vrNotes = CONCAT(vrNotes, ' 1.', CURRENT_TIME());    
    DELETE temp
    FROM Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
	WHERE cc.ParentID = 50;
       
    -- Remove invalid category
    SET vrNotes = CONCAT(vrNotes, ' 2.', CURRENT_TIME());    
    DELETE temp
    FROM Temp_NewClassification temp
    WHERE temp.CategoryID = 0;
    
    -- Update info ctscustid , subscriberid
    SET vrNotes = CONCAT(vrNotes, ' 3.', CURRENT_TIME());       
    UPDATE 		Temp_NewClassification AS temp
    INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID
	SET			temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
    
    #===================================================================================================    
	SET vrNotes = CONCAT(vrNotes, ' 4.', CURRENT_TIME());
    UPDATE 		Temp_NewClassification AS tmpCla
    INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS ccl
				ON tmpCla.CustID = ccl.CustID
                AND tmpCla.SportGroupID = ccl.SportGroupID
	SET 		tmpCla.ActionType =  (CASE WHEN tmpCla.CategoryID != ccl.CategoryID THEN 1
											  WHEN tmpCla.CategoryID = ccl.CategoryID THEN 4 END)		
	WHERE		tmpCla.CategoryID !=0;  
    /*================================================================================================================
    Update Temp Table: -1: Delete, 3: NOT Insert
		-1: Delete CTSCustomerClassification table with CategoryID = 2:  IF SportGroupID= 0, CategoryID = 0 (AI,Robot...) OR SportGroupID > 0
		 2: Remove From Tem table Category =2: Not Insert New Category If Customer has any Category (both Manual and Auto)*/	
    
    SET vrNotes = CONCAT(vrNotes, ' 5.', CURRENT_TIME());    
    UPDATE 		Temp_NewClassification AS tmpCla
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS ccl ON tmpCla.CustID = ccl.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = ccl.CategoryID
	SET			tmpCla.ActionType = (CASE WHEN (ccl.CategoryID = 2 AND tmpCla.CategoryID != 2) THEN -1 
										  WHEN (tmpCla.CategoryID = 2) THEN 2 ELSE tmpCla.ActionType
									 END)
	WHERE		tmpCla.ActionType = 0 AND cc.ParentID = 1;    

    #================================================================================================================
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    SET vrNotes = CONCAT(vrNotes, ' 6.', CURRENT_TIME());
    DELETE 		ccl
    FROM 		CTS_DataCenter.CTSCustomerClassification  AS ccl
    INNER JOIN 	Temp_NewClassification AS tmpCla
				ON tmpCla.CustID = ccl.CustID
	WHERE		ccl.CategoryID = 2 
				AND tmpCla.ActionType = -1;     
                
    SET vrNotes = CONCAT(vrNotes, ' 7.', CURRENT_TIME());
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
            , DATE(tmpCla.LastModifiedDate)	AS LastScannedDate
	FROM 	Temp_NewClassification 		AS tmpCla
	WHERE 	tmpCla.ActionType IN (0,-1)
			AND tmpCla.CategoryId != 0;   
            
	SET vrNotes = CONCAT(vrNotes, ' 8.', CURRENT_TIME());
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS ccl
    INNER JOIN 	Temp_NewClassification AS tmpCla 
				ON 	tmpCla.CustID = ccl.CustID		
				AND tmpCla.SportGroupID = ccl.SportGroupID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc 
		ON cc.CategoryID = ccl.CategoryID
 	SET  ccl.CategoryID = tmpCla.CategoryID
        , ccl.LastModifiedDate = tmpCla.LastModifiedDate 
        , ccl.LastModifiedBy = v_createdBy
        , ccl.LastScannedDate = GREATEST(DATE(tmpCla.LastModifiedDate),ccl.LastScannedDate)
	WHERE tmpCla.ActionType = 1
		AND cc.IsUsedManually = 0; # Get this item so that update correct category
    
    SET vrNotes = CONCAT(vrNotes, ' 9.', CURRENT_TIME());   
     
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
	SET vrNotes = CONCAT(vrNotes, ' 10.', CURRENT_TIME());
	### PERFORMANCE
	SET		vrEndTime = CURRENT_TIMESTAMP(4);
    
	SELECT 	Count(1), Min(tas.CustID), Max(tas.CustID)
    INTO	vrLgTotalRecord, vrFromID, vrToID
    FROM	Temp_NewClassification AS tas;    
    
    UPDATE	DCS_DataCenter.zzTracePerformance AS z
    SET		z.EndTime = vrEndTime
			, z.Duration = TIMESTAMPDIFF(MICROSECOND, vrStartTime, vrEndTime)
            , z.TotalRecord = vrLgTotalRecord
            , z.FromID = vrFromID
            , z.ToID		= vrToID
            , z.Notes = vrNotes
    WHERE	z.ExecKey = vrExecKey AND z.StepID = vrStepID ;    
    
    ### PERFORMANCE: END 
END$$

DELIMITER ;

