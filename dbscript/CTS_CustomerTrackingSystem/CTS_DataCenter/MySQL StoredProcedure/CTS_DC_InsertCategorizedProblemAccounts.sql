/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_InsertCategorizedProblemAccounts`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertCategorizedProblemAccounts`(IN  ip_ProblemAccounts	JSON)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200715@Long.Luu
		Task:		Insert for Problem Accounts
		DB:			CTS_DataCenter
		Original:

		Revisions:
			20200715@Long.Luu [#136460]: Created
			20200828@Roger.Le [#140211]: Enhance Problem Account Category - Multiple Reason 
			20200908@Irena.Vo [#141020]: Exclude VVIP Customers, Pin 
            20201001-20201014@Irena.Vo [#141930]: 
            - Add Multi Problem Category
            - Remove old categoryid from NapCM
             20201019@Irena.Vo [#141930]: Get distinct CustID List for lastest category
			- 20201202@Lex.Khuat: Disable detail categories & clean up wrong syntax [Redmine ID: #145954]
            
		Param's Explanation (filtered by):
	*/   
    DECLARE lv_CreatedBy 		INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT NOW(); 
   
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Temp_ProblemAccounts 
    (	  
			CustID				BIGINT UNSIGNED
        , 	MainDBCategoryID	SMALLINT 
        , 	NewCategoryID		SMALLINT UNSIGNED  -- Category is inserted to CTS
        , 	CTSCustID			BIGINT UNSIGNED DEFAULT NULL
        , 	SubscriberID		INT DEFAULT NULL
		, 	ActionType		    SMALLINT DEFAULT 0 -- Insert: 0; Update: 1, Remove: 2
        , 	PRIMARY KEY			PK_Temp_ProblemAccounts_CustID_MainDBCategoryID(CustID, MainDBCategoryID) 
        , 	INDEX     			IX_Temp_ProblemAccounts_CustID_NewCategoryID(CustID, NewCategoryID) 
        ,   INDEX				IX_Temp_ProblemAccounts_ActionType(ActionType)  
    );  
  
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification 
    (	  
			CustID				BIGINT UNSIGNED
        , 	CurrentCategoryID	SMALLINT UNSIGNED -- Category is existed
        ,   CreatedDate         DATETIME
        ,   IsRemove            BIT DEFAULT 0 -- 1: Remove Category, 0: No change
        , 	INDEX 				IX_Temp_ExistedClassification_CustID_CurrentCategoryID(CustID, CurrentCategoryID)       
     );
  
    INSERT INTO Temp_ProblemAccounts(CustID, MainDBCategoryID)
	SELECT 	DISTINCT temp.CustID
		, 	temp.MainDBCategoryID 
	FROM JSON_TABLE(ip_ProblemAccounts,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, MainDBCategoryID	SMALLINT 			PATH "$.CategoryId"	
		 )) AS temp;
    
    /*GET REMOVE PROBLEM ACCOUNTS*/
	UPDATE Temp_ProblemAccounts
    SET ActionType = 2
    WHERE MainDBCategoryID = -1; -- return remove PA List from NAP CM
    
    /*IGNORE VVIP - PIN CATEGORY*/
    DELETE temp
    FROM Temp_ProblemAccounts AS temp
    INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID
	WHERE sc.CreatedFromFunction IN (11, 21);
    
    /*REMOVE DETAIL & GENERAL CATEGORY BEFORE*/
    DELETE cate
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID
	INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID 
	WHERE cc.ParentID IN (1, 200);
  
	/*REMOVE PROBATION LIST BEFORE*/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = pro.CustID;
   
    /*UPDATE CUST INFO*/
    UPDATE 	Temp_ProblemAccounts AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
  
	/*UPDATE CATEGORY INFO*/
    UPDATE 	Temp_ProblemAccounts
    SET 	NewCategoryID = CASE 
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
							END
	WHERE MainDBCategoryID <> -1;
        
	/*GET EXISTED CATEGORY*/
	INSERT INTO Temp_ExistedClassification (CustID, CurrentCategoryID, CreatedDate)
	SELECT DISTINCT cate.CustID, cate.CategoryID, cate.CreatedDate
    FROM Temp_ProblemAccounts AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID 
    WHERE cc.ParentID = 50 AND (cate.CategoryID NOT BETWEEN 72 AND 80); 
    
	/*REMOVE PROBLEM ACCOUNTS OR OLD CATEGORY*/
	UPDATE Temp_ExistedClassification AS ex
    LEFT JOIN 	 Temp_ProblemAccounts AS temp ON temp.CustID = ex.CustID AND temp.NewCategoryID = ex.CurrentCategoryID
    SET 		 ex.IsRemove = 1
    WHERE  		 temp.ActionType = 2 -- remove PA.
                 OR temp.NewCategoryID IS NULL; -- remove old category.
    
	DELETE 		 cate
    FROM 		 CTS_DataCenter.CTSCustomerClassification cate
    INNER JOIN   CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
    INNER JOIN 	 Temp_ExistedClassification AS ex ON ex.CustID = cate.CustID AND ex.CurrentCategoryID = cate.CategoryID
	WHERE 		 cc.ParentID = 50 AND ex.IsRemove = 1;
    
	/*UPDATE PROBLEM ACCOUNT*/
    UPDATE 		 CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN   CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
    INNER JOIN   Temp_ProblemAccounts AS temp on temp.CustID = cate.CustID AND temp.NewCategoryID = cate.CategoryID
	SET   	    cate.CTSCustID = temp.CTSCustID
			, 	cate.SubscriberID  = temp.SubscriberID
			, 	cate.LastModifiedBy = lv_CreatedBy
			, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
			, 	temp.ActionType = 1
     WHERE 	cc.ParentID = 50;
     
    /*INSERT NEW PROBLEM ACCOUNT*/
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
		 CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	temp.SubscriberID
		, 	temp.NewCategoryID
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	CURRENT_DATE() AS LastScannedDate
	FROM 	Temp_ProblemAccounts AS temp
    WHERE 	temp.ActionType = 0;           
    
	/*INSERT LOG*/
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID,
		LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate)
    SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	temp.NewCategoryID
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	0
		, 	0
		, 	0
		, 	0
		, 	temp.ActionType
		, 	1
		, 	CURRENT_DATE() AS InsertDate
	FROM 	Temp_ProblemAccounts AS temp;            
   
    /*GET DISTINCT CUSTID FOR LASTEST CATEGORY*/
    SELECT DISTINCT temp.CustID AS CustId
    FROM Temp_ProblemAccounts AS temp; -- Get lastest custid for mapping to CC in mainDB
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;     
   
END$$

DELIMITER ;