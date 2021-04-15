/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_InsertMainCustomerClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertMainCustomerClassification`(
		IN ip_NewClassification JSON
    
    ,	OUT op_ErrorMessage 	VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20200901@Lex.Khuat
		Task:		Auto insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				- 20200901@Lex.Khuat: Created [Redmine ID: #137550]
				- 20200908@Irena.Vo: Enhance Exclude VVIP Customers, Pin category  [Redmine ID: #141020]
				- 20201001@Irena.Vo: Insert Probation Management flow [Redmine ID: #145954]
                - 20201022@Irena.Vo: Enhance SP & correct logic. [Redmine ID: #142546]
                - 20201116@Irena.Vo: Only distinct CustID list for general & Update LastScannedDate for Probation List. [Redmine ID: #145028]
                - 20201201@Aries.Nguyen: Update metadata for goSQL. Remove transaction isolation level REPEATABLE READ and READ UNCOMMITTED. [Redmine ID: #145954]
			    - 20210115@Irena.Vo: Insert History Log  [RedmineID: #145951]
				- 20210118@Casey.Huynh: Add New PA Rule NewMember(231,232,233) [RedmineID: #148908]
				- 20210226@Casey.Huynh: Add New PA Rule [RedmineID: 150455]
                - 20210401@Irena.Vo: Write log for Update Danger Level. Enhance logic SP. [RedmineID: #152249]
                - 20210415@Casey.Huynh: Ignore Probation Account Monitor if not meet the scan schedule [RedmineID: #153491]
		Param's Explanation (filtered by):
        Example:
				- CALL CTS_DataCenter.CTS_DC_InsertMainCustomerClassification('[{"CustId": "2324948","CategoryId":"206","CreatedTime":"2021-03-31 00:00:00","TurnoverRM":"100","WinlossRM":"10","BetCount":"15","ActiveDays":"10","LastXDaysMargin":100,"ProbationPeriodWinloss":100,"TaggingID":13,"TaggingType":1}]',@opp);
	*/ 
	DECLARE lv_CreatedBy INT DEFAULT 10278938;
	DECLARE lv_CurrentDateTime DATETIME DEFAULT CURRENT_TIME();

	DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification(	  	
		-- Classification info
			CustID					BIGINT UNSIGNED	PRIMARY KEY
		, 	DWCateGroup				SMALLINT
        ,	DWCateID				SMALLINT
		, 	TurnoverRM				DECIMAL(20,4)
		, 	WinlossRM				DECIMAL(20,4)
		, 	BetCount				BIGINT
		, 	ActiveDays				INT	
        , 	LastXDaysMargin   		DECIMAL(20,4)
        , 	ProbationPeriodWinloss 	DECIMAL(20,4)
		,	TaggingID				SMALLINT
        ,	TaggingType				SMALLINT	
        ,	ExistedCateGroup 		SMALLINT
        ,	ExistedCateID 			SMALLINT
        , 	NewCateGroup			SMALLINT
        ,	NewCateID				SMALLINT
        ,	OldCC					SMALLINT -- fix issue concurrency
        ,	TargetCC				SMALLINT
        ,	TargetDangerLevel1		SMALLINT
        ,	SourceTypeID      		SMALLINT
        , 	ActionType				SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN , 5: Ignore ProbationAccountMonitor if NOT MEET the Scan Schedule*/
        -- Customer info
        , 	CTSCustID				BIGINT DEFAULT 0
        , 	SubscriberID			INT DEFAULT 0        
        ,	IsLicensee				BIT 
        , 	INDEX    			    IX_Temp_NewClassification_CustID_DWCateGroup(CustID,DWCateGroup)     
		, 	INDEX 					IX_Temp_NewClassification_ExistedCateID_NewCateID(ExistedCateID,NewCateID)        
	); 
	  
	INSERT INTO Temp_NewClassification(CustID,DWCateGroup,TurnoverRM,WinlossRM,BetCount,ActiveDays,LastXDaysMargin,ProbationPeriodWinloss,TaggingID,TaggingType)
	SELECT DISTINCT temp.CustID
				, 	temp.DWCateGroup
                , 	temp.TurnoverRM
                , 	temp.WinlossRM
                , 	temp.BetCount
                , 	temp.ActiveDays
                , 	temp.LastXDaysMargin
                , 	temp.ProbationPeriodWinloss
                ,	IFNULL(temp.TaggingID,-99)
                , 	temp.TaggingType
	 FROM JSON_TABLE(ip_NewClassification,
		"$[*]" COLUMNS(
				CustID 					BIGINT UNSIGNED		PATH "$.CustId"
			, 	DWCateGroup				SMALLINT UNSIGNED	PATH "$.CategoryId"
            , 	TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
            , 	WinlossRM				DECIMAL(20,4)		PATH "$.WinlossRM"
            , 	BetCount				BIGINT				PATH "$.BetCount"
            , 	ActiveDays				INT					PATH "$.ActiveDays"		
			, 	LastXDaysMargin			DECIMAL(20,4)		PATH "$.LastXDaysMargin"		
			, 	ProbationPeriodWinloss	DECIMAL(20,4)		PATH "$.ProbationPeriodWinloss"
            , 	TaggingID				SMALLINT			PATH "$.TaggingID"
            , 	TaggingType				SMALLINT			PATH "$.TaggingType"		
		 )) AS 	temp
	 WHERE temp.DWCateGroup <> 0;

    /*	IGNORE PIN CATEGORY	*/
	UPDATE Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CustID = temp.CustID
    SET temp.ActionType = 4;     
    
	/*	IGNORE PROBLEM ACCOUNT	*/
    UPDATE Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 0
	SET temp.ActionType = 3;
    
    /*	IGNORE PROPATION ACCOUNT MONITOR IF NOT MEET THE SCAN SCHEDULE*/
	UPDATE 	Temp_NewClassification AS temp
		INNER JOIN 	ProbationAccountMonitor AS pro ON temp.CustID = pro.CustID
    SET		temp.ActionType = 5
    WHERE 	pro.CreatedDate != DATE_SUB(DATE(lv_CurrentDateTime), INTERVAL 20 DAY)
		AND	pro.CreatedDate <  DATE_SUB(DATE(lv_CurrentDateTime), INTERVAL 3 DAY);  
    
    /*	UPDATE CUSTOMER INFO */
    UPDATE Temp_NewClassification AS temp 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
        INNER JOIN CTS_DataCenter.MappingSubscriberSite AS map ON map.SubscriberID = cust.SubscriberID
	SET		temp.CTSCustID = cust.CTSCustID
		, 	temp.SubscriberID = cust.SubscriberID
        ,	temp.IsLicensee = CASE WHEN map.SubscriberGroupID = 2 THEN 1 /*Licensee*/ ELSE 0 /*Credit/CN88*/ END
	WHERE 	temp.ActionType = 0;
  
   /* UPDATE DW CATEGORY */
    UPDATE Temp_NewClassification AS temp 
		LEFT JOIN TaggingToCategory AS tag ON tag.CategoryGroup = temp.DWCateGroup AND tag.TaggingType = 1 AND temp.TaggingID = tag.TaggingID
	SET 	temp.DWCateID = IFNULL(tag.CategoryID,temp.DWCateGroup)
    WHERE 	temp.ActionType = 0;
    
   /* UPDATE EXISTED CATEGORY */  
    UPDATE Temp_NewClassification AS temp
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID AND cate.SportGroupID = 200
	SET		temp.ExistedCateGroup = 201
	WHERE 	temp.ActionType = 0 AND temp.DWCateGroup <> 201 AND cate.CustID IS NULL; -- fix issue concurrence.
    
    UPDATE Temp_NewClassification AS temp
        LEFT JOIN TaggingToCategory AS tag ON tag.CategoryGroup = temp.ExistedCateGroup AND tag.TaggingType = 1 AND temp.TaggingID = tag.TaggingID
	SET		temp.ExistedCateID = IFNULL(tag.CategoryID,temp.ExistedCateGroup)
	WHERE 	temp.ActionType = 0 AND temp.ExistedCateGroup = 201; -- fix issue concurrence.
    
	UPDATE Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID AND cate.SportGroupID = 200
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	SET		temp.ExistedCateGroup = cc.CategoryGroup
		,	temp.ExistedCateID = cate.CategoryID
        , 	temp.ActionType = 1
	WHERE temp.ActionType = 0;
    
   /* UPDATE NEW CATEGORY */
	UPDATE 	Temp_NewClassification AS temp 
	SET 	temp.NewCateGroup = CASE WHEN temp.ExistedCateGroup IN (201,202,205) AND temp.DWCateGroup IN (203,204) THEN 206 ELSE temp.DWCateGroup END
	WHERE 	temp.ActionType IN (0,1);
	
    UPDATE 	Temp_NewClassification AS temp 
		LEFT JOIN TaggingToCategory AS tag ON tag.CategoryGroup = temp.NewCateGroup AND tag.TaggingType = 1 AND temp.TaggingID = tag.TaggingID
	SET 	temp.NewCateID = IFNULL(tag.CategoryID,temp.NewCateGroup)
    WHERE 	temp.ActionType IN (0,1);
    
    /*	UPDATE SOURCE TYPE */   
    
    UPDATE Temp_NewClassification AS temp 
	SET 	temp.SourceTypeID = CASE WHEN temp.ExistedCateGroup IS NULL AND temp.NewCateGroup IN (201) THEN 1 /* Less than 10 bets */
									 WHEN temp.ExistedCateGroup = 201 AND temp.NewCateGroup <> 201 THEN 2 /* After 10 bets To Probation (if have) */
									 WHEN temp.ExistedCateGroup = 206 AND temp.NewCateGroup IN (203,204) THEN 4 /* Pass Probation */
									 WHEN (temp.ExistedCateGroup = 206 AND temp.NewCateGroup = 206) AND (temp.LastXDaysMargin IS NOT NULL AND temp.ProbationPeriodWinloss IS NOT NULL) THEN 5 /* Fail Probation */
									 WHEN temp.ExistedCateGroup IS NOT NULL AND temp.SourceTypeID IS NULL THEN 3 /* Scan Schedute Date */
								END
	WHERE 	temp.ActionType IN (0,1);     
    
    /* UPDATE TARGET CC */
    UPDATE Temp_NewClassification AS temp 
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
		LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS o ON o.CategoryID = temp.ExistedCateID AND temp.ActionType = 0 AND temp.ExistedCateGroup = 201
        LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS n ON n.CategoryID = temp.NewCateID
	SET 	temp.OldCC = IFNULL(sp.CustomerClass,o.CustomerClass)
		,	temp.TargetCC = IFNULL(sp.CustomerClass,n.CustomerClass)
	WHERE 	temp.ActionType IN (0,1);
   
    /* UPDATE TARGET DANGER LEVEL 1 */
    UPDATE Temp_NewClassification AS temp 
		INNER JOIN CTS_DataCenter.CategoryToDangerLevel AS d ON d.CategoryID = temp.NewCateID AND d.IsLicensee = temp.IsLicensee AND d.TypeID = 1
    SET 	temp.TargetDangerLevel1 = d.DangerLevel
    WHERE 	temp.ActionType IN (0,1);
    
    #========================================CLASSIFY DATA==========================================================
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 200
	SET   	cate.CTSCustID = temp.CTSCustID
		, 	cate.SubscriberID = temp.SubscriberID
		, 	cate.CategoryID = temp.NewCateID
		, 	cate.LastModifiedDate = lv_CurrentDateTime
		, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
    WHERE temp.ActionType = 1;

    INSERT INTO CTS_DataCenter.CTSCustomerClassification
	(CustID,CTSCustID,SubscriberID,SportGroupID,CategoryID,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,LastScannedDate)
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	temp.SubscriberID
		, 	200
		, 	temp.NewCateID
		, 	CASE WHEN temp.ExistedCateGroup = 201 THEN DATE_SUB(lv_CurrentDateTime,INTERVAL 1 SECOND) ELSE lv_CurrentDateTime END -- fix issue concurrence.
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime) AS LastScannedDate
	 FROM Temp_NewClassification AS temp
     WHERE temp.ActionType = 0; 

    #===========================================PROBATION MONITOR DATA=======================================================
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		INNER JOIN Temp_NewClassification AS temp on temp.CustID = pro.CustID AND pro.SportGroupID = 200
	WHERE temp.ActionType = 1 AND temp.ExistedCateGroup = 206 AND temp.NewCateGroup <> 206;
    
    INSERT IGNORE INTO CTS_DataCenter.ProbationAccountMonitor
	(CustID,CTSCustID,SportGroupID,TargetCategoryID,FirstMargin,CreatedDate,CreatedBy,CreatedTime,LastScannedDate) 
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	200 AS SportGroupID
		, 	temp.DWCateID
		, 	(CASE WHEN temp.TurnoverRM = 0 THEN 0 ELSE (temp.WinlossRM/temp.TurnoverRM) * 100 END) AS FirstMargin
		, 	DATE(lv_CurrentDateTime) AS CreatedDate
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		,   DATE(lv_CurrentDateTime) AS LastScannedDate
	FROM Temp_NewClassification AS temp
	WHERE temp.NewCateGroup = 206 AND ((temp.ActionType = 0 AND temp.ExistedCateGroup = 201) OR (temp.ActionType = 1  AND temp.ExistedCateGroup <> 206));
    
    #==========================================WRITE LOG======================================================== 
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History  -- fix issue concurrence.
	(CustID,CTSCustID,CategoryID,SportGroupID,LastModifiedDate,LastModifiedBy,TurnoverRM,WinlossRM,BetCount,ActiveDays,ActionType,IsAuto,InsertDate,TargetCC,SourceTypeID,ToCategoryID,IsDataChanged,TargetDangerLevel1)
	SELECT DISTINCT	temp.CustID
		, 	temp.CTSCustID
		, 	temp.ExistedCateID
		, 	200
		, 	DATE_SUB(lv_CurrentDateTime, INTERVAL 1 SECOND)
		, 	lv_CreatedBy
		, 	temp.TurnoverRM
		, 	temp.WinlossRM
		, 	temp.BetCount
		, 	temp.ActiveDays
		, 	temp.ActionType
		, 	1
		, 	DATE(lv_CurrentDateTime)
		,	temp.OldCC
		,   1
		, 	temp.ExistedCateID
		,   1
        ,   temp.TargetDangerLevel1
	FROM Temp_NewClassification AS temp
    WHERE temp.ActionType = 0 AND temp.ExistedCateGroup = 201; 
    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
	(CustID,CTSCustID,CategoryID,SportGroupID,LastModifiedDate,LastModifiedBy,TurnoverRM,WinlossRM,BetCount,ActiveDays,ActionType,IsAuto,InsertDate,LastXDaysMargin,ProbationPeriodWinloss,TargetCC,SourceTypeID,FromCategoryID,ToCategoryID,IsDataChanged,TaggingType,TargetDangerLevel1)
	SELECT DISTINCT	temp.CustID
		, 	temp.CTSCustID
		, 	temp.NewCateID
		, 	200
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	temp.TurnoverRM
		, 	temp.WinlossRM
		, 	temp.BetCount
		, 	temp.ActiveDays
		, 	CASE WHEN temp.ActionType = 0 AND temp.ExistedCateGroup = 201 THEN 1 ELSE temp.ActionType END
		, 	1
		, 	DATE(lv_CurrentDateTime)
		, 	temp.LastXDaysMargin
		, 	temp.ProbationPeriodWinloss
		,	temp.TargetCC 
		,   temp.SourceTypeID
		, 	temp.ExistedCateID
		, 	temp.DWCateID 
		,   CASE WHEN temp.ActionType IN (0,1) AND (temp.SourceTypeID = 5 OR (temp.NewCateID <> IFNULL(temp.ExistedCateID,0))) THEN 1 ELSE 0 END
		,	temp.TaggingType
        ,	temp.TargetDangerLevel1
	FROM Temp_NewClassification AS temp;
   
	#=========================================GET LASTEST CUSTOMERS FOR CLASSICATION========================================================= 
    SELECT DISTINCT temp.CustId FROM Temp_NewClassification AS temp WHERE temp.ActionType IN (0,1);
END$$
DELIMITER ;