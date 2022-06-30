/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_PA_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_Insert`(
		IN ip_InputType			VARCHAR(20) 
    ,	IN ip_IsToQueue			BOOLEAN
    ,   IN ip_ProblemAccounts 	JSON
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20200715@Long.Luu
		Task:		Insert for Problem Accounts
		DB:			CTS_DataCenter
		Original:
		Revisions:
            - 20220519@Casey.Huynh: Created. Renovate PA Process [RedmineID: #172061]
            - 20220627@Casey.Huynh: Add MatchID To Remark  [Redmine ID: #174218]
        Param's Explanation (filtered by):
			- ip_InputType: 1: Category, 2: Reason
        Example:
			
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_Insert('Category',0,'[
					{"CustID":1277,"CTSCustID":83,"RoleID":1,"SubscriberID":130,"IsLicensee":1,"IsDirectPA":1,"IsFromTVS":0,"IsFromTW":0, "IsFromPAM":1,"IsRobot":0,"CategoryID":153,"CategoryGroup":53,"Remark":"Na test"
					,"CreatedBy":10278938,"WinlossStatus":0,"TurnoverRM":20000,"WinlossRM":-11000,"BetCount":100,"ActiveDays":10, "MatchID":123456789}]');
             
             SELECT * FROM Temp_PA;
             SELECT s.Remark, s.SourceTypeID, s.* FROM CTSCustomerClassification_History  s WHERE CustID = 1277 ORDER BY ID Desc;  # 1281463;
             SELECT s.Remark, s.SourceTypeID, s.* FROM CTSCustomerClassification_History  s  ORDER BY ID Desc;   
	*/   
    
    DECLARE lv_CurrentDateTime	DATETIME DEFAULT CURRENT_TIME(); 
    DECLARE	CONST_SPORTGROUP_PA TINYINT DEFAULT 0;
    DECLARE CONST_ACTIONTYPE_INSERT INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE INT DEFAULT 1;
    DECLARE CONST_SPORTGROUP_NORMAL INT DEFAULT 200;
    DECLARE CONST_USERLOG_LOGTYPE SMALLINT DEFAULT 32;
    DECLARE CONST_SPNAME VARCHAR(100) DEFAULT 'CTS_DC_CustClassification_PA_Insert';
    DECLARE lv_LogInfo VARCHAR(500);
	DECLARE lv_CreatedBy INT UNSIGNED;
    DECLARE lv_NoOfCust INT;
	
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistCategory ;
    CREATE TEMPORARY TABLE Temp_ExistCategory(		
			CustID 					INT UNSIGNED
		,	CTSCustID				BIGINT UNSIGNED
        ,	ExistCategoryID 		SMALLINT UNSIGNED
		,	CategoryID 				SMALLINT UNSIGNED
        ,	CategoryGroup			SMALLINT UNSIGNED
        ,	TargetCC				SMALLINT
		,	TargetDangerLevel		SMALLINT UNSIGNED
        , 	ToEvidenceID			SMALLINT
        ,	IsProbation				BOOLEAN
        ,	RelevantCategoryID 		SMALLINT UNSIGNED
        ,	RelevantCategoryGroup	SMALLINT UNSIGNED
        ,	RelevantIsProbation		BOOLEAN
        ,	LastModifiedDate		DATETIME
        ,	CreatedBy				INT UNSIGNED
		,	Remark					VARCHAR(500)
		,	IsDirectPA				BOOLEAN
		,	IsFromTVS				BOOLEAN DEFAULT 0
        ,	IsFromTW				BOOLEAN DEFAULT 0
        ,	IsFromCTS				BOOLEAN DEFAULT 0
        ,	TVSRequestID			INT
        ,	IsFromOldPA				TINYINT(1)
        ,	SpecialCC				SMALLINT
        ,	PRIMARY KEY PK_Temp_ExistCategory_CustID(CustID, CategoryID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustProbationStatus ;
    CREATE TEMPORARY TABLE Temp_CustProbationStatus(
			CustID 					INT UNSIGNED
		,	CTSCustID 				BIGINT UNSIGNED
        ,	IsProbation				TINYINT
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT
        ,	WinlossStatus			TINYINT
		,	IsLicensee				BOOLEAN
		
        ,	PRIMARY KEY PK_Temp_CustProbationStatus_CustID(CustID)
	);    
    
    /* Mapping Category */
    CALL CTS_DC_CustClassification_PA_MappingCategory(ip_InputType,ip_ProblemAccounts);
    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationOldPA(CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
		, LastScannedDate, IsFromTVS, IsFromTW, IsFromCTS, IsDirect, InsertTime, TVSRequestID) 
    SELECT	tmpPA.CustID
		,	tmpPA.CTSCustID
        ,	tmpPA.SubscriberID
        ,	CONST_SPORTGROUP_PA AS SportGroupID
        ,	tmpPA.CategoryID
        ,	tmpPA.Remark
        ,	NOW() AS CreatedDate
        ,	tmpPA.CreatedBy
        ,	NOW() AS LastModifiedDate
        ,	tmpPA.CreatedBy AS LastModifiedBy
        ,	NOW() AS LastScannedDate
        ,	tmpPA.IsFromTVS
        ,	tmpPA.IsFromTW
        ,	tmpPA.IsFromCTS
        ,	tmpPA.IsDirectPA
        ,	CURRENT_TIMESTAMP(3) AS InsertTime
        ,	tmpPA.TVSRequestID
	FROM Temp_PA AS tmpPA
	WHERE tmpPA.PinCTSCustID IS NOT NULL; 
    
    DELETE tmpPA
    FROM Temp_PA AS tmpPA
    WHERE tmpPA.PinCTSCustID IS NOT NULL; 
    
	INSERT IGNORE INTO Temp_CustProbationStatus(CustID, CTSCustID, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsProbation, WinlossStatus, IsLicensee)
    SELECT DISTINCT tmpPA.CustID
		,	tmpPA.CTSCustID
		,	tmpPA.TurnoverRM
		,	tmpPA.WinlossRM
        ,	tmpPA.BetCount
        ,	tmpPA.ActiveDays
        ,	(CASE 	WHEN tmpPA.WinlossStatus = 0 THEN 1
					ELSE 0 END) AS IsProbation
		,	tmpPA.WinlossStatus
        ,	tmpPA.IsLicensee
	FROM Temp_PA AS tmpPA;
    
    #=============REMOVE GENERAL CATEGORY BEFORE=============
    DELETE clss
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS tmpPA ON tmpPA.CustID = clss.CustID AND clss.SportGroupID = CONST_SPORTGROUP_NORMAL;        

    #=============REMOVE PA PROBATION LIST WHEN IsProbation = 0=============
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		INNER JOIN Temp_PA AS tmpPA ON tmpPA.CustID = pro.CustID
	WHERE IsProbation = 0;
    
    #=============GET EXISTING CATEGORY=============   
    INSERT IGNORE INTO Temp_ExistCategory(CustID, CTSCustID, ExistCategoryID, CategoryID, CategoryGroup, IsProbation, LastModifiedDate, CreatedBy, Remark
			, IsDirectPA, TVSRequestID, IsFromTVS, IsFromTW, IsFromCTS, RelevantCategoryID, IsFromOldPA, SpecialCC)
    SELECT	tmpPA.CustID
		,	tmpPA.CTSCustID
        ,	cls.CategoryID AS ExistCategoryID
        ,	cat.CategoryGroup AS CategoryID
         ,	cat.CategoryGroup AS CategoryGroup
        ,	cat.IsProbation
        ,	cls.LastModifiedDate
        ,	cls.CreatedBy
        ,	cls.Remark
        , 	cls.IsDirect
        ,	cls.TVSRequestID
        ,	cls.IsFromTVS
        , 	cls.IsFromTW
        , 	cls.IsFromCTS
        ,	cat.RelevantCategoryID
        ,	0 AS IsFromOldPA
        ,	tmpPA.SpecialCC
    FROM Temp_PA AS tmpPA
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON tmpPA.CustID = cls.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID
	WHERE EXISTS (SELECT 1 FROM Temp_CustProbationStatus AS tmpCp WHERE cls.CustID = tmpCp.CustID);
    
    UPDATE Temp_PA AS tmpPA
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationOldPA AS cls ON tmpPA.CustID = cls.CustID 
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID 
	SET tmpPA.IsFromOldPA = 1, tmpPA.IsDataChanged = 1;
    
    #=======UPDATE IF Change Probation Status: DataChangeType = 1 AND IsDataChanged = 1=============
	UPDATE Temp_PA AS tmpPA
		LEFT JOIN Temp_ExistCategory AS tmpEc ON tmpPA.CustID = tmpEc.CustID AND tmpPA.CategoryGroup = tmpEc.CategoryGroup
    SET tmpPA.IsDataChanged = 1
    WHERE tmpPA.IsDataChanged = 0 AND tmpEc.CustID IS NULL;
    
    UPDATE Temp_PA AS tmpPA
		INNER JOIN Temp_ExistCategory AS tmpEc ON tmpPA.RelevantCategoryGroup = tmpEc.CategoryGroup AND tmpPA.CustID = tmpEc.CustID # AND tmpEc.IsFromOldPA = 0
	SET 	tmpPA.DataChangeType = 1 #(CASE WHEN tmpPA.WinlossStatus = 1 THEN 2 ELSE 1 END)
		,	tmpPA.IsDataChanged = 1 # (CASE WHEN tmpPA.WinlossStatus = 1 THEN 0 ELSE 1 END)
        ,	tmpPA.OldCategoryID = tmpEc.ExistCategoryID
        ,	tmpPA.LastModifiedDate = IFNULL(tmpPA.LastModifiedDate,tmpEc.LastModifiedDate)
        ,	tmpPA.ActionType = CONST_ACTIONTYPE_UPDATE
        ,	tmpPA.CreatedBy = tmpEc.CreatedBy;

    DELETE tmpEc
    FROM Temp_ExistCategory AS tmpEc
		INNER JOIN Temp_PA AS tmpPA ON tmpPA.RelevantCategoryGroup = tmpEc.CategoryGroup AND tmpPA.WinlossStatus <> 1 AND tmpEc.IsFromOldPA = 0;

    #======UPDATE IF Change Probation Status for Existing CategoryID
    INSERT INTO Temp_PA(CustID, CTSCustID, InputCategoryID, OldCategoryID, CategoryID, TargetCC,  TargetDangerLevel, ToEvidenceID, Remark, TurnoverRM, WinlossRM, BetCount, ActiveDays
				, IsDirectPA, IsFromTVS, IsFromTW, IsFromCTS, IsDataChanged, DataChangeType, LastModifiedDate, CreatedBy, IsFromOldPA, IsProbation, TVSRequestID)
	SELECT 		tmpEc.CustID
			,	tmpEc.CTSCustID
            ,	tmpEc.ExistCategoryID AS InputCategoryID
            ,	tmpEc.ExistCategoryID AS OldCategoryID
            ,	tmpLtr.CategoryGroup AS CategoryID
            ,	(CASE 	WHEN tmpEc.SpecialCC IS NOT NULL THEN tmpEc.SpecialCC ELSE IFNULL(tmpLtr.CustomerClass,-99) END) AS TargetCC
			, 	(CASE 	WHEN tmpCp.IsLicensee = 1 THEN tmpLtr.ABIDangerLevel_Licensee
						WHEN tmpCp.IsLicensee = 0 THEN tmpLtr.ABIDangerLevel_Credit END) AS TargetDangerLevel
			,	(CASE 	WHEN tmpCp.IsLicensee = 1 THEN tmpLtr.EvidenceID_Licensee
						WHEN tmpCp.IsLicensee = 0 THEN tmpLtr.EvidenceID_Credit 
						ELSE NULL END) AS ToEvidenceID
            ,	tmpEc.Remark
            ,	tmpCp.TurnoverRM
            ,	tmpCp.WinlossRM
            ,	tmpCp.BetCount
            ,	tmpCp.ActiveDays
            ,	tmpEc.IsDirectPA
            ,	tmpEc.IsFromTVS
            ,	tmpEc.IsFromTW
            ,	tmpEc.IsFromCTS
            ,	1 AS IsDataChanged
            ,	(CASE WHEN  tmpCp.WinlossStatus = NULL THEN NULL ELSE 1 END) AS DataChangeType
            ,	tmpEc.LastModifiedDate
            ,	tmpEc.CreatedBy
            ,	tmpEc.IsFromOldPA
            ,	tmpEc.IsProbation
            ,	tmpEc.TVSRequestID
		FROM Temp_ExistCategory AS tmpEc
		INNER JOIN Temp_CustProbationStatus AS tmpCp ON tmpCp.CustID = tmpEc.CustID AND tmpCp.IsProbation <> tmpEc.IsProbation AND  tmpCp.WinlossStatus <> 1 
        , LATERAL (SELECT 	cat.CategoryGroup
						,	cat.CustomerClass
                        ,	cat.ABIDangerLevel_Licensee
                        ,	cat.ABIDangerLevel_Credit
                        ,	cat.EvidenceID_Licensee
                        ,	cat.EvidenceID_Credit
					FROM CTS_DataCenter.CustomerCategory AS cat WHERE tmpEc.RelevantCategoryID = cat.CategoryID LIMIT 1) AS tmpLtr;    

	# UPDATE PA WHEN CHANGE PROBATION STATUS
    UPDATE IGNORE CTS_DataCenter.CTSCustomerClassification AS cls
        INNER JOIN Temp_PA AS tmpPA ON cls.CustID = tmpPA.CustID AND cls.CategoryID = tmpPA.OldCategoryID AND tmpPA.DataChangeType = 1
	SET 	cls.CTSCustID = tmpPA.CTSCustID
		,	cls.CategoryID =  tmpPA.CategoryID
	#	, 	cls.LastModifiedBy = tmpPA.CreatedBy
	#	,	cls.Remark = tmpPA.Remark
		, 	cls.LastScannedDate = DATE(lv_CurrentDateTime);

    #============INSERT NEW PA=================================    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
			CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsDirect, Remark, IsFromCTS, IsFromTVS, IsFromTW, TVSRequestID)
	SELECT 	tmpPA.CustID
		,	tmpPA.CTSCustID
		, 	tmpPA.SubscriberID
		, 	(CASE 	WHEN tmpPA.IsProbationStatus = 1 AND tmpPA.RelevantIsProbation = 1 THEN  tmpPA.RelevantCategoryGroup
					WHEN (tmpPA.IsProbationStatus = 0 OR tmpPA.IsProbationStatus IS NULL) THEN  tmpPA.CategoryGroup 
					ELSE tmpPA.CategoryGroup 
			END) AS CategoryID
		, 	CONST_SPORTGROUP_PA AS SportGroupID
		, 	NOW()
		, 	tmpPA.CreatedBy
		, 	IFNULL(tmpPA.LastModifiedDate, NOW()) AS LastModifiedDate
		, 	tmpPA.CreatedBy AS LastModifiedBy
		, 	NOW() AS LastScannedDate
        ,	tmpPA.IsDirectPA
        ,	tmpPA.Remark
        ,	tmpPA.IsFromCTS
        ,	tmpPA.IsFromTVS
        ,	tmpPA.IsFromTW
        ,	tmpPA.TVSRequestID
	FROM Temp_PA AS tmpPA
    WHERE tmpPA.DataChangeType = 0 OR tmpPA.IsFromOldPA = 1;   
  
    #=============INSERT HISTORY WHERE Category CHANGE OR Special Remove==================================================
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType
			, InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDirect, Remark, TVSRequestID, IsFromTVS, IsFromTW, IsFromCTS )
	SELECT 	tmpPA.CustID
		, 	tmpPA.CTSCustID
		, 	tmpPA.CategoryID
		, 	CONST_SPORTGROUP_PA AS SportGroupID
		, 	NOW() AS LastModifiedDate
		, 	tmpPA.CreatedBy AS LastModifiedBy
		, 	tmpPA.ActionType
		, 	NOW() AS InsertDate
		, 	tmpPA.TargetCC
		, 	(CASE	WHEN tmpPA.MatchID IS NOT NULL THEN 35
					WHEN tmpPA.IsDirectPA = 1 THEN 31 
					WHEN tmpPA.IsDirectPA = 0 THEN 32 END) AS SourceTypeID
		,  	1 AS IsDataChanged
		,	tmpPA.TargetDangerLevel AS TargetDangerLevel1
		,	tmpPA.TurnoverRM
		,	tmpPA.WinlossRM
		, 	tmpPA.BetCount
		, 	tmpPA.ActiveDays
        ,	tmpPA.IsDirectPA
        ,	tmpPA.Remark
        ,	tmpPA.TVSRequestID
        ,	tmpPA.IsFromTVS
        ,	tmpPA.IsFromTW
        ,	tmpPA.IsFromCTS
	FROM Temp_PA AS tmpPA
	WHERE tmpPA.IsDataChanged = 1 #OR (tmpPA.DataChangeType = 0)
    ORDER BY tmpPA.LastModifiedDate ASC, tmpPA.CategoryID ASC;

	INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate
		, TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDirect, Remark, TVSRequestID, IsFromTVS, IsFromTW, IsFromCTS)
	SELECT 		tmpPA.CustID
		,	tmpPA.CTSCustID
		,	tmpPA.CategoryID
		,	CONST_SPORTGROUP_PA AS SportGroupID
		,	IFNULL(tmpPA.LastModifiedDate,NOW())
		,	tmpPA.CreatedBy AS LastModifiedBy
		,	tmpPA.ActionType
		,	1 AS IsAuto 
		,	NOW() AS InsertDate
		,	tmpPA.TargetCC
		,	(CASE WHEN IsDirectPA = 1 THEN 31 
					WHEN IsDirectPA = 0 THEN 32 END) AS SourceTypeID
		,	tmpPA.IsDataChanged
		,	tmpPA.TargetDangerLevel
		,	tmpPA.TurnoverRM
		,	tmpPA.WinlossRM
		,	tmpPA.BetCount
		,	tmpPA.ActiveDays
		,	tmpPA.IsDirectPA
        ,	tmpPA.Remark
		,	tmpPA.TVSRequestID
        ,	tmpPA.IsFromTVS
        ,	tmpPA.IsFromTW
        ,	tmpPA.IsFromCTS
	FROM Temp_PA AS tmpPA;

    IF (ip_IsToQueue = 1) THEN
    
		# INSERT SMA PA TO QUEUE PA AS 
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationQueue(CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, CategoryID, CategoryGroup, LastDownlineCTSCustID
			, IsFromTVS, IsFromTW, IsFromCTS, ActionType, InsertTime)
		SELECT tmpPA.CTSCustID
			,	tmpPA.CustID
			,	tmpPA.RoleID
			,	tmpPA.SubscriberID
			,	tmpPA.CreatedBy
			,	tmpPA.Remark        
			,	tmpPA.CategoryID
			,	tmpPA.CategoryGroup
			,	0 AS LastDownlineCTSCustID
            ,	tmpPA.IsFromTVS AS IsFromTVS
            ,	tmpPA.IsFromTW AS IsFromTW
            ,	tmpPA.IsFromCTS AS IsFromCTS
			,	3 AS ActionType # 0: Mark PA
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_PA AS tmpPA        
		WHERE tmpPA.RoleID > 1
        ORDER BY tmpPA.LastModifiedDate, tmpPA.CategoryID;

		# WRITE USER LOG IF FROM PAM
         SELECT CreatedBy 
         INTO lv_CreatedBy
         FROM Temp_PA AS tmpPA WHERE IsFromCTS = 1 LIMIT 1;

         IF (lv_CreatedBy IS NOT NULL) THEN
			 SELECT LEFT(CONCAT('CustNo.:',COUNT(1),'_',GROUP_CONCAT(DISTINCT CTSCustID)),500)
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
   
    #====INSERT EVIDENCE FOR ROOT=========
    INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID, EvidenceID, Remark, `Level`, FromCustID,  CreatedDate, CreatedBy)
    SELECT tmpPA.CTSCustID
		,	tmpPA.ToEvidenceID
		,	tmpPA.Remark
        ,	0 AS `Level`
        ,	tmpPA.CTSCustID
        ,	lv_CurrentDateTime AS CreatedDate
        ,	tmpPA.CreatedBy
    FROM Temp_PA AS tmpPA;
    
    #========INSERT EVIDENCE QUEUE=========
	 INSERT IGNORE INTO CTS_DataCenter.CustEvidenceAffectedQueueInsert(CTSCustID, EvidenceID, Remark, CreatedBy, Created)
	 SELECT tmpPA.CTSCustID
		,	tmpPA.ToEvidenceID
		,	tmpPA.Remark
        ,	tmpPA.CreatedBy
        ,	lv_CurrentDateTime AS CreatedDate
	FROM Temp_PA AS tmpPA
	WHERE tmpPA.DataChangeType = 0 OR tmpPA.IsFromOldPA = 1;  

	#=====RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS===========
	SELECT	DISTINCT 
			tmpPA.CustID
		,	tmpPA.CTSCustID
    FROM Temp_PA AS tmpPA; 

	# INSERT INTO CTS_Log.CTSDebugLog(SPName, InsertTime, OtherText, JsonString1)
    # SELECT 'CTS_DC_CustClassification_PA_Insert_DEBUG', CURRENT_TIMESTAMP(4), CONCAT('ip_InputType:',ip_InputType,' ,ip_IsToQueue:',ip_IsToQueue),ip_ProblemAccounts;
    
END$$
DELIMITER ;