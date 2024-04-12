/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_BySport_InsertNormalAccount`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_InsertNormalAccount`(
		IN ip_NewClassification 	JSON
    
    ,	OUT op_ErrorMessage 		VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20220830@Harvey.Nguyen
		Task:		Insert customer categories for specific sport
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				- 20220830@Harvey.Nguyen: Created [Redmine ID: #177434]
				- 202230426@Long.Luu: Adjust Probation's period from 20 to 15 [Redmine ID: #187433]
                - 20230704@Jonas.Huynh: Normal Renovation [Redmine ID: #189875]
				- 20240318@Jonas.Huynh: Config Probation Days [Redmine ID: #201359]
                - 20240321@Thomas.Nguyen: Add logic for Special CC BySport [Redmine ID: #201360]

		Param's Explanation (filtered by):
        
        Example:
				CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_InsertNormalAccount
				('[{"CustId": "4345542", "SportGroup":1, "CategoryId":"203", "TurnoverRM":"100","WinlossRM":"10","BetCount":"15","ActiveDays":"10", "PerformanceTime":"2021-03-31 00:00:00"}]',@or);
*/ 
    
    DECLARE CONST_CATEGORY_NEWMEMBER 					INT DEFAULT 201;
	DECLARE	CONST_CATEGORY_NORMALMEMBER 				INT DEFAULT 202;
	DECLARE CONST_CATEGORY_SMART 						INT DEFAULT 203;
    DECLARE CONST_CATEGORY_HIGHRISK 					INT DEFAULT 204;
    DECLARE CONST_CATEGORY_GOOD							INT DEFAULT 205;
    DECLARE CONST_CATEGORY_PROBATION					INT DEFAULT 206;
    
    DECLARE CONST_ACTIONTYPE_INSERT 					INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 					INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 					INT DEFAULT 2;
    DECLARE CONST_ACTIONTYPE_IGNOREPROBATION 			INT DEFAULT 5;
    
	DECLARE CONST_SOURCETYPE_SAMECATEGORY 				INT DEFAULT 0;
    DECLARE CONST_SOURCETYPE_LESSTHAN10TICKETS			INT DEFAULT 1;

	DECLARE lv_CreatedBy 								INT DEFAULT 10278938;
	DECLARE lv_CurrentDateTime 							DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_CurrentDate								DATE DEFAULT CURRENT_DATE();
	DECLARE lv_ToProbationLastDay 						DATE DEFAULT DATE_SUB(lv_CurrentDate, INTERVAL 2 DAY);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification(	  	
			CustID						BIGINT UNSIGNED
		, 	CTSCustID					BIGINT DEFAULT 0
        ,	SportID						SMALLINT
		, 	TurnoverRM					DECIMAL(20,4)
		, 	WinlossRM					DECIMAL(20,4)
		, 	BetCount					BIGINT
		, 	ActiveDays					INT	
		,	DWCateID					SMALLINT
        ,	OldCateGroup 				SMALLINT
        ,	OldCateID 					SMALLINT
      	, 	NewCateGroup				SMALLINT
		,	NewCateID					SMALLINT
		,	IsDataChanged				BIT DEFAULT 1 /*0: No change category => No Action*/
        ,	OldTargetCC					SMALLINT
        ,	TargetCC					SMALLINT
		, 	ActionType					SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN; 5: Not satisfy Pass Probation*/
        ,	PerformanceTime				DATETIME
		,	SpecialCC					INT
		,	SourceTypeID      			SMALLINT
		, 	INDEX    			    	IX_Temp_NewClassification(CustID, DWCateID)  
        ,	PRIMARY KEY (CustID, SportID)
	); 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedCustomers;    
	CREATE TEMPORARY TABLE Temp_ExistedCustomers(	  	
			CustID					BIGINT UNSIGNED PRIMARY KEY
        , 	CTSCustID				BIGINT
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ProbationCustomers;    
	CREATE TEMPORARY TABLE Temp_ProbationCustomers(	  	
			CustID					BIGINT UNSIGNED
		,	SportID					SMALLINT
        , 	ProbationDate			DATE     
        ,	LastProbationDay		DATE
        ,	PRIMARY KEY (CustID, SportID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustIgnoranceAction;    
	CREATE TEMPORARY TABLE Temp_CustIgnoranceAction(	  	
			CustID					BIGINT UNSIGNED
		,	SportID					SMALLINT
        , 	ActionType				SMALLINT      
        ,	PRIMARY KEY (CustID, SportID)
	); 
	
    DROP TEMPORARY TABLE IF EXISTS Temp_OldClassification;    
	CREATE TEMPORARY TABLE Temp_OldClassification(	  
			CustID					BIGINT UNSIGNED
		,	SportID					SMALLINT
        ,	OldCateGroup 			SMALLINT
        ,	OldCateID 				SMALLINT
        ,	PRIMARY KEY (CustID, SportID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_OldCustomerClass;    
	CREATE TEMPORARY TABLE Temp_OldCustomerClass(	  
			CustID					BIGINT UNSIGNED
		,	SportID					SMALLINT
        ,	CustomerClass 			SMALLINT
        ,	PRIMARY KEY (CustID, SportID)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_UpdateCustomerClass;    
	CREATE TEMPORARY TABLE Temp_UpdateCustomerClass(	  
			CustID					BIGINT UNSIGNED
		,	SportID					SMALLINT
        ,	CustomerClass 			SMALLINT
        ,	PRIMARY KEY (CustID, SportID)
	); 
    
    /* START */
    /* INIT */            
	/* 1: PARSE RAW DATA */
	INSERT IGNORE INTO Temp_NewClassification(CustID, SportID, DWCateID, TurnoverRM, WinlossRM, BetCount, ActiveDays, PerformanceTime)
	SELECT DISTINCT temp.CustID
                , 	temp.SportID
				, 	temp.DWCateID
                , 	temp.TurnoverRM
                , 	temp.WinlossRM
                , 	temp.BetCount
                , 	temp.ActiveDays
                ,	temp.PerformanceTime
	 FROM JSON_TABLE(ip_NewClassification,
		"$[*]" COLUMNS(
				CustID 					BIGINT UNSIGNED		PATH "$.CustId"
            , 	SportID					SMALLINT UNSIGNED	PATH "$.SportGroup"
			, 	DWCateID				SMALLINT UNSIGNED	PATH "$.CategoryId"
            , 	TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
            , 	WinlossRM				DECIMAL(20,4)		PATH "$.WinlossRM"
            , 	BetCount				BIGINT				PATH "$.BetCount"
            , 	ActiveDays				INT					PATH "$.ActiveDays"		
            ,	PerformanceTime			DATETIME			PATH "$.PerformanceTime"
		 )) AS 	temp
	 WHERE temp.DWCateID <> 0;
	
    /* 2: EXCLUDE INTERNAL CUSTOMERS */      
    CALL CTS_DC_ExcludeCustByCondition('Temp_NewClassification');
    
    /* 3: GET CUSTOMER INFO */
    INSERT IGNORE INTO Temp_ExistedCustomers(CustID, CTSCustID)
    SELECT 	DISTINCT cust.CustID
		, 	cust.CTSCustID
    FROM Temp_NewClassification AS temp 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust 
			ON temp.CustID = cust.CustID AND cust.CustSubID = 0;
        
    UPDATE Temp_NewClassification AS temp 
		INNER JOIN Temp_ExistedCustomers AS ec ON temp.CustID = ec.CustID
	SET		temp.CTSCustID = ec.CTSCustID;
    
	UPDATE Temp_NewClassification AS temp
		INNER JOIN  CTS_DataCenter.SpecialCustomerClass_BySport AS sb ON sb.CTSCustID = temp.CTSCustID AND sb.SportID = temp.SportID
	SET temp.SpecialCC = sb.CustomerClass;

    /*4: GET PROBATION CUSTOMERS */
    INSERT IGNORE INTO Temp_ProbationCustomers(CustID, SportID, ProbationDate, LastProbationDay)
    SELECT DISTINCT prob.CustID, prob.SportID, prob.CreatedDate, DATE_SUB(lv_CurrentDate, INTERVAL CAST(s.ItemValue AS UNSIGNED) DAY)
    FROM 	Temp_NewClassification AS temp
		INNER JOIN 	CTS_DataCenter.ProbationAccountMonitor_BySport AS prob ON temp.CustID = prob.CustID AND temp.SportID =  prob.SportID
        INNER JOIN 	CTS_DataCenter.StaticList AS s ON s.ListID = 23 AND s.ItemID = temp.SportID;
    
    /* 5: EXCLUDE CUSTOMERS THAT SHOULD NOT BE SCANNED */    
    INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, SportID, ActionType)
    SELECT DISTINCT	temp.CustID, temp.SportID, CONST_ACTIONTYPE_IGNOREPROBATION
	FROM 	Temp_NewClassification AS temp 
		INNER JOIN Temp_ProbationCustomers AS pro ON temp.CustID = pro.CustID AND temp.SportID =  pro.SportID
    WHERE 	(temp.DWCateID IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK, CONST_CATEGORY_PROBATION) AND pro.ProbationDate > pro.LastProbationDay) 
			OR (pro.ProbationDate >= lv_ToProbationLastDay);
    
    /* 5.4: UPDATE BACK TO Temp_NewClassification */
	/* 5.4.1: HAS ACTION + NO VIEW LOG FAIL PROBATION FOR > PROBATION LAST DAYS */ 
    UPDATE Temp_NewClassification AS temp
		INNER JOIN  Temp_ProbationCustomers AS pro ON pro.CustID = temp.CustID AND pro.SportID = temp.SportID
	SET 	temp.IsDataChanged = 0
    WHERE 	(temp.DWCateID = CONST_CATEGORY_PROBATION AND pro.ProbationDate < pro.LastProbationDay);
    
    /* 5.4.2: NO ACTION + VIEW LOG FOR IGNORE CASES */ 
   	UPDATE Temp_NewClassification AS temp 
		INNER JOIN Temp_CustIgnoranceAction AS ig ON temp.CustID = ig.CustID AND temp.SportID =  ig.SportID
    SET 	temp.ActionType = ig.ActionType
		, 	temp.IsDataChanged = 0;
	
    /* 6: GENERATE CATEGORY */    
	/* 6.2: UPDATE EXISTED CATEGORY */  
    INSERT IGNORE INTO Temp_OldClassification(CustID, SportID, OldCateGroup, OldCateID)
    SELECT DISTINCT temp.CustID, temp.SportID, cc.CategoryGroup, cate.CategoryID
    FROM Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS cate ON temp.CustID = cate.CustID AND cate.SportID = temp.SportID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_IGNOREPROBATION);
    
    UPDATE Temp_NewClassification AS n
		LEFT JOIN Temp_OldClassification AS o ON n.CustID = o.CustID AND n.SportID = o.SportID
	SET n.OldCateGroup = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateGroup END,
		n.OldCateID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateID END,
        n.ActionType = CASE WHEN o.CustID IS NULL THEN CONST_ACTIONTYPE_INSERT ELSE CONST_ACTIONTYPE_UPDATE END
	WHERE n.ActionType IN (CONST_ACTIONTYPE_INSERT);
    
    UPDATE Temp_NewClassification AS n
		LEFT JOIN Temp_OldClassification AS o ON n.CustID = o.CustID AND n.SportID = o.SportID
	SET n.OldCateGroup = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateGroup END,
		n.OldCateID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateID END
	WHERE n.ActionType IN (CONST_ACTIONTYPE_IGNOREPROBATION);
    
    /* 6.3: UPDATE NEW CATEGORY */    
    UPDATE 	Temp_NewClassification AS temp 
	SET 	temp.NewCateGroup = (CASE WHEN temp.OldCateGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER, CONST_CATEGORY_GOOD) 
											AND temp.DWCateID IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK) THEN CONST_CATEGORY_PROBATION 
									  ELSE temp.DWCateID 
								  END)
		  , temp.NewCateID = (CASE WHEN temp.OldCateGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER, CONST_CATEGORY_GOOD) 
											AND temp.DWCateID IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK) THEN CONST_CATEGORY_PROBATION 
									  ELSE temp.DWCateID 
								  END)
	 WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);

	UPDATE 	Temp_NewClassification AS temp 
	SET 	temp.SourceTypeID = (CASE WHEN (temp.OldCateGroup IS NULL OR temp.OldCateGroup = CONST_CATEGORY_NEWMEMBER) AND temp.NewCateGroup = CONST_CATEGORY_NEWMEMBER THEN CONST_SOURCETYPE_LESSTHAN10TICKETS
                                      WHEN temp.OldCateGroup = temp.NewCateGroup THEN CONST_SOURCETYPE_SAMECATEGORY
								END)
	WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);

    /* 7: GENERATE DATA NO CHANGED */   
    UPDATE 	Temp_NewClassification AS temp
	SET 	temp.IsDataChanged = (CASE WHEN temp.NewCateID = temp.OldCateID THEN 0 /*No update category*/ ELSE temp.IsDataChanged END)
	WHERE 	temp.ActionType = CONST_ACTIONTYPE_UPDATE;     
    
    /* 8: GENERATE TARGET CC */
    UPDATE Temp_NewClassification AS tmp 
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = tmp.NewCateID
	SET 	tmp.TargetCC = IFNULL(tmp.SpecialCC, cate.CustomerClass)
	WHERE 	tmp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_IGNOREPROBATION);
	
    /* 8 PLUS:  */
    INSERT INTO Temp_OldCustomerClass(CustID, SportID)
    SELECT DISTINCT temp.CustID, temp.SportID
    FROM Temp_NewClassification AS temp
	WHERE temp.IsDataChanged  = 0;
    
    INSERT IGNORE INTO Temp_UpdateCustomerClass(CustID, SportID, CustomerClass)
    WITH CTE_LatestLog AS (
		SELECT h.CustID, h.SportID, MAX(h.LastModifiedDate) AS LatestInsertDate
		FROM Temp_OldCustomerClass AS t
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport_History AS h ON t.CustID = h.CustID AND t.SportID = h.SportID
		GROUP BY h.CustID, h.SportID
	),
    CTE_LatestHistory AS (
		SELECT h.CustID, h.SportID, h.TargetCC
		FROM CTE_LatestLog AS l
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_BySport_History AS h ON l.CustID = h.CustID AND l.SportID = h.SportID AND l.LatestInsertDate = h.LastModifiedDate
	)
    SELECT 	cte.CustID
		,	cte.SportID
		,	cte.TargetCC
	FROM CTE_LatestHistory AS cte;
        
	UPDATE Temp_UpdateCustomerClass AS c
		INNER JOIN Temp_NewClassification AS t ON c.CustID = t.CustID AND c.SportID = t.SportID
	SET t.OldTargetCC = c.CustomerClass;
    
    UPDATE Temp_NewClassification AS tmp
		INNER JOIN CustomerCategory AS cate ON tmp.OldCateID = cate.CategoryID
    SET tmp.TargetCC =	IFNULL(tmp.SpecialCC, cate.CustomerClass)
		,	tmp.NewCateID = tmp.OldCateID
        , 	tmp.NewCateGroup = tmp.OldCateGroup
    WHERE tmp.ActionType = CONST_ACTIONTYPE_IGNOREPROBATION;
        
    UPDATE Temp_NewClassification
    SET IsDataChanged = 1
		,	ActionType = CONST_ACTIONTYPE_UPDATE
    WHERE IsDataChanged = 0 
		AND ((TargetCC <> OldTargetCC) OR (OldCateID <> NewCateID))
		AND (ActionType = CONST_ACTIONTYPE_IGNOREPROBATION 
			OR SourceTypeID IN (CONST_SOURCETYPE_SAMECATEGORY, CONST_SOURCETYPE_LESSTHAN10TICKETS));
    
    /* 11: UPDATE CTS CLASSIFICATION */
    UPDATE CTS_DataCenter.CTSCustomerClassification_BySport AS cate
		INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cate.CustID AND cate.SportID = temp.SportID
	SET   	cate.CTSCustID = temp.CTSCustID
		, 	cate.CategoryID = temp.NewCateID
		, 	cate.LastModifiedDate = lv_CurrentDateTime
		, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
    WHERE temp.ActionType = CONST_ACTIONTYPE_UPDATE;
	
    /* 12: INSERT CTS CLASSIFICATION */
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport (CustID, CTSCustID, SportID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	temp.SportID
		, 	temp.NewCateID
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime) AS LastScannedDate
	 FROM Temp_NewClassification AS temp
     WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT; 

    /* 13: REMOVE DATA FOR PASS PROBATION */
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor_BySport AS pro
		INNER JOIN Temp_NewClassification AS temp on temp.CustID = pro.CustID AND pro.SportID = temp.SportID
	WHERE temp.ActionType = CONST_ACTIONTYPE_UPDATE AND temp.OldCateGroup = CONST_CATEGORY_PROBATION AND temp.NewCateGroup <> CONST_CATEGORY_PROBATION;
    
    /* 14: INSERT NEW PROBATION */
    INSERT IGNORE INTO CTS_DataCenter.ProbationAccountMonitor_BySport
	(CustID, CTSCustID, SportID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime, LastScannedDate) 
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	temp.SportID
		, 	temp.DWCateID
		, 	(CASE WHEN temp.TurnoverRM = 0 THEN 0 ELSE (temp.WinlossRM/temp.TurnoverRM) * 100 END) AS FirstMargin
		, 	DATE(lv_CurrentDateTime) AS CreatedDate
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		,   DATE(lv_CurrentDateTime) AS LastScannedDate
	FROM Temp_NewClassification AS temp
	WHERE temp.NewCateGroup = CONST_CATEGORY_PROBATION 
		AND (temp.ActionType = CONST_ACTIONTYPE_INSERT 
			OR (temp.ActionType = CONST_ACTIONTYPE_UPDATE AND temp.OldCateGroup <> CONST_CATEGORY_PROBATION));

    /* 15: WRITE HISTORY LOG (VIEW ON WEB) */
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport_History
	(CustID, CTSCustID, CategoryID, SportID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, InsertDate, TargetCC, PerformanceTime, SourceTypeID)
	SELECT DISTINCT	temp.CustID
				, 	temp.CTSCustID
				, 	temp.NewCateID
				, 	temp.SportID
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.TurnoverRM
				, 	temp.WinlossRM
				, 	temp.BetCount
				, 	temp.ActiveDays
				, 	temp.ActionType
				, 	DATE(lv_CurrentDateTime)
				,	temp.TargetCC 
                ,	temp.PerformanceTime	
				,	temp.SourceTypeID
	FROM 	Temp_NewClassification AS temp
	WHERE temp.IsDataChanged  = 1;
	
    /* 16: WRITE HISTORY LOG (TRACE DATA) */
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_BySport_Log
	(CustID, CTSCustID, CategoryID, SportID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, InsertDate, TargetCC, OldCategoryID, DWCategoryID, IsDataChanged, PerformanceTime, SourceTypeID)
	SELECT DISTINCT	temp.CustID
				, 	temp.CTSCustID
				, 	temp.NewCateID
				, 	temp.SportID
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.TurnoverRM
				, 	temp.WinlossRM
				, 	temp.BetCount
				, 	temp.ActiveDays
				, 	temp.ActionType
				, 	DATE(lv_CurrentDateTime)
				,	temp.TargetCC 
				, 	temp.OldCateID 
                , 	temp.DWCateID
				,   temp.IsDataChanged
                ,	temp.PerformanceTime
				,	temp.SourceTypeID
	FROM 	Temp_NewClassification AS temp;
    
	/* 17: RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS */
	SELECT DISTINCT temp.CustID, temp.SportID AS SportGroup
    FROM Temp_NewClassification AS temp 
    WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
END$$
DELIMITER ;