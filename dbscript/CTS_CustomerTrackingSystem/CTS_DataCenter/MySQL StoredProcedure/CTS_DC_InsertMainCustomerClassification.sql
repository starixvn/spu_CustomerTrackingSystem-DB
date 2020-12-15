/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_InsertMainCustomerClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertMainCustomerClassification`(IN ip_NewClassification JSON)
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
				-20201214@Irena.Vo: Update History Log. Get CustId. Return TypeId = 4 [RedmineID: #145951]
               - 20201215@Irena.Vo: Enhance logic join with CategoryID [RedmineID: #145951]
                
		Param's Explanation (filtered by):

        Example: 
			-  CALL CTS_DataCenter.CTS_DC_InsertMainCustomerClassification('[{"CustId": 1, "CategoryId": 202, "CreatedTime": "2020-09-13 00:01:00", "TurnoverRM": 100, "WinlossRM": 2056354, "BetCount": 500, "ActiveDays": 8}]');
	*/ 
     DECLARE  lv_CreatedBy			INT	DEFAULT 10278938;
	 DECLARE  lv_CurrentDateTime    DATETIME DEFAULT NOW();

     DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	 CREATE TEMPORARY TABLE Temp_NewClassification 
     (	  CustID					BIGINT UNSIGNED        
        , SportGroupID				SMALLINT UNSIGNED
		, CategoryID				SMALLINT UNSIGNED
		, LastModifiedDate			DATETIME
		, TurnoverRM				DECIMAL(20,4)
		, WinlossRM					DECIMAL(20,4)
		, BetCount					BIGINT
		, ActiveDays				INT	
		, CTSCustID					BIGINT UNSIGNED DEFAULT 0
        , SubscriberID				INT DEFAULT 0    
		, ActionType				SMALLINT DEFAULT 0 -- Insert: 0; Update: 1
        , LastXDaysMargin   		DECIMAL(20,4)
        , ProbationPeriodWinloss 	DECIMAL(20,4)
        , PRIMARY KEY				PK_Temp_NewClassification_CustID(CustID) 
        , INDEX 					IX_Temp_NewClassification_CategoryID(CategoryID)     
        , INDEX 					IX_Temp_NewClassification_ActionType(ActionType)        
     );     

     DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	 CREATE TEMPORARY TABLE Temp_ExistedClassification 
     (	  CustID					BIGINT UNSIGNED        
        , CategoryID				SMALLINT UNSIGNED
        , INDEX 					IX_Temp_ExistedClassification_CustID_CategoryID(CustID, CategoryID)       
     );
     
     INSERT INTO Temp_NewClassification(CustID, SportGroupID, CategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays, LastXDaysMargin, ProbationPeriodWinloss)
	 SELECT DISTINCT temp.CustID
				, 200
				, temp.CategoryID
				, temp.LastModifiedDate
                , temp.TurnoverRM
                , temp.WinlossRM
                , temp.BetCount
                , temp.ActiveDays
                , temp.LastXDaysMargin
                , temp.ProbationPeriodWinloss
	 FROM JSON_TABLE(ip_NewClassification,
		 "$[*]" COLUMNS(
			  CustID 					BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 				SMALLINT UNSIGNED	PATH "$.SportGroupId"
			, CategoryID				SMALLINT UNSIGNED	PATH "$.CategoryId"
			, LastModifiedDate			DATETIME			PATH "$.CreatedTime"
            , TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
            , WinlossRM					DECIMAL(20,4)		PATH "$.WinlossRM"
            , BetCount					BIGINT				PATH "$.BetCount"
            , ActiveDays				INT					PATH "$.ActiveDays"		
			, LastXDaysMargin			DECIMAL(20,4)		PATH "$.LastXDaysMargin"		
			, ProbationPeriodWinloss	DECIMAL(20,4)		PATH "$.ProbationPeriodWinloss"		
		 )) AS temp
	 WHERE temp.CategoryID <> 0;
     
    /*	IGNORE PIN CATEGORY	*/
     DELETE temp
	 FROM Temp_NewClassification AS temp
	 INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CustID = temp.CustID;
    
	/*	IGNORE PROBLEM CATEGORY	*/
    DELETE temp
    FROM Temp_NewClassification AS temp
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
	WHERE cate.CategoryID > 50 AND cate.CategoryID < 200;
    
    /*	GET EXISTED CATEGORY	*/ 
	INSERT INTO Temp_ExistedClassification
    SELECT DISTINCT cate.CustID, cate.CategoryID
    FROM Temp_NewClassification AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    WHERE cate.CategoryID > 200 AND cate.CategoryID < 300; 
    
    /*	UPDATE CUST INFO	*/
    UPDATE 	Temp_NewClassification AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;

    /*	UPDATE CATEGORY	*/
    UPDATE Temp_NewClassification AS temp 
    INNER JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
    SET temp.ActionType = 1;
    
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN  Temp_NewClassification AS temp on temp.CustID = cate.CustID AND temp.SportGroupID = cate.SportGroupID  
    INNER JOIN  Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
    SET   cate.CTSCustID = temp.CTSCustID
        , cate.SubscriberID  = temp.SubscriberID
        , cate.CategoryID = (CASE WHEN (ex.CategoryID IN (202, 205) AND temp.CategoryID IN (203, 204)) THEN 206 -- Update New, Normal, VIP to Smart Punter, High Risk Punter
                                  ELSE temp.CategoryID
                             END)
        , cate.LastModifiedDate = temp.LastModifiedDate 
        , cate.LastModifiedBy = lv_CreatedBy
        , cate.LastScannedDate = DATE(lv_CurrentDateTime)
    WHERE cate.CategoryID > 200 AND cate.CategoryID < 300;
    
    /*	INSERT NEW CATEGORY	*/
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification
     (CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	 SELECT DISTINCT  temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, temp.SportGroupID
            , temp.CategoryID 
			, temp.LastModifiedDate
			, lv_CreatedBy
			, temp.LastModifiedDate
			, lv_CreatedBy
            , DATE(lv_CurrentDateTime)
	 FROM 	Temp_NewClassification 		AS temp
     WHERE temp.ActionType = 0;
   
	/*	DELETE PROBATION LIST IF PASSED TARGET CATEGORY	*/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN Temp_NewClassification AS temp on temp.CustID = pro.CustID  AND temp.SportGroupID = pro.SportGroupID  
	INNER JOIN   Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
	WHERE ex.CategoryID = 206 AND temp.CategoryID IN (202, 203, 204, 205) AND pro.SportGroupID = 200;
       
    /*	INSERT NEW PROBATION LIST	*/
    INSERT  INTO CTS_DataCenter.ProbationAccountMonitor
		(CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime, LastScannedDate) 
	SELECT  DISTINCT temp.CustID
		, 	temp.CTSCustID
        , 	temp.SportGroupID
		, 	temp.CategoryID
		, 	CASE WHEN temp.TurnoverRM = 0 THEN 0
                   ELSE (temp.WinlossRM / temp.TurnoverRM) * 100
			END AS FirstMargin
		, 	DATE(temp.LastModifiedDate)
		, 	lv_CreatedBy
		, 	temp.LastModifiedDate
		,   DATE(lv_CurrentDateTime)
	FROM   Temp_NewClassification     AS temp
	LEFT JOIN   Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
	WHERE      temp.ActionType = 0 AND (   ex.CategoryID IS NULL AND temp.CategoryID = 206) -- New Category 
			OR (temp.ActionType = 1 AND (  (ex.CategoryID IN (203, 204) AND temp.CategoryID = 206)
										OR (ex.CategoryID IN (202, 205) AND temp.CategoryID IN (203, 204, 206)) ) );  -- Old Category
	
    /*	INSERT LOG	*/
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays
    , ActionType,  IsAuto, InsertDate, LastXDaysMargin, ProbationPeriodWinloss, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID)
    SELECT DISTINCT	  temp.CustID
			, temp.CTSCustID
			, CASE WHEN (ex.CategoryID IN (201, 202, 205) AND temp.CategoryID IN (203, 204)) THEN 206 -- Update category to Smart Punter, High Risk Punter
				   ELSE temp.CategoryID
              END
            , temp.SportGroupID
            , temp.LastModifiedDate
            , lv_CreatedBy
            , temp.TurnoverRM
            , temp.WinlossRM
            , temp.BetCount
            , temp.ActiveDays
			, temp.ActionType
            , 1 -- auto
            , DATE(lv_CurrentDateTime)
			, temp.LastXDaysMargin
            , temp.ProbationPeriodWinloss
			, CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass
                   WHEN (ex.CategoryID IN (201, 202, 205) AND temp.CategoryID IN (203, 204)) THEN 5 -- Probation
                   ELSE map.CustomerClass
			  END
            , CASE WHEN ex.CategoryID = 201 AND temp.CategoryID IN (202, 205) THEN 2 -- item name = After first 10 bets
                   WHEN ex.CategoryID = 201 AND temp.CategoryID IN (203, 204, 206) THEN 2 -- item name = After first 10 bets - To Probation
                   WHEN ex.CategoryID IN (202, 205) AND temp.CategoryID IN (202, 205) THEN 3 -- item name = Scan Schedule Date
                   WHEN ex.CategoryID = 206 AND temp.CategoryID IN (202, 205) THEN 3 -- item name = Scan Schedule Date
                   WHEN ex.CategoryID IN (203, 204) AND temp.CategoryID IN (203, 204) THEN 3 -- item name = Scan Schedule Date
                   WHEN ex.CategoryID IN (202, 205) AND temp.CategoryID IN (203, 204, 206) THEN 3 -- item name = Scan Schedule Date - To Probation
                   WHEN ex.CategoryID IN (203, 204) AND temp.CategoryID = 206 THEN 3 -- item name = Scan Schedule Date - To Probation
                   WHEN ex.CategoryID = 206 AND temp.CategoryID IN (203, 204) THEN 4 -- item name = Pass Probation
                   WHEN ex.CategoryID = 206 AND temp.CategoryID = 206 THEN 5 -- item name = Fail Probation
                   WHEN temp.CategoryID = 201 THEN 1 -- item name = Less than 10 bets
                   WHEN temp.CategoryID IN (202, 203, 204, 205, 206) THEN 2 -- item name = After first 10 bets
			  END AS SourceTypeID
			, ex.CategoryID
            , temp.CategoryID
	FROM 	Temp_NewClassification AS temp
    INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON temp.CategoryID = map.CategoryID
    LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
    LEFT JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID;
   
   /*	GET LASTEST CUSTID LIST	*/
    SELECT DISTINCT temp.CustId, 4 AS TypeId FROM Temp_NewClassification AS temp; 

END$$

DELIMITER ;