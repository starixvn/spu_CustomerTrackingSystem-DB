/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_VVIP_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_VVIP_Insert`(
		IN ip_FromAction		TINYINT
	,	IN ip_UplineRoleID		TINYINT
    ,	IN ip_QueueID			BIGINT
    ,	IN ip_AffectDownline	BOOLEAN
    ,	IN ip_CustJson			JSON
)
    SQL SECURITY INVOKER
sp: BEGIN
		/*
		Created:	20200423@Long.Luu	
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200423@Long.Luu 			[Redmine ID: #132623]: Created 
			- 20200608@Casey.Huynh 			[Redmine ID: #]: Add parameter ip_CustID
											+ Rule "Delete Category "New Member" When Add Manaual Caterory" 
			- 20200701@Casey.Huynh 			[Redmine ID: #]: 
											+ Remove Rule "Delete Category "New Member" When Add Manaual Caterory"
											+ Update History table
											+ Remove Verify VIP vs Smartpunter 
			- [20200908@Irena.Vo][141020]: 	Enhance insert manual for VVIP (include CustomerClass) . Add categoryid = 207 for VVIP (general)
			- [20200921@Irena.Vo][141755]: 	Enhance SP & insert Probation Management flow.
			- [20200923@Irena.Vo][141755]: 	Enhance SP
			- 20201202@Lex.Khuat: 			Disable detail categories & clean up wrong syntax [Redmine ID: #145954]
			- 20201214-20201229@Irena.Vo: 	Insert History Log & Auto Pin [RedmineID: #145951]
			- 20210226@Irena.Vo: 			Update CategoryID from VVIP [RedmineID: #150454]
			- 20210419@Irena.Vo: 			Get Category more [RedmineID: #153617]
			- 20210525@Irena.Vo: 			Change col name PinCustomerCategory: CustID -> CTSCustID [RedmineID: #152965] 
			- 20210920@Aries.Nguyen: 		Split history log  [Redmine ID: #161890]
			- 10220418@Casey.Huynh: 		Add and Remove VVIP for Downline [Redmine ID: #159013]
			- 20220519@Casey.Huynh: 		Renovate PA Process [RedmineID: #172061]
			- 20220713@Casey.Huynh: 		Switching for Licensee VIP & BA Categories [Redmine ID: #174219]
			- 20221007@Harvey.Nguyen: 		Change CTSCustomerClassificationOldPA -> CTSCustomerClassificationOldCategory [Redmine ID: #178022]
			- 20230315@Victoria.Le:			Add Robot Imperva [Redmine ID: #184773]
			- 20230404@Victoria.Le:			TVS Abnormal Bet and Abnormal Account - Add IsParlay,SportType,IssueTypeId [Redmine ID: #185319] 
			- 20230516@Casey.Huynh:			New Category for Robot OCRD [RedmineID: #186991]
            - 20231228@Thomas.Nguyen:		New Category for System Detect Unauthorized Login [RedmineID: #197710]
            - 20240315@Casey.Huynh: 		Classify Danger Score [Redmine ID: #201358]
			- 20240424@Thomas.Nguyen:		Classify Initial Group Betting - Add ParentID = 150, SportGroupID = 150 [Redmine ID: #200854]

		Param's Explanation:
			ip_FromAction: From Web(1),From Service VVIPDownLine(2), From Insert NewCustomer(3)
            ip_QueueID: From Web(NULL), From Service(<QueueID>)
            ip_AffectDownline:  From Web(0,1) , From Service(NULL)
            ip_UplineRoleID: From Web(NULL), From Service(<UplineRoleID>)
            
		Example:
			CALL CTS_DC_CustClassification_VVIP_Insert(1,NULL,NULL,1,'[{"CustID":722,"CTSCustID":722,"SubscriberID":2,"CategoryID":210,"CreatedBy":169368,"Remark":"Test Insert 01"}]');
	*/
    DECLARE lv_CurrentDateTime 		DATETIME DEFAULT CURRENT_TIME();
	DECLARE lv_SPName 				VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_VVIP_Insert';
    DECLARE	lv_CategoryID			INT DEFAULT 210;
    DECLARE lv_SportGroupID			INT DEFAULT 200;
    DECLARE lv_LogTypeID			INT DEFAULT 10;
    DECLARE lv_ActionType			INT DEFAULT 0;
	DECLARE lv_IsAuto				INT DEFAULT 0;
    DECLARE lv_MaxCTSCustID			BIGINT UNSIGNED;
    DECLARE lv_SourceTypeID			INT;    
    DECLARE lv_CustomerClass		INT; 
    
	DECLARE	CONST_GROUP_POTENTIALPA 	INT DEFAULT 150;

    DECLARE	CONST_CATEGORY_RISKY 		INT DEFAULT 203;
    DECLARE	CONST_CATEGORY_SMART		INT DEFAULT 204;
    DECLARE	CONST_CATEGORY_ROBOTUSER 		INT DEFAULT 163;
    DECLARE	CONST_CATEGORY_ROBOTUSER_LOSING	INT DEFAULT 164;
	DECLARE	CONST_CATEGORY_ROBOTOCRD 		INT DEFAULT 165;
    DECLARE	CONST_CATEGORY_ROBOTOCRD_LOSING	INT DEFAULT 166;
	DECLARE	CONST_CATEGORY_UNAUTHORIZEDLOGIN 			INT DEFAULT 64;
    DECLARE	CONST_CATEGORY_UNAUTHORIZEDLOGIN_LOSING		INT DEFAULT 104;
    DECLARE	CONST_CATEGORY_EARLYWARNINGMEMBERS 			INT DEFAULT 65;
    DECLARE	CONST_CATEGORY_EARLYWARNINGMEMBERS_LOSING	INT DEFAULT 105;
	DECLARE	CONST_CATEGORY_INITIALGB		 			INT DEFAULT 67;
    DECLARE	CONST_CATEGORY_INITIALGB_LOSING				INT DEFAULT 107;

#	INSERT INTO CaseyLog(SPName, OthersParam, JsonText)
 #   SELECT 'CTS_DC_CustClassification_VVIP_Insert', CONCAT('ip_FromAction:',ip_FromAction,' ip_UplineRoleID:', ip_UplineRoleID, ' ip_QueueID:', ip_QueueID, ' ip_AffectDownline:', ip_AffectDownline) , ip_CustJson;

	DROP TEMPORARY TABLE IF EXISTS Temp_Customer;
	CREATE TEMPORARY TABLE 		Temp_Customer (
		 	CustID			BIGINT UNSIGNED		
         ,  CTSCustID 		BIGINT UNSIGNED
         ,	SubscriberID 	INT UNSIGNED
         ,	RoleID			INT	
         ,	CreatedBy		BIGINT UNSIGNED
         ,	Remark			VARCHAR(300)
         ,	IsExistVVIP		BOOLEAN
         ,	IsDirect		BOOLEAN
         
         ,	PRIMARY KEY PK_Temp_Customer(CustID)
         ,	INDEX IX_Temp_Customer_CTSCustID(CTSCustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_WrapperCategory;
    CREATE TEMPORARY TABLE Temp_WrapperCategory(
		CategoryID SMALLINT UNSIGNED PRIMARY KEY
	);
    #=======================================================================
    INSERT INTO Temp_WrapperCategory(CategoryID)
    SELECT cat.CategoryID 
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE cat.ParentID = 1;
    
    SELECT  cat.CustomerClass
    INTO lv_CustomerClass
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE cat.CategoryID = lv_CategoryID;    
    
    /**************************************************************************************/
    INSERT INTO Temp_Customer(CustID, CTSCustID, SubscriberID, RoleID, CreatedBy, Remark, IsExistVVIP, IsDirect) 
	SELECT 	DISTINCT temp.CustID, temp.CTSCustID, temp.SubscriberID, temp.RoleID, temp.CreatedBy, temp.Remark
		,	(CASE WHEN cls.CustID IS NOT NULL THEN 1 ELSE 0 END) AS IsExistVVIP
        ,	(CASE WHEN ip_FromAction = 1 THEN  1 ELSE 0 END) AS IsDirect 
	FROM JSON_TABLE(ip_CustJson,
		 "$[*]" COLUMNS(
				CustID 			BIGINT UNSIGNED	PATH "$.CustID"
			,	CTSCustID 		BIGINT UNSIGNED	PATH "$.CTSCustID"
            ,	RoleID			INT				PATH "$.RoleID"
            ,	SubscriberID 	INT UNSIGNED	PATH "$.SubscriberID"
            ,	CreatedBy 		BIGINT UNSIGNED	PATH "$.CreatedBy"            
            ,	Remark			VARCHAR(300)	PATH "$.Remark"
		 )) AS temp
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON  temp.CustID = cls.CustID AND cls.CategoryID = 210;
	
    SELECT MAX(tmpCus.CTSCustID)
    INTO lv_MaxCTSCustID
    FROM Temp_Customer AS tmpCus;
    
    /****SET SourceTypeID for write log******/
    SET lv_SourceTypeID = CASE 	WHEN ip_FromAction = 1 THEN 13
								WHEN ip_FromAction = 2 AND ip_UplineRoleID = 4 THEN 24
                                WHEN ip_FromAction = 2 AND ip_UplineRoleID = 3 THEN 25
                                WHEN ip_FromAction = 2 AND ip_UplineRoleID = 2 THEN 26
                                WHEN ip_FromAction = 3 THEN 30
							END;    
    /************************************************************************************/
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationVVIP(CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, CategoryID, IsAffectToDownline,InsertTime, IsDirect) 
	SELECT tmpCus.CTSCustID
		,	tmpCus.CustID
		,	tmpCus.RoleID
		,	tmpCus.SubscriberID
		,	tmpCus.CreatedBy
		,	tmpCus.Remark
		,	lv_CategoryID
		,	ip_AffectDownline AS IsAffectToDownline
		,	lv_CurrentDateTime AS InsertTime
		,	tmpCus.IsDirect
	FROM Temp_Customer AS tmpCus
    WHERE tmpCus.IsExistVVIP = 0;
	
    /**** MOVE PA/RISKY/SMART TO CTSCustomerClassificationOldCategory *****/ 

    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationOldCategory(	
			CustID
		,	CTSCustID
		,	SubscriberID
		,	SportGroupID
		,	CategoryID
		,	Remark
		,	CreatedDate
		,	CreatedBy
		,	LastModifiedDate
		,	LastModifiedBy
		,	LastScannedDate
		,	IsFromTVS
		,	IsFromTW
		,	IsFromCTS
		,	IsFromAI
		,	IsDirect
		,	InsertTime
		,	TVSRequestID
		,	IsFromImperva
		,	IsParlay
		,	SportType
		,	IssueTypeID
		) 
    SELECT	cls.CustID
		,	cls.CTSCustID
        ,	cls.SubscriberID
        ,	cls.SportGroupID
        ,	cls.CategoryID
        ,	cls.Remark
        ,	cls.CreatedDate
        ,	cls.CreatedBy
        ,	cls.LastModifiedDate
        ,	cls.LastModifiedBy
        ,	cls.LastScannedDate
        ,	cls.IsFromTVS
        ,	cls.IsFromTW
        ,	cls.IsFromCTS
        ,	cls.IsFromAI
        ,	cls.IsDirect
        ,	CURRENT_TIMESTAMP(3) AS InsertTime
        ,	cls.TVSRequestID
		,	cls.IsFromImperva
		,	cls.IsParlay
		,	cls.SportType
		,	cls.IssueTypeId
	FROM CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_Customer AS tmpCus ON cls.CustID = tmpCus.CustID AND tmpCus.IsExistVVIP = 0
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cls.CategoryID
	WHERE NOT EXISTS (SELECT 1 FROM Temp_WrapperCategory AS tmpWr WHERE tmpWr.CategoryID = cls.CategoryID)
		  AND ((cls.SportGroupID = 0 AND cc.CategoryGroup NOT IN (CONST_CATEGORY_ROBOTUSER, CONST_CATEGORY_ROBOTUSER_LOSING,CONST_CATEGORY_ROBOTOCRD, CONST_CATEGORY_ROBOTOCRD_LOSING, CONST_CATEGORY_UNAUTHORIZEDLOGIN, CONST_CATEGORY_UNAUTHORIZEDLOGIN_LOSING)) 
			OR (cc.CategoryGroup IN (CONST_CATEGORY_ROBOTUSER, CONST_CATEGORY_ROBOTUSER_LOSING) AND cls.IsFromAI = 0 AND cls.IsFromTW = 0 AND cls.IsFromImperva = 0)
			OR (cls.SportGroupID = 200 AND cc.CategoryGroup IN (CONST_CATEGORY_RISKY, CONST_CATEGORY_SMART))
			OR (cls.SportGroupID = CONST_GROUP_POTENTIALPA AND cc.CategoryGroup NOT IN (CONST_CATEGORY_EARLYWARNINGMEMBERS,CONST_CATEGORY_EARLYWARNINGMEMBERS_LOSING, CONST_CATEGORY_INITIALGB, CONST_CATEGORY_INITIALGB_LOSING)));

	/*****Remove all category, customer class, probation list before******/
	DELETE cls
    FROM CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_Customer AS tmpCus ON cls.CustID = tmpCus.CustID AND tmpCus.IsExistVVIP = 0
	WHERE NOT EXISTS (SELECT 1 FROM Temp_WrapperCategory AS tmpWr WHERE tmpWr.CategoryID = cls.CategoryID);
	
    DELETE pcl
    FROM CTS_DataCenter.SpecialCustomerClass AS pcl
		INNER JOIN Temp_Customer AS tmpCus ON pcl.CTSCustID = tmpCus.CTSCustID AND pcl.CreatedFromFunction = 1 AND tmpCus.IsExistVVIP = 0;
    
	DELETE pam
    FROM CTS_DataCenter.ProbationAccountMonitor AS pam
		INNER JOIN Temp_Customer AS tmpCus ON pam.CustID = tmpCus.CustID WHERE tmpCus.IsExistVVIP = 0;
        
	/*Insert VVIP*/
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification (CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsDirect)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		, 	tmpCus.SubscriberID
		, 	lv_CategoryID
		,   lv_SportGroupID
		, 	tmpCus.Remark
		, 	lv_CurrentDateTime AS CreatedDate
		,   tmpCus.CreatedBy
		,   lv_CurrentDateTime AS LastModifiedDate
		,   tmpCus.CreatedBy AS LastModifiedBy
		,   DATE(lv_CurrentDateTime) AS LastScannedDate
        ,	tmpCus.IsDirect
	FROM Temp_Customer AS tmpCus
    WHERE tmpCus.IsExistVVIP = 0;
  
	/*Insert VVIP history*/
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID , LastModifiedDate, LastModifiedBy, ActionType, IsAuto
			, InsertDate, TargetCC, SourceTypeID, IsDataChanged, Remark, IsDirect)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		, 	lv_CategoryID
		, 	lv_SportGroupID
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpCus.CreatedBy AS LastModifiedBy
		,	lv_ActionType
		,	lv_IsAuto
		,   DATE(lv_CurrentDateTime) AS InsertDate
		,   lv_CustomerClass AS TargetCC
		,   lv_SourceTypeID AS SourceTypeID
		,	1 AS IsDataChanged
        ,	tmpCus.Remark
        , 	tmpCus.IsDirect
	FROM Temp_Customer AS tmpCus
    WHERE tmpCus.IsExistVVIP = 0;
	
	INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID ,LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, IsDirect)
	SELECT 	tmpCus.CustID
		, 	tmpCus.CTSCustID
		, 	lv_CategoryID
		, 	lv_SportGroupID
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpCus.CreatedBy AS LastModifiedBy
		,	lv_ActionType
		,	lv_IsAuto
		,   DATE(lv_CurrentDateTime) AS InsertDate
		,   lv_CustomerClass AS TargetCC
		,   lv_SourceTypeID AS SourceTypeID
		,	1 AS IsDataChanged
        ,	tmpCus.IsDirect
	FROM Temp_Customer AS tmpCus
    WHERE tmpCus.IsExistVVIP = 0;
    
	/*Auto Pin Category*/
	INSERT IGNORE INTO CTS_DataCenter.PinCustomerCategory(CTSCustID, CreatedTime, CreatedBy)
	SELECT tmpCus.CTSCustID, lv_CurrentDateTime, tmpCus.CreatedBy
    FROM Temp_Customer AS tmpCus
    WHERE tmpCus.IsExistVVIP = 0;  
 
    /*RETURN CustList: push CC to NAP */
    SELECT	tmpCus.CustID AS CustId
		,	lv_CustomerClass AS CustomerClass
        ,	lv_CategoryID AS Category
    FROM  Temp_Customer AS tmpCus
    WHERE tmpCus.IsExistVVIP = 0;
    
    /*****UPDATE Queue LastID************/
    IF ip_FromAction = 2 AND ip_QueueID IS NOT NULL THEN
		UPDATE CTS_DataCenter.CTSCustomerClassificationQueue AS que
		SET que.LastDownlineCTSCustID = lv_MaxCTSCustID
		WHERE que.ID = ip_QueueID;
    END IF;
    
    /********USER LOG***********************************************************************/
    IF ip_FromAction = 1 THEN
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		SELECT  lv_LogTypeID
			, 	lv_SPName
			, 	CONCAT('Insert VVIP: CTSCustID_', tmpCus.CTSCustID,'; RoleID_', tmpCus.RoleID, '; AffectDownline_', ip_AffectDownline,'; SubscriberID_', tmpCus.SubscriberID, '; CategoryID_', lv_CategoryID, '; Remark_', tmpCus.Remark)
            ,	lv_CurrentDateTime AS CreatedDate
            , 	tmpCus.CreatedBy
        FROM Temp_Customer AS tmpCus;
	END IF;
    
END$$
DELIMITER ;