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
				- 20200901@Lex.Khuat: Created [Redmine ID: #137550]
        
		Param's Explanation (filtered by):
			call CTS_DataCenter.CTS_DC_InsertMainCustomerClassification('[
				{"CustId": 1, "CategoryId": 201, "CreatedTime": "2020-09-13 00:01:00", "TurnoverRM": 100, "WinlossRM": 2056354, "BetCount": 500, "ActiveDays": 8},
				{"CustId": 2, "CategoryId": 202, "CreatedTime": "2020-09-13 00:01:01", "TurnoverRM": 200, "WinlossRM": 10, "BetCount": 10, "ActiveDays": 12}]');
	*/ 

    DECLARE vrCreatedBy			INT			DEFAULT 10278938;		# Default user for auto main categories creator 'starixIT'
    DECLARE vrLastScannedDate	DATETIME	DEFAULT CURRENT_TIMESTAMP(4);	# Get current time to update last scanned date
    
    #============================================
    DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;
    #============================================
    
	CREATE TEMPORARY TABLE Temp_NewClassification
    (	  
		  CustID			BIGINT UNSIGNED
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
	SELECT 		tmpTable.CustID
				, 0
				, tmpTable.CategoryID
				, tmpTable.LastModifiedDate
                , tmpTable.TurnoverRM
                , tmpTable.WinlossRM
                , tmpTable.BetCount
                , tmpTable.ActiveDays
	FROM JSON_TABLE(ip_NewClassification,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, CategoryID		SMALLINT UNSIGNED	PATH "$.CategoryId"
			, LastModifiedDate	DATETIME			PATH "$.CreatedTime"
            , TurnoverRM		DECIMAL(20, 4)		PATH "$.TurnoverRM"
            , WinlossRM			DECIMAL(20, 4)		PATH "$.WinlossRM"
            , BetCount			BIGINT				PATH "$.BetCount"
            , ActiveDays		INT					PATH "$.ActiveDays"		
		 )) as tmpTable;
	
    #========= FILL CUSTOMER INFORMATION (MEMBER ONLY) =========
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  

    UPDATE 		Temp_NewClassification AS ct
    INNER JOIN	CTS_DataCenter.CTSCustomer AS c
					ON ct.CustID = c.CustID AND c.CustSubID = 0
	SET			ct.ActionType = 0
				, ct.CTSCustID = c.CTSCustID
				, ct.SubscriberID = c.SubscriberID;
                
	#========= SET UPDATE/INSERT/IGNORE MARK TO CUSTOMER CLASSIFICATION LIST IN TEMP TABLE =========   
    UPDATE Temp_NewClassification AS ct,
    LATERAL (
		SELECT DISTINCT	cc.CustID
						, CASE WHEN c.ParentID = 50 THEN 0	# Ignore all abnormal customers
								WHEN c.ParentID = 200 THEN 1	# If already exists, change action type from insert to update
								ELSE 2
							END AS ActionType
        FROM CTS_DataCenter.CTSCustomerClassification AS cc
        INNER JOIN CTS_DataCenter.CustomerCategory AS c
			ON cc.CategoryID = c.CategoryID
            AND c.ParentID in (50, 200)
		WHERE cc.CustID = ct.CustID
			AND cc.SportGroupID = 0
	) AS pa
    SET ct.ActionType = pa.ActionType
    WHERE ct.ActionType = 0;
    
    #========= UPDATE EXISTING CUSTOMER CATEGORY LIST IN PHYSIC TABLE =========
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cc
    INNER JOIN CTS_DataCenter.CustomerCategory AS c
			ON cc.CategoryID = c.CategoryID
            AND c.ParentID in (50, 200)
    INNER JOIN Temp_NewClassification AS tmp
		ON 	tmp.CustID = cc.CustID
        AND tmp.SportGroupID = cc.SportGroupID
 	SET	cc.CategoryID = tmp.CategoryID
		, cc.Remark = null
        , cc.LastModifiedDate = tmp.LastModifiedDate 
        , cc.LastModifiedBy = vrCreatedBy
        , cc.LastScannedDate = DATE(tmp.LastModifiedDate)
	WHERE tmp.ActionType = 1;
    
    #========= INSERT NEW CUSTOMER CATEGORY LIST TO PHYSIC TABLE =========
    INSERT  INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark
				 , CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT	tmp.CustID
			, tmp.CTSCustID
			, tmp.SubscriberID
			, tmp.CategoryID
			, tmp.SportGroupID
            , null
			, tmp.LastModifiedDate
			, vrCreatedBy
			, tmp.LastModifiedDate
			, vrCreatedBy
            , DATE(tmp.LastModifiedDate) AS LastScannedDate
	FROM 	Temp_NewClassification AS tmp
	WHERE 	tmp.ActionType = 0;
    
    #========= INSERT LOG =========
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID
					, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate)
    SELECT 	tmp.CustID
			, tmp.CTSCustID
			, tmp.CategoryID
            , tmp.SportGroupID
            , tmp.LastModifiedDate
            , vrCreatedBy
            , tmp.TurnoverRM
            , tmp.WinlossRM
            , tmp.BetCount
            , tmp.ActiveDays
			, tmp.ActionType
            , 1
            , CURRENT_DATE() AS InsertDate
	FROM 	Temp_NewClassification AS tmp
    WHERE	tmp.ActionType IN (0, 1);   
    
    #================================================================================================================
	SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
END$$

DELIMITER ;

