/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_Insert`(
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
            - 20201214-20201229@Irena.Vo: Insert History Log & Auto Pin [RedmineID: #145951]
            - 20210226@Irena.Vo: Update CategoryID from VVIP [RedmineID: #150454]
            - 20210419@Irena.Vo: Get Category more [RedmineID: #153617]
            - 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [RedmineID: #152965] 
	*/
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
	DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_Insert';
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
   
	/*Remove all category, customer class, probation list before.*/
	DELETE FROM CTS_DataCenter.CTSCustomerClassification WHERE CTSCustID = ip_CTSCustID; 

	DELETE FROM CTS_DataCenter.SpecialCustomerClass WHERE CTSCustID = ip_CTSCustID AND CreatedFromFunction = 1; 
	
	DELETE FROM CTS_DataCenter.ProbationAccountMonitor WHERE CustID = ip_CustID;

	/*Insert VVIP*/
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
	
	/*Insert VVIP history*/
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History
	(CustID, CTSCustID, CategoryID, SportGroupID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
	SELECT 	ip_CustID
		, 	ip_CTSCustID
		, 	ip_CategoryID
		, 	200
		, 	lv_CurrentDateTime
		, 	ip_CreatedBy
		,	0 
		,	0 
		,   DATE(lv_CurrentDateTime)
		,   100 
		,   13 
		,	1;

	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	VALUES(10, lv_SPName, CONCAT('Insert VVIP: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID, ';ip_CategoryID_', ip_CategoryID, ';ip_Remark_', ip_Remark), lv_CurrentDateTime, ip_CreatedBy);

	/*Auto Pin Category*/
	INSERT IGNORE INTO CTS_DataCenter.PinCustomerCategory(CTSCustID, CreatedTime)
	SELECT ip_CTSCustID, lv_CurrentDateTime;
 
    /*GET LATEST VVIP*/
    SELECT ip_CustID AS CustId, 100 AS CustomerClass, ip_CategoryID AS Category, lv_CurrentDateTime AS ScannedTime;
END$$
DELIMITER ;