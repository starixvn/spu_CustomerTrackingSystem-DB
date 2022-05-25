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
			
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_Insert('[{"CustID": 456, "ReasonID": 59, "RobotCounter": 0}]',0,@op_ErrorMessage);
	*/ 
    DECLARE lv_CurrentDateTime	DATETIME DEFAULT CURRENT_TIME(); 
    DECLARE	CONST_PA_SPORTGROUP TINYINT DEFAULT 0;
    DECLARE CONST_ACTIONTYPE_REMOVE INT DEFAULT 0;
    DECLARE CONST_NORMAL_SPORTGROUP INT DEFAULT 200;
    DECLARE CONST_USERLOG_LOGTYPE SMALLINT DEFAULT 33;
    DECLARE CONST_SPNAME VARCHAR(100) DEFAULT 'CTS_DC_CustClassification_PA_Remove';
    DECLARE lv_LogInfo VARCHAR(500);
	DECLARE lv_CreatedBy INT UNSIGNED;
    DECLARE lv_NoOfCust INT;

    DROP TEMPORARY TABLE IF EXISTS Temp_PA;    
	CREATE TEMPORARY TABLE Temp_PA(
			CustID					BIGINT UNSIGNED 
		, 	CTSCustID				BIGINT UNSIGNED DEFAULT 0
        ,	RoleID					INT
        , 	SubscriberID			INT DEFAULT 0
        ,	Remark 					VARCHAR(500)        
        ,	CreatedBy 				INT UNSIGNED
        ,	IsExceptDirectDownline	BOOLEAN DEFAULT 0
        ,	IsPA					BOOLEAN DEFAULT 0
        
        ,	PRIMARY KEY PK_Temp_PA(CustID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_EvidencePA;
    CREATE TEMPORARY TABLE Temp_EvidencePA(
			EvidenceID SMALLINT
        ,	PRIMARY KEY PK_Temp_EvidencePA(EvidenceID)
    );    
    
	INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, RoleID, SubscriberID, CreatedBy, Remark, IsExceptDirectDownline, IsPA)
	SELECT 	DISTINCT tmpJs.CustID
		,	tmpJs.CTSCustID
		,	tmpJs.RoleID
        ,	tmpJs.SubscriberID
		,	tmpJs.CreatedBy 
		,	tmpJs.Remark
		,	tmpJs.IsExceptDirectDownline
        ,	tmpPa.IsPA
	FROM JSON_TABLE(ip_ProblemAccounts,
		"$[*]" COLUMNS(			
				CustID 					INT UNSIGNED		PATH "$.CustID"
			, 	CTSCustID				INT UNSIGNED 		PATH "$.CTSCustID"
            ,   RoleID 					BIGINT UNSIGNED		PATH "$.RoleID"
            ,   SubscriberID 			BIGINT UNSIGNED		PATH "$.SubscriberID"
			, 	CreatedBy				INT UNSIGNED		PATH "$.CreatedBy"
			, 	Remark					VARCHAR(500)		PATH "$.Remark"
			, 	IsExceptDirectDownline	BOOLEAN 			PATH "$.IsExceptDirectDownline"
	)) AS tmpJs,
    LATERAL (
				SELECT 1 AS IsPA
                FROM CTS_DataCenter.CTSCustomerClassification AS cls
				WHERE tmpJs.CustID = cls.CustID AND cls.SportGroupID = CONST_PA_SPORTGROUP
			) AS tmpPa;   

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
    DELETE cls
    FROM CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_PA AS tmpPA ON cls.CustID = tmpPA.CustID AND cls.SportGroupID = CONST_PA_SPORTGROUP
	WHERE tmpPA.IsPA = 1;
	
    UPDATE CTS_DataCenter.RobotDetection AS rd
		INNER JOIN Temp_PA AS tmpPA ON rd.CustID = tmpPA.CustID
	SET rd.IsDisabled = 1;
    
    DELETE ce
    FROM CTS_DataCenter.CustEvidence AS ce
		INNER JOIN Temp_PA AS tmpPA ON ce.CTSCustID = tmpPA.CTSCustID
        INNER JOIN Temp_EvidencePA AS tmpEp ON ce.EvidenceID = tmpEp.EvidenceID;     
    
	INSERT INTO CTS_DataCenter.CustEvidenceAffectedQueueRemove(CTSCustID, EvidenceID, Created)
    SELECT tmpPA.CTSCustID
		,	ce.EvidenceID
        ,	lv_CurrentDateTime
    FROM CTS_DataCenter.CustEvidence AS ce
		INNER JOIN Temp_PA AS tmpPA ON ce.CTSCustID = tmpPA.CTSCustID
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
		FROM Temp_PA AS tmpPA
		WHERE tmpPA.RoleID > 1;              
        
		/* WRITE USER LOG IF FROM PAM*/
         SELECT CreatedBy 
         INTO lv_CreatedBy
         FROM Temp_PA AS tmpPA LIMIT 1;

         IF (lv_CreatedBy IS NOT NULL) THEN
			 SELECT LEFT(CONCAT('CustNo.:',COUNT(1),'_IsExceptDirectDownline:',IsExceptDirectDownline,'_',GROUP_CONCAT(DISTINCT CTSCustID)),500)
			 INTO lv_LogInfo
			 FROM Temp_PA AS tmpPA;
             
		 INSERT IGNORE INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		 SELECT CONST_USERLOG_LOGTYPE AS LogTypeID
			,	CONST_SPNAME AS SPName
			,	lv_LogInfo AS LogInfo
			,	DATE(lv_CurrentDateTime) AS CreatedDate
			,	lv_CreatedBy AS CreatedBy;        
        END IF;    
        
	END IF;
    
	/* 19: RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS */
	SELECT	DISTINCT 
			tmpPA.CustID
		,	tmpPA.CTSCustID
    FROM Temp_PA AS tmpPA; 
 
END$$
DELIMITER ;