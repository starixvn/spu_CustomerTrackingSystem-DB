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
           [20201112][Irena.Vo][#141563]: Created 
           [20201126][Irena.Vo][#141563]: Enhance logic remove Evidence to category 
           [20201127][Irena.Vo][#141563]: Enhance logic update LastModifiedDate for category 
		Param's Explanation (filtered by):			
	*/   
    DECLARE		lv_SPName 			VARCHAR(100) 		DEFAULT 'CTS_DC_CustEvidence_SyncToCategory';  
    DECLARE		lv_CreatedDateTime 	DATETIME 			DEFAULT CURRENT_TIME();
    DECLARE     lv_CreatedBy        BIGINT DEFAULT     	10278938;
    DECLARE		lv_IsSyncEvi2Cate	VARCHAR(1) 			DEFAULT '';  
   
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
   
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidences;    
	CREATE TEMPORARY TABLE Temp_CustomerEvidences 
    (	  
			CustID              BIGINT UNSIGNED
        ,   CTSCustID			BIGINT UNSIGNED
        ,   SubscriberID        INT 
		,   EvidenceID          SMALLINT UNSIGNED
        ,   CategoryID          SMALLINT UNSIGNED
        ,   ActionType          SMALLINT UNSIGNED -- 0: Insert, 2: Remove
        , 	INDEX 				IX_Temp_CustomerEvidences_CustID_ActionType(CustID,ActionType)       
     );
     
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedEviCategories;    
	CREATE TEMPORARY TABLE Temp_ExistedEviCategories 
    (	  
			CustID		    BIGINT UNSIGNED
        ,   CategoryID      SMALLINT UNSIGNED
        ,   EvidenceID      SMALLINT UNSIGNED
        ,   CreatedTime     DATETIME
        , 	INDEX 			IX_Temp_ExistedEviCategories_CustID_CategoryID_EvidenceID(CustID,CategoryID,EvidenceID)    
     );
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;  
	
    INSERT INTO Temp_CustomerEvidences(CustID, CTSCustID, SubscriberID, EvidenceID, CategoryID, ActionType)
	SELECT DISTINCT temp.CustID
				, temp.CTSCustID
				, temp.SubscriberID
                , temp.EvidenceID
                , ec.CategoryID
                , temp.ActionType
	 FROM JSON_TABLE(ip_CustEvidences,
		 "$[*]" COLUMNS(
			  CustID 			BIGINT UNSIGNED		PATH "$.CustId"
			, CTSCustID			BIGINT UNSIGNED		PATH "$.CTSCustId"
			, SubscriberID		INT					PATH "$.SubscriberId"
            , EvidenceID 		SMALLINT UNSIGNED	PATH "$.EvidenceId"
            , ActionType		SMALLINT UNSIGNED	PATH "$.ActionType"
		 )) AS temp
	LEFT JOIN CTS_DataCenter.EvidenceToCategory AS ec on ec.EvidenceID = temp.EvidenceID;
    
    /*SYNC EVIDENCE TO CATEGORY*/
    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
     IF(lv_IsSyncEvi2Cate = '1') THEN
        -- Ignore customer has CC before
		DELETE temp
        FROM Temp_CustomerEvidences AS temp
		INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID;
        
        -- Remove all Normal Category
		DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
        INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID
        WHERE cc.ParentID IN (1, 200);
        
        -- Remove all Probation List
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro 
        INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = pro.CustID;
	
        -- Get existed Cust Category Evidences
        INSERT INTO Temp_ExistedEviCategories(CustID,EvidenceID,CategoryID,CreatedTime)
        SELECT DISTINCT cate.CustID, ce.EvidenceID, cate.CategoryID, ce.CreatedDate
        FROM CTS_DataCenter.CustEvidence AS ce
        INNER JOIN Temp_CustomerEvidences AS temp ON temp.CTSCustID = ce.FromCustID AND ce.Level = 0  AND ce.EvidenceID <> temp.EvidenceID
        INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID
        INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID AND e.CategoryID = cate.CategoryID;
        
        -- Remove old Evidence Category
        DELETE cate
        FROM CTS_DataCenter.CTSCustomerClassification AS cate
        INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID
        LEFT JOIN Temp_ExistedEviCategories AS ex ON ex.CustID = cate.CustID AND (ex.CategoryID IS NULL OR cate.CategoryID = ex.CategoryID)
		WHERE (temp.ActionType = 2 AND ex.CustID IS NULL )
              OR (temp.ActionType = 0 AND cate.CategoryID = ex.CategoryID);
       
       -- Update Time for old Evidence Category
       UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
       INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND temp.CategoryID = cate.CategoryID
	   INNER JOIN Temp_ExistedEviCategories AS ex ON ex.CustID = cate.CustID AND cate.CategoryID = ex.CategoryID
       SET cate.CreatedDate = ex.CreatedTime
           , cate.LastModifiedDate = ex.CreatedTime
           , cate.LastScannedDate = CURRENT_DATE()
       WHERE temp.ActionType = 2;
       
        -- Insert new Evidence Category
		INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT 	DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.SubscriberID
			, 	temp.CategoryID
			,   0
			, 	'Synced by Evidence'
			, 	lv_CreatedDateTime
			,   lv_CreatedBy
			, 	lv_CreatedDateTime
			,   lv_CreatedBy
			, 	DATE(lv_CreatedDateTime)
		FROM Temp_CustomerEvidences AS temp
        WHERE temp.ActionType = 0;
	
        -- Insert log
        INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
		SELECT 	DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	CASE WHEN temp.ActionType = 0 THEN temp.CategoryID
                     ELSE NULL
				END AS CategoryID
			,   0
			,   lv_CreatedDateTime
			,   lv_CreatedBy
            ,   temp.ActionType
            ,   1
			,   DATE(lv_CreatedDateTime)
		FROM Temp_CustomerEvidences AS temp
        LEFT JOIN Temp_ExistedEviCategories AS ex ON ex.CustID = temp.CustID AND (ex.CategoryID IS NULL OR temp.CategoryID = ex.CategoryID)
        WHERE temp.ActionType = 0 
              OR (temp.ActionType = 2 AND (ex.CustID IS NULL OR ex.CategoryID IS NULL));
    END IF;
     
    -- Return distinct CustID mapping CC to mainDB
    SELECT DISTINCT temp.CustId FROM Temp_CustomerEvidences AS temp;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedEviCategories;    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidences;   

END$$

DELIMITER ;