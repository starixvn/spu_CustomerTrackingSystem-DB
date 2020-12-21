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
            - 20201221@Irena.Vo: Update Logic SP for View History [RedmineID: #145951]
            
		Param's Explanation (filtered by):
	*/   
    DECLARE lv_CreatedBy 		INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME(); 
   
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Temp_ProblemAccounts 
    (	  
			CustID				BIGINT UNSIGNED 
        , 	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , 	SubscriberID		INT DEFAULT 0 
        , 	MainDBCategoryID	SMALLINT 
        ,   SportGroupID        SMALLINT UNSIGNED 
        , 	CategoryID		    SMALLINT UNSIGNED
        ,	NapCMCategoryID     SMALLINT UNSIGNED    
		, 	ActionType		    SMALLINT DEFAULT 0 -- Insert: 0, Update: 1, Remove: 2
        , 	PRIMARY KEY     	PK_Temp_ProblemAccounts_CustID_MainDBCategoryID(CustID,MainDBCategoryID) 
        ,	INDEX				IX_Temp_ProblemAccounts_MainDBCategoryID(MainDBCategoryID)
        ,   INDEX				IX_Temp_ProblemAccounts_ActionType(ActionType)  
    );  
     
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification 
    (	  
			CustID				BIGINT UNSIGNED 
        , 	CategoryID	        SMALLINT UNSIGNED
        ,	NapCMCategoryID     SMALLINT UNSIGNED    
        , 	PRIMARY KEY 		PK_Temp_ExistedClassification_CustID_CategoryID(CustID, CategoryID)       
        ,	INDEX				IX_Temp_ExistedClassification_NapCMCategoryID(NapCMCategoryID)
     );
     
	DROP TEMPORARY TABLE IF EXISTS Temp_NumOfNapCMCategory;    
	CREATE TEMPORARY TABLE Temp_NumOfNapCMCategory 
    (	  
			CustID				BIGINT UNSIGNED 
        ,	NapCMCategoryID     SMALLINT UNSIGNED    
        ,   NumOfCategoryID     SMALLINT UNSIGNED    
		,	INDEX				IX_Temp_NumOfNapCMCategory_CustID_NapCMCategoryID(CustID,NapCMCategoryID)
	 ); 
     
    INSERT INTO Temp_ProblemAccounts(CustID, SportGroupID, MainDBCategoryID, CategoryID)
	SELECT 	DISTINCT temp.CustID
		, 	0
		, 	temp.MainDBCategoryID 
        ,   CASE 
				WHEN temp.MainDBCategoryID = 27 THEN 51
				WHEN temp.MainDBCategoryID = 28 THEN 52
				WHEN temp.MainDBCategoryID = 29 THEN 53
				WHEN temp.MainDBCategoryID = 30 THEN 54
				WHEN temp.MainDBCategoryID = 31 THEN 55
				WHEN temp.MainDBCategoryID = 32 THEN 56
				WHEN temp.MainDBCategoryID = 36 THEN 57
				WHEN temp.MainDBCategoryID = 37 THEN 58
				WHEN temp.MainDBCategoryID = 38 THEN 59
				WHEN temp.MainDBCategoryID = 101 THEN 151
				WHEN temp.MainDBCategoryID = 102 THEN 152
				WHEN temp.MainDBCategoryID = 103 THEN 153
				WHEN temp.MainDBCategoryID = 104 THEN 154
				WHEN temp.MainDBCategoryID = 105 THEN 155
				WHEN temp.MainDBCategoryID = 106 THEN 156
				WHEN temp.MainDBCategoryID = 107 THEN 157
				WHEN temp.MainDBCategoryID = 108 THEN 158
				WHEN temp.MainDBCategoryID = 109 THEN 159
				WHEN temp.MainDBCategoryID = 255 THEN 160
			END AS CategoryID
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
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 200 AND (cate.CategoryID > 200 AND cate.CategoryID < 300);
  
	/*	REMOVE PROBATION LIST BEFORE	*/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = pro.CustID;
   
    /*	UPDATE CUST INFO	*/
    UPDATE 	Temp_ProblemAccounts AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
    
    /* UPDATE NAPCM CATEGORY INFO	*/
    UPDATE 	Temp_ProblemAccounts
    SET 	NapCMCategoryID = CASE 	WHEN CategoryID = 151 THEN 51
									WHEN CategoryID = 152 THEN 52
									WHEN CategoryID = 153 THEN 53
									WHEN CategoryID = 154 THEN 54 
									WHEN CategoryID = 155 THEN 55
									WHEN CategoryID = 156 THEN 56
									WHEN CategoryID = 157 THEN 57
									WHEN CategoryID = 158 THEN 58
									WHEN CategoryID = 159 THEN 59
									ELSE CategoryID
								END;
    
    /*	GET EXISTED CATEGORY	*/
	INSERT INTO Temp_ExistedClassification (CustID, CategoryID, NapCMCategoryID)
	SELECT DISTINCT 	cate.CustID
					, 	cate.CategoryID
                    ,   CASE 	WHEN cate.CategoryID = 151 THEN 51
								WHEN cate.CategoryID IN (72, 152) THEN 52
								WHEN cate.CategoryID IN (73, 153) THEN 53
								WHEN cate.CategoryID IN (74, 154) THEN 54 
								WHEN cate.CategoryID IN (75, 155) THEN 55
								WHEN cate.CategoryID IN (76, 156) THEN 56
								WHEN cate.CategoryID IN (77, 157) THEN 57
								WHEN cate.CategoryID IN (78, 158) THEN 58
								WHEN cate.CategoryID IN (79, 159) THEN 59
								WHEN cate.CategoryID = 80 THEN 60
								ELSE cate.CategoryID
						 END AS NapCMCategoryID
    FROM Temp_ProblemAccounts AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 0
    WHERE cate.CategoryID > 50 AND cate.CategoryID < 200; -- both NapCM & Evidence.
    
    /* COUNT OF NAPCM CATEGORY (ActionType = 2)*/
    INSERT INTO Temp_NumOfNapCMCategory (CustID, NapCMCategoryID, NumOfCategoryID)
    SELECT DISTINCT ex.CustID, ex.NapCMCategoryID, COUNT(ex.NapCMCategoryID)
    FROM Temp_ExistedClassification AS ex
    GROUP BY ex.CustID, ex.NapCMCategoryID;
    
	/*	REMOVE PROBLEM ACCOUNTS */
	DELETE 		 cate
    FROM 		 CTS_DataCenter.CTSCustomerClassification cate
    INNER JOIN 	 Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID
	WHERE 		 temp.ActionType = 2 AND (cate.CategoryID > 50 AND cate.CategoryID < 200 AND (cate.CategoryID NOT BETWEEN 72 AND 80));
    
	/*	UPDATE PROBLEM ACCOUNT	*/
    UPDATE 		 CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN   Temp_ProblemAccounts AS temp on temp.CustID = cate.CustID AND temp.CategoryID = cate.CategoryID
	SET   	    cate.CTSCustID = temp.CTSCustID
			, 	cate.SubscriberID  = temp.SubscriberID
			, 	cate.LastModifiedBy = lv_CreatedBy
			,   cate.LastModifiedDate = lv_CurrentDateTime
			, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
            ,	temp.ActionType = 1
     WHERE 	cate.CategoryID > 50 AND cate.CategoryID < 200 AND (cate.CategoryID NOT BETWEEN 72 AND 80);
     
    /*	INSERT NEW PROBLEM ACCOUNT	*/
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
	CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	temp.CustID
		, 	temp.CTSCustID
		, 	temp.SubscriberID
		, 	temp.CategoryID
		, 	temp.SportGroupID
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime)
	FROM 	Temp_ProblemAccounts AS temp
    WHERE 	temp.ActionType = 0;           
   
    /* INSERT LOG */
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID)
    SELECT  temp.CustID
		, 	temp.CTSCustID
		, 	CASE WHEN temp.ActionType = 2 THEN ex.CategoryID  -- remove PA
				 ELSE temp.CategoryID
			END
		, 	0 
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	temp.ActionType
		, 	1 -- auto
		, 	DATE(lv_CurrentDateTime)
		, 	CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass 
				 WHEN map.CustomerClass IS NULL THEN -1 -- no mapping CC
                 ELSE map.CustomerClass
			END
		, 	CASE WHEN temp.ActionType = 2 THEN 8 -- item name = Remove PA from Nap CM
                 ELSE 6 -- item name = Add from NAP CM
			END
	FROM 	Temp_ProblemAccounts AS temp
    LEFT JOIN Temp_ExistedClassification AS ex ON (CASE WHEN temp.ActionType = 2 THEN ex.CustID = temp.CustID AND ex.CategoryID NOT BETWEEN 72 AND 80
                                                        WHEN temp.ActionType = 0 THEN ex.CustID = temp.CustID AND ex.NapCMCategoryID = temp.NapCMCategoryID
                                                   END)
    LEFT JOIN Temp_NumOfNapCMCategory AS num ON num.NumOfCategoryID = 2 AND num.CustID = ex.CustID AND num.NapCMCategoryID = ex.NapCMCategoryID                 
	LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
    LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON (CASE WHEN temp.ActionType = 0 THEN  map.CategoryID = temp.NapCMCategoryID
																	WHEN temp.ActionType = 2 THEN  map.CategoryID = ex.NapCMCategoryID
																END)
	
    WHERE (temp.ActionType = 2 AND num.NapCMCategoryID IS NULL) OR (temp.ActionType = 0 AND ex.NapCMCategoryID IS NULL);
   
	/*	GET LASTEST CUSTID LIST	*/
	SELECT DISTINCT temp.CustId
    FROM Temp_ProblemAccounts AS temp
	LEFT JOIN Temp_ExistedClassification AS ex ON (CASE WHEN temp.ActionType = 2 THEN ex.CustID = temp.CustID AND ex.CategoryID NOT BETWEEN 72 AND 80
                                                        WHEN temp.ActionType = 0 THEN ex.CustID = temp.CustID AND ex.NapCMCategoryID = temp.NapCMCategoryID
                                                   END)
	LEFT JOIN Temp_NumOfNapCMCategory AS num ON num.NumOfCategoryID = 2 AND num.CustID = ex.CustID AND num.NapCMCategoryID = ex.NapCMCategoryID
    WHERE (temp.ActionType = 2 AND num.NapCMCategoryID IS NULL) OR (temp.ActionType = 0 AND ex.NapCMCategoryID IS NULL);
    
END$$

DELIMITER ;