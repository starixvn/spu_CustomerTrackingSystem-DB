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
				- 20200901@Lex.Khuat [Redmine ID: #137550]: Created 
				- 20200908@Irena.Vo [Redmine ID: #141020]: Enhance Exclude VVIP Customers, Pin category 
		Param's Explanation (filtered by):
			call CTS_DataCenter.CTS_DC_InsertMainCustomerClassification('[
				{"CustId": 1, "CategoryId": 201, "CreatedTime": "2020-09-13 00:01:00", "TurnoverRM": 100, "WinlossRM": 2056354, "BetCount": 500, "ActiveDays": 8},
				{"CustId": 2, "CategoryId": 202, "CreatedTime": "2020-09-13 00:01:01", "TurnoverRM": 200, "WinlossRM": 10, "BetCount": 10, "ActiveDays": 12}]');
	*/ 

    DECLARE lv_CreatedBy			INT	 DEFAULT 10278938;		# Default user for auto main categories creator 'starixIT'
    
    #============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;
    #============================================
    
	CREATE TEMPORARY TABLE Temp_NewClassification
    (	  CustID			BIGINT UNSIGNED
		, SportGroupID		SMALLINT UNSIGNED
        , CategoryID		SMALLINT UNSIGNED
		, LastModifiedDate	DATETIME
        , CTSCustID			BIGINT UNSIGNED DEFAULT 0
        , SubscriberID		INT DEFAULT 0
        , ActionType		INT DEFAULT 2 		#(0: INSERT), (1: UPDATE), (2: IGNORE)
		, TurnoverRM		DECIMAL(20, 4)
		, WinlossRM			DECIMAL(20, 4)
		, BetCount			BIGINT
		, ActiveDays		INT
        , PRIMARY KEY	PK_Temp_NewClassification_CustID(CustID)
        , INDEX 		IX_Temp_NewClassification_ActionType(ActionType)
    );  
    
    #========= GET LIST OF MAIN CATEGORIES FROM PARAMS =========
    INSERT INTO Temp_NewClassification(CustID, SportGroupID, CategoryID, LastModifiedDate, TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT 		temp.CustID
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
			, CategoryID		SMALLINT UNSIGNED	PATH "$.CategoryId"
			, LastModifiedDate	DATETIME			PATH "$.CreatedTime"
            , TurnoverRM		DECIMAL(20, 4)		PATH "$.TurnoverRM"
            , WinlossRM			DECIMAL(20, 4)		PATH "$.WinlossRM"
            , BetCount			BIGINT				PATH "$.BetCount"
            , ActiveDays		INT					PATH "$.ActiveDays"		
		 )) AS temp;
	
    #========= FILL CUSTOMER INFORMATION (MEMBER ONLY) =========
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
    SET SQL_SAFE_UPDATES = 0;
    
    -- Ignore VVIP, Pin Category before
    DELETE temp
    FROM Temp_NewClassification AS temp
		 INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sc on sc.CustID = temp.CustID
	WHERE sc.CreatedFromFunction IN (11, 21);

    -- Remove invalid category
    DELETE temp
    FROM Temp_NewClassification AS temp
    WHERE temp.CategoryID = 0;

    -- Update info ctscustid , subscriberid
    UPDATE 		Temp_NewClassification AS temp
    INNER JOIN	CTS_DataCenter.CTSCustomer AS cust
					ON temp.CustID = cust.CustID AND cust.RoleID = 1
	SET			temp.ActionType = 0
				, temp.CTSCustID = cust.CTSCustID
				, temp.SubscriberID = cust.SubscriberID;
                
	#========= SET UPDATE/INSERT/IGNORE MARK TO CUSTOMER CLASSIFICATION LIST IN TEMP TABLE =========
    UPDATE Temp_NewClassification AS temp,
    LATERAL (
		SELECT DISTINCT	cate.CustID
						, CASE WHEN cc.ParentID = 50 THEN 2	# Ignore all abnormal customers
								WHEN cc.ParentID = 200 THEN 1	# If already exists, change action type from insert to update
								ELSE 0
							END AS ActionType
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc
			ON cate.CategoryID = cc.CategoryID
		WHERE cate.CustID = temp.CustID
			AND cc.ParentID in (50, 200)
            AND cate.SportGroupID in (0, 200)
	) AS pa
    SET temp.ActionType = pa.ActionType
    WHERE temp.ActionType = 0;
    
    #========= UPDATE EXISTING CUSTOMER CATEGORY LIST IN PHYSIC TABLE =========
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
    INNER JOIN CTS_DataCenter.CustomerCategory AS cc
			ON cate.CategoryID = cc.CategoryID
            AND cc.ParentID in (50, 200)
    INNER JOIN Temp_NewClassification AS temp
		ON 	temp.CustID = cate.CustID
        AND temp.SportGroupID = cate.SportGroupID
 	SET	cate.CategoryID = temp.CategoryID
		, cate.Remark = NULL
        , cate.LastModifiedDate = temp.LastModifiedDate 
        , cate.LastModifiedBy = lv_CreatedBy
        , cate.LastScannedDate = DATE(temp.LastModifiedDate)
	WHERE temp.ActionType = 1;
    
    #========= INSERT NEW CUSTOMER CATEGORY LIST TO PHYSIC TABLE =========
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification
    (CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT	temp.CustID
			, temp.CTSCustID
			, temp.SubscriberID
			, temp.CategoryID
			, temp.SportGroupID
			, temp.LastModifiedDate
			, lv_CreatedBy
			, temp.LastModifiedDate
			, lv_CreatedBy
            , DATE(temp.LastModifiedDate)
	FROM 	Temp_NewClassification AS temp
	WHERE 	temp.ActionType = 0;
    
    #========= RETURN LIST OF CUSTOMER CATEGORIES TO UPDATE ON MAINDB =========
    SELECT	CustID, CategoryID
    FROM Temp_NewClassification
    WHERE ActionType IN (0, 1);
    
    #========= INSERT LOG =========
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate)
    SELECT 	temp.CustID
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
	FROM 	Temp_NewClassification AS temp
    WHERE	temp.ActionType IN (0, 1);   
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$

DELIMITER ;