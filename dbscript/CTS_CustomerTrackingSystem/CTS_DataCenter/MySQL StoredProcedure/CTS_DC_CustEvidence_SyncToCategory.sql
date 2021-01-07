/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustEvidence_SyncToCategory`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_SyncToCategory`(IN ip_CustEvidences JSON, OUT op_ErrorMessage VARCHAR(200))
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
	       - 20201214-20210107@Irena.Vo: Insert History Log. Insert Error Log & update logic SP. Return All List CustID. Update logic SP.  [RedmineID: #145951]
           
		Param's Explanation (filtered by):		 	
	*/   
    DECLARE	lv_CurrentDateTime 	DATETIME 		DEFAULT CURRENT_TIME();
    DECLARE lv_CreatedBy        BIGINT DEFAULT  10278938;
    DECLARE	lv_IsSyncEvi2Cate	VARCHAR(1) 		DEFAULT '';  
    
    DECLARE	lv_No				INT			 DEFAULT 0;
    DECLARE lv_ErrorNo 			INT          DEFAULT 0;
    DECLARE lv_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No 	= 	NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	lv_ErrorNo 			= 	MYSQL_ERRNO
		,	lv_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.CTSErrorLog(EventID, Message, Description)
        VALUES(9, op_ErrorMessage, JSON_OBJECT('err_no',lv_ErrorNo,'cod_name',lv_CodName,'parameter',ip_CustEvidences));
    END;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidences;    
	CREATE TEMPORARY TABLE Temp_CustomerEvidences 
    (	  
			CTSCustID			BIGINT UNSIGNED
		,	CustID              BIGINT UNSIGNED
        ,   SubscriberID        INT 
		,   EvidenceID          SMALLINT 
		, 	CategoryID		    SMALLINT 
        ,	CategoryGroupID     SMALLINT     
        ,	TargetCC			SMALLINT
        ,	SourceTypeID		SMALLINT
		, 	ActionType		    SMALLINT DEFAULT 0 -- 0: Insert, 1: Update, 2: Remove, 4: Ignore PIN
        ,	IsExistedEvi		BIT DEFAULT 0 -- 1: Not existed Evi Cate => No action remove PA
        ,   IsNeedToRescan      BIT DEFAULT 0 -- 1: After action Manual Remove => Insert any data
        , 	PRIMARY KEY     	PK_Temp_CustomerEvidences_CustID_EvidenceID(CustID,EvidenceID) 
        , 	INDEX 				IX_Temp_CustomerEvidences_CustID(CustID) 
        , 	INDEX 				IX_Temp_CustomerEvidences_CustID_CategoryGroupID(CustID,CategoryGroupID)          
     );
     
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification 
    (	  
			CustID				BIGINT UNSIGNED 
        , 	CategoryID	        SMALLINT UNSIGNED
        ,	CategoryGroupID     SMALLINT UNSIGNED  
        ,	RowOrder			SMALLINT
        , 	PRIMARY KEY 		PK_Temp_ExistedClassification_CustID_CategoryID(CustID, CategoryID)   
		, 	INDEX 				IX_Temp_ExistedClassification_CustID(CustID) 
        ,	INDEX				IX_Temp_ExistedClassification_CustID_CategoryGroupID(CustID,CategoryGroupID)
     );
    
    INSERT INTO 	Temp_CustomerEvidences(CTSCustID, CustID, SubscriberID, EvidenceID, CategoryID, ActionType)
	SELECT DISTINCT temp.CTSCustID
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
		 )) AS 	temp
	INNER JOIN 	CTS_DataCenter.EvidenceToCategory AS ec on ec.EvidenceID = temp.EvidenceID;
    
    /*	SYNC EVIDENCE TO CATEGORY	*/
    SELECT 	ParameterValue
    INTO 	lv_IsSyncEvi2Cate
    FROM 	CTS_DataCenter.SystemParameter
    WHERE 	ParameterID = 6;
    
	IF	(lv_IsSyncEvi2Cate = '1')	THEN
        /*	IGNORE PIN CATEGORY	*/
        UPDATE 		Temp_CustomerEvidences AS temp
        INNER JOIN 	CTS_DataCenter.PinCustomerCategory AS pin ON temp.CustID = pin.CustID
        SET 		temp.ActionType = 4;
        
        /*	REMOVE GENERAL CATEGORY BEFORE	*/
		DELETE 		cate
        FROM 		CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN 	Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 200;
        
        /*	REMOVE PROBATION LIST BEFORE	*/
		DELETE 		pro
        FROM 		CTS_DataCenter.ProbationAccountMonitor AS pro 
        INNER JOIN 	Temp_CustomerEvidences AS temp ON temp.CustID = pro.CustID;
        
        /* UPDATE CATEGORY GROUP ID INFO */
		UPDATE 		Temp_CustomerEvidences AS temp 
		INNER JOIN	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = temp.CategoryID
		SET			temp.CategoryGroupID = cc.CategoryGroup;
		
        #=========================================ACTION TYPE = 0, 1, 2=========================================================
		/*	GET EXISTED CATEGORY	*/
		INSERT INTO Temp_ExistedClassification (CustID, CategoryGroupID, CategoryID, RowOrder)
        SELECT 		cate.CustID
				, 	cc.CategoryGroup
                , 	cate.CategoryID  
				, 	ROW_NUMBER() OVER (PARTITION BY CustID, CategoryGroupID 
                                       ORDER BY (CASE WHEN cate.CategoryID BETWEEN 72 AND 80 THEN 1 -- From Evd will lastest records
													  ELSE 0
												 END) ) AS RowOrder
		FROM 		CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN 	Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 0
		INNER JOIN 	CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
		WHERE 		temp.ActionType IN (0, 2);
       
		UPDATE 		Temp_CustomerEvidences AS temp 
		INNER JOIN	Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryID = temp.CategoryID
		SET			temp.ActionType = 1
        WHERE 		temp.ActionType = 0;
        
         /*	UPDATE TARGET CC INFO */
		UPDATE 		Temp_CustomerEvidences AS temp 
		LEFT JOIN   CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID 
		LEFT JOIN   CTS_DataCenter.CategoryToCustomerClass AS map ON map.CategoryID = temp.CategoryID
		SET			temp.TargetCC = (CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass -- Existed CC
										  WHEN map.CategoryID IS NOT NULL THEN map.CustomerClass  -- Mapping CC
										  ELSE -99 -- No mapping CC
									 END)
		WHERE 		temp.ActionType IN (0, 1);
        
        UPDATE 		Temp_CustomerEvidences AS temp 
		LEFT JOIN   CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID 
		SET			temp.TargetCC = (CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass -- Existed CC
										  ELSE -1 -- Remove PA
									 END)
		WHERE 		temp.ActionType = 2;
    
		/*	UPDATE SOURCE TYPE ID INFO */
		UPDATE 		Temp_CustomerEvidences AS temp 
		SET			temp.SourceTypeID = (CASE WHEN temp.ActionType IN (0, 1) THEN 7
											  ELSE 9
										 END)
		WHERE 		temp.ActionType IN (0, 1, 2);
    
		#===========================================CLASSIFICATION DATA==================================================================
		/*	REMOVE PROBLEM ACCOUNTS */
		UPDATE 		Temp_CustomerEvidences AS temp
        INNER JOIN 	CTS_DataCenter.CustEvidence AS ce ON ce.CTSCustID = temp.CTSCustID
		INNER JOIN 	CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID AND ce.Level = 0 AND e.CategoryID = temp.CategoryID
	    SET        	temp.IsExistedEvi = 1;
        
        -- Only remove PA from Evidence
		DELETE 		 cate
		FROM 		 CTS_DataCenter.CTSCustomerClassification cate
		INNER JOIN 	 Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 0 AND temp.CategoryID = cate.CategoryID 
		WHERE 		 temp.ActionType = 2 AND temp.IsExistedEvi = 0 AND (cate.CategoryID BETWEEN 72 AND 80); 
        
        /*	UPDATE PROBLEM ACCOUNT */
		UPDATE 		CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN  Temp_CustomerEvidences AS temp on temp.CustID = cate.CustID AND cate.SportGroupID = 0 AND temp.CategoryID = cate.CategoryID 
		SET   	    cate.CTSCustID = temp.CTSCustID
				, 	cate.SubscriberID  = temp.SubscriberID
				, 	cate.LastModifiedBy = lv_CreatedBy
				,   cate.LastModifiedDate = lv_CurrentDateTime
				, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
		 WHERE 	temp.ActionType = 1; 
          
        /*	INSERT NEW PROBLEM ACCOUNT	*/
		INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT 	DISTINCT temp.CustID
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
		FROM 	Temp_CustomerEvidences AS temp
		WHERE 	temp.ActionType = 0;
   
		#===========================================WRITE LOG==================================================================
	    /* INSERT LOG RE-SCAN PA */    
        UPDATE 	Temp_CustomerEvidences AS temp 
	    INNER JOIN ( SELECT his.CustID, MAX(his.ID) AS HistoryID
					 FROM CTS_DataCenter.CTSCustomerClassification_History AS his
					 WHERE his.SourceTypeID IN (8, 9, 12, 14) and his.IsDataChanged = 1
					 GROUP BY his.CustID) AS t ON t.CustID = temp.CustID
		SET 	temp.IsNeedToRescan = 1;  -- 8: Remove PA by NAP CM, 9: Remove: PA by Evd, 12: Remove Special CC, 14: Remove VVIP ok
        
        INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT 	DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.CategoryID
			,   0
			,   lv_CurrentDateTime
			,   lv_CreatedBy
            ,   temp.ActionType
            ,   1
			,   DATE(lv_CurrentDateTime)
            , 	temp.TargetCC
            , 	16 -- Rescan Problem Account
			,	1 -- View History
		FROM 	Temp_CustomerEvidences AS temp
		WHERE 	temp.IsNeedToRescan = 1 AND temp.ActionType IN (0, 1);
        
       /*	INSERT LOG INSERT NEW/ UPDATE PA */
        INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT  DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.CategoryID
			, 	0 
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.ActionType
			, 	1 -- auto
			, 	DATE(lv_CurrentDateTime)
			, 	temp.TargetCC
			, 	temp.SourceTypeID
			,   CASE WHEN ex.CategoryGroupID IS NULL THEN 1 -- View History
					 ELSE 0
				END
		FROM 		Temp_CustomerEvidences AS temp
		LEFT JOIN 	Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryGroupID = temp.CategoryGroupID -- Not existed NAP CM Cate.
		WHERE 		temp.IsNeedToRescan = 0 AND temp.ActionType IN (0, 1);
        
        /*	INSERT LOG REMOVE PA */
	    INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
		SELECT  DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	ex.CategoryID
			, 	0 
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.ActionType
			, 	1 -- auto
			, 	DATE(lv_CurrentDateTime)
			, 	temp.TargetCC
			, 	temp.SourceTypeID
			,   CASE WHEN ex.CategoryGroupID IS NOT NULL THEN 1 -- View History
					 ELSE 0
				END
		FROM 	  Temp_CustomerEvidences AS temp
		LEFT JOIN Temp_ExistedClassification AS ex ON ex.CustID = temp.CustID AND ex.CategoryGroupID = temp.CategoryGroupID AND ex.RowOrder = 1 -- Not existed NAP CM Cate.
		WHERE     temp.IsNeedToRescan = 0 AND temp.ActionType = 2;
	  
		/*	INSERT LOG IGNORE PIN */
		INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
		SELECT  DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.CategoryID
			, 	0 
			, 	lv_CurrentDateTime
			, 	lv_CreatedBy
			, 	temp.ActionType
			, 	1 -- auto
			, 	DATE(lv_CurrentDateTime)
		FROM 	Temp_CustomerEvidences AS temp
		WHERE   temp.IsNeedToRescan = 0 AND temp.ActionType = 4;
		
		#=========================================GET LASTEST RESULTS=========================================================
		/*	GET LASTEST CUSTID LIST	-> GET LATEST CLASSICATION -> SYNC CC IN MAINDB */
		SELECT DISTINCT temp.CustId FROM Temp_CustomerEvidences AS temp
        WHERE temp.ActionType IN (0, 1, 2); 
	END IF;
END$$
DELIMITER ;