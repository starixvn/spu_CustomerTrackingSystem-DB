USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_InsertMainCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertMainCustomerClassification`(IN ip_NewClassification JSON)
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
                [20201003-20201008@Irena.Vo][142546]: Enhance SP & correct logic. 
                
		Param's Explanation (filtered by):
			call CTS_DataCenter.CTS_DC_InsertMainCustomerClassification
            ('[{"CustId": 1, "CategoryId": 202, "CreatedTime": "2020-09-13 00:01:00", "TurnoverRM": 100, "WinlossRM": 2056354, "BetCount": 500, "ActiveDays": 8}]');
	*/ 
     DECLARE  lv_CreatedBy			INT	DEFAULT 10278938;

     DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;
	 CREATE TEMPORARY TABLE Temp_NewClassification 
     (	  CustID			BIGINT UNSIGNED        
        , SportGroupID		SMALLINT UNSIGNED
		, CurrentCategoryID	SMALLINT UNSIGNED -- Category is existed in CTS
		, TargetCategoryID	SMALLINT UNSIGNED -- Category is returned from DW
        , NewCategoryID		SMALLINT UNSIGNED -- Category is inserted to CTS
		, LastModifiedDate	DATETIME
		, TurnoverRM		DECIMAL(20,4)
		, WinlossRM			DECIMAL(20,4)
		, BetCount			BIGINT
		, ActiveDays		INT	
		, CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , SubscriberID		INT DEFAULT 0    
		, ActionType		SMALLINT DEFAULT 0 -- Insert: 0; Update: 1
        , PRIMARY KEY		PK_Temp_NewClassification_CustID(CustID) 
        , INDEX     		IX_Temp_NewClassification_CustID_NewCategoryID(CustID, NewCategoryID) 
        , INDEX 			IX_Temp_NewClassification_ActionType(ActionType)        
     );   
     
	 DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	 CREATE TEMPORARY TABLE Temp_ExistedClassification 
     (	  CustID			BIGINT UNSIGNED        
        , CurrentCategoryID	SMALLINT UNSIGNED
        , INDEX 			IX_Temp_ExistedClassification_CustID_CurrentCategoryID(CustID, CurrentCategoryID)       
     );
    
    INSERT INTO Temp_NewClassification(CustID, SportGroupID, TargetCategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT 		temp.CustID
				, 200
				, temp.TargetCategoryID
				, temp.LastModifiedDate
                , temp.TurnoverRM
                , temp.WinlossRM
                , temp.BetCount
                , temp.ActiveDays
	FROM JSON_TABLE(ip_NewClassification,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, TargetCategoryID	SMALLINT UNSIGNED	PATH "$.CategoryId"
			, LastModifiedDate	DATETIME			PATH "$.CreatedTime"
            , TurnoverRM		DECIMAL(20, 4)		PATH "$.TurnoverRM"
            , WinlossRM			DECIMAL(20, 4)		PATH "$.WinlossRM"
            , BetCount			BIGINT				PATH "$.BetCount"
            , ActiveDays		INT					PATH "$.ActiveDays"		
		 )) AS temp
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = temp.TargetCategoryID 
	WHERE cc.ParentID = 200 AND temp.TargetCategoryID <> 0;
	
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    SET SQL_SAFE_UPDATES = 0;
    
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
    SELECT cate.CustID, cate.CategoryID
    FROM Temp_NewClassification AS temp
    INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc on cc.CategoryID = cate.CategoryID 
    WHERE cc.ParentID = 200; 
    
    /*IGNORE PROBATION TO VIP OR NORMAL*/ 
	DELETE temp
    FROM Temp_NewClassification AS temp 
    INNER JOIN Temp_ExistedClassification AS ex on ex.CustID = temp.CustID
	WHERE ex.CurrentCategoryID = 206 AND temp.TargetCategoryID IN (202, 205);
    
	/*UPDATE CURRENT & NEW CATEGORY*/ 
    UPDATE 		Temp_NewClassification AS temp 
    LEFT JOIN  	Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID
	SET			temp.CurrentCategoryID = (CASE  WHEN ex.CurrentCategoryID IS NULL THEN NULL -- New
												ELSE ex.CurrentCategoryID -- Old
											END)
				, temp.NewCategoryID =  (CASE  	WHEN ex.CurrentCategoryID IN (202, 205) AND temp.TargetCategoryID IN (203, 204) THEN 206 -- From Other Category to Smart or High Risk
												ELSE temp.TargetCategoryID
											END)
	WHERE temp.NewCategoryID IS NULL; -- Update Other Category or Insert Other Category
    
    /*UPDATE CUST INFO*/
    UPDATE 	Temp_NewClassification AS temp 
	INNER JOIN	CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
	SET		temp.CTSCustID = cust.CTSCustID, temp.SubscriberID = cust.SubscriberID;
    
    /****************************************************END DATA**********************************************************/
    
    /****************************************************START CATEGORY***************************************************/
    /*UPDATE CATEGORY*/
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN   Temp_NewClassification AS temp on temp.CustID = cate.CustID AND temp.SportGroupID = cate.SportGroupID
    SET   	temp.ActionType = 1
        ,   cate.CTSCustID = temp.CTSCustID
        , 	cate.SubscriberID  = temp.SubscriberID
        , 	cate.CategoryID = temp.NewCategoryID
        , 	cate.LastModifiedDate = temp.LastModifiedDate 
        , 	cate.LastModifiedBy = lv_CreatedBy
        , 	cate.LastScannedDate = GREATEST(DATE(temp.LastModifiedDate), cate.LastScannedDate)
     WHERE 	temp.CurrentCategoryID IS NOT NULL AND cate.SportGroupID = 200; -- sport group = 200
   
    /*INSERT NEW CATEGORY*/
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification
     (CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	 SELECT   temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, temp.SportGroupID
            , temp.NewCategoryID 
			, temp.LastModifiedDate
			, lv_CreatedBy
			, temp.LastModifiedDate
			, lv_CreatedBy
            , DATE (temp.LastModifiedDate)
	 FROM 	Temp_NewClassification 		AS temp
     WHERE  temp.ActionType = 0 AND temp.CurrentCategoryID IS NULL;
     
     /*INSERT LOG*/
    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate,LastModifiedBy,TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType,  IsAuto, InsertDate)
    SELECT 	  temp.CustID
			, temp.CTSCustID
			, temp.NewCategoryID
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
	INNER JOIN Temp_NewClassification AS temp on temp.CustID = pro.CustID
	WHERE temp.CurrentCategoryID = 206 AND temp.TargetCategoryID IN (203, 204) AND pro.SportGroupID = 200;
    
     /*INSERT NEW PROBATION LIST*/
    INSERT  INTO CTS_DataCenter.ProbationAccountMonitor
    (CustID, CTSCustID, SportGroupID, TargetCategoryID, FirstMargin, CreatedDate, CreatedBy, CreatedTime)
	SELECT    temp.CustID
			, temp.CTSCustID
            , temp.SportGroupID
			, temp.TargetCategoryID
			, CASE WHEN temp.TurnoverRM = 0 THEN 0
                   ELSE (temp.WinlossRM/temp.TurnoverRM) * 100
			  END AS FirstMargin
			, DATE (temp.LastModifiedDate) 
			, lv_CreatedBy
			, temp.LastModifiedDate
	 FROM 	Temp_NewClassification 		AS temp
	 WHERE  (temp.ActionType = 0 AND temp.NewCategoryID = 206)
         OR (temp.ActionType = 1 AND temp.NewCategoryID = 206 AND temp.CurrentCategoryID IN (202, 203, 204, 205)); 
    /***************************************************END PROBATION*************************************************/
    /*GET DISTINCT CUSTID*/
    SELECT DISTINCT temp.CustID as CustId, temp.NewCategoryID as CategoryId
    FROM Temp_NewClassification AS temp; -- Get lastest custid for mapping to CC in mainDB
    
	SET SQL_SAFE_UPDATES = 1;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
   
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;     
END$$

DELIMITER ;