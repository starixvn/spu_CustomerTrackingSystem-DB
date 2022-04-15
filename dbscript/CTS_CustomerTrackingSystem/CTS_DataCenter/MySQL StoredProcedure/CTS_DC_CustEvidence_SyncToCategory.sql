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
		   - 20220210@Irena.Vo: Add new logic for Update ABI Danger Level [#167746]
		   - 20220414@Aries.Nguyen: Add new category/class for PA Probation [Redmine ID: #170468]
            
		Param's Explanation (filtered by):
		Exmaple:
			- CALL CTS_DataCenter.CTS_DC_CustEvidence_SyncToCategory('[{"CustID":43600693, "CTSCustID": 221882500, "SubscriberId": 130, "EvidenceId": 41, "ActionType": 0}]',0,@op_ErrorMessage);
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
	
    /*  1: Get Mapping category*/
	CALL CTS_DC_CustClassification_MappingPACategory(ip_CustEvidences, 'Evidence');

    SELECT ParameterValue
    INTO lv_IsSyncEvi2Cate
    FROM CTS_DataCenter.SystemParameter
    WHERE ParameterID = 6;
    
	IF (lv_IsSyncEvi2Cate = '1') THEN
        /*	2: REMOVE GENERAL CATEGORY BEFORE	*/
		DELETE clss
        FROM CTS_DataCenter.CTSCustomerClassification AS clss
			INNER JOIN Temp_PA AS pa ON pa.CustID = clss.CustID AND clss.SportGroupID = CONST_GROUP_NORMAL
		WHERE pa.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_REMOVE);
        
        /*	3: REMOVE PROBATION LIST BEFORE	*/
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro 
			INNER JOIN Temp_PA AS pa ON pa.CustID = pro.CustID
		WHERE pa.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_REMOVE);
        
		
		/*	4: REMOVE PA FROM EVIDENCE */
		DELETE clss
		FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS pa ON pa.CustID = clss.CustID AND clss.SportGroupID = CONST_GROUP_PA AND pa.CategoryID = clss.CategoryID 
        INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = clss.CategoryID
		WHERE	pa.ActionType = CONST_ACTIONTYPE_REMOVE AND pa.IsExistedEvi = 0 AND cate.SourceType = 'NAP'; 
        
        /*	5: UPDATE PA FROM EVIDENCE */
		UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
			INNER JOIN Temp_PA AS pa on pa.CustID = clss.CustID AND clss.SportGroupID = CONST_GROUP_PA AND pa.CategoryID = clss.CategoryID 
		SET   	clss.CTSCustID = pa.CTSCustID
			, 	clss.SubscriberID  = pa.SubscriberID
			, 	clss.LastModifiedBy = lv_CreatedBy
			,   clss.LastModifiedDate = lv_CurrentDateTime
			, 	clss.LastScannedDate = DATE(lv_CurrentDateTime)
		 WHERE pa.ActionType = CONST_ACTIONTYPE_UPDATE; 
		
        /*	7: UPDATE PA By Winloss Probation */
		UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
			INNER JOIN Temp_ExistedClassification AS pa on pa.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PA AND pa.CategoryID = cate.CategoryID 
		SET 	cate.CTSCustID = pa.CTSCustID
			,	cate.CategoryID = pa.RelevantCategoryID
			, 	cate.LastModifiedBy = lv_CreatedBy
			,   cate.LastModifiedDate = lv_CurrentDateTime
			, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
		WHERE pa.IsChangeByWinloss = 1;
        
        /*	6: INSERT NEW PA FROM EVIDENCE */
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
        SELECT	DISTINCT 
				pa.CustID
			, 	pa.CTSCustID
			, 	pa.SubscriberID
			, 	pa.CategoryID
			,   CONST_GROUP_PA
			, 	'Synced by Evidence'
			, 	lv_CurrentDateTime
			,   lv_CreatedBy
			, 	lv_CurrentDateTime
			,   lv_CreatedBy
			, 	DATE(lv_CurrentDateTime)
		FROM Temp_PA AS pa
		WHERE pa.ActionType = CONST_ACTIONTYPE_INSERT;
   
		IF (ip_IsRescan = 1) THEN
            UPDATE Temp_CustomerEvidences AS temp
            SET temp.SourceTypeID = CONST_SOURCETYPE_RESCANBYEVIDENCE;
        END IF;    
	    
        /*	7: Write log IsDataChange*/
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
		SELECT	DISTINCT 
				pa.CustID
			, 	pa.CTSCustID
			, 	pa.CategoryID
			,   CONST_GROUP_PA
			,   lv_CurrentDateTime
			,   lv_CreatedBy
			,   pa.ActionType
			,   1
			,   DATE(lv_CurrentDateTime)
			, 	pa.TargetCC
			, 	pa.SourceTypeID
			,   pa.IsDataChanged
			,	pa.TargetDangerLevel
			,	pa.TurnoverRM
			,	pa.WinlossRM
			, 	pa.BetCount
			, 	pa.ActiveDays
		FROM Temp_PA AS pa
		WHERE pa.IsDataChanged = 1;
	END IF;
    
    /* 8: WRITE HISTORY LOG (TRACE DATA) */
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log (CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT 	DISTINCT 
			pa.CustID
		, 	pa.CTSCustID
		, 	pa.CategoryID
		, 	CONST_GROUP_PA
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	pa.ActionType
		, 	1
		, 	DATE(lv_CurrentDateTime)
		, 	pa.TargetCC
		, 	pa.SourceTypeID
		,   pa.IsDataChanged
        ,	pa.TargetDangerLevel
        ,	pa.TurnoverRM
		,	pa.WinlossRM
		, 	pa.BetCount
		, 	pa.ActiveDays
	FROM Temp_PA AS pa;
    
    /* 18: RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS */
	SELECT	DISTINCT 
			pa.CustID
		,	pa.CTSCustID
	FROM  Temp_PA AS pa
	WHERE pa.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE); 
END$$
DELIMITER ;