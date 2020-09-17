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
                [20200908@Irena.Vo][141755]: Enhance SP & insert Probation Management flow.
		Param's Explanation (filtered by):
                
	*/   
    /**********1. PREPARE PARAMS - TABLES - DATA**********/
     -- Params
     DECLARE     lv_CreatedBy INT DEFAULT 10278938;  
	 DECLARE	 lv_SPName	 VARCHAR(200)  DEFAULT 'CTS_DC_AutoTagCustomerClassification' ;
 
     -- Temporary new category table
     DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	 CREATE TEMPORARY TABLE Temp_NewClassification 
     (	  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED
		, CategoryID		SMALLINT UNSIGNED
		, LastModifiedDate	DATETIME
		, TurnoverRM		DECIMAL(20,4)
		, WinlossRM			DECIMAL(20,4)
		, BetCount			BIGINT
		, ActiveDays		INT	
		, CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , SubscriberID		INT DEFAULT 0    
		, ActionType		INT -- Insert Probation: 0, 3, 5; Insert Category: 0, 1, 3, 4; Update Category: 5, 6; Delete New member: 3, 4; No action: 2
        , PRIMARY KEY	PK_Temp_NewClassification_CustID_SportGroupID(CustID, SportGroupID) 
        , INDEX 		IX_Temp_NewClassification_ActionType(ActionType)        
     );     
    
    -- Temporary existed category table
	 DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	 CREATE TEMPORARY TABLE Temp_ExistedClassification 
     (	  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED
        , CategoryID		SMALLINT UNSIGNED
        , PRIMARY KEY	PK_Temp_ExistedClassification_CustID_SportGroupID_CategoryID(CustID, SportGroupID, CategoryID) 
     );
    
    -- New category data
     INSERT INTO Temp_NewClassification(CustID, SportGroupID, CategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	 SELECT 	  temp.CustID
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
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
			, CategoryID		SMALLINT UNSIGNED	PATH "$.CategoryId"
			, LastModifiedDate	DATETIME			PATH "$.CreatedTime"
            , TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
            , WinlossRM			DECIMAL(20,4)		PATH "$.WinlossRM"
            , BetCount			BIGINT				PATH "$.BetCount"
            , ActiveDays		INT					PATH "$.ActiveDays"		
		 )) AS temp;   
	
    
	 SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
	 SET SQL_SAFE_UPDATES = 0;
    
    /**********2. IGNORE VVIP - PIN CATEGORY**********/
     DELETE temp
	 FROM Temp_NewClassification AS temp
     LEFT JOIN CTS_DataCenter.ProbationAccountMonitor AS pro on pro.CustID IS NULL -- not in Probation list
	 INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID -- is VVIP OR PIN
	 WHERE sc.CreatedFromFunction IN (11, 21);
    
	/**********3. IGNORE PROBLEM CATEGORY**********/
    DELETE temp
    FROM Temp_NewClassification AS temp
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
	INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
	WHERE cc.ParentID = 50;
    
    /**********4. REMOVE INVALID CATEGORY**********/
    DELETE temp
    FROM Temp_NewClassification AS temp
    WHERE temp.CategoryID = 0;
    
    /**********5. UPDATE CUST INFO**********/
    UPDATE 	Temp_NewClassification AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
    
    /**********6. GET EXISTED CATEGORY**********/
    INSERT INTO Temp_ExistedClassification
    SELECT cate.CustID, cate.SportGroupID, cate.CategoryID
    FROM Temp_NewClassification AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID= cate.CategoryID 
    WHERE cc.ParentID = 1; 
    
    /**********7. UPDATE ACTION TYPE**********/
    -- For Other Category
    UPDATE 		Temp_NewClassification AS temp
	LEFT JOIN 	Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID
	SET 		temp.ActionType =  (CASE 
                                         -- Case 1: SportGroupID IS NULL --
                                         -- insert Category, Probation List
                                         WHEN ex.SportGroupID IS NULL AND temp.CategoryID = 10 THEN 0 
										 -- insert Category
                                         WHEN ex.SportGroupID IS NULL THEN 1
                                         -- Case 2: SportGroupID IS NOT NULL --
										 -- no action
                                         WHEN (ex.SportGroupID != 0 AND temp.SportGroupID = 0) OR (ex.SportGroupID = temp.SportGroupID AND ex.CategoryID = temp.CategoryID) THEN 2
                                         -- delete New Member & insert Category, Probation List 
                                         WHEN ex.SportGroupID = 0 AND temp.SportGroupID != 0 AND temp.CategoryID IN (6, 7, 10) THEN 3
										 -- delete New Member & insert Category
                                         WHEN ex.SportGroupID = 0 AND temp.SportGroupID != 0 THEN 4
										 -- update Category to Probation & Insert Probation List
                                         WHEN ex.SportGroupID = temp.SportGroupID 
                                               AND (   (ex.CategoryID NOT IN (6, 7) AND temp.CategoryID IN (6, 7, 10)) 
                                                        OR (ex.CategoryID IN (6, 7) AND temp.CategoryID = 10)
												   )THEN 5
										 -- update Category
                                         WHEN ex.SportGroupID = temp.SportGroupID AND ex.CategoryID != temp.CategoryID THEN 6
									END);
    
   
    /**********8. PROCESS FOR ACTION TYPE**********/
    -- Delete New Member: ActionType = 3, 4
    DELETE 		cate
    FROM 		CTS_DataCenter.CTSCustomerClassification  AS cate
	INNER JOIN 	Temp_NewClassification AS temp ON temp.CustID = cate.CustID
	WHERE		cate.CategoryID = 2 AND temp.ActionType IN (3, 4);     
    
    -- Update Category: ActionType = 5, 6
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN 	Temp_NewClassification AS temp ON 	temp.CustID = cate.CustID AND temp.SportGroupID = cate.SportGroupID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
 	SET   cate.CategoryID = (CASE WHEN temp.ActionType = 5 THEN 10
                                  ELSE temp.CategoryID
                             END)
        , cate.LastModifiedDate = temp.LastModifiedDate 
        , cate.LastModifiedBy = lv_CreatedBy
        , cate.LastScannedDate = GREATEST(DATE(temp.LastModifiedDate),cate.LastScannedDate)
	WHERE temp.ActionType IN (5, 6) AND cc.IsUsedManually = 0;
    
    -- Insert Probation Account Monitor: ActionType = 0, 3, 5
    INSERT  INTO CTS_DataCenter.ProbationAccountMonitor
    (CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime)
	SELECT    temp.CustID
			, temp.CTSCustID
            , temp.SportGroupID
			, temp.CategoryID
			, (temp.WinlossRM/ temp.TurnoverRM) * 100
			, DATE(temp.LastModifiedDate)
			, lv_CreatedBy
			, temp.LastModifiedDate
	 FROM 	Temp_NewClassification 		AS temp
	 WHERE 	temp.ActionType IN (0, 3, 5);
     
     -- Insert Probation Account Info: ActionType = 0, 3, 5
     INSERT  INTO CTS_DataCenter.ProbationAccountInfo (CustID, SportGroupID, CurrentMargin, BetCount, CreatedDate)
	 SELECT   temp.CustID
            , temp.SportGroupID
			, (temp.WinlossRM/ temp.TurnoverRM) * 100
            , temp.BetCount
			, DATE(temp.LastModifiedDate)
	 FROM 	Temp_NewClassification AS temp
	 WHERE 	temp.ActionType IN (0, 3, 5);
    
    -- Insert Category List: ActionType = 0, 1, 3, 4
     INSERT  INTO CTS_DataCenter.CTSCustomerClassification
     (CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	 SELECT   temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, temp.SportGroupID
            , CASE WHEN temp.ActionType IN (0, 3) THEN 10
                   ELSE temp.CategoryID
			 END
			, temp.LastModifiedDate
			, lv_CreatedBy
			, temp.LastModifiedDate
			, lv_CreatedBy
            , DATE(temp.LastModifiedDate)
	 FROM 	Temp_NewClassification 		AS temp
	 WHERE 	temp.ActionType IN (0, 1, 3, 4);
            
    -- Insert Category History List: ActionType = 0, 1, 3, 4, 5, 6
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate,LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType,  IsAuto, InsertDate)
    SELECT 	  temp.CustID
			, temp.CTSCustID
			, CASE WHEN temp.ActionType IN (0, 3, 5) THEN 10
                   ELSE temp.CategoryID
			  END AS CategoryID
            , temp.SportGroupID
            , temp.LastModifiedDate
            , lv_CreatedBy
            , temp.TurnoverRM
            , temp.WinlossRM
            , temp.BetCount
            , temp.ActiveDays
			, temp.ActionType
            , 1
            , CURRENT_DATE()
	FROM 	Temp_NewClassification AS temp
    WHERE	temp.ActionType IN (0, 1, 3, 4, 5, 6);   
   
    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;     

END$$

DELIMITER ;