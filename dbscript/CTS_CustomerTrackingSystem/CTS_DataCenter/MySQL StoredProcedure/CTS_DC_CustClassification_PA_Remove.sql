/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_PA_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_Remove`(
		IN ip_IsFromQueue			BOOLEAN
    ,   IN ip_ProblemAccounts 		JSON
    ,	OUT op_ErrorMessage 		VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20220519@Casey.Huynh
		Task:		Remove Problem Account
		DB:			CTS_DataCenter
		Original:
		Revisions:
            - 20220519@Casey.Huynh: Renovate PA Process [Redmine ID: #172561]
            
        Param's Explanation (filtered by):
			- ip_ByType: 1: Category, 2: Reason
        Example:
	
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_Remove(0,'[{"CustID": 456, "CTSCustID": 324557, "RoleID": 4, "SubscriberID": 2, "CreatedBy": 8, "IsExceptDirectDownline": 1}]',@op_ErrorMessage);
            
	*/ 
    DECLARE lv_CurrentDateTime	DATETIME DEFAULT CURRENT_TIME(); 
    DECLARE	CONST_PA_SPORTGROUP TINYINT DEFAULT 0;
    DECLARE CONST_ACTIONTYPE_REMOVE INT DEFAULT 2;
    DECLARE CONST_NORMAL_SPORTGROUP INT DEFAULT 200;
    DECLARE CONST_USERLOG_LOGTYPE SMALLINT DEFAULT 33;
    DECLARE CONST_SPNAME VARCHAR(100) DEFAULT 'CTS_DC_CustClassification_PA_Remove';
    DECLARE lv_LogInfo VARCHAR(500);
	DECLARE lv_CreatedBy INT UNSIGNED;
    DECLARE lv_NoOfCust INT;
    DECLARE lv_IsExceptDirectDownline BOOLEAN;

    DROP TEMPORARY TABLE IF EXISTS Temp_InputCust;    
	CREATE TEMPORARY TABLE Temp_InputCust(
			CustID					BIGINT UNSIGNED 
		, 	CTSCustID				BIGINT UNSIGNED DEFAULT 0
        ,	RoleID					INT
        , 	SubscriberID			INT DEFAULT 0
        ,	Remark 					VARCHAR(500)        
        ,	CreatedBy 				INT UNSIGNED
        ,	IsExceptDirectDownline	BOOLEAN DEFAULT NULL
        ,	IsDirectPA				BOOLEAN DEFAULT NULL
        ,	IsRemovedPA				BOOLEAN DEFAULT 1
        
        ,	PRIMARY KEY PK_Temp_InputCust(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustPA;
    CREATE TEMPORARY TABLE Temp_CustPA(
			CustID 				INT UNSIGNED
		,	CTSCustID 			BIGINT UNSIGNED
        ,	CategoryID 			SMALLINT UNSIGNED
        ,	EvidenceID_Licensee SMALLINT UNSIGNED	
        ,	EvidenceID_Credit	SMALLINT UNSIGNED
        ,	RoleID				INT
        , 	SubscriberID		INT DEFAULT 0
        ,	Remark 				VARCHAR(500)        
        ,	CreatedBy 			INT UNSIGNED
         ,	IsDirectPA			BOOLEAN DEFAULT NULL
        ,	IsRemovedPA 		BOOLEAN DEFAULT 0
        
        ,	PRIMARY KEY PK_Temp_CustPA_CustIDCategoryID(CustID, CategoryID)
        ,	INDEX IX_Temp_CustPA_IsRemovedPA(IsRemovedPA)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_EvidencePA;
    CREATE TEMPORARY TABLE Temp_EvidencePA(
			EvidenceID SMALLINT
        ,	PRIMARY KEY PK_Temp_EvidencePA(EvidenceID)
    );  
	
	INSERT IGNORE INTO Temp_InputCust(CustID, CTSCustID, RoleID, SubscriberID, CreatedBy, Remark, IsExceptDirectDownline, IsDirectPA)
	SELECT 	DISTINCT tmpJs.CustID
		,	tmpJs.CTSCustID
		,	tmpJs.RoleID
        ,	tmpJs.SubscriberID
		,	tmpJs.CreatedBy 
		,	tmpJs.Remark
		,	tmpJs.IsExceptDirectDownline
        ,	tmpJs.IsDirectPA
	FROM JSON_TABLE(ip_ProblemAccounts,
		"$[*]" COLUMNS(			
				CustID 					INT UNSIGNED		PATH "$.CustID"
			, 	CTSCustID				INT UNSIGNED 		PATH "$.CTSCustID"
            ,   RoleID 					BIGINT UNSIGNED		PATH "$.RoleID"
            ,   SubscriberID 			BIGINT UNSIGNED		PATH "$.SubscriberID"
			, 	CreatedBy				INT UNSIGNED		PATH "$.CreatedBy"
			, 	Remark					VARCHAR(500)		PATH "$.Remark"
			, 	IsExceptDirectDownline	BOOLEAN 			PATH "$.IsExceptDirectDownline"
            , 	IsDirectPA				BOOLEAN 			PATH "$.IsDirectPA"
	)) AS tmpJs
    LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on tmpJs.CTSCustID = pin.CTSCustID # Exclude IF Cust is Pin Category;
    WHERE pin.CTSCustID IS NULL;

    INSERT IGNORE INTO Temp_CustPA(CustID, CTSCustID, CategoryID, EvidenceID_Licensee, EvidenceID_Credit
					, RoleID, SubscriberID, CreatedBy, Remark, IsDirectPA, IsRemovedPA)
    SELECT	tmpIc.CustID
		,	tmpIc.CTSCustID
		,	cls.CategoryID
        ,	cat.EvidenceID_Licensee
        ,	cat.EvidenceID_Credit
        ,	tmpIc.RoleID
        ,	tmpIc.SubscriberID
        ,	tmpIc.CreatedBy
        ,	tmpIc.Remark
        ,	tmpIc.IsDirectPA
        ,	(CASE WHEN tmpIc.IsExceptDirectDownline <> cls.IsDirect THEN 1 ELSE 0 END) AS IsRemovedPA    
    FROM Temp_InputCust AS tmpIc
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON tmpIc.CustID = cls.CustID AND cls.SportGroupID = CONST_PA_SPORTGROUP
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID; 
    
	INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueRemove(CTSCustID, EvidenceID, Created)
    SELECT	tmpCp.CTSCustID
		,	ce.EvidenceID
        ,	CURRENT_TIMESTAMP(3) AS Created
    FROM CTS_DataCenter.CustEvidence AS ce
		INNER JOIN Temp_CustPA AS tmpCp ON ce.CTSCustID = tmpCp.CTSCustID AND ce.Level = 0 
					AND ce.EvidenceID IN (tmpCp.EvidenceID_Licensee, tmpCp.EvidenceID_Credit)
	WHERE tmpCp.IsRemovedPA = 1;
    
	UPDATE CTS_DataCenter.RobotDetection AS rd
	SET rd.IsDisabled = 1
    WHERE NOT EXISTS (SELECT 1 FROM Temp_CustPA AS tmpCp WHERE tmpCp.IsRemovedPA = 0 AND tmpCp.CustID = rd.CustID);
    
	DELETE ce
    FROM CTS_DataCenter.CustEvidence AS ce
		INNER JOIN Temp_CustPA AS tmpCp ON ce.CTSCustID = tmpCp.CTSCustID AND ce.Level = 0
					AND ce.EvidenceID  IN (tmpCp.EvidenceID_Licensee, tmpCp.EvidenceID_Credit)					
	WHERE tmpCp.IsRemovedPA = 1;
  
    UPDATE Temp_InputCust AS tmpIc
    SET tmpIc.IsRemovedPA = 1
    WHERE NOT EXISTS (SELECT 1 FROM Temp_CustPA AS tmpCp WHERE tmpCp.IsRemovedPA = 0 AND tmpIc.CustID = tmpCp.CustID);
           
	IF(ip_IsFromQueue = 0) THEN    
		# INSERT SMA PA TO QUEUE PA AS #
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationQueue(CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, LastDownlineCTSCustID, ActionType, InsertTime, IsExceptDirectDownline)
		SELECT tmpIc.CTSCustID
			,	tmpIc.CustID
			,	tmpIc.RoleID
			,	tmpIc.SubscriberID
			,	tmpIc.CreatedBy
			,	tmpIc.Remark    
			,	0 AS LastDownlineCTSCustID
			,	4 AS ActionType # 4: UnMark PA, 3: Mark PA
			,	lv_CurrentDateTime AS InsertTime
            , 	tmpIc.IsExceptDirectDownline
		FROM Temp_InputCust AS tmpIc
		WHERE tmpIc.RoleID > 1;              

		# WRITE USER LOG IF FROM PAM#
         SELECT tmpIc.CreatedBy, tmpIc.IsExceptDirectDownline
         INTO lv_CreatedBy, lv_IsExceptDirectDownline
         FROM Temp_InputCust AS tmpIc LIMIT 1;

         IF (lv_CreatedBy IS NOT NULL) THEN
			 SELECT LEFT(CONCAT('CustNo.:',COUNT(1),'_IsExceptDirectDL:',lv_IsExceptDirectDownline,'_CustList',GROUP_CONCAT(DISTINCT tmpIc.CTSCustID)),500)
			 INTO lv_LogInfo
			 FROM Temp_InputCust AS tmpIc;
             
		 INSERT IGNORE INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		 SELECT CONST_USERLOG_LOGTYPE AS LogTypeID
			,	CONST_SPNAME AS SPName
			,	lv_LogInfo AS LogInfo
			,	DATE(lv_CurrentDateTime) AS CreatedDate
			,	lv_CreatedBy AS CreatedBy;
            
        END IF;        
	END IF;    

    DELETE cls
    FROM CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_CustPA AS tmpCp ON cls.CustID = tmpCp.CustID AND cls.SportGroupID = CONST_PA_SPORTGROUP AND cls.CategoryID = tmpCp.CategoryID
	WHERE tmpCp.IsRemovedPA = 1;

  #**********INSERT LOG FOR IsDataChange: CategoryID OR CC********#
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType
			, InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDirect, Remark)
	SELECT 	DISTINCT 
			tmpCp.CustID
		, 	tmpCp.CTSCustID
		, 	NULL  AS CategoryID
		, 	CONST_PA_SPORTGROUP
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpCp.CreatedBy AS LastModifiedBy
		, 	CONST_ACTIONTYPE_REMOVE AS ActionType
		, 	DATE(lv_CurrentDateTime) AS InsertDate
		, 	NULL AS TargetCC
		, 	(CASE WHEN tmpCp.IsDirectPA = 1 THEN 33 
					WHEN tmpCp.IsDirectPA = 0 THEN 34 END) AS SourceTypeID
		,  	1 AS IsDataChanged
		,	NULL AS TargetDangerLevel1
		,	NULL AS TurnoverRM
		,	NULL AS WinlossRM
		, 	NULL AS BetCount
		, 	NULL AS ActiveDays
        ,	NULL AS IsDirectPA
        ,	tmpCp.Remark
	FROM Temp_CustPA AS tmpCp
    WHERE tmpCp.IsRemovedPA = 1;

   #******INSERT LOG FOR ALL ******#
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType
			, InsertDate, TargetCC, SourceTypeID, IsDataChanged,  TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDirect)
	SELECT 	DISTINCT 
			tmpCp.CustID
		, 	tmpCp.CTSCustID
		, 	NULL AS CategoryID
		, 	CONST_PA_SPORTGROUP
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpCp.CreatedBy AS LastModifiedBy
		, 	CONST_ACTIONTYPE_REMOVE AS ActionType
		, 	DATE(lv_CurrentDateTime) AS InsertDate
		, 	NULL AS TargetCC
		, 	(CASE WHEN IsDirectPA = 1 THEN 33 
					WHEN IsDirectPA = 0 THEN 34 END) AS SourceTypeID
		,  	1 AS IsDataChanged
		,	NULL AS TargetDangerLevel1
		,	NULL AS TurnoverRM
		,	NULL AS WinlossRM
		, 	NULL AS BetCount
		, 	NULL AS ActiveDays
        ,	NULL AS IsDirectPA
	FROM Temp_InputCust AS tmpCp;

	#RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS #
	SELECT	DISTINCT 
			tmpCp.CustID
		,	tmpCp.CTSCustID
        ,	tmpCp.IsRemovedPA
    FROM Temp_InputCust AS tmpCp; 
	
END$$
DELIMITER ;