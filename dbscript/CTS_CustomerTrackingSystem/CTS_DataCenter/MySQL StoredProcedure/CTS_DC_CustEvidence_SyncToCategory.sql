/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_SyncToCategory`;

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
	       - 20210111@Irena.Vo: Insert History Log. Insert Error Log & update logic SP. Return All List CustID. Update logic SP.  [RedmineID: #145951]
           
		Param's Explanation (filtered by):	
			CALL CTS_DataCenter.CTS_DC_CustEvidence_SyncToCategory('[{"CustId":43600693, "CTSCustId": 221882500, "SubscriberId": 130, "EvidenceId": 41, "ActionType": 0}]',0,@op_ErrorMessage);
	*/   
    DECLARE	lv_CurrentDateTime DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_CreatedBy BIGINT DEFAULT  10278938;
    DECLARE	lv_IsSyncEvi2Cate VARCHAR(1) DEFAULT '';  
    
    DECLARE	lv_No INT DEFAULT 1;

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No = NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
			op_ErrorMessage = MESSAGE_TEXT;	
	
		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_CustEvidence_SyncToCategory',op_ErrorMessage, JSON_OBJECT('parameter', ip_CustEvidences));
    
		SIGNAL SQLSTATE '99999' SET MESSAGE_TEXT = op_ErrorMessage;
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidences;    
	CREATE TEMPORARY TABLE Temp_CustomerEvidences(	  
			CTSCustID			BIGINT UNSIGNED
		,	CustID              BIGINT UNSIGNED
        ,   SubscriberID        INT 
		,   EvidenceID          SMALLINT 
		, 	CategoryID		    SMALLINT 
        ,	CategoryGroupID     SMALLINT     
        ,	TargetCC			SMALLINT
        ,	SourceTypeID		SMALLINT
		, 	ActionType		    SMALLINT DEFAULT 0 /* 0: Insert, 1: Update, 2: Remove, 4: Ignore PIN */
        ,	IsExistedEvi		BIT DEFAULT 0 /* 1: Not existed Evi Cate => No action remove PA */
        , 	PRIMARY KEY     	PK_Temp_CustomerEvidences_CustID_EvidenceID(CustID,EvidenceID) 
        , 	INDEX 				IX_Temp_CustomerEvidences_CustID(CustID) 
        , 	INDEX 				IX_Temp_CustomerEvidences_CustID_CategoryGroupID(CustID,CategoryGroupID)          
     );
     
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification(	  
			CustID				BIGINT UNSIGNED 
        , 	CategoryID	        SMALLINT UNSIGNED
        ,	CategoryGroupID     SMALLINT UNSIGNED  
        ,	RowOrder			SMALLINT
        , 	PRIMARY KEY 		PK_Temp_ExistedClassification_CustID_CategoryID(CustID, CategoryID)   
		, 	INDEX 				IX_Temp_ExistedClassification_CustID(CustID) 
        ,	INDEX				IX_Temp_ExistedClassification_CustID_CategoryGroupID(CustID,CategoryGroupID)
     );
    
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
		 )) AS temp
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS ec on ec.EvidenceID = temp.EvidenceID;
    
    /*	SYNC EVIDENCE TO CATEGORY	*/
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
	IF (lv_IsSyncEvi2Cate = '1') THEN
		#=========================================PREPARE DATA=========================================================
        /*	IGNORE PIN CATEGORY	*/
        UPDATE Temp_CustomerEvidences AS temp
			INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin ON temp.CustID = pin.CustID
        SET temp.ActionType = 4;
        
        /*	REMOVE GENERAL CATEGORY BEFORE	*/
		DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 200
		WHERE temp.ActionType IN (0, 2);
        
        /*	REMOVE PROBATION LIST BEFORE	*/
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro 
			INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = pro.CustID
		WHERE temp.ActionType IN (0, 2);
        
        /* UPDATE CATEGORY GROUP ID INFO */
		UPDATE 	Temp_CustomerEvidences AS temp 
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = temp.CategoryID
		SET	temp.CategoryGroupID = cc.CategoryGroup
        WHERE temp.ActionType IN (0, 2);
		
		/*	GET EXISTED CATEGORY */
		INSERT IGNORE INTO Temp_ExistedClassification (CustID, CategoryGroupID, CategoryID, RowOrder)
		SELECT 	cate.CustID
			, 	cc.CategoryGroup
			, 	cate.CategoryID  
			, 	ROW_NUMBER() OVER (PARTITION BY cate.CustID, cc.CategoryGroup
								   ORDER BY (CASE WHEN cate.CategoryID BETWEEN 72 AND 80 THEN 1 /* From Evd will lastest records */
												  ELSE 0
											 END) ) AS RowOrder
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 0
			INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
		WHERE temp.ActionType IN (0, 2);
       
		UPDATE Temp_CustomerEvidences AS temp 
			INNER JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryID = temp.CategoryID
		SET	temp.ActionType = 1
        WHERE temp.ActionType = 0;
        
		/*	UPDATE TARGET CC INFO */
		UPDATE Temp_CustomerEvidences AS temp 
			LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID 
			LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.CategoryID
		SET	temp.TargetCC = (CASE WHEN temp.ActionType IN (0, 1) AND sp.CustID IS NOT NULL THEN sp.CustomerClass /* Existed CC */
								  WHEN temp.ActionType IN (0, 1) AND map.CategoryID IS NOT NULL THEN map.CustomerClass  /* Mapping CC */
								  WHEN temp.ActionType IN (0, 1) AND sp.CustID IS NULL AND map.CategoryID IS NULL THEN -99 /* No mapping CC */
								  WHEN temp.ActionType = 2 THEN -1  /* Remove PA */
							 END)
		WHERE temp.ActionType IN (0, 1, 2);
    
		/*	UPDATE SOURCE TYPE ID INFO */
		UPDATE Temp_CustomerEvidences AS temp 
		SET	temp.SourceTypeID = (CASE WHEN temp.ActionType IN (0, 1) THEN 7 /* Insert & Update */
									  WHEN temp.ActionType = 2 THEN 9 /* Remove */
								  END)
		WHERE temp.ActionType IN (0, 1, 2);
    
		#===========================================CLASSIFY DATA==================================================================
		/*	REMOVE PA FROM EVIDENCE */
		UPDATE Temp_CustomerEvidences AS temp
			INNER JOIN CTS_DataCenter.CustEvidence AS ce ON ce.CTSCustID = temp.CTSCustID
			INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID AND ce.Level = 0 AND e.CategoryID = temp.CategoryID
	    SET temp.IsExistedEvi = 1;
        
		DELETE cate
		FROM CTS_DataCenter.CTSCustomerClassification cate
			INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 0 AND temp.CategoryID = cate.CategoryID 
		WHERE temp.ActionType = 2 AND temp.IsExistedEvi = 0 AND (cate.CategoryID BETWEEN 72 AND 80); 
        
        /*	UPDATE PA FROM EVIDENCE */
		UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_CustomerEvidences AS temp on temp.CustID = cate.CustID AND cate.SportGroupID = 0 AND temp.CategoryID = cate.CategoryID 
		SET   	cate.CTSCustID = temp.CTSCustID
			, 	cate.SubscriberID  = temp.SubscriberID
			, 	cate.LastModifiedBy = lv_CreatedBy
			,   cate.LastModifiedDate = lv_CurrentDateTime
			, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
		 WHERE temp.ActionType = 1; 
          
        /*	INSERT NEW PA FROM EVIDENCE */
		INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.SubscriberID
			, 	temp.CategoryID
			,   0
			, 	'Synced by Evidence'
			, 	lv_CurrentDateTime
			,   lv_CreatedBy
			, 	lv_CurrentDateTime
			,   lv_CreatedBy
			, 	DATE(lv_CurrentDateTime)
		FROM Temp_CustomerEvidences AS temp
		WHERE temp.ActionType = 0;
   
		#===========================================WRITE LOG==================================================================
		IF (ip_IsRescan = 1) THEN
			/* INSERT LOG RE-SCAN PA FROM EVIDENCE */    
			INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
			(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
			SELECT DISTINCT temp.CustID
				, 	temp.CTSCustID
				, 	temp.CategoryID
				,   0
				,   lv_CurrentDateTime
				,   lv_CreatedBy
				,   temp.ActionType
				,   1
				,   DATE(lv_CurrentDateTime)
				, 	temp.TargetCC
				, 	16 /* Rescan PA */
				,	1
			FROM Temp_CustomerEvidences AS temp;
		ELSE                         
			/*	INSERT LOG NEW & UPDATE PA FROM EVIDENCE */
			INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
			(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
			SELECT DISTINCT temp.CustID
				, 	temp.CTSCustID
				, 	temp.CategoryID
				, 	0
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.ActionType
				, 	1
				, 	DATE(lv_CurrentDateTime)
				, 	temp.TargetCC
				, 	temp.SourceTypeID
				,   CASE WHEN ex.CategoryGroupID IS NULL THEN 1
						 ELSE 0
					END
			FROM Temp_CustomerEvidences AS temp
				LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryGroupID = temp.CategoryGroupID  /* Not existed NAP CM Cate. */
			WHERE temp.ActionType IN (0, 1);
        
			/*	INSERT LOG REMOVE PA FROM EVIDENCE */
			INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
			(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
			SELECT DISTINCT temp.CustID
				, 	temp.CTSCustID
				, 	temp.CategoryID
				, 	0
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.ActionType
				, 	1
				, 	DATE(lv_CurrentDateTime)
				, 	temp.TargetCC
				, 	temp.SourceTypeID
				,   CASE WHEN ex.CategoryGroupID IS NOT NULL THEN 1
						 ELSE 0
					END
			FROM Temp_CustomerEvidences AS temp
				LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryID BETWEEN 72 AND 80 AND ex.RowOrder = 1 /* Only existed Evd Cate. */
			WHERE temp.ActionType = 2 AND temp.IsExistedEvi = 0;
	  
			/*	INSERT LOG IGNORE PIN */
			INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
			(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
			SELECT DISTINCT temp.CustID
				, 	temp.CTSCustID
				, 	temp.CategoryID
				, 	0 
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.ActionType
				, 	1
				, 	DATE(lv_CurrentDateTime)
			FROM Temp_CustomerEvidences AS temp
			WHERE temp.ActionType = 4;
		END IF;
	END IF;
    #=========================================GET LASTEST CUSTOMERS FOR CLASSICATION=========================================================
	SELECT DISTINCT temp.CustId FROM Temp_CustomerEvidences AS temp
	WHERE temp.ActionType IN (0, 1, 2); 
END$$
DELIMITER ;