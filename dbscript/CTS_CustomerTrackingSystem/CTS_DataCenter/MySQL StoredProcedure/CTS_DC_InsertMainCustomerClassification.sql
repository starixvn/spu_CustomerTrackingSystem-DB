/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_InsertMainCustomerClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertMainCustomerClassification`(IN ip_NewClassification JSON, OUT op_ErrorMessage VARCHAR(200))
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200901@Lex.Khuat
		Task:		Auto insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				-20200901@Lex.Khuat: Created [Redmine ID: #137550]
				-20200908@Irena.Vo: Enhance Exclude VVIP Customers, Pin category  [Redmine ID: #141020]
				-20200921-20201001@Irena.Vo:  [Redmine ID: #145954]
                    -Enhance SP
                    -Insert Probation Management flow
                    -Add get parentid for process update category. 
                -20201003-20201022@Irena.Vo: Enhance SP & correct logic. [Redmine ID: #142546]
                -20201026@Irena.Vo: Enhance init data for Probation to VIP OR Normal. [Redmine ID: #142546]
                -20201116@Irena.Vo: Only distinct CustID list for general & Update LastScannedDate for Probation List. [Redmine ID: #145028]
                -20201201@Aries.Nguyen: Update metadata for goSQL. Remove transaction isolation level REPEATABLE READ and READ UNCOMMITTED. [Redmine ID: #145954]
			    - 20201214-20210107@Irena.Vo: Insert History Log. Insert Error Log & update logic SP. Return All List CustID. Update logic SP.  [RedmineID: #145951]
               
		Param's Explanation (filtered by):
			  CALL CTS_DataCenter.CTS_DC_InsertMainCustomerClassification('[{"CustId": 1, "CategoryId": 202, "CreatedTime": "2020-09-13 00:01:00", "TurnoverRM": 100, "WinlossRM": 2056354, "BetCount": 500, "ActiveDays": 8}]');
	*/ 
	DECLARE lv_CreatedBy		INT			DEFAULT 10278938;
	DECLARE lv_CurrentDateTime  DATETIME 	DEFAULT CURRENT_TIME();

	  
    DECLARE	lv_No				INT			 DEFAULT 0;
    DECLARE lv_ErrorNo 			INT          DEFAULT 0;
    DECLARE lv_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No 	= 	NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	lv_ErrorNo 			= 	MYSQL_ERRNO
		,	lv_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description)
        VALUES(11, op_ErrorMessage, JSON_OBJECT('err_no',lv_ErrorNo,'cod_name',lv_CodName,'parameter',ip_NewClassification));
    END;
    
     DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	 CREATE TEMPORARY TABLE Temp_NewClassification 
     (	  	CustID					BIGINT UNSIGNED	PRIMARY KEY       
     	, 	CTSCustID				BIGINT DEFAULT 0
        , 	SubscriberID			INT DEFAULT 0    
        ,	ExistCategoryID 		SMALLINT -- existed
		, 	NewCategoryID			SMALLINT -- new
        , 	LastCategoryID		    SMALLINT -- lastest
		, 	LastModifiedDate		DATETIME
		, 	TurnoverRM				DECIMAL(20,4)
		, 	WinlossRM				DECIMAL(20,4)
		, 	BetCount				BIGINT
		, 	ActiveDays				INT	
        , 	LastXDaysMargin   		DECIMAL(20,4)
        , 	ProbationPeriodWinloss 	DECIMAL(20,4)
        ,	TargetCC				SMALLINT
        ,	SourceTypeID            SMALLINT
        , 	ActionType				SMALLINT DEFAULT 0 -- 0: Insert; 1: Update, 3: Ignore Existed PA, 4: Ignore PIN
        ,   IsNeedToRescan      	BIT DEFAULT 0 -- 1: After action Manual Remove => Insert any data
        , 	INDEX    			    IX_Temp_NewClassification_CustID_CategoryID(CustID,CategoryID)     
		, 	INDEX 					IX_Temp_NewClassification_ExistCategoryID_LastCategoryID(ExistCategoryID,LastCategoryID)        
     );     

     DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	 CREATE TEMPORARY TABLE Temp_ExistedClassification 
     (	  	CustID					BIGINT UNSIGNED     
        , 	CategoryID				SMALLINT
        , 	INDEX    			    IX_Temp_ExistedClassification_CustID_CategoryID(CustID,CategoryID)       
     );
 
     INSERT INTO Temp_NewClassification(CustID, NewCategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays, LastXDaysMargin, ProbationPeriodWinloss)
	 SELECT DISTINCT temp.CustID
				, 	temp.NewCategoryID
				, 	temp.LastModifiedDate
                , 	temp.TurnoverRM
                , 	temp.WinlossRM
                , 	temp.BetCount
                , 	temp.ActiveDays
                , 	temp.LastXDaysMargin
                , 	temp.ProbationPeriodWinloss
	 FROM JSON_TABLE(ip_NewClassification,
		 "$[*]" COLUMNS(
				CustID 					BIGINT UNSIGNED		PATH "$.CustId"
			, 	NewCategoryID			SMALLINT UNSIGNED	PATH "$.CategoryId"
			, 	LastModifiedDate		DATETIME			PATH "$.CreatedTime"
            , 	TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
            , 	WinlossRM				DECIMAL(20,4)		PATH "$.WinlossRM"
            , 	BetCount				BIGINT				PATH "$.BetCount"
            , 	ActiveDays				INT					PATH "$.ActiveDays"		
			, 	LastXDaysMargin			DECIMAL(20,4)		PATH "$.LastXDaysMargin"		
			, 	ProbationPeriodWinloss	DECIMAL(20,4)		PATH "$.ProbationPeriodWinloss"		
		 )) AS 	temp
	 WHERE 		temp.NewCategoryID <> 0;
     
    #================================================ALL ACTION TYPES================================================== 
    /*	IGNORE PIN CATEGORY	*/
	UPDATE      Temp_NewClassification AS temp
	INNER JOIN 	CTS_DataCenter.PinCustomerCategory AS pin on pin.CustID = temp.CustID
    SET         temp.ActionType = 4; 
    
	/*	IGNORE PROBLEM ACCOUNT	*/
    UPDATE      Temp_NewClassification AS temp
	INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 0
	SET         temp.ActionType = 3;
    
    /*	UPDATE CUSTOMER INFO */
    UPDATE 		Temp_NewClassification AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET			temp.CTSCustID = cust.CTSCustID
			, 	temp.SubscriberID = cust.SubscriberID;
    
    #==============================================ONLY ACTION TYPE = 0, 1====================================================
	/*	GET EXISTED CATEGORY	*/ 
	INSERT INTO Temp_ExistedClassification (CustID, CategoryID)
    SELECT DISTINCT cate.CustID, cate.CategoryID
    FROM 		CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN  Temp_NewClassification AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 200
	WHERE 		temp.ActionType = 0;
    
    /*	UPDATE EXIST CATEGORY ID INFO */
    UPDATE 		Temp_NewClassification AS temp 
	INNER JOIN	Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID
	SET			temp.ExistCategoryID = ex.CategoryID
			,	temp.ActionType = 1;
    
	/*	UPDATE LAST CATEGORY ID INFO */
	UPDATE 		Temp_NewClassification AS temp 
	SET 		temp.LastCategoryID = (CASE WHEN temp.ExistCategoryID IN (201, 202, 205) AND temp.NewCategoryID IN (203, 204) THEN 206 -- Update New, Normal, VIP to Smart Punter, High Risk Punter
										    ELSE temp.NewCategoryID
									   END)
	WHERE 		temp.ActionType IN (0, 1);

     /*	UPDATE TARGET CC INFO */
    UPDATE 		Temp_NewClassification AS temp 
    LEFT JOIN 	CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
    LEFT JOIN 	CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.LastCategoryID
    SET 		temp.TargetCC =  (CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass -- Existed CC
									   WHEN map.CategoryID IS NOT NULL THEN map.CustomerClass -- Mapping CC
									   ELSE -99 -- No mapping CC
								  END)
	WHERE 		temp.ActionType IN (0, 1);

    /*	UPDATE SOURCE TYPE ID INFO */
    UPDATE 		Temp_NewClassification AS temp 
	SET 		temp.SourceTypeID = (CASE  WHEN temp.ExistCategoryID IS NULL AND temp.LastCategoryID = 201 THEN 1 -- item name = Less than 10 bets
                                           WHEN temp.ExistCategoryID IS NULL AND temp.LastCategoryID IN (202, 203, 204, 205, 206) THEN 2 -- item name = After 10 bets
										   WHEN temp.ExistCategoryID = 201 AND temp.LastCategoryID IN (202, 203, 204, 205, 206) THEN 2 -- item name = After 10 bets To Probation (if have)
										   WHEN temp.ExistCategoryID = 206 AND temp.LastCategoryID IN (203, 204) THEN 4 -- item name = Pass Probation
										   WHEN (temp.ExistCategoryID = 206 AND temp.LastCategoryID = 206) 
                                                AND (temp.LastXDaysMargin IS NOT NULL AND temp.ProbationPeriodWinloss IS NOT NULL) THEN 5 -- item name = Fail Probation
										   WHEN temp.ExistCategoryID IS NOT NULL THEN 3 -- item name = Scan Schedute Date
									  END)
	WHERE 		temp.ActionType IN (0, 1);
    
    #========================================CLASSIFICATION DATA==========================================================
    /*	UPDATE EXISTED CATEGORY */
    UPDATE 		CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN  Temp_NewClassification AS temp on temp.CustID = cate.CustID AND cate.SportGroupID = 200
	SET   		cate.CTSCustID 			= temp.CTSCustID
			, 	cate.SubscriberID  		= temp.SubscriberID
			, 	cate.CategoryID 		= temp.LastCategoryID
			, 	cate.LastModifiedDate 	= temp.LastModifiedDate 
			, 	cate.LastScannedDate 	= DATE(lv_CurrentDateTime)
    WHERE 	temp.ActionType = 1;
    
    /*	INSERT NEW CATEGORY	*/
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification
	(CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT DISTINCT temp.CustID
				, 	temp.CTSCustID
				, 	temp.SubscriberID
				, 	200
				, 	temp.LastCategoryID
				, 	temp.LastModifiedDate
				, 	lv_CreatedBy
				, 	temp.LastModifiedDate
				, 	lv_CreatedBy
				, 	DATE(lv_CurrentDateTime)
	 FROM 		Temp_NewClassification 	AS temp
     WHERE 		temp.ActionType = 0;
    
    #===========================================PROBATION MONITOR DATA=======================================================
	/*	DELETE PROBATION LIST IF PASSED	*/
    DELETE 		pro
    FROM 		CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN 	Temp_NewClassification AS temp on temp.CustID = pro.CustID AND pro.SportGroupID = 200
	WHERE 		temp.ActionType = 1 AND temp.ExistCategoryID = 206 AND temp.LastCategoryID IN (201, 202, 203, 204, 205);
       
    /*	INSERT NEW PROBATION LIST	*/
    INSERT  INTO CTS_DataCenter.ProbationAccountMonitor
	(CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime, LastScannedDate) 
	SELECT  DISTINCT temp.CustID
				, 	temp.CTSCustID
				, 	200
				, 	temp.LastCategoryID
				, 	CASE WHEN temp.TurnoverRM = 0 THEN 0
						 ELSE (temp.WinlossRM / temp.TurnoverRM) * 100
					END AS FirstMargin
				, 	DATE(temp.LastModifiedDate)
				, 	lv_CreatedBy
				, 	temp.LastModifiedDate
				,   DATE(lv_CurrentDateTime)
	FROM  		Temp_NewClassification     AS temp
	WHERE      	(temp.ActionType = 0 AND temp.LastCategoryID = 206);
    
    INSERT  INTO CTS_DataCenter.ProbationAccountMonitor
	(CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime, LastScannedDate) 
	SELECT  DISTINCT temp.CustID
				, 	temp.CTSCustID
				, 	200
				, 	temp.LastCategoryID
				, 	CASE WHEN temp.TurnoverRM = 0 THEN 0
						 ELSE (temp.WinlossRM / temp.TurnoverRM) * 100
					END AS FirstMargin
				, 	DATE(temp.LastModifiedDate)
				, 	lv_CreatedBy
				, 	temp.LastModifiedDate
				,   DATE(lv_CurrentDateTime)
	FROM  		Temp_NewClassification     AS temp
	WHERE      	(temp.ActionType = 1 AND temp.ExistCategoryID <> 206 AND temp.LastCategoryID = 206);
    
    #==========================================WRITE LOG========================================================
    /* INSERT LOG RE-SCAN NORMAL */    
    UPDATE Temp_NewClassification AS temp 
	INNER JOIN ( SELECT his.CustID, MAX(his.ID) AS HistoryID
				 FROM CTS_DataCenter.CTSCustomerClassification_History AS his
				 WHERE his.SourceTypeID IN (8, 9, 12, 14) and his.IsDataChanged = 1
				 GROUP BY his.CustID) AS t ON t.CustID = temp.CustID
	SET temp.IsNeedToRescan = 1;  -- 8: Remove PA by NAP CM, 9: Remove: PA by Evd, 12: Remove Special CC, 14: Remove VVIP ok
    
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
     (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays
    , ActionType,  IsAuto, InsertDate, LastXDaysMargin, ProbationPeriodWinloss, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged)
    SELECT DISTINCT	 temp.CustID
				, 	temp.CTSCustID
				, 	temp.LastCategoryID
				, 	200
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.TurnoverRM
				, 	temp.WinlossRM
				, 	temp.BetCount
				, 	temp.ActiveDays
				, 	temp.ActionType
				, 	1 -- auto
				, 	DATE(lv_CurrentDateTime)
				, 	temp.LastXDaysMargin
				, 	temp.ProbationPeriodWinloss
                ,	temp.TargetCC
                ,   17 -- Rescan Normal Account
				, 	temp.ExistCategoryID
				, 	temp.NewCategoryID
                ,	1 -- View History
	FROM 	    Temp_NewClassification AS temp
	WHERE       temp.IsNeedToRescan = 1 AND temp.ActionType IN (0, 1);
    
    /* INSERT LOG NEW CATEGORY */    
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
     (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays
    , ActionType,  IsAuto, InsertDate, LastXDaysMargin, ProbationPeriodWinloss, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged)
    SELECT DISTINCT	 temp.CustID
				, 	temp.CTSCustID
				, 	temp.LastCategoryID
				, 	200
				, 	temp.LastModifiedDate
				, 	lv_CreatedBy
				, 	temp.TurnoverRM
				, 	temp.WinlossRM
				, 	temp.BetCount
				, 	temp.ActiveDays
				, 	temp.ActionType
				, 	1 -- auto
				, 	DATE(lv_CurrentDateTime)
				, 	temp.LastXDaysMargin
				, 	temp.ProbationPeriodWinloss
                ,	temp.TargetCC
                ,   temp.SourceTypeID
				, 	temp.ExistCategoryID
				, 	temp.NewCategoryID
                ,	1 -- View History
	FROM 		Temp_NewClassification AS temp
	WHERE       temp.IsNeedToRescan = 0 AND temp.ActionType = 0;
    
	/* INSERT LOG EXISTED CATEGORY */    
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays
    , ActionType,  IsAuto, InsertDate, LastXDaysMargin, ProbationPeriodWinloss, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged)
    SELECT DISTINCT	 temp.CustID
				, 	temp.CTSCustID
				, 	temp.LastCategoryID
				, 	200
				, 	temp.LastModifiedDate
				, 	lv_CreatedBy
				, 	temp.TurnoverRM
				, 	temp.WinlossRM
				, 	temp.BetCount
				, 	temp.ActiveDays
				, 	temp.ActionType
				, 	1 -- auto
				, 	DATE(lv_CurrentDateTime)
				, 	temp.LastXDaysMargin
				, 	temp.ProbationPeriodWinloss
				, 	temp.TargetCC
				, 	temp.SourceTypeID
				, 	temp.ExistCategoryID
				, 	temp.NewCategoryID
                ,	CASE WHEN temp.LastCategoryID <> temp.ExistCategoryID THEN 1 -- View History
						 WHEN temp.SourceTypeID = 5 THEN 1 -- View History (Fail Probation)
						 ELSE 0 
					END
	FROM 		Temp_NewClassification AS temp
	WHERE       temp.IsNeedToRescan = 0 AND temp.ActionType = 1;
   
    /*	INSERT LOG IGNORE PIN & EXISTED PA */
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
     (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays
    , ActionType,  IsAuto, InsertDate, LastXDaysMargin, ProbationPeriodWinloss)
    SELECT DISTINCT	 temp.CustID
				, 	temp.CTSCustID
				, 	temp.NewCategoryID
				, 	200
				, 	temp.LastModifiedDate
				, 	lv_CreatedBy
				, 	temp.TurnoverRM
				, 	temp.WinlossRM
				, 	temp.BetCount
				, 	temp.ActiveDays
				, 	temp.ActionType
				, 	1 -- auto
				, 	DATE(lv_CurrentDateTime)
				, 	temp.LastXDaysMargin
				, 	temp.ProbationPeriodWinloss
	FROM 	Temp_NewClassification AS temp
	WHERE   temp.IsNeedToRescan = 0 AND temp.ActionType IN (3, 4);
    
    #==========================================GET LASTEST RESULTS========================================================
	/*	GET LASTEST CUSTID LIST	-> GET LATEST CLASSICATION -> SYNC CC IN MAINDB */
    SELECT DISTINCT temp.CustId FROM Temp_NewClassification AS temp
    WHERE temp.ActionType IN (0, 1);
END$$
DELIMITER ;