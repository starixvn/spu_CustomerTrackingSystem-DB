/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_SyncToCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_SyncToCategory`(
		IN ip_CustEvidences JSON
    ,	IN ip_IsRescan BIT    
        
    ,	OUT op_ErrorMessage VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
    /*
		Created:	20201112@Irena.Vo
		Task:		Sync Evidence to Category
		DB:			CTS_DataCenter
		Original:
		Revisions:
           - 20201112@Irena.Vo: Created [RedmineID: #141563]
           - 20201126@Irena.Vo: Enhance logic remove Evidence to category [RedmineID: #141563]
           - 20201127@Irena.Vo: Enhance logic update LastModifiedDate for category [RedmineID: #141563]
           - 20201201@Irena.Vo: Enhance logic Remove old category [RedmineID: #141563]
           - 20201203@Irena.Vo: Enhance logic Category is NULL [RedmineID: #141563]
	       - 20210115@Irena.Vo: Insert History Log. [RedmineID: #145951]
		   - 20210119@Aries.Nguyen: Write main error log - rescan [RedmineID: #149026]
           - 20210510@Casey.Huynh: Exclude Customer of Odds Feed Sites [Redmine ID: 154694]
           - 20210512@Casey.Huynh: Exclude Customer of Internal Account [Redmine ID: 154844]
           - 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [Redmine ID: 152965]
		   - 20210622@Aries.Nguyen: Update coding convention and inprove locking [Redmine ID: #157203]
           - 20211009@Irena.Vo: Additional compare CategoryGroup for remove evidence [Redmine ID: #161232]
		   - 20210922@Long.Luu: Split Classification History & Log  [Redmine ID: #161890]
		   - 20211026@Aries.Nguyen: Archive inactive association [Redmine ID: #163087]
            
		Param's Explanation (filtered by):
		Exmaple:
			- CALL CTS_DataCenter.CTS_DC_CustEvidence_SyncToCategory('[{"CustId":43600693, "CTSCustId": 221882500, "SubscriberId": 130, "EvidenceId": 41, "ActionType": 0}]',0,@op_ErrorMessage);
	*/   
	DECLARE	CONST_GROUP_PA 						INT DEFAULT 0;
	DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
    
    DECLARE CONST_ACTIONTYPE_INSERT 			INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 			INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 			INT DEFAULT 2;
    DECLARE CONST_ACTIONTYPE_IGNOREPIN 			INT DEFAULT 4; 
    
    DECLARE CONST_SOURCETYPE_ADDEVIDENCE 		INT DEFAULT 7;
    DECLARE CONST_SOURCETYPE_REMOVEEVIDENCE 	INT DEFAULT 9;  
    DECLARE CONST_SOURCETYPE_RESCANBYEVIDENCE 	INT DEFAULT 16;
	
    /* Only use for IsRescan = 1 */
    DECLARE CONST_SOURCETYPE_REMOVENAPPA 		INT DEFAULT 8;
    DECLARE CONST_SOURCETYPE_REMOVEVVIP 		INT DEFAULT 14;
    DECLARE CONST_SOURCETYPE_REMOVESPECIALCC 	INT DEFAULT 12;
    DECLARE CONST_SOURCETYPE_EXCLUDEASSWITHPA	INT DEFAULT 20;
    DECLARE CONST_SOURCETYPE_INCLUDEASSWITHPA	INT DEFAULT 21;
	
    DECLARE	lv_CurrentDateTime	DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_CreatedBy		BIGINT DEFAULT  10278938;
    DECLARE	lv_IsSyncEvi2Cate	VARCHAR(1) DEFAULT '';
    
	DROP TEMPORARY TABLE IF EXISTS Temp_PinnedCustomers;    
	CREATE TEMPORARY TABLE Temp_PinnedCustomers(	  
			CTSCustID				BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomersTargetCC;    
	CREATE TEMPORARY TABLE Temp_CustomersTargetCC(	  
			CustID				BIGINT UNSIGNED 
        , 	CategoryID		    SMALLINT 
        ,	TargetCC			SMALLINT
        , 	PRIMARY KEY     	PK_Temp_CustomersTargetCC_CustID_CategoryID(CustID,CategoryID)  
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidences;    
	CREATE TEMPORARY TABLE Temp_CustomerEvidences(	  
			CTSCustID			BIGINT UNSIGNED
		,	CustID              BIGINT UNSIGNED
        ,   SubscriberID        INT 
		,   EvidenceID          SMALLINT 
		, 	CategoryID		    SMALLINT 
        ,	CategoryGroup     	SMALLINT     
        ,	TargetCC			SMALLINT
        ,	SourceTypeID		SMALLINT
		, 	ActionType		    SMALLINT DEFAULT 0 /* 0: Insert, 1: Update, 2: Remove, 4: Ignore PIN */
        ,	IsExistedEvi		BIT DEFAULT 0 /* 1: Not existed Evi Cate => No action remove PA */
        ,	IsLastDataChanged	BIT DEFAULT 0
        ,	LastSourceTypeID	INT
        ,	IsDataChanged		BIT DEFAULT 1 /*0: No change category => No Action*/
        , 	PRIMARY KEY     	PK_Temp_CustomerEvidences_CustID_EvidenceID(CustID,EvidenceID)      
     );
     
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification(	  
			CustID				BIGINT UNSIGNED 
        , 	CategoryID	        SMALLINT UNSIGNED
        ,	CategoryGroup     	SMALLINT UNSIGNED  
        ,	RowOrder			SMALLINT
        , 	PRIMARY KEY 		PK_Temp_ExistedClassification_CustID_CategoryID(CustID, CategoryID)   
     );

	DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence;    
	CREATE TEMPORARY TABLE Temp_CustEvidence(	  
			CTSCustID		BIGINT UNSIGNED 
		,	CategoryID		INT
		, 	PRIMARY KEY		PK_Temp_CustEvidence(CTSCustID,CategoryID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LastHistory;    
	CREATE TEMPORARY TABLE Temp_LastHistory(	  
			CustID			BIGINT UNSIGNED 
		,	HistoryID		BIGINT
		, 	PRIMARY KEY		PK_Temp_LastHistory(HistoryID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustHistory;    
	CREATE TEMPORARY TABLE Temp_CustHistory(	  
			CustID			BIGINT UNSIGNED 
		,	SourceTypeID	INT
        ,	IsDataChanged	BIT
		, 	PRIMARY KEY		PK_Temp_LastHistory(CustID)
    );
    
    /* START */
	/* 1: PARSE RAW DATA */
    INSERT IGNORE INTO Temp_CustomerEvidences(CTSCustID, CustID, SubscriberID, EvidenceID, CategoryID, ActionType)
    SELECT 		temp.CTSCustID
			, 	temp.CustID
			, 	temp.SubscriberID
			, 	temp.EvidenceID
			, 	ec.CategoryID
			, 	temp.ActionType
	FROM JSON_TABLE(ip_CustEvidences,
		"$[*]" COLUMNS(
				CTSCustID			BIGINT UNSIGNED		PATH "$.CTSCustId"
            , 	CustID 				BIGINT UNSIGNED		PATH "$.CustId"
			, 	SubscriberID		INT					PATH "$.SubscriberId"
            , 	EvidenceID 			SMALLINT UNSIGNED	PATH "$.EvidenceId"
            , 	ActionType			SMALLINT UNSIGNED	PATH "$.ActionType"
		 )
	) AS temp
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS ec on ec.EvidenceID = temp.EvidenceID;
        
    /* 2: EXCLUDE CUSTOMER */      
    CALL CTS_DC_ExcludeCustByCondition('Temp_CustomerEvidences');
    
    /* 3: SYNC EVIDENCE TO CATEGORY	*/
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
	IF (lv_IsSyncEvi2Cate = '1') THEN
		/*	4: IGNORE PIN CATEGORY	*/
		INSERT IGNORE INTO Temp_PinnedCustomers(CTSCustID)
		SELECT temp.CTSCustID
		FROM Temp_CustomerEvidences AS temp
			INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin ON temp.CTSCustID = pin.CTSCustID;

        UPDATE Temp_CustomerEvidences AS temp
			INNER JOIN Temp_PinnedCustomers AS pin ON temp.CTSCustID = pin.CTSCustID
        SET temp.ActionType = CONST_ACTIONTYPE_IGNOREPIN;
        
        /*	5: REMOVE GENERAL CATEGORY BEFORE	*/
		DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_NORMAL
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_REMOVE);
        
        /*	6: REMOVE PROBATION LIST BEFORE	*/
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro 
			INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = pro.CustID
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_REMOVE);
        
        /* 7: UPDATE CATEGORY GROUP ID INFO */
		UPDATE 	Temp_CustomerEvidences AS temp 
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = temp.CategoryID
		SET	temp.CategoryGroup = cc.CategoryGroup
        WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_REMOVE);
		
		/*	8: GET EXISTED CATEGORY */
		INSERT IGNORE INTO Temp_ExistedClassification (CustID, CategoryGroup, CategoryID, RowOrder)
		SELECT 	cate.CustID
			, 	cc.CategoryGroup
			, 	cate.CategoryID  
			, 	ROW_NUMBER() OVER (PARTITION BY cate.CustID, cc.CategoryGroup
								   ORDER BY (CASE WHEN cate.CategoryID BETWEEN 72 AND 150 THEN 1 /* From Evd will lastest records */
												  ELSE 0
											 END) ) AS RowOrder
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PA
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_REMOVE);
       
		UPDATE Temp_CustomerEvidences AS temp 
			INNER JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryID = temp.CategoryID
		SET	temp.ActionType = CONST_ACTIONTYPE_UPDATE
        WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
        
		/*	9: UPDATE TARGET CC */
		INSERT IGNORE INTO Temp_CustomersTargetCC(CustID, CategoryID, TargetCC)
		SELECT	temp.CustID 
			,	temp.CategoryID
			,	(CASE WHEN temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) THEN IFNULL(IFNULL(sp.CustomerClass, map.CustomerClass), -99)
				  WHEN temp.ActionType = CONST_ACTIONTYPE_REMOVE THEN -1  /* Remove PA */
				END) AS TargetCC
		FROM Temp_CustomerEvidences AS temp 
			LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID 
			LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.CategoryID
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE);
		
		UPDATE Temp_CustomerEvidences AS temp 
			INNER JOIN Temp_CustomersTargetCC AS cc ON cc.CustID = temp.CustID AND cc.CategoryID = temp.CategoryID
		SET temp.TargetCC = cc.TargetCC;

		/*	10: UPDATE SOURCE TYPE ID */
		UPDATE Temp_CustomerEvidences AS temp 
		SET	temp.SourceTypeID = (CASE WHEN temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) THEN CONST_SOURCETYPE_ADDEVIDENCE
									  WHEN temp.ActionType = CONST_ACTIONTYPE_REMOVE THEN CONST_SOURCETYPE_REMOVEEVIDENCE
								  END)
		WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE);
    
		/*	11: REMOVE PA FROM EVIDENCE */
		INSERT IGNORE INTO Temp_CustEvidence(CTSCustID, CategoryID)
		SELECT  temp.CTSCustID
			,	temp.CategoryID
		FROM Temp_CustomerEvidences AS temp
			INNER JOIN CTS_DataCenter.CustEvidence AS ce ON ce.CTSCustID = temp.CTSCustID
			INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID AND ce.Level = 0 AND e.CategoryID = temp.CategoryID;

		UPDATE Temp_CustomerEvidences AS temp
			INNER JOIN Temp_CustEvidence AS ce ON ce.CTSCustID = temp.CTSCustID AND ce.CategoryID = temp.CategoryID
	    SET temp.IsExistedEvi = 1;
        
		DELETE cate
		FROM CTS_DataCenter.CTSCustomerClassification cate
		INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PA AND temp.CategoryID = cate.CategoryID 
		WHERE	temp.ActionType = CONST_ACTIONTYPE_REMOVE AND temp.IsExistedEvi = 0 AND (cate.CategoryID BETWEEN 72 AND 150); 
        
        /*	12: UPDATE PA FROM EVIDENCE */
		UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_CustomerEvidences AS temp on temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PA AND temp.CategoryID = cate.CategoryID 
		SET   	cate.CTSCustID = temp.CTSCustID
			, 	cate.SubscriberID  = temp.SubscriberID
			, 	cate.LastModifiedBy = lv_CreatedBy
			,   cate.LastModifiedDate = lv_CurrentDateTime
			, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
		 WHERE temp.ActionType = 1; 
          
        /*	13: INSERT NEW PA FROM EVIDENCE */
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT	DISTINCT 
				temp.CustID
			, 	temp.CTSCustID
			, 	temp.SubscriberID
			, 	temp.CategoryID
			,   CONST_GROUP_PA
			, 	'Synced by Evidence'
			, 	lv_CurrentDateTime
			,   lv_CreatedBy
			, 	lv_CurrentDateTime
			,   lv_CreatedBy
			, 	DATE(lv_CurrentDateTime)
		FROM Temp_CustomerEvidences AS temp
		WHERE temp.ActionType = 0;
   
		/* 14: WRITE HISTORY LOG (VIEW ON WEB) */
		/* 14.1: Rescan data */    
		IF (ip_IsRescan = 1) THEN
			 /* 14.1.1: Insert Last History */    
			INSERT INTO Temp_LastHistory (CustID, HistoryID)
			SELECT  his.CustID,	MAX(his.ID)
			FROM CTS_DataCenter.CTSCustomerClassification_History AS his
				INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = his.CustID
			GROUP BY his.CustID;

			INSERT INTO Temp_CustHistory (CustID, SourceTypeID, IsDataChanged)
			SELECT l.CustID, his.SourceTypeID, his.IsDataChanged
			FROM Temp_LastHistory AS l
				INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS his ON his.ID = l.HistoryID;
			
			UPDATE Temp_CustomerEvidences AS temp
				INNER JOIN Temp_CustHistory AS h ON temp.CustID = h.CustID
			SET 	temp.LastSourceTypeID = h.SourceTypeID
				, 	temp.IsLastDataChanged = h.IsDataChanged;
         
			/* 14.1.2: Update IsDataChanged */
            UPDATE Temp_CustomerEvidences AS temp
            SET temp.IsDataChanged = 0
            WHERE temp.LastSourceTypeID NOT IN (CONST_SOURCETYPE_REMOVEEVIDENCE,CONST_SOURCETYPE_REMOVENAPPA,CONST_SOURCETYPE_REMOVEVVIP,CONST_SOURCETYPE_REMOVESPECIALCC,CONST_SOURCETYPE_EXCLUDEASSWITHPA,CONST_SOURCETYPE_INCLUDEASSWITHPA)
					OR (temp.LastSourceTypeID IN (CONST_SOURCETYPE_REMOVEEVIDENCE,CONST_SOURCETYPE_REMOVENAPPA) AND temp.IsLastDataChanged = 0);
			
            /* 14.1.3: Update SourceTypeID */
            UPDATE Temp_CustomerEvidences AS temp
            SET temp.SourceTypeID = CONST_SOURCETYPE_RESCANBYEVIDENCE;
            
			/* 14.1.4: Insert log from Insert/Update Evidence */    
			INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
			SELECT	DISTINCT 
					temp.CustID
				, 	temp.CTSCustID
				, 	temp.CategoryID
				,   CONST_GROUP_PA
				,   lv_CurrentDateTime
				,   lv_CreatedBy
				,   temp.ActionType
				,   1
				,   DATE(lv_CurrentDateTime)
				, 	temp.TargetCC
				, 	temp.SourceTypeID
				,   temp.IsDataChanged
			FROM Temp_CustomerEvidences AS temp
            WHERE temp.IsDataChanged = 1;
        
        /* 14.2: Normal data */    
		ELSE          
			/* 14.2.1: Update IsDataChanged */
			UPDATE Temp_CustomerEvidences AS temp
				INNER JOIN Temp_PinnedCustomers AS pin ON pin.CTSCustID = temp.CTSCustID
			SET temp.IsDataChanged = 0;
            
            UPDATE Temp_CustomerEvidences AS temp
				INNER JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryGroup = temp.CategoryGroup /* Not existed NAP CM Cate. */
			SET temp.IsDataChanged = 0
			WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
			
			UPDATE Temp_CustomerEvidences AS temp
				LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryGroup = temp.CategoryGroup AND ex.CategoryID BETWEEN 72 AND 150 AND ex.RowOrder = 1 /* Only existed Evd Cate. */
			SET temp.IsDataChanged = 0
			WHERE temp.ActionType = CONST_ACTIONTYPE_REMOVE AND ex.CategoryGroup IS NULL;
        
			/* 14.2.2: Insert log from Insert/Update Evidence */    
			INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
			SELECT	DISTINCT 
					temp.CustID
				, 	temp.CTSCustID
				, 	temp.CategoryID
				, 	CONST_GROUP_PA
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.ActionType
				, 	1
				, 	DATE(lv_CurrentDateTime)
				, 	temp.TargetCC
				, 	temp.SourceTypeID
				,   temp.IsDataChanged
			FROM Temp_CustomerEvidences AS temp
			WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) AND temp.IsDataChanged = 1;
        
			/* 14.2.3: Insert log from Remove Evidence */    
			INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
			SELECT	DISTINCT 
					temp.CustID
				, 	temp.CTSCustID
				, 	temp.CategoryID
				, 	CONST_GROUP_PA
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.ActionType
				, 	1
				, 	DATE(lv_CurrentDateTime)
				, 	temp.TargetCC
				, 	temp.SourceTypeID
				,   temp.IsDataChanged
			FROM Temp_CustomerEvidences AS temp
			WHERE temp.ActionType = CONST_ACTIONTYPE_REMOVE AND temp.IsExistedEvi = 0 AND temp.IsDataChanged = 1;
		END IF;
	END IF;
    
    /* 15: WRITE HISTORY LOG (TRACE DATA) */
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	temp.CategoryID
		, 	CONST_GROUP_PA
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	temp.ActionType
		, 	1
		, 	DATE(lv_CurrentDateTime)
		, 	temp.TargetCC
		, 	temp.SourceTypeID
		,   temp.IsDataChanged
	FROM Temp_CustomerEvidences AS temp
    WHERE temp.ActionType <> CONST_ACTIONTYPE_REMOVE OR (temp.ActionType = CONST_ACTIONTYPE_REMOVE AND temp.IsExistedEvi = 0);
    
    /* 16: RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS */
	SELECT	DISTINCT 
			temp.CustId 
		,	temp.CTSCustID
	FROM Temp_CustomerEvidences AS temp
	WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE); 
END$$
DELIMITER ;