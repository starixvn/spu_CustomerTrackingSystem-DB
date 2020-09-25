USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_InsertCategorizedProblemAccounts`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertCategorizedProblemAccounts`(IN ip_ProblemAccounts JSON)
BEGIN
	/*
		Created:	20200715@Long.Luu
		Task:		Insert for Problem Accounts
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- [20200715@Long.Luu][136460]: Created 
            - [20200908@Irena.Vo][141020]: Enhance Exclude VVIP Customers, Pin
            - [20200921@Irena.Vo][141755]: Enhance SP & insert Probation Management flow.
			- [20200923@Irena.Vo][141755]: Enhance SP 
             
		Param's Explanation (filtered by):
             call CTS_DataCenter.CTS_DC_InsertCategorizedProblemAccounts ('[{"CustId": 1, "CategoryId": 27}]');
	*/   
    /**********1. PREPARE PARAMS**********/
    DECLARE lv_CreatedBy 		INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT NOW();
 
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Temp_ProblemAccounts 
    (	    CustID				BIGINT UNSIGNED
        , 	MainDBCategoryID	SMALLINT UNSIGNED
        , 	CategoryID			SMALLINT UNSIGNED
        , 	CTSCustID			BIGINT UNSIGNED DEFAULT NULL
        , 	SubscriberID		INT DEFAULT NULL
        ,   ActionType		    INT-- Insert: 0; Update Category: 1; No action: 2
		, 	PRIMARY KEY			PK_Temp_ProblemAccounts_CustID(CustID)  
        ,	INDEX				IX_Temp_ProblemAccounts_ActionType(ActionType)  
    );     
    
	 DROP TEMPORARY TABLE IF EXISTS Temp_ExistedProblemAccounts;    
	 CREATE TEMPORARY TABLE Temp_ExistedProblemAccounts 
     (	  CustID			BIGINT UNSIGNED        
        , CategoryID		SMALLINT UNSIGNED
     );
    
    INSERT INTO Temp_ProblemAccounts(CustID, MainDBCategoryID)
	SELECT 	temp.CustID
		, 	temp.MainDBCategoryID
	FROM JSON_TABLE(ip_ProblemAccounts,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, MainDBCategoryID	SMALLINT UNSIGNED	PATH "$.CategoryId"	
		 )) AS temp;   
        
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;     
    SET SQL_SAFE_UPDATES = 0;
    
    /**********2. IGNORE INVALID PROBLEM ACCOUNT**********/
    DELETE temp
    FROM Temp_ProblemAccounts AS temp
    WHERE temp.MainDBCategoryID = 0; 
    
	/**********3. IGNORE VVIP - PIN CATEGORY**********/
    DELETE temp
	FROM Temp_ProblemAccounts AS temp
	INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID -- is VVIP OR PIN
	WHERE sc.CreatedFromFunction IN (11, 21);
    
    /**********4. REMOVE DETAIL & GENERAL CATEGORY BEFORE**********/
    DELETE cate
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID
	INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID 
	WHERE cc.ParentID IN (1, 200);
    
    /**********5. REMOVE PROBATION LIST BEFORE**********/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = pro.CustID;
   
   /**********6. UPDATE CUST INFO**********/
    UPDATE 	Temp_ProblemAccounts AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
    
   /**********7. UPDATE CATEGORY INFO**********/
    UPDATE Temp_ProblemAccounts
    SET CategoryID =   CASE 
							WHEN MainDBCategoryID = 27 THEN 51
                            WHEN MainDBCategoryID = 28 THEN 52
                            WHEN MainDBCategoryID = 29 THEN 53
                            WHEN MainDBCategoryID = 30 THEN 54
                            WHEN MainDBCategoryID = 31 THEN 55
                            WHEN MainDBCategoryID = 32 THEN 56
                            WHEN MainDBCategoryID = 36 THEN 57
                            WHEN MainDBCategoryID = 37 THEN 58
                            WHEN MainDBCategoryID = 38 THEN 59
                            WHEN MainDBCategoryID = 101 THEN 151
                            WHEN MainDBCategoryID = 102 THEN 152
                            WHEN MainDBCategoryID = 103 THEN 153
                            WHEN MainDBCategoryID = 104 THEN 154
                            WHEN MainDBCategoryID = 105 THEN 155
                            WHEN MainDBCategoryID = 106 THEN 156
                            WHEN MainDBCategoryID = 107 THEN 157
                            WHEN MainDBCategoryID = 108 THEN 158
                            WHEN MainDBCategoryID = 109 THEN 159
                            WHEN MainDBCategoryID = 255 THEN 160
						END;

    /**********8. GET EXISTED CATEGORY**********/
    INSERT INTO Temp_ExistedProblemAccounts
    SELECT cate.CustID, cate.CategoryID
    FROM Temp_ProblemAccounts AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID= cate.CategoryID 
    WHERE cc.ParentID = 50; 
    
    /**********9. UPDATE ACTION TYPE**********/
	UPDATE 	Temp_ProblemAccounts AS temp
	LEFT JOIN 	Temp_ExistedProblemAccounts AS ex ON ex.CustID = temp.CustID
	SET 		temp.ActionType =  (CASE 
                                         -- no action
                                         WHEN ex.CategoryID = temp.CategoryID THEN 2
										 -- insert Category
										 WHEN ex.CategoryID IS NULL THEN 0
										 -- only update category
										 WHEN ex.CategoryID != temp.CategoryID THEN 1
									END)
     WHERE temp.ActionType IS NULL; 
   
   /**********10. PROCESS FOR ACTION TYPE**********/
    -- Update Category: ActionType = 1
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN 	Temp_ProblemAccounts AS temp ON 	temp.CustID = cate.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
 	SET    cate.CTSCustID = temp.CTSCustID
        , cate.SubscriberID  = temp.SubscriberID
		, cate.CategoryID = temp.CategoryID
        , cate.LastModifiedDate = lv_CurrentDateTime
        , cate.LastModifiedBy = lv_CreatedBy
        , cate.LastScannedDate = DATE(lv_CurrentDateTime)
	WHERE temp.ActionType = 1 AND cc.ParentID = 50 AND cc.IsUsedManually = 0;
    
     -- Insert Category List: ActionType = 0
     INSERT  INTO CTS_DataCenter.CTSCustomerClassification
     (CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	 SELECT   temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, 0
            , temp.CategoryID
			, lv_CurrentDateTime
			, lv_CreatedBy
			, lv_CurrentDateTime
			, lv_CreatedBy
            , DATE(lv_CurrentDateTime)
	 FROM 	Temp_ProblemAccounts 		AS temp
	 WHERE 	temp.ActionType = 0;
            
    -- Insert Category History List: ActionType = 0, 1
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate,LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType,  IsAuto, InsertDate)
    SELECT 	  temp.CustID
			, temp.CTSCustID
			, temp.CategoryID
            , 0
            , lv_CurrentDateTime
            , lv_CreatedBy
            , 0
            , 0
            , 0
            , 0
			, temp.ActionType
            , 1
            , CURRENT_DATE()
	FROM 	Temp_ProblemAccounts AS temp
    WHERE	temp.ActionType IN (0, 1);    
    
	SET SQL_SAFE_UPDATES = 1; 
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedProblemAccounts;    
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;    
    
END$$

DELIMITER ;