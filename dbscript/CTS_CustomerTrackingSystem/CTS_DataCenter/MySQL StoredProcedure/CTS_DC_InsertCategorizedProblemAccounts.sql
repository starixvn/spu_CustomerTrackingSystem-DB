/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_InsertCategorizedProblemAccounts`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertCategorizedProblemAccounts`(IN ip_ProblemAccounts json, OUT op_ErrorMessage VARCHAR(200))
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
			- 20201214-20201229@Irena.Vo: Insert History Log. Insert Error Log & update logic SP. Return All List CustID  [RedmineID: #145951]
            
		Param's Explanation (filtered by):
	*/   
    DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_InsertCategorizedProblemAccounts';
    DECLARE lv_CreatedBy 		INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME(); 
    
    DECLARE op_ErrorNo 			INT DEFAULT 0;
    DECLARE op_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS @op_No = NUMBER;
		GET DIAGNOSTICS CONDITION @op_No 
         	op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	op_ErrorNo 			= 	MYSQL_ERRNO
		,	op_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.ErrorLog(EventName, InsertedTime, Message, Err_No, Description)
        VALUES(lv_SPName, lv_CurrentDateTime, op_ErrorMessage, op_ErrorNo, 	JSON_OBJECT('err_no',op_ErrorNo,'cod_name',op_CodName,'parameter',ip_ProblemAccounts));
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Temp_ProblemAccounts 
    (	  
			CustID				BIGINT UNSIGNED 
        , 	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , 	SubscriberID		INT DEFAULT 0 
        , 	MainDBCategoryID	SMALLINT 
        , 	CategoryID		    SMALLINT
        ,	NapCMCategoryID     SMALLINT    
		, 	ActionType		    SMALLINT DEFAULT 0 -- Insert: 0, Update: 1, Remove: 2, Ignore: 3
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
     
	DROP TEMPORARY TABLE IF EXISTS Temp_CountNapCMCategory;    
	CREATE TEMPORARY TABLE Temp_CountNapCMCategory 
    (	  
			CustID				BIGINT UNSIGNED 
        ,	NapCMCategoryID     SMALLINT UNSIGNED    
        ,   CountValue          SMALLINT UNSIGNED    
		,	INDEX				IX_Temp_CountNapCMCategory_CustID_NapCMCategoryID(CustID,NapCMCategoryID)
	 ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ManualRemovedList;    -- Rescan PA
	 CREATE TEMPORARY TABLE Temp_ManualRemovedList 
     (	  
			CustID				BIGINT UNSIGNED PRIMARY KEY    
      );
    
    /* GET DATA FROM NAP CM	*/ 
    INSERT INTO Temp_ProblemAccounts(CustID, MainDBCategoryID, CategoryID)
	SELECT 	DISTINCT temp.CustID
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
                ELSE temp.MainDBCategoryID
			END AS CategoryID
	FROM JSON_TABLE(ip_ProblemAccounts,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, MainDBCategoryID	SMALLINT 			PATH "$.CategoryId"	
		 )) AS temp
	WHERE temp.MainDBCategoryID <> 0;
         
    /*	IGNORE PIN CATEGORY	*/
    UPDATE     Temp_ProblemAccounts AS temp
    INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CustID = temp.CustID
    SET        temp.ActionType = 3; 
    
    /*	REMOVE GENERAL CATEGORY BEFORE	*/
    DELETE cate
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 200
    WHERE temp.ActionType = 0;
  
	/*	REMOVE PROBATION LIST BEFORE	*/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = pro.CustID
    WHERE temp.ActionType = 0;
    
    /*	UPDATE CUST INFO & NAP CM CATEGORYID	*/
    UPDATE 	Temp_ProblemAccounts AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID
		, 	temp.SubscriberID = cust.SubscriberID
        ,	temp.NapCMCategoryID = CASE 	WHEN temp.CategoryID = 151 THEN 51
											WHEN temp.CategoryID = 152 THEN 52
											WHEN temp.CategoryID = 153 THEN 53
											WHEN temp.CategoryID = 154 THEN 54 
											WHEN temp.CategoryID = 155 THEN 55
											WHEN temp.CategoryID = 156 THEN 56
											WHEN temp.CategoryID = 157 THEN 57
											WHEN temp.CategoryID = 158 THEN 58
											WHEN temp.CategoryID = 159 THEN 59
											ELSE temp.CategoryID
									END
	WHERE temp.ActionType = 0;
    
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
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 0 -- both NapCM & Evidence.
    WHERE temp.ActionType = 0;
    
	/*	REMOVE PROBLEM ACCOUNTS IN CTS */
    UPDATE Temp_ProblemAccounts AS temp
    SET temp.ActionType = 2
    WHERE temp.CategoryID = -1;
    
	DELETE 		 cate
    FROM 		 CTS_DataCenter.CTSCustomerClassification cate
    INNER JOIN 	 Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 0
	WHERE 		 temp.ActionType = 2  AND (cate.CategoryID NOT BETWEEN 72 AND 80); -- Only remove PA from NAP CM
    
	/*	UPDATE PROBLEM ACCOUNT IN CTS */
    UPDATE 		 CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN   Temp_ProblemAccounts AS temp on temp.CustID = cate.CustID AND cate.SportGroupID = 0 AND temp.CategoryID = cate.CategoryID 
	SET   	    cate.CTSCustID = temp.CTSCustID
			, 	cate.SubscriberID  = temp.SubscriberID
			, 	cate.LastModifiedBy = lv_CreatedBy
			,   cate.LastModifiedDate = lv_CurrentDateTime
			, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
            ,	temp.ActionType = 1
     WHERE 	temp.ActionType = 0 AND cate.CategoryID NOT BETWEEN 72 AND 80; -- Only update PA from NAP CM
     
    /*	INSERT NEW PROBLEM ACCOUNT IN CTS	*/
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
   
    /* INSERT HISTORY IN CTS */
    INSERT INTO Temp_CountNapCMCategory (CustID, NapCMCategoryID, CountValue) -- Count NapCMCategory so that compare with NAP CM
    SELECT DISTINCT ex.CustID, ex.NapCMCategoryID, COUNT(ex.NapCMCategoryID) AS CountValue
    FROM Temp_ExistedClassification AS ex
    GROUP BY ex.CustID, ex.NapCMCategoryID;
    
	INSERT INTO Temp_ManualRemovedList (CustID)
    SELECT DISTINCT t1.CustID
    FROM (  SELECT DISTINCT his.CustID, MAX(his.ID) AS HistoryID
			FROM CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = his.CustID
            WHERE temp.ActionType IN (0, 1)
			GROUP BY his.CustID) AS t1
	INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS t2 ON t2.CustID = t1.CustID AND t2.ID = t1.HistoryID 
    WHERE t2.SourceTypeID IN (8, 9, 12, 14); -- 8: Remove PA by NAP CM, 9: Remove: PA by Evd, 12: Remove Special CC, 14: Remove VVIP
    
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
    SELECT  DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	CASE WHEN temp.ActionType = 2 THEN ex.CategoryID  -- Remove PA
				 ELSE temp.CategoryID
			END
		, 	0 
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	temp.ActionType
		, 	1 -- auto
		, 	DATE(lv_CurrentDateTime)
		, 	CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass -- Existed CC
				 WHEN map.CustomerClass IS NULL THEN -1 -- No mapping CC
                 ELSE map.CustomerClass
			END
		, 	CASE WHEN temp.ActionType = 2 THEN 8 -- item name = Remove PA from Nap CM
                 ELSE 6 -- item name = Add from NAP CM
			END
		,   CASE WHEN s.CustID IS NOT NULL THEN 1 -- View History 
				 WHEN (temp.ActionType = 0 AND ex.NapCMCategoryID IS NULL) THEN 1 -- View History
				 WHEN (temp.ActionType = 2 AND c.NapCMCategoryID IS NULL) THEN 1 -- View History
                 ELSE 0
			END
	FROM 	Temp_ProblemAccounts AS temp
	LEFT JOIN   Temp_ManualRemovedList AS s ON temp.CustID = s.CustID -- Need to View History for Rescan PA
    LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID -- Existed CC
    LEFT JOIN Temp_ExistedClassification AS ex ON (CASE WHEN temp.ActionType = 2 THEN ex.CustID = temp.CustID AND ex.CategoryID NOT BETWEEN 72 AND 80 -- Get existed PA from NAP CM for View History
                                                        WHEN temp.ActionType = 0 THEN ex.CustID = temp.CustID AND ex.NapCMCategoryID = temp.NapCMCategoryID -- Ignore if existed Evd Category for View History
                                                   END)
    LEFT JOIN Temp_CountNapCMCategory AS c ON c.CountValue = 2 AND c.CustID = ex.CustID AND c.NapCMCategoryID = ex.NapCMCategoryID -- Ignore if existed Evd Category for View History. Count NAPCM Category = 2
    LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON (CASE WHEN temp.ActionType IN (0, 1) THEN  map.CategoryID = temp.NapCMCategoryID -- Mapping from temp Category
																	 WHEN temp.ActionType = 2 THEN  map.CategoryID = ex.NapCMCategoryID -- Mapping from existed Category
																END)
	 WHERE temp.ActionType IN (0, 1, 2);
   
	/*	GET LASTEST CUSTID LIST	-> GET LATEST CLASSICATION -> SYNC CC IN MAINDB */
	SELECT DISTINCT temp.CustId FROM Temp_ProblemAccounts AS temp;
END$$

DELIMITER ;