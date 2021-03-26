/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_InsertMainCustomerClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertMainCustomerClassification`(
		IN ip_NewClassification JSON
    
    ,	OUT op_ErrorMessage VARCHAR(200)
)
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
			    - 20210115@Irena.Vo: Insert History Log  [RedmineID: #145951]
				- 20210118@Casey.Huynh: Add New PA Rule NewMember(231,232,233)[RedmineID: #148908]
				- 20210226@Casey.Huynh: Add New PA Rule [RedmineID: #150454, 150455]
                - 20210326@Irena.Vo: Save Additional IsCateChanged [RedmineID: #152249]
                
		Param's Explanation (filtered by):
			  call CTS_DataCenter.CTS_DC_InsertMainCustomerClassification
('[{"CustId": "43600693","CategoryId":"202","CreatedTime":"2020-10-01 00:00:00","TurnoverRM":"100","WinlossRM":"10","BetCount":"15","ActiveDays":"10", "TaggingID":10, "TaggingType":1}]', @err);
	*/ 
	DECLARE lv_CreatedBy INT DEFAULT 10278938;
	DECLARE lv_CurrentDateTime DATETIME DEFAULT CURRENT_TIME();
	DECLARE	lv_No INT DEFAULT 1;
	
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No = NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            op_ErrorMessage = MESSAGE_TEXT;	
	
		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_InsertMainCustomerClassification',op_ErrorMessage, JSON_OBJECT('parameter', ip_NewClassification));
    
		SIGNAL SQLSTATE '99999' SET MESSAGE_TEXT = op_ErrorMessage;
	END;

	DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification(	  	
			CustID					BIGINT UNSIGNED	PRIMARY KEY
		, 	NewCategoryGroup		SMALLINT -- DW Category
		, 	TurnoverRM				DECIMAL(20,4)
		, 	WinlossRM				DECIMAL(20,4)
		, 	BetCount				BIGINT
		, 	ActiveDays				INT	
        , 	LastXDaysMargin   		DECIMAL(20,4)
        , 	ProbationPeriodWinloss 	DECIMAL(20,4)
		,	TaggingID				SMALLINT
        ,	TaggingType				SMALLINT		
        ,	TargetCC				SMALLINT
        ,	SourceTypeID            SMALLINT
        , 	ActionType				SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN */
		, 	CTSCustID				BIGINT DEFAULT 0
        , 	SubscriberID			INT DEFAULT 0        
        ,	ExistCategoryID 		SMALLINT -- Exist
        ,	ExistCategoryGroup		SMALLINT
        ,	NewCategoryID			SMALLINT
        , 	INDEX    			    IX_Temp_NewClassification_CustID_NewCategoryID(CustID,NewCategoryGroup)     
		, 	INDEX 					IX_Temp_NewClassification_ExistCategoryID_NewCategoryID(ExistCategoryID,NewCategoryID)        
	); 
	  
	INSERT INTO Temp_NewClassification(CustID, NewCategoryGroup, TurnoverRM, WinlossRM, BetCount, ActiveDays, LastXDaysMargin, ProbationPeriodWinloss, TaggingID, TaggingType)
	SELECT DISTINCT temp.CustID
				, 	temp.NewCategoryGroup
                , 	temp.TurnoverRM
                , 	temp.WinlossRM
                , 	temp.BetCount
                , 	temp.ActiveDays
                , 	temp.LastXDaysMargin
                , 	temp.ProbationPeriodWinloss
                ,	IFNULL(temp.TaggingID,0)
                , 	temp.TaggingType
	 FROM JSON_TABLE(ip_NewClassification,
		"$[*]" COLUMNS(
				CustID 					BIGINT UNSIGNED		PATH "$.CustId"
			, 	NewCategoryGroup		SMALLINT UNSIGNED	PATH "$.CategoryId"
            , 	TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
            , 	WinlossRM				DECIMAL(20,4)		PATH "$.WinlossRM"
            , 	BetCount				BIGINT				PATH "$.BetCount"
            , 	ActiveDays				INT					PATH "$.ActiveDays"		
			, 	LastXDaysMargin			DECIMAL(20,4)		PATH "$.LastXDaysMargin"		
			, 	ProbationPeriodWinloss	DECIMAL(20,4)		PATH "$.ProbationPeriodWinloss"
            , 	TaggingID				SMALLINT			PATH "$.TaggingID"
            , 	TaggingType				SMALLINT			PATH "$.TaggingType"		
		 )) AS 	temp
	 WHERE temp.NewCategoryGroup <> 0;
	
    #================================================PREPARE DATA================================================== 
    /*	IGNORE PIN CATEGORY	*/
	UPDATE Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CustID = temp.CustID
    SET temp.ActionType = 4;     
    
	/*	IGNORE PROBLEM ACCOUNT	*/
    UPDATE Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 0
	SET temp.ActionType = 3;
    
    /*	UPDATE CUSTOMER INFO */
    UPDATE Temp_NewClassification AS temp 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID
		, 	temp.SubscriberID = cust.SubscriberID;
    
	/*	GET Exist CATEGORY*/   
   UPDATE Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID AND cate.SportGroupID = 200
        INNER JOIN TaggingToCategory AS tag ON tag.CategoryID = cate.CategoryID 
   SET	temp.ExistCategoryID = cate.CategoryID
		, temp.ExistCategoryGroup = tag.CategoryGroup
        , temp.ActionType = 1
	WHERE temp.ActionType = 0;
   
	/*	UPDATE LAST CATEGORY ID INFO */
	UPDATE Temp_NewClassification AS temp 
	SET temp.NewCategoryGroup = (CASE WHEN temp.ExistCategoryGroup IN (201, 202, 205) AND temp.NewCategoryGroup IN (203, 204) THEN 206 /* Update New, Normal, VIP to Smart Punter, High Risk Punter */
									ELSE temp.NewCategoryGroup
								END)
	WHERE temp.ActionType IN (0, 1);	
	   
    /*	UPDATE SOURCE TYPE ID INFO */
    UPDATE Temp_NewClassification AS temp 
	SET temp.SourceTypeID = (CASE WHEN temp.ExistCategoryGroup IS NULL AND temp.NewCategoryGroup IN (201) THEN 1 /* Less than 10 bets */
                                  WHEN temp.ExistCategoryGroup IS NULL AND temp.NewCategoryGroup IN (202, 203, 204, 205, 206) THEN 2 /* After 10 bets */
								  WHEN temp.ExistCategoryGroup = 201 AND temp.NewCategoryGroup IN (202, 203, 204, 205, 206) THEN 2 /* After 10 bets To Probation (if have) */
								  WHEN temp.ExistCategoryGroup = 206 AND temp.NewCategoryGroup IN (203, 204) THEN 4 /* Pass Probation */
								  WHEN (temp.ExistCategoryGroup = 206 AND temp.NewCategoryGroup = 206) 
                                         AND (temp.LastXDaysMargin IS NOT NULL AND temp.ProbationPeriodWinloss IS NOT NULL) THEN 5 /* Fail Probation */
								  WHEN temp.ExistCategoryGroup IS NOT NULL THEN 3 /* Scan Schedute Date */
									  END)
	WHERE temp.ActionType IN (0, 1);    
     
    #========================================CLASSIFY DATA==========================================================
    /*UPDATE NewCategoryID By TaggingToCategory */
    UPDATE Temp_NewClassification AS temp
		LEFT JOIN  CTS_DataCenter.TaggingToCategory AS ttc ON ttc.CategoryGroup = temp.NewCategoryGroup AND ttc.TaggingType = temp.TaggingType AND ttc.TaggingID = temp.TaggingID
    SET		temp.NewCategoryID = IFNULL(ttc.CategoryID,temp.NewCategoryGroup);	

    /*UPDATE TARGET CC INFO */
    UPDATE Temp_NewClassification AS temp 
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
		LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.NewCategoryID
	SET temp.TargetCC = (CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass /* Exist CC */
							  WHEN map.CategoryID IS NOT NULL THEN map.CustomerClass /* Mapping CC */
							  ELSE -99 /* No mapping CC */
						  END)
	WHERE temp.ActionType IN (0, 1);    
   
    /*	UPDATE Exist CATEGORY */
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 200
	SET   	cate.CTSCustID = temp.CTSCustID
		, 	cate.SubscriberID = temp.SubscriberID
		, 	cate.CategoryID = temp.NewCategoryID
		, 	cate.LastModifiedDate = lv_CurrentDateTime
		, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
    WHERE temp.ActionType = 1;

    INSERT INTO CTS_DataCenter.CTSCustomerClassification
	(CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	temp.SubscriberID
		, 	200
		, 	temp.NewCategoryID
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime) AS LastScannedDate
	 FROM Temp_NewClassification AS temp
     WHERE temp.ActionType = 0;

    #===========================================PROBATION MONITOR DATA=======================================================
	/*	DELETE PROBATION LIST IF PASSED	*/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		INNER JOIN Temp_NewClassification AS temp on temp.CustID = pro.CustID AND pro.SportGroupID = 200
	WHERE temp.ActionType = 1 AND temp.ExistCategoryGroup = 206 AND temp.NewCategoryGroup IN (201, 202, 203, 204, 205);
    
    /*	INSERT NEW PROBATION LIST	*/
    INSERT INTO CTS_DataCenter.ProbationAccountMonitor
	(CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime, LastScannedDate) 
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	200 AS SportGroupID
		, 	temp.NewCategoryID
		, 	(CASE WHEN temp.TurnoverRM = 0 THEN 0
				 ELSE (temp.WinlossRM / temp.TurnoverRM) * 100
			END) AS FirstMargin
		, 	DATE(lv_CurrentDateTime) AS CreatedDate
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		,   DATE(lv_CurrentDateTime) AS LastScannedDate
	FROM Temp_NewClassification AS temp
	WHERE (temp.ActionType = 0 AND temp.NewCategoryGroup = 206);
    
    INSERT INTO CTS_DataCenter.ProbationAccountMonitor
	(CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime, LastScannedDate) 
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	200 AS SportGroupID
		, 	temp.NewCategoryID
		, 	(CASE WHEN temp.TurnoverRM = 0 THEN 0
				 ELSE (temp.WinlossRM / temp.TurnoverRM) * 100
			END) AS FirstMargin
		, 	DATE(lv_CurrentDateTime) AS CreatedDate
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		,   DATE(lv_CurrentDateTime) AS LastScannedDate
	FROM Temp_NewClassification AS temp
	WHERE (temp.ActionType = 1 AND temp.ExistCategoryGroup <> 206 AND temp.NewCategoryGroup = 206);
    
    #==========================================WRITE LOG======================================================== 
    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
	 (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays
	 , ActionType,  IsAuto, InsertDate, LastXDaysMargin, ProbationPeriodWinloss, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged, TaggingType, IsCateChanged)
	SELECT DISTINCT	temp.CustID
		, 	temp.CTSCustID
		, 	temp.NewCategoryID
		, 	200 AS SportGroupID
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	temp.TurnoverRM
		, 	temp.WinlossRM
		, 	temp.BetCount
		, 	temp.ActiveDays
		, 	temp.ActionType
		, 	1 AS IsAuto
		, 	DATE(lv_CurrentDateTime) AS InsertDate
		, 	temp.LastXDaysMargin
		, 	temp.ProbationPeriodWinloss
		,	temp.TargetCC
		,   temp.SourceTypeID
		, 	temp.ExistCategoryID
		, 	temp.NewCategoryID
		,   (CASE WHEN temp.SourceTypeID = 5 OR (temp.NewCategoryID <> IFNULL(temp.ExistCategoryID,0)) THEN 1 ELSE 0 END) AS IsDataChanged
		,	temp.TaggingType
		,   (CASE WHEN temp.NewCategoryID <> IFNULL(temp.ExistCategoryID,0) THEN 1 ELSE 0 END) AS IsCateChanged
	FROM Temp_NewClassification AS temp;
   
	#=========================================GET LASTEST CUSTOMERS FOR CLASSICATION=========================================================
    SELECT DISTINCT temp.CustId FROM Temp_NewClassification AS temp WHERE temp.ActionType IN (0, 1);
END$$
DELIMITER ;