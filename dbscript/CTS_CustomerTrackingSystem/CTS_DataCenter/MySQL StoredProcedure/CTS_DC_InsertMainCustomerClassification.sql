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
				- 20201214@Irena.Vo: Update History Log. Get CustId. Return TypeId = 4 [RedmineID: #145951]
                - 20201222@Irena.Vo: Update Logic SP for View History. Insert Error Log [RedmineID: #145951]
				- 20201223@Irena.Vo: Update view log for Rescan Normal [RedmineID: #145951]
                  - 20201224@Irena.Vo: Update view log for Manual Removed list to rescan Normal [RedmineID: #145951]
               
		Param's Explanation (filtered by):
			  CALL CTS_DataCenter.CTS_DC_InsertMainCustomerClassification('[{"CustId": 1, "CategoryId": 202, "CreatedTime": "2020-09-13 00:01:00", "TurnoverRM": 100, "WinlossRM": 2056354, "BetCount": 500, "ActiveDays": 8}]');
	*/ 
	DECLARE	lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_InsertMainCustomerClassification';  
	DECLARE lv_CreatedBy		INT	DEFAULT 10278938;
	DECLARE lv_CurrentDateTime  DATETIME DEFAULT CURRENT_TIME();

	DECLARE op_ErrorNo 			INT DEFAULT 0;
    DECLARE op_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS CONDITION 1 
         	op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	op_ErrorNo 			= 	MYSQL_ERRNO
		,	op_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.ErrorLog(EventName, InsertedTime, Message, Err_No, Description)
        VALUES(lv_SPName, lv_CurrentDateTime, op_ErrorMessage, op_ErrorNo, 	JSON_OBJECT('err_no',op_ErrorNo,'cod_name',op_CodName,'parameter',ip_NewClassification));
    END;

     DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	 CREATE TEMPORARY TABLE Temp_NewClassification 
     (	  	CustID					BIGINT UNSIGNED	PRIMARY KEY       
     	, 	CTSCustID				BIGINT UNSIGNED DEFAULT 0
        , 	SubscriberID			INT DEFAULT 0    
        ,	ExistCategoryID 		SMALLINT UNSIGNED -- existed
		, 	NewCategoryID			SMALLINT UNSIGNED -- new
        , 	LastCategoryID		    SMALLINT UNSIGNED -- lastest
		, 	LastModifiedDate		DATETIME
		, 	TurnoverRM				DECIMAL(20,4)
		, 	WinlossRM				DECIMAL(20,4)
		, 	BetCount				BIGINT
		, 	ActiveDays				INT	
        , 	LastXDaysMargin   		DECIMAL(20,4)
        , 	ProbationPeriodWinloss 	DECIMAL(20,4)
        , 	ActionType				SMALLINT DEFAULT 0 -- Insert: 0; Update: 1
		, 	INDEX 					IX_Temp_NewClassification_ExistCategoryID(ExistCategoryID)     
        , 	INDEX 					IX_Temp_NewClassification_LastCategoryID(LastCategoryID)     
        , 	INDEX 					IX_Temp_NewClassification_ActionType(ActionType)        
     );     

     DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	 CREATE TEMPORARY TABLE Temp_ExistedClassification 
     (	  	CustID					BIGINT UNSIGNED PRIMARY KEY       
        , 	CategoryID				SMALLINT UNSIGNED
        , 	INDEX 					IX_Temp_ExistedClassification_CategoryID(CategoryID)       
     );
     
	 DROP TEMPORARY TABLE IF EXISTS Temp_ManualRemovedList;    -- Rescan Normal
	 CREATE TEMPORARY TABLE Temp_ManualRemovedList 
     (	  
			CustID				BIGINT UNSIGNED PRIMARY KEY    
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
     
    /*	IGNORE PIN CATEGORY	*/
	DELETE 		temp
	FROM 		Temp_NewClassification AS temp
	INNER JOIN 	CTS_DataCenter.PinCustomerCategory AS pin on pin.CustID = temp.CustID;
    
	/*	IGNORE PROBLEM CATEGORY	(MULTI)*/
    DELETE 		temp
    FROM 		Temp_NewClassification AS temp
	INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 0;
    
    /*	UPDATE CUST INFO	*/
    UPDATE 		Temp_NewClassification AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET			temp.CTSCustID = cust.CTSCustID, 	temp.SubscriberID = cust.SubscriberID;

	/*	GET EXISTED CATEGORY	*/ 
	INSERT INTO Temp_ExistedClassification (CustID, CategoryID)
    SELECT DISTINCT cate.CustID, cate.CategoryID
    FROM 		Temp_NewClassification AS temp
    INNER JOIN 	CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 200; 
    
    /*	UPDATE INFO ExistCategoryID, LastCategoryID	FOR TEMP	*/
    UPDATE 		Temp_NewClassification AS temp 
	INNER JOIN	Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID
	SET			temp.ExistCategoryID = ex.CategoryID,	temp.ActionType = 1; -- Only Update PA
    
	UPDATE 		Temp_NewClassification AS temp 
	SET 		temp.LastCategoryID = CASE WHEN (temp.ExistCategoryID IN (201, 202, 205) AND temp.NewCategoryID IN (203, 204)) THEN 206 -- Update New, Normal, VIP to Smart Punter, High Risk Punter
										   ELSE temp.NewCategoryID
									  END; -- Both Insert New & Update PA

    /*	UPDATE INFO FOR EXISTED CATEGORY	*/
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
   
	/*	DELETE PROBATION LIST IF PASSED TARGET CATEGORY	*/
    DELETE 		pro
    FROM 		CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN 	Temp_NewClassification AS temp on temp.CustID = pro.CustID AND pro.SportGroupID = 200
	WHERE 		temp.ExistCategoryID = 206 AND temp.LastCategoryID IN (201, 202, 203, 204, 205);
       
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
	WHERE      	(temp.ExistCategoryID IS NULL OR temp.ExistCategoryID <> 206) AND temp.LastCategoryID = 206;
	
    /*	INSERT HISTORY	*/
	INSERT INTO Temp_ManualRemovedList (CustID)
    SELECT DISTINCT t1.CustID
    FROM (  SELECT DISTINCT his.CustID, MAX(his.ID) AS HistoryID
			FROM CTS_DataCenter.CTSCustomerClassification_History AS his
			INNER JOIN Temp_NewClassification AS temp ON temp.CustID = his.CustID
			GROUP BY his.CustID) AS t1
	INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS t2 ON t2.CustID = t1.CustID AND t2.ID = t1.HistoryID 
    WHERE t2.SourceTypeID IN (8, 9, 12, 14); -- 8: Remove PA by NAP CM, 9: Remove: PA by Evd, 12: Remove Special CC, 14: Remove VVIP
    
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays
    , ActionType,  IsAuto, InsertDate, LastXDaysMargin, ProbationPeriodWinloss, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsView)
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
				, 	CASE 	WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass -- Existed CC
							ELSE map.CustomerClass
					END
				, 	CASE   WHEN temp.ExistCategoryID IS NULL AND temp.LastCategoryID = 201 THEN 1 -- item name = Less than 10 bets
						   WHEN temp.ExistCategoryID IS NULL AND temp.LastCategoryID IN (202, 203, 204, 205, 206) THEN 2 -- item name = After 10 bets
						   WHEN temp.ExistCategoryID = 201 AND temp.LastCategoryID IN (202, 203, 204, 205, 206) THEN 2 -- item name = After 10 bets To Probation (if have)
						   WHEN temp.ExistCategoryID = 206 AND temp.LastCategoryID IN (203, 204) THEN 4 -- item name = Pass Probation
						   WHEN temp.ExistCategoryID = 206 AND temp.LastCategoryID = 206 THEN 5 -- item name = Fail Probation
                           ELSE 3 -- item name = Scan Schedute Date
					END AS SourceTypeID
				, 	temp.ExistCategoryID
				, 	temp.NewCategoryID
                ,	CASE WHEN s.CustID IS NOT NULL THEN 1 -- View History
						 WHEN temp.ActionType = 0 THEN 1 -- View History
                         WHEN temp.ActionType = 1 AND (temp.LastCategoryID <> temp.ExistCategoryID) THEN 1 -- View History
						 WHEN temp.ActionType = 1 AND (temp.LastCategoryID = 206 AND temp.ExistCategoryID = 206) THEN 1 -- View History
						 ELSE 0
					END
	FROM 		Temp_NewClassification AS temp
    LEFT JOIN   Temp_ManualRemovedList AS s ON temp.CustID = s.CustID -- Need to View for Rescan Normal
	LEFT JOIN 	CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
    INNER JOIN 	CTS_DataCenter.CategoryToCustomerClass AS map ON temp.LastCategoryID = map.CategoryID;
   
	/*	GET LASTEST CUSTID LIST	-> GET LATEST CLASSICATION -> SYNC CC IN MAINDB */
    SELECT DISTINCT temp.CustId FROM Temp_NewClassification AS temp;
END$$

DELIMITER ;