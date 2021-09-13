/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_InsertProblemAccount`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_InsertProblemAccount`(
		IN ip_ProblemAccounts 	JSON
    ,	IN ip_IsRescan 			BIT
    
    ,	OUT op_ErrorMessage 	VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20200715@Long.Luu
		Task:		Insert for Problem Accounts
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20200715@Long.Luu [#136460]: Created
			- 20200828@Roger.Le [#140211]: Enhance Problem Account Category - Multiple Reason 
			- 20200908@Irena.Vo [#141020]: Exclude VVIP Customers, Pin 
            - 20201014@Irena.Vo [#141930]: Add Multi Problem Category, Remove old categoryid from NapCM
            - 20201019@Irena.Vo  [#141930]: Get distinct CustID List for lastest category
            - 20210115@Irena.Vo: Insert History Log [RedmineID: #145951]
			- 20210119@Aries.Nguyen: Write main error log - Rescan  [RedmineID: #149026]
			- 20210316@Irena.Vo: Write Robot User log more.  [RedmineID: #151374]
            - 20210419@Irena.Vo: Update Priority Robot User.  [RedmineID: #152250] 
            - 20210510@Casey.Huynh: Exclude Customer of Odd Feed Sites [Redmine ID: 154694]
            - 20210512@Casey.Huynh: Exclude Customer of Internal Account [Redmine ID: 154844]
            - 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [Redmine ID: 152965]
			- 20210625@Long.Luu: Refactor. Update logic  [Redmine ID: #157203]
			- 20210907@Long.Luu: Update Robot Users rules  [Redmine ID: #161232]
            
        Param's Explanation (filtered by):
        
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_InsertProblemAccount('[{"CustId": 123, "CategoryId": 27}]',0,@op_ErrorMessage);
	*/   
    DECLARE	CONST_CATEGORYID_ROBOTUSERS 	INT DEFAULT 61;
    
    DECLARE	CONST_GROUP_PA 					INT DEFAULT 0;
	DECLARE	CONST_GROUP_NORMAL 				INT DEFAULT 200;
    
    DECLARE CONST_ACTIONTYPE_INSERT 		INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 		INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 		INT DEFAULT 2;
    DECLARE CONST_ACTIONTYPE_IGNOREPIN 		INT DEFAULT 4;
    
    DECLARE CONST_SOURCETYPE_INSERTPA 		INT DEFAULT 6;
	DECLARE	CONST_SOURCETYPE_REMOVEPA 		INT DEFAULT 8;
	DECLARE CONST_SOURCETYPE_INSERTROBOT	INT DEFAULT 11;
    DECLARE CONST_SOURCETYPE_RESCANPA 		INT DEFAULT 15;
       
    DECLARE lv_CreatedBy INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime DATETIME DEFAULT CURRENT_TIME(); 

	DROP TEMPORARY TABLE IF EXISTS Temp_InputCustomers;    
	CREATE TEMPORARY TABLE Temp_InputCustomers(	  
			CustID				BIGINT UNSIGNED 
        , 	ReasonID			SMALLINT 
        , 	RobotCounter		SMALLINT 
        , 	PRIMARY KEY     	PK_Temp_InputCustomers_CustID_ReasonID(CustID,ReasonID)  
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_PinnedCustomers;    
	CREATE TEMPORARY TABLE Temp_PinnedCustomers(	  
			CTSCustID				BIGINT UNSIGNED PRIMARY KEY
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomersTargetCC;    
	CREATE TEMPORARY TABLE Temp_CustomersTargetCC(	  
			CustID				BIGINT UNSIGNED 
        , 	CategoryID		    SMALLINT 
        ,	TargetCC			SMALLINT
        , 	PRIMARY KEY     	PK_Temp_CustomersTargetCC_CustID_CategoryID(CustID,CategoryID)  
    ); 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ProblemAccounts;    
	CREATE TEMPORARY TABLE Temp_ProblemAccounts(	  
			CustID				BIGINT UNSIGNED 
		, 	CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , 	SubscriberID		INT DEFAULT 0 
        , 	ReasonID			SMALLINT 
        , 	CategoryID		    SMALLINT
        ,	CategoryGroup     	SMALLINT    
        ,	TargetCC			SMALLINT
        ,	SourceTypeID		SMALLINT
		, 	ActionType		    SMALLINT DEFAULT 0 /* 0: Insert, 1: Update, 2: Remove, 4: Ignore PIN */
        , 	IsLastDataChanged   BIT DEFAULT 0
        ,	LastSourceTypeID	INT
        , 	RobotCounter		SMALLINT 
        , 	PRIMARY KEY     	PK_Temp_ProblemAccounts_CustID_ReasonID(CustID,ReasonID)  
    );  
     
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification(	  
			CustID				BIGINT UNSIGNED 
        , 	CategoryID	        SMALLINT UNSIGNED
        ,	CategoryGroup     	SMALLINT UNSIGNED    
        ,	RowOrder			SMALLINT
        , 	PRIMARY KEY 		PK_Temp_ExistedClassification_CustID_CategoryID(CustID, CategoryID)     
     );
   
	DROP TEMPORARY TABLE IF EXISTS Temp_LastHistory;    
	CREATE TEMPORARY TABLE Temp_LastHistory(	  
			CustID			BIGINT UNSIGNED 
		,	HistoryID		BIGINT
		, 	PRIMARY KEY		PK_Temp_LastHistory(HistoryID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustHistory;    
	CREATE TEMPORARY TABLE Temp_CustHistory(	  
			CustID			BIGINT UNSIGNED 
		,	SourceTypeID	INT
        ,	IsDataChanged	BIT
		, 	PRIMARY KEY		PK_Temp_LastHistory(CustID)
    );
   
    INSERT INTO Temp_InputCustomers(CustID, ReasonID, RobotCounter)
	SELECT DISTINCT temp.CustID, temp.ReasonID , temp.RobotCounter
	FROM JSON_TABLE(ip_ProblemAccounts,
		"$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED		PATH "$.CustID"
			,	ReasonID		SMALLINT 			PATH "$.ReasonID"	
			,	RobotCounter	SMALLINT 			PATH "$.RobotCounter"	
		 )) AS temp
	WHERE temp.ReasonID <> 0;
    
	/*	EXCLUDE Customer */    
    CALL CTS_DC_ExcludeCustByCondition('Temp_InputCustomers');
    
    /*	INSERT CUST INFO */
    INSERT INTO Temp_ProblemAccounts(CustID, ReasonID, CTSCustID, SubscriberID, RobotCounter)
    SELECT temp.CustID, temp.ReasonID, cust.CTSCustID, cust.SubscriberID, temp.RobotCounter
    FROM Temp_InputCustomers AS temp 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0;
    
    /*	IGNORE PIN CATEGORY	*/
    INSERT INTO Temp_PinnedCustomers (CTSCustID)
    SELECT DISTINCT pin.CTSCustID
    FROM Temp_ProblemAccounts AS temp
		INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CTSCustID = temp.CTSCustID; 
        
	UPDATE Temp_ProblemAccounts AS pa
		INNER JOIN Temp_PinnedCustomers AS pin ON pa.CTSCustID = pin.CTSCustID
	SET 	pa.ActionType = CONST_ACTIONTYPE_IGNOREPIN;
    
    /*	REMOVE GENERAL CATEGORY BEFORE	*/
    DELETE cate
    FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_NORMAL
	WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
  
	/*	REMOVE PROBATION LIST BEFORE	*/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = pro.CustID
	WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
    
    /*  UPDATE CATEGORY ID, CATEGORY GROUP ID INFO */
    UPDATE Temp_ProblemAccounts AS temp 
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.DisplayOrder = temp.ReasonID
    SET 	temp.CategoryID = IFNULL(cc.CategoryID,temp.ReasonID)
		,	temp.CategoryGroup = IFNULL(cc.CategoryGroup,temp.ReasonID);
    
    /*	GET EXISTED CATEGORY	*/
	INSERT IGNORE INTO Temp_ExistedClassification (CustID, CategoryGroup, CategoryID, RowOrder)
	SELECT 	cate.CustID
		, 	cc.CategoryGroup
        , 	cate.CategoryID  
		, 	ROW_NUMBER() OVER (PARTITION BY cate.CustID, cc.CategoryGroup
								ORDER BY (CASE WHEN cate.CategoryID NOT BETWEEN 72 AND 150 THEN 1 /* From NAP CM will lastest records */
											   ELSE 0 /* Evidence */
										  END)) AS RowOrder
	FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PA
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
   
	UPDATE Temp_ProblemAccounts AS temp 
		INNER JOIN	Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryID = temp.CategoryID
	SET	temp.ActionType = CONST_ACTIONTYPE_UPDATE
	WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;

    /* GET REMOVED PROBLEM ACCOUNTS */
    UPDATE Temp_ProblemAccounts AS temp
    SET temp.ActionType = CONST_ACTIONTYPE_REMOVE
    WHERE temp.CategoryID = -1 AND temp.ActionType = CONST_ACTIONTYPE_INSERT;
    
    /*	UPDATE TARGET CC INFO */
    INSERT INTO Temp_CustomersTargetCC(CustID, CategoryID, TargetCC)
    SELECT 	temp.CustID, temp.CategoryID
		,	(CASE WHEN temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) THEN IFNULL(IFNULL(sp.CustomerClass, map.CustomerClass), -99)
				  WHEN temp.ActionType = CONST_ACTIONTYPE_REMOVE THEN -1  /* Remove PA */
			END)
    FROM Temp_ProblemAccounts AS temp 
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID 
		LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.CategoryID
	WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE);
    
	UPDATE Temp_ProblemAccounts AS temp 
		INNER JOIN Temp_CustomersTargetCC AS tcc ON tcc.CustID = temp.CustID AND tcc.CategoryID = temp.CategoryID
	SET	temp.TargetCC = tcc.TargetCC
	WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE);
    
    /*	UPDATE SOURCE TYPE ID INFO */
	UPDATE Temp_ProblemAccounts AS temp 
    SET	temp.SourceTypeID = (CASE WHEN temp.CategoryID = CONST_CATEGORYID_ROBOTUSERS THEN CONST_SOURCETYPE_INSERTROBOT /* Insert Robot User */
								  WHEN temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) THEN CONST_SOURCETYPE_INSERTPA /* Insert & Update */
								  ELSE CONST_SOURCETYPE_REMOVEPA /* Remove */
							 END)
	WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE);
    
    #===========================================CLASSIFY DATA==================================================================
	/*	REMOVE PA FROM NAP CM */
	DELETE cate
    FROM CTS_DataCenter.CTSCustomerClassification cate
		INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PA
	WHERE temp.ActionType = CONST_ACTIONTYPE_REMOVE AND cate.CategoryID <> CONST_CATEGORYID_ROBOTUSERS AND (cate.CategoryID NOT BETWEEN 72 AND 150);
    
	/*	UPDATE PA FROM NAP CM */
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_ProblemAccounts AS temp on temp.CustID = cate.CustID 
			AND cate.SportGroupID = CONST_GROUP_PA AND temp.CategoryID = cate.CategoryID 
	SET 	cate.CTSCustID = temp.CTSCustID
		, 	cate.SubscriberID  = temp.SubscriberID
		, 	cate.LastModifiedBy = lv_CreatedBy
		,   cate.LastModifiedDate = lv_CurrentDateTime
		, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
	WHERE temp.ActionType = CONST_ACTIONTYPE_UPDATE
		AND temp.CategoryID <> CONST_CATEGORYID_ROBOTUSERS;
        
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
    WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;           
    
    #===========================================WRITE LOG==================================================================
    IF (ip_IsRescan = 1) THEN
        /* Insert Last History*/    
        INSERT INTO Temp_LastHistory (CustID, HistoryID)
		SELECT  his.CustID,	MAX(his.ID)
		FROM CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_ProblemAccounts AS temp ON temp.CustID = his.CustID
		GROUP BY his.CustID;

		INSERT INTO Temp_CustHistory (CustID, SourceTypeID, IsDataChanged)
        SELECT l.CustID, his.SourceTypeID, his.IsDataChanged
        FROM Temp_LastHistory AS l
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS his ON his.ID = l.HistoryID;
        
		UPDATE Temp_ProblemAccounts AS temp
			INNER JOIN Temp_CustHistory AS h ON temp.CustID = h.CustID
		SET 	temp.LastSourceTypeID = h.SourceTypeID
			, 	temp.IsLastDataChanged = h.IsDataChanged;
     
		/* INSERT LOG RE-SCAN PA FROM NAP CM */    
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter)
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
			, 	CONST_SOURCETYPE_RESCANPA
			,   CASE WHEN temp.LastSourceTypeID IN (14,20,21) THEN 1
					 WHEN temp.IsLastDataChanged = 1 AND ex.CategoryGroup IS NULL THEN 1
					 ELSE 0
				END
			,	temp.RobotCounter
		FROM Temp_ProblemAccounts AS temp
			LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID 
				AND ex.CategoryGroup = temp.CategoryGroup AND ex.CategoryID BETWEEN 72 AND 150 /* Not existed Evd Cate (Rescan)*/;
    ELSE 
		/*	INSERT LOG NEW & UPDATE PA FROM NAP CM */
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter)
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
			,   CASE WHEN ex.CategoryGroup IS NULL THEN 1
					 ELSE 0
				END
			,	temp.RobotCounter
		FROM Temp_ProblemAccounts AS temp
			LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID 
				AND ex.CategoryGroup = temp.CategoryGroup AND ex.CategoryID BETWEEN 72 AND 150 /* Not existed Evd Cate. */
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
		
		/*	INSERT LOG REMOVE PA FROM NAP CM */
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter)
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
			,   CASE WHEN ex.CategoryGroup IS NOT NULL THEN 1
					 ELSE 0
				END AS IsDataChanged
			,	temp.RobotCounter
		FROM Temp_ProblemAccounts AS temp
			LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID 
				AND ex.CategoryID <> CONST_CATEGORYID_ROBOTUSERS AND (ex.CategoryID NOT BETWEEN 72 AND 150) AND ex.RowOrder = 1
		WHERE temp.ActionType = CONST_ACTIONTYPE_REMOVE;
			
		/*	INSERT LOG IGNORE PIN */
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
		SELECT DISTINCT temp.CustID
			,	temp.CTSCustID
			, 	temp.CategoryID
			, 	0
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.ActionType
			, 	1
			, 	DATE(lv_CurrentDateTime)
		FROM Temp_ProblemAccounts AS temp
		WHERE temp.ActionType = CONST_ACTIONTYPE_IGNOREPIN; 
    END IF;
    
	#=========================================GET LASTEST CUSTOMERS FOR CLASSICATION=========================================================
	SELECT DISTINCT temp.CustId 
    FROM Temp_ProblemAccounts AS temp 
    WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE);
END$$
DELIMITER ;