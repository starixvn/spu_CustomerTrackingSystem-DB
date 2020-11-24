/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_InsertMainCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertMainCustomerClassification`(IN ip_NewClassification JSON)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200901@Lex.Khuat
		Task:		Auto insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		Original:
		Revisions:
				[20200901@Lex.Khuat][137550]: Created 
				[20200908@Irena.Vo][141020]: Enhance Exclude VVIP Customers, Pin category 
				[20200921-20201001@Irena.Vo][141755]: 
                - Enhance SP
                - Insert Probation Management flow
                - Add get parentid for process update category. 
                [20201003-20201022@Irena.Vo][142546]: Enhance SP & correct logic. 
                [20201026@Irena.Vo][142546]: Enhance init data for Probation to VIP OR Normal.
                [20201116@Irena.Vo][145028]: Only distinct CustID list for general & Update LastScannedDate for Probation List.
                
		Param's Explanation (filtered by):
			call CTS_DataCenter.CTS_DC_InsertMainCustomerClassification
            ('[{"CustId": 1, "CategoryId": 202, "CreatedTime": "2020-09-13 00:01:00", "TurnoverRM": 100, "WinlossRM": 2056354, "BetCount": 500, "ActiveDays": 8}]');
	*/ 
     DECLARE  lv_CreatedBy			INT	DEFAULT 10278938;

     DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	 CREATE TEMPORARY TABLE Temp_NewClassification 
     (	  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED
		, CategoryID		SMALLINT UNSIGNED
		, LastModifiedDate	DATETIME
		, TurnoverRM		DECIMAL(20,4)
		, WinlossRM			DECIMAL(20,4)
		, BetCount			BIGINT
		, ActiveDays		INT	
		, CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , SubscriberID		INT DEFAULT 0    
		, ActionType		SMALLINT DEFAULT 0 -- Insert: 0; Update: 1
        , PRIMARY KEY		PK_Temp_NewClassification_CustID(CustID) 
        , INDEX 			IX_Temp_NewClassification_CustID_SportGroupID_CategoryID(CustID, SportGroupID, CategoryID)     
        , INDEX 			IX_Temp_NewClassification_ActionType(ActionType)        
     );     

     DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	 CREATE TEMPORARY TABLE Temp_ExistedClassification 
     (	  CustID			BIGINT UNSIGNED        
        , CategoryID		SMALLINT UNSIGNED
        , INDEX 			IX_Temp_ExistedClassification_CustID_CategoryID(CustID, CategoryID)       
     );
     
     INSERT INTO Temp_NewClassification(CustID, SportGroupID, CategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	 SELECT DISTINCT temp.CustID
				, 200
				, temp.CategoryID
				, temp.LastModifiedDate
                , temp.TurnoverRM
                , temp.WinlossRM
                , temp.BetCount
                , temp.ActiveDays
	 FROM JSON_TABLE(ip_NewClassification,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SportGroupID 		SMALLINT UNSIGNED	PATH "$.SportGroupId"
			, CategoryID		SMALLINT UNSIGNED	PATH "$.CategoryId"
			, LastModifiedDate	DATETIME			PATH "$.CreatedTime"
            , TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
            , WinlossRM			DECIMAL(20,4)		PATH "$.WinlossRM"
            , BetCount			BIGINT				PATH "$.BetCount"
            , ActiveDays		INT					PATH "$.ActiveDays"		
		 )) AS temp
	 INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = temp.CategoryID 
	 WHERE cc.ParentID = 200 AND temp.CategoryID <> 0;
	
     SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
     
	/*******************************************START DATA*********************************************************/ 
    /*IGNORE VVIP - PIN CATEGORY*/
     DELETE temp
	 FROM Temp_NewClassification AS temp
	 INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID -- is VVIP OR PIN
	 WHERE sc.CreatedFromFunction IN (11, 21);
    
	/*IGNORE PROBLEM CATEGORY*/
    DELETE temp
    FROM Temp_NewClassification AS temp
	INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
	INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID
	WHERE cc.ParentID = 50;
    
    /*GET EXISTED CATEGORY*/ 
	INSERT INTO Temp_ExistedClassification
    SELECT DISTINCT cate.CustID, cate.CategoryID
    FROM Temp_NewClassification AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID 
    WHERE cc.ParentID = 200; 
    
    /*UPDATE CUST INFO*/
    UPDATE 	Temp_NewClassification AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
	/****************************************************END DATA**********************************************************/
    
    /****************************************************START CATEGORY***************************************************/
    /*UPDATE CATEGORY*/
    UPDATE Temp_NewClassification AS temp 
    INNER JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
    SET temp.ActionType = 1;
    
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN  Temp_NewClassification AS temp on temp.CustID = cate.CustID AND temp.SportGroupID = cate.SportGroupID  
    INNER JOIN  Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
    INNER JOIN  CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID 
    SET   cate.CTSCustID = temp.CTSCustID
        , cate.SubscriberID  = temp.SubscriberID
        , cate.CategoryID = (CASE WHEN (ex.CategoryID IN (202, 205) AND temp.CategoryID IN (203, 204)) THEN 206 -- Update category to Smart Punter, High Risk Punter
                                  ELSE temp.CategoryID
                             END)
        , cate.LastModifiedDate = temp.LastModifiedDate 
        , cate.LastModifiedBy = lv_CreatedBy
        , cate.LastScannedDate = GREATEST(DATE(temp.LastModifiedDate), cate.LastScannedDate)
    WHERE cc.ParentID = 200;
    
    /*INSERT NEW CATEGORY*/
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
            , DATE(temp.LastModifiedDate)
	 FROM 	Temp_NewClassification 		AS temp
     LEFT JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
     WHERE ex.CategoryID IS NULL;  -- temp.ActionType = 0
    
    /*INSERT LOG*/
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate,LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType,  IsAuto, InsertDate)
    SELECT DISTINCT	  temp.CustID
			, temp.CTSCustID
			, temp.CategoryID
            , temp.SportGroupID
            , temp.LastModifiedDate
            , lv_CreatedBy
            , temp.TurnoverRM
            , temp.WinlossRM
            , temp.BetCount
            , temp.ActiveDays
			, temp.ActionType
            , 1
            , CURRENT_DATE()
	FROM 	Temp_NewClassification AS temp;
    /****************************************************END CATEGORY***************************************************/
    
    /***************************************************START PROBATION*************************************************/
	/*DELETE PROBATION LIST IF PASSED TARGET CATEGORY*/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	INNER JOIN Temp_NewClassification AS temp on temp.CustID = pro.CustID  AND temp.SportGroupID = pro.SportGroupID  
	INNER JOIN   Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
	WHERE ex.CategoryID = 206 AND temp.CategoryID IN (202, 203, 204, 205) AND pro.SportGroupID = 200;
       
    /*INSERT NEW PROBATION LIST*/
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
		,   DATE(temp.LastModifiedDate)
   FROM   Temp_NewClassification     AS temp
   LEFT JOIN   Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
   WHERE      temp.ActionType = 0 AND (   ex.CategoryID IS NULL AND temp.CategoryID = 206) -- New Category 
          OR (temp.ActionType = 1 AND (  (ex.CategoryID IN (203, 204) AND temp.CategoryID = 206)
										OR (ex.CategoryID IN (202, 205) AND temp.CategoryID IN (203, 204, 206)) ) );  -- Old Category
	/***************************************************END PROBATION*************************************************/
     /*GET DISTINCT CUSTID*/
    SELECT DISTINCT temp.CustID AS CustId
			, (CASE WHEN (ex.CategoryID IN (202, 205) AND temp.CategoryID IN (203, 204)) THEN 206 -- Update category to Smart Punter, High Risk Punter
                     ELSE temp.CategoryID
			   END) AS CategoryId
    FROM Temp_NewClassification AS temp
    LEFT JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID; -- Get lastest custid for mapping to CC in mainDB
   
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;     
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;      

END$$

DELIMITER ;