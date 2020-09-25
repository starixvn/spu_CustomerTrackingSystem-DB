USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_InsertMainCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertMainCustomerClassification`(IN ip_NewClassification JSON)
BEGIN
	/*
		Created:	20200901@Lex.Khuat
		Task:		Auto insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		Original:
		Revisions:
				- [20200901@Lex.Khuat][137550]: Created 
				- [20200908@Irena.Vo][141020]: Enhance Exclude VVIP Customers, Pin category 
				- [20200921@Irena.Vo][141755]: Enhance SP & insert Probation Management flow. Have actioned Probation is initial data yet.
                - [20200923@Irena.Vo][141755]: Enhance SP.
                
		Param's Explanation (filtered by):
			call CTS_DataCenter.CTS_DC_InsertMainCustomerClassification
            ('[{"CustId": 1, "CategoryId": 201, "CreatedTime": "2020-09-13 00:01:00", "TurnoverRM": 100, "WinlossRM": 2056354, "BetCount": 500, "ActiveDays": 8}]');
	*/ 
	/**********1. PREPARE PARAMS**********/
     DECLARE  lv_CreatedBy			INT	DEFAULT 10278938;		# Default user for auto main categories creator 'starixIT'

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
		, ActionType		INT-- Insert: 0; Update Category (Probation): 1; Update Category: 2; Update Category & Delete Probation list: -2; No action: 3
        , PRIMARY KEY	PK_Temp_NewClassification_CustID(CustID) 
        , INDEX 		IX_Temp_NewClassification_ActionType(ActionType)        
     );   
     
	 DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	 CREATE TEMPORARY TABLE Temp_ExistedClassification 
     (	  CustID			BIGINT UNSIGNED        
        , CategoryID		SMALLINT UNSIGNED
     );
    
    INSERT INTO Temp_NewClassification(CustID, SportGroupID, CategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT 		temp.CustID
				, 200
				, temp.CategoryID
				, temp.LastModifiedDate
                , temp.TurnoverRM
                , temp.WinlossRM
                , temp.BetCount
                , temp.ActiveDays
	FROM JSON_TABLE(ip_NewClassification,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, CategoryID		SMALLINT UNSIGNED	PATH "$.CategoryId"
			, LastModifiedDate	DATETIME			PATH "$.CreatedTime"
            , TurnoverRM		DECIMAL(20, 4)		PATH "$.TurnoverRM"
            , WinlossRM			DECIMAL(20, 4)		PATH "$.WinlossRM"
            , BetCount			BIGINT				PATH "$.BetCount"
            , ActiveDays		INT					PATH "$.ActiveDays"		
		 )) AS temp;
	
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    SET SQL_SAFE_UPDATES = 0;
    
    /**********2. IGNORE VVIP - PIN CATEGORY**********/
     DELETE temp
	 FROM Temp_NewClassification AS temp
	 INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID -- is VVIP OR PIN
	 WHERE sc.CreatedFromFunction IN (11, 21);
    
	/**********3. IGNORE PROBLEM CATEGORY**********/
    DELETE temp
    FROM Temp_NewClassification AS temp
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
	INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
	WHERE cc.ParentID = 50;
    
    /**********4. UPDATE CUST INFO**********/
    UPDATE 	Temp_NewClassification AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
    
    /**********5. GET EXISTED CATEGORY**********/
    INSERT INTO Temp_ExistedClassification
    SELECT cate.CustID, cate.CategoryID
    FROM Temp_NewClassification AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID= cate.CategoryID 
    WHERE cc.ParentID = 200; 
   
	/**********6. UPDATE ACTION TYPE**********/
     UPDATE 	Temp_NewClassification AS temp
	LEFT JOIN 	Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID
	SET 		temp.ActionType =  (CASE 
                                         -- No action
                                         WHEN ex.CategoryID = temp.CategoryID THEN 3
										 -- Insert Category
										 WHEN ex.CategoryID IS NULL THEN 0 -- NULL to Other Category. Include Probation
										 -- Update Category to Probation & Insert Probation List
                                         WHEN  (ex.CategoryID NOT IN (203, 204, 206) AND temp.CategoryID IN (203, 204, 206)) -- Normal, VIP to Smart, High Risk, Probation
                                                OR (ex.CategoryID IN (203, 204) AND temp.CategoryID = 206)  -- Smart, High Risk to Probation
											   THEN 1
										-- Update category & Delete Probation if existed Probation before (Scanned is Smart/High Risk)
										  WHEN (ex.CategoryID = 206 AND temp.CategoryID IN (203, 204)) THEN -2 -- Update category & Delete Probation list
										-- Only update category
										  WHEN ex.CategoryID != temp.CategoryID THEN 2 -- Update category (Not Smart, High Risk, Probation) 
									END)
     WHERE temp.ActionType IS NULL; 
   
   /**********7. PROCESS FOR ACTION TYPE**********/
   -- Remove Probation Account Monitor: ActionType = -2
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN Temp_NewClassification AS temp on temp.CustID = pro.CustID
	WHERE 	pro.SportGroupID = 200 AND temp.ActionType = -2;
    
    -- Update Category: ActionType = -2, 1, 2
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN 	Temp_NewClassification AS temp ON 	temp.CustID = cate.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
 	SET   cate.CTSCustID = temp.CTSCustID
        , cate.SubscriberID  = temp.SubscriberID
        , cate.CategoryID = (CASE WHEN (temp.ActionType = 1 AND temp.CategoryID IN (203, 204)) THEN 206 -- Update category to Smart Punter, High Risk Punter
                                  ELSE temp.CategoryID
                             END)
        , cate.LastModifiedDate = temp.LastModifiedDate 
        , cate.LastModifiedBy = lv_CreatedBy
        , cate.LastScannedDate = GREATEST(DATE(temp.LastModifiedDate),cate.LastScannedDate)
	WHERE temp.ActionType IN (-2, 1, 2) AND cc.ParentID = 200 AND cc.IsUsedManually = 0;
    
    -- Insert Probation Account Monitor: ActionType = 0, 1
    INSERT  INTO CTS_DataCenter.ProbationAccountMonitor
    (CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime)
	SELECT    temp.CustID
			, temp.CTSCustID
            , temp.SportGroupID
			, temp.CategoryID
			, CASE WHEN temp.WinlossRM != 0 THEN (temp.WinlossRM/ temp.TurnoverRM) * 100
                   ELSE 0
			  END AS FirstMargin
			, DATE(temp.LastModifiedDate)
			, lv_CreatedBy
			, temp.LastModifiedDate
	 FROM 	Temp_NewClassification 		AS temp
	 WHERE 	(temp.ActionType = 0 AND temp.CategoryID = 206)  -- Insert new Probation
            OR (temp.ActionType = 1 AND temp.CategoryID IN (203, 204, 206));  -- Update category to Probation, Smart Punter, High Risk Punter
     
    -- Insert Category List: ActionType = 0
     INSERT  INTO CTS_DataCenter.CTSCustomerClassification
     (CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	 SELECT   temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, temp.SportGroupID
            , temp.CategoryID
			, temp.LastModifiedDate
			, lv_CreatedBy
			, temp.LastModifiedDate
			, lv_CreatedBy
            , DATE(temp.LastModifiedDate)
	 FROM 	Temp_NewClassification 		AS temp
	 WHERE 	temp.ActionType = 0;
            
    -- Insert Category History List: ActionType = -2, 0, 1, 2
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate,LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType,  IsAuto, InsertDate)
    SELECT 	  temp.CustID
			, temp.CTSCustID
			, temp.CategoryID
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
    WHERE	temp.ActionType IN (-2, 0, 1, 2);   
   
	SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
   
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;     
END$$

DELIMITER ;