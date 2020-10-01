USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_AutoTagCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_AutoTagCustomerClassification`(IN ip_NewClassification JSON)
BEGIN
	/*
		Created:	20200505@Terry.Nguyen212121
		Task:		Auto tag for Customer Classification
		DB:			CTS_DataCenter
		Original:

		Revisions:
				[20200612@Casey.Huynh][135324]: Enhance SP      
                [20200618@Casey.Huynh][135324]: Enhance SP  
                [20200701@Casey.Huynh][135324]: Change Flow and Store more Info
				[20200903@Irena.Vo][137550]: Ignore Main category with ActionType = -1. 
                [20200903@Irena.Vo][141042]: Enhance get IsUsedManually = 0 for update category
                [20200908@Irena.Vo][141020]: Enhance exclude VVIP Customers, Pin Category
                [20200921@Irena.Vo][141755]: Enhance SP & insert Probation Management flow. Have actioned Probation is initial data yet.
				[20200923@Irena.Vo][141755]: Enhance SP. 
                [20200929@Irena.Vo][141755]: Enhance SP. DELETE TEMP NEW CATEGORY.
				[20200930@Irena.Vo][141755]: Enhance SP. FIX issue by have not delete TEMP NEW CATEGORY if insert with other category in the same time
                [20201001@Irena.Vo][141755]: Fix issue duplicate category & enhance logic
                
		Param's Explanation (filtered by):
                call CTS_DataCenter.CTS_DC_AutoTagCustomerClassification
                ('[{"CustId": "43600890","SportGroupId":1, "CategoryId":"10", "CreatedTime": "2020-09-19", "TurnoverRM":"100", "WinlossRM":"11","BetCount":"11", "ActiveDays":"10"}]');
	*/   
     DECLARE     lv_CreatedBy INT DEFAULT 10278938;  
 
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
        , PRIMARY KEY		PK_Temp_NewClassification_CustID_SportGroupID(CustID, SportGroupID) 
        , INDEX 			IX_Temp_NewClassification_ActionType(ActionType)        
     );     
    
	 DROP TEMPORARY TABLE IF EXISTS Temp_OtherCategory;    
	 CREATE TEMPORARY TABLE Temp_OtherCategory 
     (	  CustID			BIGINT UNSIGNED        
       ,  CategoryID		SMALLINT UNSIGNED
     );
     
     DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	 CREATE TEMPORARY TABLE Temp_ExistedClassification 
     (	  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED
        , CategoryID		SMALLINT UNSIGNED
     );
     
     INSERT INTO Temp_NewClassification(CustID, SportGroupID, CategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	 SELECT 	  temp.CustID
				, temp.SportGroupID
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
		 )) AS temp;   
	
     SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
	 SET SQL_SAFE_UPDATES = 0;
     
	/*******************************************START DATA*********************************************************/ 
    /*IGNORE DANGEROUS CUSTOMER*/
    DELETE temp
    FROM Temp_NewClassification AS temp
    WHERE temp.CategoryID = 0;
    
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
    
	/*IGNORE NEW MEMBER (IF CUSTOMER HAS BOTH NEW MEMBER & OTHER CATEGORY)*/ 
    INSERT INTO Temp_OtherCategory
	SELECT CustID, CategoryID
    FROM Temp_NewClassification 
    WHERE CategoryID != 2;
    
    DELETE temp
    FROM Temp_NewClassification AS temp 
    INNER JOIN Temp_OtherCategory AS other on other.CustID = temp.CustID
	WHERE temp.CategoryID = 2;
    
    /*GET EXISTED CATEGORY*/ 
	INSERT INTO Temp_ExistedClassification
    SELECT DISTINCT cate.CustID, cate.SportGroupID, cate.CategoryID
    FROM Temp_NewClassification AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID 
    WHERE cc.ParentID = 1; -- Save existed category before so that insert new probation list with Probation Category from New Member
    
    /*IGNORE PROBATION TO VIP OR NORMAL*/ 
	DELETE temp
    FROM Temp_NewClassification AS temp 
    INNER JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID AND ex.SportGroupID = temp.SportGroupID 
	WHERE ex.CategoryID = 10 AND temp.CategoryID IN (4, 5);
    
    /*DELETE NO CHANGED CATEGORY*/ 
    DELETE temp
    FROM Temp_NewClassification AS temp 
    INNER JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = temp.CategoryID 
	WHERE cc.ParentID = 1 AND ex.CategoryID != 2 AND temp.CategoryID = 2; 
    
    /*DELETE NEW MEMBER IS EXISTED BEFORE (IF CUSTOMER HAS OTHER CATEGORY)*/ 
	DELETE 		cate
    FROM 		CTS_DataCenter.CTSCustomerClassification  AS cate
    LEFT JOIN   Temp_OtherCategory AS o on o.CustID = cate.CustID
    INNER JOIN  CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = o.CategoryID 
	WHERE		cc.ParentID = 1 AND cate.CategoryID = 2;
    
    /*UPDATE CUST INFO*/
    UPDATE 	Temp_NewClassification AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
	/****************************************************END DATA**********************************************************/
    
    /****************************************************START CATEGORY***************************************************/
    /*UPDATE CATEGORY*/
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN   Temp_NewClassification AS temp on temp.CustID = cate.CustID AND temp.SportGroupID = cate.SportGroupID
    INNER JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID AND ex.SportGroupID = temp.SportGroupID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = temp.CategoryID 
    SET   cate.CTSCustID = temp.CTSCustID
        , cate.SubscriberID  = temp.SubscriberID
        , cate.CategoryID = (CASE WHEN (ex.CategoryID NOT IN (6, 7, 10) AND temp.CategoryID IN (6, 7)) THEN 10 -- Update category to Smart Punter, High Risk Punter
                                  ELSE temp.CategoryID
                             END)
        , cate.LastModifiedDate = temp.LastModifiedDate 
        , cate.LastModifiedBy = lv_CreatedBy
        , cate.LastScannedDate = GREATEST(DATE(temp.LastModifiedDate), cate.LastScannedDate)
    WHERE cc.ParentID = 1;
    
    UPDATE Temp_NewClassification AS temp 
    INNER JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID AND ex.SportGroupID = temp.SportGroupID
    SET temp.ActionType = 1;
    
    /*INSERT NEW CATEGORY*/
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification
     (CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	 SELECT   temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, temp.SportGroupID
            , (CASE WHEN (ex.CategoryID = 2 AND temp.CategoryID IN (6, 7)) THEN 10 -- New Member to Smart Punter, High Risk Punter
					ELSE temp.CategoryID 
              END)
			, temp.LastModifiedDate
			, lv_CreatedBy
			, temp.LastModifiedDate
			, lv_CreatedBy
            , DATE(temp.LastModifiedDate)
	 FROM 	Temp_NewClassification 		AS temp
     LEFT JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
     INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = temp.CategoryID 
     WHERE cc.ParentID = 1 AND ( (ex.CategoryID = 2 AND temp.CategoryID != 2) OR ex.SportGroupID IS NULL);  -- temp.ActionType = 0
    
    /*INSERT LOG*/
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate,LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType,  IsAuto, InsertDate)
    SELECT 	  temp.CustID
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
	INNER JOIN Temp_NewClassification AS temp on temp.CustID = pro.CustID AND temp.SportGroupID = pro.SportGroupID
	INNER JOIN   Temp_ExistedClassification AS ex on ex.CustID = temp.CustID AND ex.SportGroupID = temp.SportGroupID
	INNER JOIN   CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = temp.CategoryID 
	WHERE cc.ParentID = 1 AND ex.CategoryID = 10 AND temp.CategoryID IN (6, 7) AND pro.SportGroupID < 200;
       
    /*INSERT NEW PROBATION LIST*/
	INSERT  INTO CTS_DataCenter.ProbationAccountMonitor
    (CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime)
	SELECT    temp.CustID
			, temp.CTSCustID
            , temp.SportGroupID
			, temp.CategoryID
			, CASE WHEN temp.TurnoverRM = 0 THEN 0
                   ELSE (temp.WinlossRM/temp.TurnoverRM) * 100
			  END AS FirstMargin
			, DATE(temp.LastModifiedDate)
			, lv_CreatedBy
			, temp.LastModifiedDate
	 FROM 	Temp_NewClassification 		AS temp
     LEFT JOIN   Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
	 WHERE   temp.ActionType = 0 
				AND (	(ex.CategoryID = 2 AND temp.CategoryID IN (6, 7, 10)) 
						OR (ex.SportGroupID IS NULL AND temp.CategoryID = 10)	); -- New Member & New Category
                
    INSERT  INTO CTS_DataCenter.ProbationAccountMonitor
    (CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime) 
	SELECT    temp.CustID
			, temp.CTSCustID
            , temp.SportGroupID
			, temp.CategoryID
			, CASE WHEN temp.TurnoverRM = 0 THEN 0
                   ELSE (temp.WinlossRM / temp.TurnoverRM) * 100
			  END AS FirstMargin
			, DATE(temp.LastModifiedDate)
			, lv_CreatedBy
			, temp.LastModifiedDate
	 FROM 	Temp_NewClassification 		AS temp
     LEFT JOIN   Temp_ExistedClassification AS ex on ex.CustID = temp.CustID AND ex.SportGroupID = temp.SportGroupID
	 WHERE  temp.ActionType = 1 
				AND (  (ex.CategoryID IN (6, 7) AND temp.CategoryID = 10)
						OR (ex.CategoryID IN (6, 7, 10) AND temp.CategoryID IN (6, 7, 10)) );  -- Old Category
	/***************************************************END PROBATION*************************************************/
     
    SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
    DROP TEMPORARY TABLE IF EXISTS Temp_OtherCategory;        
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    

END$$

DELIMITER ;