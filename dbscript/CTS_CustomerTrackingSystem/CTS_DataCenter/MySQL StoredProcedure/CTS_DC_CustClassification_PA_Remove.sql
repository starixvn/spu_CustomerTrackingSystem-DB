/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_PA_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_Remove`(
		IN ip_IsFromQueue			BOOLEAN
	,	IN ip_ExceptDirectDownline 	BOOLEAN
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
	
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_Remove(0,0,'[{"CustID": 456, "CTSCustID": 324557, "RoleID": 4, "SubscriberID": 2, "CreatedBy": 8, "IsExceptDirectDownline": 0}]',@op_ErrorMessage);
            
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
        ,	IsPA					BOOLEAN DEFAULT NULL
        
        ,	PRIMARY KEY PK_Temp_InputCust(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_PACust;
    CREATE TEMPORARY TABLE Temp_PACust(
		CustID INT UNSIGNED PRIMARY KEY
        , IsDirectPA BOOLEAN DEFAULT NULL
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
	)) AS tmpJs;
    
    INSERT IGNORE INTO Temp_PACust(CustID, IsDirectPA)
    SELECT tmpPa.CustID
		,	tmpPa.IsDirectPA
    FROM Temp_InputCust AS tmpPa,
    LATERAL (	SELECT CustID
				FROM CTS_DataCenter.CTSCustomerClassification AS cls 
				WHERE cls.CustID = tmpPa.CustID AND cls.SportGroupID = CONST_PA_SPORTGROUP
			) AS tmpCls;
			
	UPDATE Temp_InputCust AS tmpIc
    INNER JOIN Temp_PACust AS tmpPA ON tmpIc.CustID = tmpPA.CustID
    SET tmpIc.IsPA = 1;
	#===========================================================
    INSERT INTO Temp_EvidencePA(EvidenceID)
    SELECT DISTINCT cat.EvidenceID_Credit
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE EvidenceID_Credit IS NOT NULL;
    
	INSERT IGNORE INTO Temp_EvidencePA(EvidenceID) 
    SELECT DISTINCT cat.EvidenceID_Licensee
    FROM CTS_DataCenter.CustomerCategory AS cat
    WHERE cat.EvidenceID_Licensee IS NOT NULL;

    #==============================================================    
    INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueRemove(CTSCustID, EvidenceID, Created)
    SELECT tmpPA.CTSCustID
		,	ce.EvidenceID
        ,	lv_CurrentDateTime
    FROM CTS_DataCenter.CustEvidence AS ce
		INNER JOIN Temp_InputCust AS tmpPA ON ce.CTSCustID = tmpPA.CTSCustID AND ce.Level = 0
        INNER JOIN Temp_EvidencePA AS tmpEp ON ce.EvidenceID = tmpEp.EvidenceID;    
	
    UPDATE CTS_DataCenter.RobotDetection AS rd
		INNER JOIN Temp_InputCust AS tmpPA ON rd.CustID = tmpPA.CustID
	SET rd.IsDisabled = 1;

    DELETE ce
    FROM CTS_DataCenter.CustEvidence AS ce
		INNER JOIN Temp_InputCust AS tmpPA ON ce.CTSCustID = tmpPA.CTSCustID
        INNER JOIN Temp_EvidencePA AS tmpEp ON ce.EvidenceID = tmpEp.EvidenceID;    
    
	IF(ip_IsFromQueue = 0) THEN
		/* INSERT SMA PA TO QUEUE PA AS */

		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationQueue(CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, LastDownlineCTSCustID, ActionType, InsertTime, IsExceptDirectDownline)
		SELECT tmpPA.CTSCustID
			,	tmpPA.CustID
			,	tmpPA.RoleID
			,	tmpPA.SubscriberID
			,	tmpPA.CreatedBy
			,	tmpPA.Remark    
			,	0 AS LastDownlineCTSCustID
			,	4 AS ActionType # 4: UnMark PA, 3: Mark PA
			,	lv_CurrentDateTime AS InsertTime
            , 	tmpPA.IsExceptDirectDownline
		FROM Temp_InputCust AS tmpPA
		WHERE tmpPA.RoleID > 1;              

		/* WRITE USER LOG IF FROM PAM*/
         SELECT CreatedBy, IsExceptDirectDownline
         INTO lv_CreatedBy, lv_IsExceptDirectDownline
         FROM Temp_InputCust AS tmpPA LIMIT 1;

         IF (lv_CreatedBy IS NOT NULL) THEN
			 SELECT LEFT(CONCAT('CustNo.:',COUNT(1),'_IsExceptDirectDL:',lv_IsExceptDirectDownline,'_CustList',GROUP_CONCAT(DISTINCT CTSCustID)),500)
			 INTO lv_LogInfo
			 FROM Temp_InputCust AS tmpPA;
             
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
		INNER JOIN Temp_InputCust AS tmpPA ON cls.CustID = tmpPA.CustID AND cls.SportGroupID = CONST_PA_SPORTGROUP
	WHERE tmpPA.IsPA = 1;

    /**********INSERT LOG FOR IsDataChange: CategoryID OR CC********/  
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType
			, InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDirect, Remark)
	SELECT 	DISTINCT 
			tmpPA.CustID
		, 	tmpPA.CTSCustID
		, 	NULL  AS CategoryID
		, 	CONST_PA_SPORTGROUP
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpPA.CreatedBy AS LastModifiedBy
		, 	CONST_ACTIONTYPE_REMOVE AS ActionType
		, 	DATE(lv_CurrentDateTime) AS InsertDate
		, 	NULL AS TargetCC
		, 	(CASE WHEN tmpPA.IsDirectPA = 1 THEN 33 
					WHEN tmpPA.IsDirectPA = 0 THEN 34 END) AS SourceTypeID
		,  	1 AS IsDataChanged
		,	NULL AS TargetDangerLevel1
		,	NULL AS TurnoverRM
		,	NULL AS WinlossRM
		, 	NULL AS BetCount
		, 	NULL AS ActiveDays
        ,	NULL AS IsDirectPA
        ,	tmpPA.Remark
	FROM Temp_InputCust AS tmpPA
    WHERE tmpPA.IsPA = 1;

    /******INSERT LOG FOR ALL ******/
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType
			, InsertDate, TargetCC, SourceTypeID, IsDataChanged,  TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDirect)
	SELECT 	DISTINCT 
			tmpPA.CustID
		, 	tmpPA.CTSCustID
		, 	NULL AS CategoryID
		, 	CONST_PA_SPORTGROUP
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpPA.CreatedBy AS LastModifiedBy
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
	FROM Temp_InputCust AS tmpPA;
    
	/*RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS */
	SELECT	DISTINCT 
			tmpPA.CustID
		,	tmpPA.CTSCustID
    FROM Temp_InputCust AS tmpPA; 
 
END$$
DELIMITER ;