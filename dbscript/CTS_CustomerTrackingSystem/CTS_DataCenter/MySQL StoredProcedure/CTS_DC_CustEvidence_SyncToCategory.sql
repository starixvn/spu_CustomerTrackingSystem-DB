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
		   - 20201214@Irena.Vo: Insert History & Return list CustID with TypeID IN (3, 4) [RedmineID: #145951]
		   - 20201215@Irena.Vo: Enhance logic join with CategoryID [RedmineID: #145951]
		   - 20201221@Irena.Vo: Update logic for View History [RedmineID: #145951]
           
		Param's Explanation (filtered by):		 	
	*/   
    DECLARE		lv_SPName 			VARCHAR(100) 		DEFAULT 'CTS_DC_CustEvidence_SyncToCategory';  
    DECLARE		lv_CurrentDateTime 	DATETIME 			DEFAULT CURRENT_TIME();
    DECLARE     lv_CreatedBy        BIGINT DEFAULT     	10278938;
    DECLARE		lv_IsSyncEvi2Cate	VARCHAR(1) 			DEFAULT '';  
   
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
   
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidences;    
	CREATE TEMPORARY TABLE Temp_CustomerEvidences 
    (	  
			CTSCustID			BIGINT UNSIGNED
		,	CustID              BIGINT UNSIGNED
        ,   SubscriberID        INT 
		,   EvidenceID          SMALLINT UNSIGNED
		,   SportGroupID        SMALLINT UNSIGNED 
		, 	CategoryID		    SMALLINT UNSIGNED
        ,	NapCMCategoryID     SMALLINT UNSIGNED    
		, 	ActionType		    SMALLINT DEFAULT 0 -- Insert: 0, Update: 1, Remove: 2
        , 	PRIMARY KEY     	PK_Temp_CustomerEvidences_CTSCustID_EvidenceID(CTSCustID,EvidenceID) 
		, 	INDEX 				IX_Temp_CustomerEvidences_NapCMCategoryID(NapCMCategoryID)    
		, 	INDEX 				IX_Temp_CustomerEvidences_ActionType(ActionType)       
     );
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedClassification;    
	CREATE TEMPORARY TABLE Temp_ExistedClassification 
    (	  
			CTSCustID			BIGINT UNSIGNED 
        , 	CategoryID	        SMALLINT UNSIGNED
        ,	NapCMCategoryID     SMALLINT UNSIGNED    
        , 	PRIMARY KEY 		PK_Temp_ExistedClassification_CTSCustID_CategoryID(CTSCustID, CategoryID)       
        ,	INDEX				IX_Temp_ExistedClassification_NapCMCategoryID(NapCMCategoryID)
     );
     
	DROP TEMPORARY TABLE IF EXISTS Temp_NumOfNapCMCategory;    
	CREATE TEMPORARY TABLE Temp_NumOfNapCMCategory 
    (	  
			CTSCustID			BIGINT UNSIGNED 
        ,	NapCMCategoryID     SMALLINT UNSIGNED    
        ,   NumOfCategoryID     SMALLINT UNSIGNED    
		,	INDEX				IX_Temp_NumOfNapCMCategory_CTSCustID_NapCMCategoryID(CTSCustID,NapCMCategoryID)
	 ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedOldEviCategories;    
	CREATE TEMPORARY TABLE Temp_ExistedOldEviCategories 
    (	  
			CTSCustID           BIGINT UNSIGNED
        ,   CategoryID			BIGINT UNSIGNED
        , 	INDEX 				IX_Temp_ExistedOldEviCategories_CTSCustID_CategoryID(CTSCustID,CategoryID)       
     );
    
    INSERT INTO Temp_CustomerEvidences(CTSCustID, CustID, SubscriberID, EvidenceID, SportGroupID, CategoryID, NapCMCategoryID, ActionType)
	SELECT DISTINCT temp.CTSCustID
				, temp.CustID
				, temp.SubscriberID
                , temp.EvidenceID
                , 0
                , ec.CategoryID
                , CASE 	WHEN ec.CategoryID = 72 THEN 52
						WHEN ec.CategoryID = 73 THEN 53
						WHEN ec.CategoryID = 74 THEN 54 
						WHEN ec.CategoryID = 75 THEN 55
						WHEN ec.CategoryID = 76 THEN 56
						WHEN ec.CategoryID = 77 THEN 57
						WHEN ec.CategoryID = 78 THEN 58
						WHEN ec.CategoryID = 79 THEN 59
						WHEN ec.CategoryID = 80 THEN 60
					END AS NapCMCategoryID
                , temp.ActionType
	 FROM JSON_TABLE(ip_CustEvidences,
		 "$[*]" COLUMNS(
			  CTSCustID			BIGINT UNSIGNED		PATH "$.CTSCustId"
            , CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, SubscriberID		INT					PATH "$.SubscriberId"
            , EvidenceID 		SMALLINT UNSIGNED	PATH "$.EvidenceId"
            , ActionType		SMALLINT UNSIGNED	PATH "$.ActionType"
		 )) AS temp
	INNER JOIN CTS_DataCenter.EvidenceToCategory AS ec on ec.EvidenceID = temp.EvidenceID;
    
    /*	SYNC EVIDENCE TO CATEGORY	*/
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
     IF(lv_IsSyncEvi2Cate = '1') THEN
        -- Ignore Pin category
        DELETE temp
        FROM  Temp_CustomerEvidences AS temp
        INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin ON temp.CustID = pin.CustID;
        
        -- Remove all Normal Category
		DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 200 AND (cate.CategoryID > 200 AND cate.CategoryID < 300);
        
        -- Remove all Probation List
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro 
        INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = pro.CustID;
      
	    -- Get existed category
		INSERT INTO Temp_ExistedClassification (CTSCustID, CategoryID, NapCMCategoryID)
		SELECT DISTINCT 	cate.CTSCustID
						, 	cate.CategoryID
						,   CASE 	WHEN cate.CategoryID = 151 THEN 51
									WHEN cate.CategoryID IN (72, 152) THEN 52
									WHEN cate.CategoryID IN (73, 153) THEN 53
									WHEN cate.CategoryID IN (74, 154) THEN 54 
									WHEN cate.CategoryID IN (75, 155) THEN 55
									WHEN cate.CategoryID IN (76, 156) THEN 56
									WHEN cate.CategoryID IN (77, 157) THEN 57
									WHEN cate.CategoryID IN (78, 158) THEN 58
									WHEN cate.CategoryID IN (79, 159) THEN 59
									WHEN cate.CategoryID = 80 THEN 60
									ELSE cate.CategoryID
							 END AS NapCMCategoryID
		FROM Temp_CustomerEvidences AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 0
		WHERE cate.CategoryID > 50 AND cate.CategoryID < 200; -- both NapCM & Evidence.
		
        -- Count NAPCM Category so that compare with ActionType = 2
		INSERT INTO Temp_NumOfNapCMCategory (CTSCustID, NapCMCategoryID, NumOfCategoryID)
		SELECT DISTINCT ex.CTSCustID, ex.NapCMCategoryID, COUNT(ex.NapCMCategoryID)
		FROM Temp_ExistedClassification AS ex
		GROUP BY ex.CTSCustID, ex.NapCMCategoryID;
    
        -- Get Existed Evidence can sync to Category
        INSERT INTO Temp_ExistedOldEviCategories (CTSCustID,CategoryID)
		SELECT ce.FromCustID, e.CategoryID
		FROM CTS_DataCenter.CustEvidence AS ce 
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID AND ce.Level = 0
		INNER JOIN Temp_CustomerEvidences AS temp ON temp.CTSCustID = ce.CTSCustID AND e.CategoryID = temp.CategoryID;
        
        -- Remove Problem Accounts
		DELETE 		 cate
		FROM 		 CTS_DataCenter.CTSCustomerClassification cate
		INNER JOIN 	 Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND temp.CategoryID = cate.CategoryID AND cate.SportGroupID = 0
        LEFT JOIN    Temp_ExistedOldEviCategories AS exEvi ON exEvi.CTSCustID = cate.CTSCustID AND exEvi.CategoryID = cate.CategoryID AND cate.SportGroupID = 0
		WHERE 		 temp.ActionType = 2 AND exEvi.CategoryID IS NULL AND (cate.CategoryID BETWEEN 72 AND 80);
    
		-- Update Problem Accounts
		UPDATE 		 CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN   Temp_CustomerEvidences AS temp on temp.CustID = cate.CustID AND temp.CategoryID = cate.CategoryID AND cate.SportGroupID = 0
		SET   	    cate.CTSCustID = temp.CTSCustID
				, 	cate.SubscriberID  = temp.SubscriberID
				, 	cate.LastModifiedBy = lv_CreatedBy
				,   cate.LastModifiedDate = lv_CurrentDateTime
				, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
				,	temp.ActionType = 1
		 WHERE 	cate.CategoryID BETWEEN 72 AND 80;
        
        -- Insert New Problem Accounts
		INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT 	DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.SubscriberID
			, 	temp.CategoryID
			,   temp.SportGroupID
			, 	'Synced by Evidence'
			, 	lv_CurrentDateTime
			,   lv_CreatedBy
			, 	lv_CurrentDateTime
			,   lv_CreatedBy
			, 	DATE(lv_CurrentDateTime)
		FROM Temp_CustomerEvidences AS temp
        WHERE temp.ActionType = 0;
   
        -- Insert log
        INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID)
		SELECT 	DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	CASE WHEN temp.ActionType = 2 THEN ex.CategoryID  -- remove PA
					ELSE temp.CategoryID
				END
			,   0
			,   lv_CurrentDateTime
			,   lv_CreatedBy
            ,   temp.ActionType
            ,   1
			,   DATE(lv_CurrentDateTime)
           , 	CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass 
					 WHEN map.CustomerClass IS NULL THEN -1 -- no mapping CC
					 ELSE map.CustomerClass
				END
            , 	CASE WHEN temp.ActionType = 2 THEN 9 -- item name = Remove PA from Evidence
					 ELSE 7 -- item name = Add from Evidence
				END
		FROM Temp_CustomerEvidences AS temp
		LEFT JOIN Temp_ExistedClassification AS ex ON (CASE WHEN temp.ActionType = 2 THEN ex.CTSCustID = temp.CTSCustID AND ex.CategoryID = temp.CategoryID
															WHEN temp.ActionType = 0 THEN ex.CTSCustID = temp.CTSCustID AND ex.NapCMCategoryID = temp.NapCMCategoryID
													   END)
        LEFT JOIN Temp_NumOfNapCMCategory AS num ON num.NumOfCategoryID = 2 AND num.CTSCustID = ex.CTSCustID AND num.NapCMCategoryID = ex.NapCMCategoryID
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
        LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON (CASE WHEN temp.ActionType = 0 THEN  map.CategoryID = temp.NapCMCategoryID
																		 WHEN temp.ActionType = 2 THEN  map.CategoryID = ex.NapCMCategoryID
																	END)
		
		WHERE (temp.ActionType = 2 AND num.NapCMCategoryID IS NULL) OR (temp.ActionType = 0 AND ex.NapCMCategoryID IS NULL);
        
    END IF;
     
	/*	GET LASTEST CUSTID LIST	*/
	SELECT DISTINCT temp.CustId
	FROM Temp_CustomerEvidences AS temp
	LEFT JOIN Temp_ExistedClassification AS ex ON (CASE WHEN temp.ActionType = 2 THEN ex.CTSCustID = temp.CTSCustID AND ex.CategoryID = temp.CategoryID
														WHEN temp.ActionType = 0 THEN ex.CTSCustID = temp.CTSCustID AND ex.NapCMCategoryID = temp.NapCMCategoryID
													END)
	LEFT JOIN Temp_NumOfNapCMCategory AS num ON num.NumOfCategoryID = 2 AND num.CTSCustID = ex.CTSCustID AND num.NapCMCategoryID = ex.NapCMCategoryID
	WHERE (temp.ActionType = 2 AND num.NapCMCategoryID IS NULL) OR (temp.ActionType = 0 AND ex.NapCMCategoryID IS NULL);
    
END$$

DELIMITER ;