/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Insert`(
		IN ip_CustID			BIGINT UNSIGNED
    , 	IN ip_CTSCustID			BIGINT UNSIGNED	
    ,	IN ip_SubscriberID		INT
	,	IN ip_CategoryID		SMALLINT
    , 	IN ip_Remark 			VARCHAR(300)
	,	IN ip_CreatedBy 		INT
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
	SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu [Redmine ID: #132623]: Created 
			- 20200608@Casey.Huynh [Redmine ID: #]: Add parameter ip_CustID
					+ Rule "Delete Category "New Member" When Add Manaual Caterory" 
            - 20200701@Casey.Huynh [Redmine ID: #]: 
					+ Remove Rule "Delete Category "New Member" When Add Manaual Caterory"
                    + Update History table
					+ Remove Verify VIP vs Smartpunter 
			- [20200908@Irena.Vo][141020]: Enhance insert manual for VVIP (include CustomerClass) . Add categoryid = 207 for VVIP (general)
            - [20200921@Irena.Vo][141755]: Enhance SP & insert Probation Management flow.
            - [20200923@Irena.Vo][141755]: Enhance SP
            - 20201202@Lex.Khuat: Disable detail categories & clean up wrong syntax [Redmine ID: #145954]
            
		Param's Explanation:
	*/ 
	/**********1. PREPARE PARAMS**********/
    DECLARE lv_CurrentDateTime DATETIME DEFAULT NOW();
	DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_Insert';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	IF (SELECT COUNT(1) FROM CTS_DataCenter.CustomerCategory WHERE CategoryID = ip_CategoryID AND IsUsedManually = 0) > 0 THEN		
		SET op_ErrorMessage = 'This Category is not allowed for manually update!!!!'; 
        LEAVE sp;
    END IF;   
    
	/**********2. ACTION FOR VVIP**********/
    IF (ip_CategoryID = 213) THEN
        -- Remove all categories before
	    DELETE cate
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
		WHERE cate.CustID = ip_CustID; 
        
	    INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(12, lv_SPName, CONCAT('Remove all classification: From ip_CustID_', ip_CustID, '; ip_CategoryID_', 3), lv_CurrentDateTime, ip_CreatedBy);

        -- Insert for CTSCustomerClassification
        INSERT INTO CTS_DataCenter.CTSCustomerClassification
		(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
		SELECT 	ip_CustID
			, 	ip_CTSCustID
			, 	ip_SubscriberID
			, 	213 -- General VVIP
			,   200
			, 	ip_Remark
			, 	lv_CurrentDateTime
			,   ip_CreatedBy
			,   lv_CurrentDateTime
			,   ip_CreatedBy
			,   DATE(lv_CurrentDateTime);
        
	   -- Insert history
        INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
		(CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
		SELECT 	ip_CustID
			, 	ip_CTSCustID
			, 	213 -- General VVIP
			, 	200 
			, 	lv_CurrentDateTime
			, 	ip_CreatedBy
			,	0 -- Add new
			,	0 -- IsAuto
			,   DATE(lv_CurrentDateTime);

		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(10, lv_SPName, CONCAT('Insert classification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID,';ip_SportGroupIDList_', ip_SportGroupIDList,  ';ip_CategoryID_', 213, ';ip_Remark_', ip_Remark), lv_CurrentDateTime, ip_CreatedBy);
    
        -- Remove all probation list before
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	    WHERE pro.CustID = ip_CustID;
        
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(12, lv_SPName, CONCAT('Remove all probation list: From ip_CustID_', ip_CustID), lv_CurrentDateTime, ip_CreatedBy);

        -- Remove old customer class before
        DELETE sc
		FROM CTS_DataCenter.SpecialCustomerClass AS sc
		WHERE sc.CTSCustID = ip_CTSCustID AND sc.CreatedFromFunction = 1; 
        
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(12, lv_SPName, CONCAT('Remove all special customer class: From ip_CTSCustID_', ip_CTSCustID), lv_CurrentDateTime, ip_CreatedBy);
        
		 -- Insert for SpecialCustomerClass For VVIP
        INSERT INTO CTS_DataCenter.SpecialCustomerClass(CTSCustID, CustID, RootCTSCustID, SubscriberID, CustomerClass, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction)
		SELECT 	ip_CTSCustID
			,	ip_CustID
			,	ip_CTSCustID
			,	ip_SubscriberID
			,	100
			,	ip_CreatedBy
			,	lv_CurrentDateTime
            ,   ip_CreatedBy
			,	lv_CurrentDateTime
			,   11; -- VVIP
            
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(19, lv_SPName, CONCAT('Insert special customer class: ip_CTSCustID = ', ip_CTSCustID, ';ip_CustomerClass = ', 100), lv_CurrentDateTime, ip_CreatedBy);
   
    END IF;
    
    /**********3. ACTION FOR OTHER CATEGORY**********/
    -- Insert for CTSCustomerClassification
	INSERT INTO CTS_DataCenter.CTSCustomerClassification
    (CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	ip_CustID
		, 	ip_CTSCustID
		, 	ip_SubscriberID
        , 	ip_CategoryID
        ,   200
        , 	ip_Remark
        , 	lv_CurrentDateTime
        ,   ip_CreatedBy
        ,   lv_CurrentDateTime
        ,   ip_CreatedBy
        ,   DATE(lv_CurrentDateTime);

   -- Insert history
   INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
    (CustID, CTSCustID, CategoryID,SportGroupID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate)
	SELECT 	ip_CustID
		, 	ip_CTSCustID
        , 	ip_CategoryID
        , 	200
        , 	lv_CurrentDateTime
        , 	ip_CreatedBy
        ,	0 -- Add new
        ,	0 -- IsAuto
        ,   CURRENT_DATE();
    
	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(10, lv_SPName, CONCAT('Insert classification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID,';ip_SportGroupIDList_', ip_SportGroupIDList,  ';ip_CategoryID_', ip_CategoryID, ';ip_Remark_', ip_Remark), lv_CurrentDateTime, ip_CreatedBy);

END$$

DELIMITER ;