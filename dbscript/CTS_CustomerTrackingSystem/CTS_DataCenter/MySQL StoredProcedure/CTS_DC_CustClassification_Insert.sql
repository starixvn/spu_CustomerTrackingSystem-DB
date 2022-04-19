/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_Insert`(
		IN ip_CategoryID		SMALLINT UNSIGNED        
    ,	IN ip_FromAction		TINYINT
    ,	IN ip_QueueID			BIGINT
    ,	IN ip_AffectDownline	BOOLEAN
    ,	IN ip_CustJson			JSON
    
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
			- 20210920@Aries.Nguyen: Split history log  [Redmine ID: #161890]
            - 10220418@Casey.Huynh: Add and Remove VVIP for Downline [Redmine ID: #159013]
            
		Param's Explanation:
			ip_FromAction: 1: Manual, 2:Service
	*/
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
	DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_Insert';
    DECLARE lv_Role 			INT;
    DECLARE lv_MaxCTSCustID		BIGINT UNSIGNED;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE 		Temp_Customer (
		 	CustID			BIGINT UNSIGNED		
         ,  CTSCustID 		BIGINT UNSIGNED
         ,	SubscriberID 	INT UNSIGNED
         ,	CreatedBy		BIGINT UNSIGNED
         ,	Remark			VARCHAR(300)
         
         ,	PRIMARY KEY PK_Temp_Customer(CustID)
         ,	INDEX IX_Temp_Customer_CTSCustID(CTSCustID)
	);
    
    /**************************************************************************************/
    INSERT INTO Temp_Customer(CustID, CTSCustID, SubscriberID, CreatedBy, Remark) 
	SELECT 	DISTINCT temp.CustID, temp.CTSCustID, temp.SubscriberID, temp.CreatedBy, temp.Remark
	FROM JSON_TABLE(ip_CustJson,
		 "$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED	PATH "$.CustID"
			,	CTSCustID 		BIGINT UNSIGNED	PATH "$.CTSCustID"
            ,	SubscriberID 	INT UNSIGNED	PATH "$.SubscriberID"
            ,	CreatedBy 		BIGINT UNSIGNED	PATH "$.CreatedBy"
            ,	Remark			VARCHAR(300)	PATH "$.Remark"
		 )) AS temp;
	
    SELECT MAX(tmpCus.CTSCustID)
    INTO lv_MaxCTSCustID
    FROM Temp_Customer AS tmpCus;
    /************************************************************************************/        
	/*Remove all category, customer class, probation list before.*/
	DELETE cls
    FROM CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_Customer AS tmpCus ON cls.CustID = tmpCus.CustID;
	
    DELETE pcl
    FROM CTS_DataCenter.SpecialCustomerClass AS pcl
		INNER JOIN Temp_Customer AS tmpCus ON pcl.CTSCustID = tmpCus.CTSCustID AND pcl.CreatedFromFunction = 1;
    
	DELETE pam
    FROM CTS_DataCenter.ProbationAccountMonitor AS pam
		INNER JOIN Temp_Customer AS tmpCus ON pam.CustID = tmpCus.CustID;
        
	/*Insert VVIP*/
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification
	(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		, 	tmpCus.SubscriberID
		, 	ip_CategoryID
		,   200
		, 	tmpCus.Remark
		, 	lv_CurrentDateTime
		,   tmpCus.CreatedBy
		,   lv_CurrentDateTime
		,   tmpCus.CreatedBy
		,   DATE(lv_CurrentDateTime)
	FROM Temp_Customer AS tmpCus;
	
	/*Insert VVIP history*/
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		, 	ip_CategoryID
		, 	200
		, 	lv_CurrentDateTime
		, 	tmpCus.CreatedBy
		,	0 
		,	0 
		,   DATE(lv_CurrentDateTime)
		,   100 
		,   13 
		,	1
	FROM Temp_Customer AS tmpCus;

	INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		, 	ip_CategoryID
		, 	200
		, 	lv_CurrentDateTime
		, 	tmpCus.CreatedBy
		,	0 
		,	0 
		,   DATE(lv_CurrentDateTime)
		,   100 
		,   13 
		,	1
	FROM Temp_Customer AS tmpCus;

	IF ip_FromAction = 1 THEN
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT 10 AS LogTypeID
			, 	lv_SPName
			, 	CONCAT('Insert VVIP: CTSCustID', tmpCus.CTSCustID,'; AffectDownline_', ip_AffectDownline,'; SubscriberID_', tmpCus.SubscriberID, '; ip_CategoryID_', ip_CategoryID, '; Remark_', tmpCus.Remark)
            ,	lv_CurrentDateTime
            , 	tmpCus.CreatedBy
        FROM Temp_Customer AS tmpCus;
	END IF;
    
	/*Auto Pin Category*/
	INSERT IGNORE INTO CTS_DataCenter.PinCustomerCategory(CTSCustID, CreatedTime)
	SELECT tmpCus.CTSCustID, lv_CurrentDateTime
    FROM Temp_Customer AS tmpCus;
 
    /*GET LATEST VVIP*/
    SELECT	tmpCus.CustID AS CustId
		,	100 AS CustomerClass
        ,	ip_CategoryID AS Category
        ,	lv_CurrentDateTime AS ScannedTime
    FROM  Temp_Customer AS tmpCus;
    
    /*****UPDATE Queue LastID************/
    IF ip_FromActionType = 2 AND ip_QueueID <> NULL THEN
		UPDATE CTS_DataCenter.QueueCustomerClassificationDownline AS que
		SET que.LastDownlineCTSCustID = lv_MaxCTSCustID
		WHERE que.ID = ip_QueueID;
    END IF;   
    
END$$
DELIMITER ;