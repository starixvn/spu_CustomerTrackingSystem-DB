/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_InsertCategorizedProblemAccounts`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertCategorizedProblemAccounts`(IN ip_ProblemAccounts json)
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
            20201019@Irena.Vo  [#141930]: Get distinct CustID List for lastest category
            - 20201202@Lex.Khuat: Disable detail categories & clean up wrong syntax [Redmine ID: #145954]
			- 20201214@Irena.Vo: Update History Log & Return list CustID with TypeID IN (3, 4) [RedmineID: #145951]
           - 20201215@Irena.Vo: Enhance logic join with CategoryID [RedmineID: #145951]
            
		Param's Explanation (filtered by):
	*/   
    DECLARE lv_CreatedBy 		INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME(); 
   
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Temp_ProblemAccounts 
    (	  
			CustID				BIGINT UNSIGNED
        , 	MainDBCategoryID	SMALLINT 
        , 	CategoryID		    SMALLINT UNSIGNED
        , 	CTSCustID			BIGINT UNSIGNED
        , 	SubscriberID		INT DEFAULT NULL
		, 	ActionType		    SMALLINT DEFAULT 0 -- Insert: 0, Update: 1, Remove: 2
        ,   TargetCC            TINYINT
        , 	PRIMARY KEY			PK_Temp_ProblemAccounts_CustID_MainDBCategoryID(CustID, MainDBCategoryID) 
        , 	INDEX     			IX_Temp_ProblemAccounts_CategoryID_TargetCC(CategoryID,TargetCC) 
        ,   INDEX				IX_Temp_ProblemAccounts_ActionType(ActionType)  
    );  
     
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification 
    (	  
			CustID				BIGINT UNSIGNED
        , 	CategoryID	        SMALLINT UNSIGNED
        ,   IsRemove            BIT DEFAULT 0 -- 1: Remove Category, 0: No Action
        , 	INDEX 				IX_Temp_ExistedClassification_CustID_CategoryID(CustID, CategoryID)       
        , 	INDEX 				IX_Temp_ExistedClassification_IsRemove(IsRemove)       
     );
     
    INSERT INTO Temp_ProblemAccounts(CustID, MainDBCategoryID)
	SELECT 	DISTINCT temp.CustID
		, 	temp.MainDBCategoryID 
	FROM JSON_TABLE(ip_ProblemAccounts,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, MainDBCategoryID	SMALLINT 			PATH "$.CategoryId"	
		 )) AS temp;
    
    /*	GET REMOVE PROBLEM ACCOUNTS	*/
	UPDATE Temp_ProblemAccounts
    SET ActionType = 2
    WHERE MainDBCategoryID = -1; -- return remove PA List from NAP CM
    
    /*	IGNORE PIN CATEGORY	*/
    DELETE temp
    FROM Temp_ProblemAccounts AS temp
    INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CustID = temp.CustID;
    
    /*	REMOVE GENERAL CATEGORY BEFORE	*/
    DELETE cate
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID
	WHERE cate.CategoryID > 200 AND cate.CategoryID < 300;
  
	/*	REMOVE PROBATION LIST BEFORE	*/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = pro.CustID;
   
    /*	UPDATE CUST INFO	*/
    UPDATE 	Temp_ProblemAccounts AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
  
	/*	UPDATE CATEGORY INFO	*/
    UPDATE 	Temp_ProblemAccounts
    SET 	CategoryID = CASE 
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
	INSERT INTO Temp_ExistedClassification (CustID, CategoryID)
	SELECT DISTINCT cate.CustID, cate.CategoryID
    FROM Temp_ProblemAccounts AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    WHERE cate.CategoryID > 50 AND cate.CategoryID < 200 AND (cate.CategoryID NOT BETWEEN 72 AND 80); 
    
	/*	REMOVE PROBLEM ACCOUNTS OR OLD CATEGORY	*/
	UPDATE       Temp_ExistedClassification AS ex
    LEFT JOIN 	 Temp_ProblemAccounts AS temp ON temp.CustID = ex.CustID AND temp.CategoryID = ex.CategoryID
    SET 		 ex.IsRemove = 1
    WHERE  		 temp.ActionType = 2 -- remove PA.
                 OR temp.CategoryID IS NULL; -- remove old category.
    
	DELETE 		 cate
    FROM 		 CTS_DataCenter.CTSCustomerClassification cate
    INNER JOIN 	 Temp_ExistedClassification AS ex ON ex.CustID = cate.CustID AND ex.CategoryID = cate.CategoryID
	WHERE 		 cate.CategoryID > 50 AND cate.CategoryID < 200 AND (cate.CategoryID NOT BETWEEN 72 AND 80) AND ex.IsRemove = 1;
    
	/*	UPDATE PROBLEM ACCOUNT	*/
    UPDATE       Temp_ProblemAccounts AS temp 
    INNER JOIN 	 Temp_ExistedClassification AS ex ON temp.CustID = ex.CustID AND temp.CategoryID = ex.CategoryID
    SET 		 temp.ActionType = 1;
    
    UPDATE 		 CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN   Temp_ProblemAccounts AS temp on temp.CustID = cate.CustID AND temp.CategoryID = cate.CategoryID
	SET   	    cate.CTSCustID = temp.CTSCustID
			, 	cate.SubscriberID  = temp.SubscriberID
			, 	cate.LastModifiedBy = lv_CreatedBy
            ,   cate.LastModifiedDate = lv_CurrentDateTime
			, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
     WHERE 	cate.CategoryID > 50 AND cate.CategoryID < 200 AND (cate.CategoryID NOT BETWEEN 72 AND 80) AND temp.ActionType = 1;
     
    /*	INSERT NEW PROBLEM ACCOUNT	*/
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
		 CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	temp.SubscriberID
		, 	temp.CategoryID
		, 	0 
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime)
	FROM 	Temp_ProblemAccounts AS temp
    WHERE 	temp.ActionType = 0;           
   
   -- UPDATE CUSTOMER CLASS
	UPDATE Temp_ProblemAccounts AS temp
	INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON temp.CategoryID = map.CategoryID
	SET temp.TargetCC = map.CustomerClass;
   
    /* INSERT LOG */
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID)
    SELECT  temp.CustID
		, 	temp.CTSCustID
		, 	CASE WHEN temp.ActionType = 2 AND ex.CategoryID IS NOT NULL THEN ex.CategoryID  -- remove PA
				 ELSE temp.CategoryID
			END
		, 	0 
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	temp.ActionType
		, 	1 -- auto
		, 	DATE(lv_CurrentDateTime)
		, 	CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass 
				 WHEN temp.TargetCC IS NULL THEN -1 -- no mapping CC
                 ELSE temp.TargetCC
			END
		, 	CASE WHEN temp.ActionType = 2 THEN 8 -- item name = Remove PA
                 ELSE 6 -- item name = Add from NAP CM
			END
	FROM 	Temp_ProblemAccounts AS temp
    LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID
    LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID;
   
	/*	GET LASTEST CUSTID LIST	*/
    SELECT DISTINCT temp.CustId
					,	CASE WHEN temp.ActionType = 2 THEN 3
							 ELSE 4
						END AS TypeId
    FROM Temp_ProblemAccounts AS temp;
    
END$$

DELIMITER ;