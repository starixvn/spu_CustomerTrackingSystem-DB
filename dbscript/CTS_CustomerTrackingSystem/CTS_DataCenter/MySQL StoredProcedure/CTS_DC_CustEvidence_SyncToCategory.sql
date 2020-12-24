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
			- 20201222@Irena.Vo: Update Logic SP for View History. Insert Error Log [RedmineID: #145951]
            - 20201223@Irena.Vo: Update view log [RedmineID: #145951]
         - 20201224@Irena.Vo: Update view log for Manual Removed list to rescan PA [RedmineID: #145951]
           
		Param's Explanation (filtered by):		 	
	*/   
    DECLARE	lv_SPName 			VARCHAR(100) 	DEFAULT 'CTS_DC_CustEvidence_SyncToCategory';  
    DECLARE	lv_CurrentDateTime 	DATETIME 		DEFAULT CURRENT_TIME();
    DECLARE lv_CreatedBy        BIGINT DEFAULT  10278938;
    DECLARE	lv_IsSyncEvi2Cate	VARCHAR(1) 		DEFAULT '';  
   
    DECLARE op_ErrorNo 			INT DEFAULT 0;
    DECLARE op_CodName 			VARCHAR(200) DEFAULT '0';

	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS CONDITION 1 
         	op_ErrorMessage 	= 	MESSAGE_TEXT	
		,	op_ErrorNo 			= 	MYSQL_ERRNO
		,	op_CodName 			= 	RETURNED_SQLSTATE;
    
        INSERT INTO CTS_Log.ErrorLog(EventName, InsertedTime, Message, Err_No, Description)
        VALUES(lv_SPName, lv_CurrentDateTime, op_ErrorMessage, op_ErrorNo, 	JSON_OBJECT('err_no',op_ErrorNo,'cod_name',op_CodName,'parameter',ip_CustEvidences));
    END;
   
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerEvidences;    
	CREATE TEMPORARY TABLE Temp_CustomerEvidences 
    (	  
			CTSCustID			BIGINT UNSIGNED
		,	CustID              BIGINT UNSIGNED
        ,   SubscriberID        INT 
		,   EvidenceID          SMALLINT UNSIGNED
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
     
	DROP TEMPORARY TABLE IF EXISTS Temp_CountNapCMCategory;    
	CREATE TEMPORARY TABLE Temp_CountNapCMCategory 
    (	  
			CTSCustID			BIGINT UNSIGNED 
        ,	NapCMCategoryID     SMALLINT UNSIGNED    
        ,   CountValue     		SMALLINT UNSIGNED    
		,	INDEX				IX_Temp_CountNapCMCategory_CTSCustID_NapCMCategoryID(CTSCustID,NapCMCategoryID)
	 ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistedOldEviCategories;    
	CREATE TEMPORARY TABLE Temp_ExistedOldEviCategories 
    (	  
			CTSCustID           BIGINT UNSIGNED
        ,   CategoryID			BIGINT UNSIGNED
        , 	INDEX 				IX_Temp_ExistedOldEviCategories_CTSCustID_CategoryID(CTSCustID,CategoryID)       
     );
    
     DROP TEMPORARY TABLE IF EXISTS Temp_ManualRemovedList;    -- For Rescan PA
	 CREATE TEMPORARY TABLE Temp_ManualRemovedList 
     (	  
			CustID				BIGINT UNSIGNED PRIMARY KEY    
      );
    
    INSERT INTO Temp_CustomerEvidences(CTSCustID, CustID, SubscriberID, EvidenceID, CategoryID, NapCMCategoryID, ActionType)
	SELECT DISTINCT temp.CTSCustID
				, temp.CustID
				, temp.SubscriberID
                , temp.EvidenceID
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
        INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 200;
        
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
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = 0; -- Both NapCM & Evidence.
        
        -- Remove Problem Accounts in CTS
		INSERT INTO Temp_ExistedOldEviCategories (CTSCustID,CategoryID)
		SELECT ce.FromCustID, e.CategoryID
		FROM CTS_DataCenter.CustEvidence AS ce 
		INNER JOIN CTS_DataCenter.EvidenceToCategory AS e ON e.EvidenceID = ce.EvidenceID AND ce.Level = 0
		INNER JOIN Temp_CustomerEvidences AS temp ON temp.CTSCustID = ce.CTSCustID AND e.CategoryID = temp.CategoryID;
        
		DELETE 		 cate
		FROM 		 CTS_DataCenter.CTSCustomerClassification cate
		INNER JOIN 	 Temp_CustomerEvidences AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = 0 AND temp.CategoryID = cate.CategoryID 
        LEFT JOIN    Temp_ExistedOldEviCategories AS exEvi ON exEvi.CTSCustID = cate.CTSCustID AND cate.SportGroupID = 0 AND exEvi.CategoryID = cate.CategoryID 
		WHERE 		 temp.ActionType = 2 AND exEvi.CategoryID IS NULL AND (cate.CategoryID BETWEEN 72 AND 80); -- Only remove PA from Evidence
    
		-- Update Problem Accounts in CTS
		UPDATE 		 CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN   Temp_CustomerEvidences AS temp on temp.CustID = cate.CustID AND cate.SportGroupID = 0 AND temp.CategoryID = cate.CategoryID 
		SET   	    cate.CTSCustID = temp.CTSCustID
				, 	cate.SubscriberID  = temp.SubscriberID
				, 	cate.LastModifiedBy = lv_CreatedBy
				,   cate.LastModifiedDate = lv_CurrentDateTime
				, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
				,	temp.ActionType = 1
		 WHERE 	cate.CategoryID BETWEEN 72 AND 80; -- Only update PA from Evidence
        
        -- Insert New Problem Accounts
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
		FROM Temp_CustomerEvidences AS temp
		WHERE temp.ActionType = 0;
   
        -- Insert history
		INSERT INTO Temp_CountNapCMCategory (CTSCustID, NapCMCategoryID, CountValue)  -- Count NapCMCategory so that compare with NAP CM
		SELECT DISTINCT ex.CTSCustID, ex.NapCMCategoryID, COUNT(ex.NapCMCategoryID)
		FROM Temp_ExistedClassification AS ex
		GROUP BY ex.CTSCustID, ex.NapCMCategoryID;
        
        INSERT INTO Temp_ManualRemovedList (CustID)
		SELECT DISTINCT t1.CustID
		FROM (  SELECT DISTINCT his.CustID, MAX(his.ID) AS HistoryID
				FROM CTS_DataCenter.CTSCustomerClassification_History AS his
				INNER JOIN Temp_CustomerEvidences AS temp ON temp.CustID = his.CustID
				GROUP BY his.CustID) AS t1
		INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS t2 ON t2.CustID = t1.CustID AND t2.ID = t1.HistoryID 
        WHERE t2.SourceTypeID IN (8, 9, 12, 14); -- 8: Remove PA by NAP CM, 9: Remove PA by Evd, 12: Remove Special CC, 14: Remove VVIP
    
        INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsView)
		SELECT 	DISTINCT temp.CustID
			, 	temp.CTSCustID
			, 	CASE WHEN temp.ActionType = 2 THEN ex.CategoryID  -- Remove PA
					ELSE temp.CategoryID
				END
			,   0
			,   lv_CurrentDateTime
			,   lv_CreatedBy
            ,   temp.ActionType
            ,   1
			,   DATE(lv_CurrentDateTime)
           , 	CASE WHEN sp.CustID IS NOT NULL THEN sp.CustomerClass -- Existed CC
					 WHEN map.CustomerClass IS NULL THEN -1 -- No mapping CC
					 ELSE map.CustomerClass
				END
            , 	CASE WHEN temp.ActionType = 2 THEN 9 -- item name = Remove PA from Evidence
					 ELSE 7 -- item name = Add from Evidence
				END
			,	CASE WHEN s.CustID IS NOT NULL THEN 1 -- View History
					 WHEN (temp.ActionType = 0 AND ex.NapCMCategoryID IS NULL) THEN 1 -- View History
					 WHEN (temp.ActionType = 2 AND c.NapCMCategoryID IS NULL) THEN 1 -- View History
                     ELSE 0
				END
		FROM Temp_CustomerEvidences AS temp
		LEFT JOIN   Temp_ManualRemovedList AS s ON temp.CustID = s.CustID -- Need to Rescan PA
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = temp.CustID
        LEFT JOIN Temp_ExistedClassification AS ex ON (CASE WHEN temp.ActionType = 2 THEN ex.CTSCustID = temp.CTSCustID AND ex.CategoryID = temp.CategoryID -- Get existed PA from NAP CM for View History
															WHEN temp.ActionType = 0 THEN ex.CTSCustID = temp.CTSCustID AND ex.NapCMCategoryID = temp.NapCMCategoryID -- Ignore if existed Evd Category for View History
													   END)
        LEFT JOIN Temp_CountNapCMCategory AS c ON c.CountValue = 2 AND c.CTSCustID = ex.CTSCustID AND c.NapCMCategoryID = ex.NapCMCategoryID -- Ignore if existed Evd Category for View History. Count NAPCM Category = 2
        LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS map ON (CASE WHEN temp.ActionType IN (0, 1) THEN  map.CategoryID = temp.NapCMCategoryID  -- Mapping from temp Category
																		 WHEN temp.ActionType = 2 THEN  map.CategoryID = ex.NapCMCategoryID  -- Mapping from existed Category
																	END);
    END IF;
     
	/*	GET LASTEST CUSTID LIST	-> GET LATEST CLASSICATION -> SYNC CC IN MAINDB */
	SELECT DISTINCT temp.CustId FROM Temp_CustomerEvidences AS temp;
END$$

DELIMITER ;