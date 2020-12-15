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
        ,   TargetCC            TINYINT
        , 	INDEX 				IX_Temp_CustomerEvidences_CustID(CustID)       
		, 	INDEX 				IX_Temp_CustomerEvidences_CategoryID_TargetCC(CategoryID,TargetCC)    
		, 	INDEX 				IX_Temp_CustomerEvidences_ActionType(ActionType)       
     );
    
     DROP TEMPORARY TABLE IF EXISTS Temp_ExistedOldEviCategories;    
	CREATE TEMPORARY TABLE Temp_ExistedOldEviCategories 
    (	  
			CTSCustID           BIGINT UNSIGNED
        ,   CategoryID			BIGINT UNSIGNED
		,   CreatedTime         DATETIME
        , 	INDEX 				IX_Temp_ExistedOldEviCategories_CTSCustID_CategoryID(CTSCustID,CategoryID)       
     );
     
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
        INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID
        WHERE cate.CategoryID > 200 AND cate.CategoryID < 300;
        
        -- Remove all Probation List
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro 
        INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = pro.CustID;
      
		-- REMOVE OLD EVIDENCE CATEGORY
		DELETE cate
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.CategoryID = temp.CategoryID;
        
        -- GET EXISTED OLD EVIDENCE TO SYNC CATEGORY IF HAVE (ActionType = 2)
        INSERT INTO Temp_ExistedOldEviCategories (CTSCustID,CategoryID,CreatedTime)
		SELECT ce.FromCustID, e.CategoryID, MAX(ce.CreatedDate) AS CreatedTime
		FROM CTS_DataCenter.CustEvidence AS ce 
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID AND ce.Level = 0
		INNER JOIN Temp_CustomerEvidences AS temp ON temp.CTSCustID = ce.CTSCustID AND e.CategoryID = temp.CategoryID
		GROUP BY ce.FromCustID, e.CategoryID;
        
        -- Insert new Evidence Category
		INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT 	DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.SubscriberID
			, 	temp.CategoryID
			,   0
			, 	'Synced by Evidence'
			, 	CASE WHEN temp.ActionType = 0 THEN lv_CreatedDateTime
                     ELSE ex.CreatedTime
				END
			,   lv_CreatedBy
			, 	CASE WHEN temp.ActionType = 0 THEN lv_CreatedDateTime
                     ELSE ex.CreatedTime
				END
			,   lv_CreatedBy
			, 	DATE(lv_CreatedDateTime)
		FROM Temp_CustomerEvidences AS temp
        LEFT JOIN Temp_ExistedOldEviCategories AS ex ON ex.CTSCustID = temp.CTSCustID
        WHERE temp.ActionType = 0 OR (temp.ActionType = 2 AND ex.CTSCustID IS NOT NULL);
   
   	    -- UPDATE CUSTOMER CLASS
		UPDATE Temp_CustomerEvidences AS temp
		INNER JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON temp.CategoryID = map.CategoryID
		SET temp.TargetCC = map.CustomerClass;
	   
        -- Insert log
        INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID)
		SELECT 	DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	temp.CategoryID
			,   0
			,   lv_CreatedDateTime
			,   lv_CreatedBy
            ,   temp.ActionType
            ,   1
			,   DATE(lv_CreatedDateTime)
            , 	CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass 
					 WHEN temp.ActionType = 2 OR temp.TargetCC IS NULL THEN -1 -- no mapping CC
					 ELSE temp.TargetCC
				END
            , 	CASE WHEN temp.ActionType = 2 THEN 9 -- item name = Remove PA
					 ELSE 7 -- item name = Add from Evidence
				END
		FROM Temp_CustomerEvidences AS temp
        LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
		LEFT JOIN Temp_ExistedOldEviCategories AS ex ON ex.CTSCustID = temp.CTSCustID
        WHERE temp.ActionType = 0 OR (temp.ActionType = 2 AND ex.CTSCustID IS NULL);
        
    END IF;
     
   /*	GET LASTEST CUSTID LIST	*/
   SELECT DISTINCT temp.CustId
					,	CASE WHEN temp.ActionType = 2 THEN 3
							 ELSE 4
						END AS TypeId
   FROM Temp_CustomerEvidences AS temp
   LEFT JOIN Temp_ExistedOldEviCategories AS ex ON ex.CTSCustID = temp.CTSCustID
   WHERE temp.ActionType = 0 OR (temp.ActionType = 2 AND ex.CTSCustID IS NULL);

END$$

DELIMITER ;