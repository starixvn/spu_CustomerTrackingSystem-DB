/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DataCenter`.`CTS_DC_InsertCategorizedProblemAccounts`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertCategorizedProblemAccounts`(
		IN ip_ProblemAccounts JSON
    ,	IN ip_IsRescan BIT
    
    ,	OUT op_ErrorMessage VARCHAR(200)
)
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
            - 2020120211@Irena.Vo: Insert History Log. Insert Error Log & update logic SP. Return All List CustID. Update logic SP.  [RedmineID: #145951]
            
		Param's Explanation (filtered by):
			CALL CTS_DataCenter.CTS_DC_InsertCategorizedProblemAccounts('[{"CustId": 123, "CategoryId": 27}]',0,@op_ErrorMessage);
	*/   
    DECLARE lv_CreatedBy INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime DATETIME DEFAULT CURRENT_TIME(); 
    
    DECLARE	lv_No INT DEFAULT 1;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No = NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            op_ErrorMessage = MESSAGE_TEXT;	
	
		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_InsertCategorizedProblemAccounts',op_ErrorMessage, JSON_OBJECT('parameter', ip_ProblemAccounts));
    
		SIGNAL SQLSTATE '99999' SET MESSAGE_TEXT = op_ErrorMessage;
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Temp_ProblemAccounts(	  
			CustID				BIGINT UNSIGNED 
		, 	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , 	SubscriberID		INT DEFAULT 0 
        , 	MainDBCategoryID	SMALLINT 
        , 	CategoryID		    SMALLINT
        ,	CategoryGroupID     SMALLINT    
        ,	TargetCC			SMALLINT
        ,	SourceTypeID		SMALLINT
		, 	ActionType		    SMALLINT DEFAULT 0 /* 0: Insert, 1: Update, 2: Remove, 4: Ignore PIN */
        , 	PRIMARY KEY     	PK_Temp_ProblemAccounts_CustID_MainDBCategoryID(CustID,MainDBCategoryID) 
        ,   INDEX				IX_Temp_ProblemAccounts_CustID(CustID)  
        ,   INDEX				IX_Temp_ProblemAccounts_CustID_CategoryGroupID(CustID,CategoryGroupID)  
    );  
     
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification(	  
			CustID				BIGINT UNSIGNED 
        , 	CategoryID	        SMALLINT UNSIGNED
        ,	CategoryGroupID     SMALLINT UNSIGNED    
        ,	RowOrder			SMALLINT
        , 	PRIMARY KEY 		PK_Temp_ExistedClassification_CustID_CategoryID(CustID, CategoryID)     
		,   INDEX				IX_Temp_ExistedClassification_CustID(CustID)  
        ,   INDEX				IX_Temp_ExistedClassification_CustID_CategoryGroupID(CustID,CategoryGroupID)  
     );
   
    INSERT INTO Temp_ProblemAccounts(CustID, MainDBCategoryID)
	SELECT DISTINCT temp.CustID, 	temp.MainDBCategoryID 
	FROM JSON_TABLE(ip_ProblemAccounts,
		"$[*]" COLUMNS(
				CustID 				BIGINT UNSIGNED		PATH "$.CustId"
			,	MainDBCategoryID	SMALLINT 			PATH "$.CategoryId"	
		 )) AS temp
	WHERE temp.MainDBCategoryID <> 0;
    
	#===========================================PREPARE DATA==================================================================
    /*	IGNORE PIN CATEGORY	*/
    UPDATE Temp_ProblemAccounts AS temp
		INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CustID = temp.CustID
    SET temp.ActionType = 4; 
    
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
    
    /*  UPDATE CATEGORY ID, CATEGORY GROUP ID INFO */
    UPDATE Temp_ProblemAccounts AS temp 
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.DisplayOrder = temp.MainDBCategoryID
    SET 	temp.CategoryID = (CASE WHEN cc.DisplayOrder IS NOT NULL THEN cc.CategoryID
									ELSE temp.MainDBCategoryID
								END)
		,	temp.CategoryGroupID = (CASE WHEN cc.DisplayOrder IS NOT NULL THEN cc.CategoryGroup
										 ELSE temp.MainDBCategoryID
									END)
	WHERE temp.ActionType = 0;
    
    /*	UPDATE CUST INFO */
    UPDATE Temp_ProblemAccounts AS temp 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID
		, 	temp.SubscriberID = cust.SubscriberID;
    
    /*	GET EXISTED CATEGORY	*/
	INSERT INTO Temp_ExistedClassification (CustID, CategoryGroupID, CategoryID, RowOrder)
	SELECT 	cate.CustID
		, 	cc.CategoryGroup
        , 	cate.CategoryID  
		, 	ROW_NUMBER() OVER (PARTITION BY cate.CustID, cc.CategoryGroup
								ORDER BY (CASE WHEN cate.CategoryID NOT BETWEEN 72 AND 80 THEN 1 /* From NAP CM will lastest records */
											   ELSE 0
										  END)) AS RowOrder
	FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 0
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE temp.ActionType = 0;
   
	UPDATE Temp_ProblemAccounts AS temp 
		INNER JOIN	Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryID = temp.CategoryID
	SET	temp.ActionType = 1
	WHERE temp.ActionType = 0;

    /* GET REMOVED PROBLEM ACCOUNTS */
    UPDATE Temp_ProblemAccounts AS temp
    SET temp.ActionType = 2
    WHERE temp.CategoryID = -1;
    
    /*	UPDATE TARGET CC INFO */
	UPDATE Temp_ProblemAccounts AS temp 
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID 
		LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.CategoryID
	SET	temp.TargetCC = (CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass /* Existed CC */
							  WHEN map.CategoryID IS NOT NULL THEN map.CustomerClass  /* Mapping CC */
							  ELSE 
								   CASE WHEN temp.ActionType IN (0, 1) THEN -99 /* No mapping CC */
										WHEN temp.ActionType = 2 THEN -1  /* Remove PA */
								   END
						END)
	WHERE temp.ActionType IN (0, 1, 2);
    
    /*	UPDATE SOURCE TYPE ID INFO */
	UPDATE Temp_ProblemAccounts AS temp 
    SET	temp.SourceTypeID = (CASE WHEN temp.ActionType IN (0, 1) THEN 6 /* Insert & Update */
								  ELSE 8 /* Remove */
							 END)
	WHERE temp.ActionType IN (0, 1, 2);
    
    #===========================================CLASSIFY DATA==================================================================
	/*	REMOVE PA FROM NAP CM */
	DELETE cate
    FROM CTS_DataCenter.CTSCustomerClassification cate
		INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 0
	WHERE temp.ActionType = 2 AND (cate.CategoryID NOT BETWEEN 72 AND 80);
    
	/*	UPDATE PA FROM NAP CM */
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_ProblemAccounts AS temp on temp.CustID = cate.CustID AND cate.SportGroupID = 0 AND temp.CategoryID = cate.CategoryID 
	SET 	cate.CTSCustID = temp.CTSCustID
		, 	cate.SubscriberID  = temp.SubscriberID
		, 	cate.LastModifiedBy = lv_CreatedBy
		,   cate.LastModifiedDate = lv_CurrentDateTime
		, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
	WHERE temp.ActionType = 1;
     
    /*	INSERT NEW PA FROM NAP CM */
    INSERT INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
	CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	temp.CustID
		,	temp.CTSCustID
		, 	temp.SubscriberID
		, 	temp.CategoryID
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime)
	FROM Temp_ProblemAccounts AS temp
    WHERE temp.ActionType = 0;           
    
    #===========================================WRITE LOG==================================================================
    IF (ip_IsRescan = 1) THEN
		/* INSERT LOG RE-SCAN PA FROM NAP CM */    
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.CategoryID
			, 	0
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.ActionType
			, 	1
			, 	DATE(lv_CurrentDateTime)
			, 	temp.TargetCC
			, 	15 /* Rescan PA */
			,   1
		FROM Temp_ProblemAccounts AS temp;
	ELSE 
		/*	INSERT LOG NEW & UPDATE PA FROM NAP CM */
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.CategoryID
			, 	0
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.ActionType
			, 	1
			, 	DATE(lv_CurrentDateTime)
			, 	temp.TargetCC
			, 	temp.SourceTypeID
			,   CASE WHEN ex.CategoryGroupID IS NULL THEN 1
					 ELSE 0
				END
		FROM Temp_ProblemAccounts AS temp
			LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryGroupID = temp.CategoryGroupID /* Not existed Evd Cate. */
		WHERE temp.ActionType IN (0, 1);
		
		/*	INSERT LOG REMOVE PA FROM NAP CM */
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	ex.CategoryID
			, 	0
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.ActionType
			, 	1
			, 	DATE(lv_CurrentDateTime)
			, 	temp.TargetCC
			, 	temp.SourceTypeID
			,   CASE WHEN ex.CategoryGroupID IS NOT NULL THEN 1
					 ELSE 0
				END
		FROM Temp_ProblemAccounts AS temp
			LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryID NOT BETWEEN 72 AND 80 AND ex.RowOrder = 1
		WHERE temp.ActionType = 2;
			
		/*	INSERT LOG IGNORE PIN */
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
		SELECT DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.CategoryID
			, 	0
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.ActionType
			, 	1
			, 	DATE(lv_CurrentDateTime)
		FROM Temp_ProblemAccounts AS temp
		WHERE temp.ActionType = 4;
    END IF;
    
	#=========================================GET LASTEST CUSTOMERS FOR CLASSICATION=========================================================
	SELECT DISTINCT temp.CustId FROM Temp_ProblemAccounts AS temp 
    WHERE temp.ActionType IN (0, 1, 2);
END$$
DELIMITER ;