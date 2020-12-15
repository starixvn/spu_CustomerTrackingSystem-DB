/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Insert`;

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
            - 20201214@Irena.Vo: Update History Log & Auto Pin [RedmineID: #145951]
	*/
    DECLARE lv_CurrentDateTime DATETIME DEFAULT CURRENT_TIME();
	DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_Insert';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	IF (SELECT COUNT(1) FROM CTS_DataCenter.CustomerCategory WHERE CategoryID = ip_CategoryID AND IsUsedManually = 0) > 0 THEN		
		SET op_ErrorMessage = 'This Category is not allowed for manually update!!!!'; 
        LEAVE sp;
    END IF;   
   
    IF (ip_CategoryID = 213) THEN
        -- Remove all category before: General, Problem.
	    DELETE cate
		FROM CTS_DataCenter.CTSCustomerClassification AS cate
		WHERE cate.CustID = ip_CustID; 
        
		-- Remove all probation list before
		DELETE pro
        FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	    WHERE pro.CustID = ip_CustID;
        
        -- Remove old customer class before
        DELETE sc
		FROM CTS_DataCenter.SpecialCustomerClass AS sc
		WHERE sc.CTSCustID = ip_CTSCustID AND sc.CreatedFromFunction = 1; 
        
 		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(12, lv_SPName, CONCAT('Remove all category and probation list: From ip_CustID_', ip_CustID), lv_CurrentDateTime, ip_CreatedBy);
        
        INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	    VALUES(20, lv_SPName, CONCAT('Remove all special customer class: From ip_CustID_', ip_CustID), lv_CurrentDateTime, ip_CreatedBy);

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
		(CustID, CTSCustID, CategoryID, SportGroupID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID)
		SELECT 	ip_CustID
			, 	ip_CTSCustID
			, 	ip_CategoryID
			, 	200
			, 	lv_CurrentDateTime
			, 	ip_CreatedBy
			,	0  -- insert
			,	0  -- manual
			,   DATE(lv_CurrentDateTime)
            ,   100 -- is VVIP
            ,   13 -- item = Add VVIP
            ;

		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(10, lv_SPName, CONCAT('Insert VVIP: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID,';ip_SportGroupIDList_', 200,  ';ip_CategoryID_', ip_CategoryID, ';ip_Remark_', ip_Remark), lv_CurrentDateTime, ip_CreatedBy);
    
       -- Auto Pin Category (have not Pin before)
       INSERT IGNORE INTO CTS_DataCenter.PinCustomerCategory(CustID, CreatedTime)
	   SELECT 	    ip_CustID,	lv_CurrentDateTime;
   
    END IF;
    
    -- GET LATEST CC
    SELECT ip_CustID AS CustId, 100 AS CustomerClass, lv_CurrentDateTime AS ScannedTime;
    
END$$

DELIMITER ;