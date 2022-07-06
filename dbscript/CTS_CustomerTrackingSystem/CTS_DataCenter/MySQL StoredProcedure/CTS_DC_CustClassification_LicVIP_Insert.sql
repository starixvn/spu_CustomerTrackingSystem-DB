/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_LicVIP_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_LicVIP_Insert`(
		IN ip_CustIDList TEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
		/*
		Created:	20200705@Casey.Huynh
		Task :		New Category Licensee VIP 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200705@Casey.Huynh [Redmine ID: #174219]: Created
            
		Param's Explanation:
            
		Example:
			CALL CTS_DC_CustClassification_LicVIP_Insert('1,2,3,4');
	*/
    
    
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
	DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_CustClassification_LicVIP_Insert';
    DECLARE	lv_CategoryID		INT DEFAULT 210;
    DECLARE lv_SportGroupID		INT DEFAULT 200;
    DECLARE lv_LogTypeID		INT DEFAULT 10;
    DECLARE lv_ActionType		INT DEFAULT 0;
	DECLARE lv_IsAuto			INT DEFAULT 0;
    DECLARE lv_MaxCTSCustID		BIGINT UNSIGNED;
    DECLARE lv_SourceTypeID		INT;    
    DECLARE lv_CustomerClass	INT; 

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
	
    /****MOVE PA TO OLD PA*****/
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationOldPA(CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
    , LastScannedDate, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsDirect, InsertTime, TVSRequestID) 
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
	FROM CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_Customer AS tmpCus ON cls.CustID = tmpCus.CustID AND tmpCus.IsExistVVIP = 0;
        
	/*****Remove all category, customer class, probation list before******/
	DELETE cls
    FROM CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_Customer AS tmpCus ON cls.CustID = tmpCus.CustID AND tmpCus.IsExistVVIP = 0;
	
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