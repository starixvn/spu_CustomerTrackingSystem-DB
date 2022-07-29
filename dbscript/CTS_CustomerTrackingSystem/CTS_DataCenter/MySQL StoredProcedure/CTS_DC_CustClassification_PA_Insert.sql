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
            - 20220801@Long.Luu: Fix cannot rescan Normal when removing PA(Losing)  [Redmine ID: #176163]
            - 20220713@Casey.Huynh: Switching for Licensee VIP & BA Categories [Redmine ID: #174219]
            
        Param's Explanation (filtered by):
			- ip_InputType: 1: Category, 2: Reason
        Example:
			
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_Insert('Category',0,'[
					{"CustID":3679910,"CTSCustID":16,"RoleID":1,"SubscriberID":130,"IsLicensee":1,"IsDirectPA":1,"IsFromTVS":0,"IsFromTW":0, "IsFromPAM":1,"IsRobot":0,"CategoryID":92,"CategoryGroup":92,"Remark":"Na test"
					,"CreatedBy":10278938,"WinlossStatus":0,"TurnoverRM":20000,"WinlossRM":-11000,"BetCount":100,"ActiveDays":10}]');
	*/   

    DECLARE lv_CurrentDateTime				DATETIME DEFAULT CURRENT_TIME(); 
    DECLARE	CONST_SPORTGROUP_PA 			TINYINT DEFAULT 0;
    DECLARE CONST_ACTIONTYPE_INSERT 		INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 		INT DEFAULT 1;
    DECLARE CONST_SPORTGROUP_NORMAL 		INT DEFAULT 200;
    DECLARE CONST_USERLOG_LOGTYPE 			SMALLINT DEFAULT 32;
    DECLARE CONST_SPNAME 					VARCHAR(100) DEFAULT 'CTS_DC_CustClassification_PA_Insert';
	DECLARE CONST_LICVIPPROBLEM_CATEGORYID	SMALLINT UNSIGNED DEFAULT 3;
	DECLARE CONST_LICVIPNORMAL_CATEGORYID	SMALLINT UNSIGNED DEFAULT 4;    
    
	DECLARE lv_LicVIPProblem_CC				SMALLINT UNSIGNED;
	DECLARE lv_LicVIPNormal_CC				SMALLINT UNSIGNED; 
    DECLARE lv_LicVIP_CategoryID			SMALLINT UNSIGNED;
    DECLARE lv_LicVIP_CC					SMALLINT UNSIGNED;
    DECLARE lv_LogInfo 						VARCHAR(500);
	DECLARE lv_CreatedBy 					INT UNSIGNED;
    DECLARE lv_NoOfCust 					INT;
    
	INSERT INTO CTS_Log.CTSDebugLog(SPName, InsertTime, OtherText, JsonString1)
    SELECT CONST_SPNAME, CURRENT_TIME(),CONCAT(ip_InputType,',',ip_IsToQueue), ip_ProblemAccounts;
    
    SELECT cat.CustomerClass
	INTO lv_LicVIPProblem_CC
	FROM CTS_DataCenter.CustomerCategory AS cat
	WHERE cat.CategoryID = CONST_LICVIPPROBLEM_CATEGORYID;
	
	SELECT cat.CustomerClass
	INTO lv_LicVIPNormal_CC
	FROM CTS_DataCenter.CustomerCategory AS cat
	WHERE cat.CategoryID = CONST_LICVIPNORMAL_CATEGORYID;
    
	
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistPA ;
    CREATE TEMPORARY TABLE Temp_ExistPA(		
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
        ,	CustomerClass			INT
        ,	Priority				INT
        ,	PRIMARY KEY PK_Temp_ExistPA_CustID(CustID, CategoryID)
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
    
        
    DROP TEMPORARY TABLE IF EXISTS Temp_LastHistory;
    CREATE TEMPORARY TABLE Temp_LastHistory(
			CustID		INT UNSIGNED PRIMARY KEY
        ,	CategoryID	SMALLINT UNSIGNED
        ,	TargetCC	SMALLINT UNSIGNED
	);
    
    #================Mapping Category================
    CALL CTS_DC_CustClassification_PA_MappingCategory(ip_InputType,ip_ProblemAccounts);
    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationOldPA(CustID, CTSCustID, SubscriberID, SportGroupID, CategoryID, Remark, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy
		, LastScannedDate, IsFromTVS, IsFromTW, IsFromCTS, IsDirect, InsertTime, TVSRequestID) 
    SELECT	tmpPa.CustID
		,	tmpPa.CTSCustID
        ,	tmpPa.SubscriberID
        ,	CONST_SPORTGROUP_PA AS SportGroupID
        ,	tmpPa.CategoryID
        ,	tmpPa.Remark
        ,	NOW() AS CreatedDate
        ,	tmpPa.CreatedBy
        ,	NOW() AS LastModifiedDate
        ,	tmpPa.CreatedBy AS LastModifiedBy
        ,	NOW() AS LastScannedDate
        ,	tmpPa.IsFromTVS
        ,	tmpPa.IsFromTW
        ,	tmpPa.IsFromCTS
        ,	tmpPa.IsDirectPA
        ,	CURRENT_TIMESTAMP(3) AS InsertTime
        ,	tmpPa.TVSRequestID
	FROM Temp_PA AS tmpPa
	WHERE tmpPa.PinCTSCustID IS NOT NULL; 
    
    DELETE tmpPa
    FROM Temp_PA AS tmpPa
    WHERE tmpPa.PinCTSCustID IS NOT NULL; 
    
	INSERT IGNORE INTO Temp_CustProbationStatus(CustID, CTSCustID, TurnoverRM, WinlossRM, BetCount, ActiveDays, IsProbation, WinlossStatus, IsLicensee)
    SELECT DISTINCT tmpPa.CustID
		,	tmpPa.CTSCustID
		,	tmpPa.TurnoverRM
		,	tmpPa.WinlossRM
        ,	tmpPa.BetCount
        ,	tmpPa.ActiveDays
        ,	(CASE 	WHEN tmpPa.WinlossStatus = 0 THEN 1
					ELSE 0 END) AS IsProbation
		,	tmpPa.WinlossStatus
        ,	tmpPa.IsLicensee
	FROM Temp_PA AS tmpPa;
    
    #=============REMOVE GENERAL CATEGORY BEFORE=============
    DELETE clss
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS tmpPa ON tmpPa.CustID = clss.CustID AND clss.SportGroupID = CONST_SPORTGROUP_NORMAL;       
	#WHERE NOT EXISTS (SELECT 1 FROM Temp_WrapperCategory AS tmpWr WHERE tmpWr.CategoryID = cls.CategoryID);
    
    #=============REMOVE PA PROBATION LIST WHEN IsProbation = 0=============
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		INNER JOIN Temp_PA AS tmpPa ON tmpPa.CustID = pro.CustID;
    
    #=============GET EXISTING CATEGORY=============   
    INSERT IGNORE INTO Temp_ExistPA(CustID, CTSCustID, ExistCategoryID, CategoryID, CategoryGroup, IsProbation, LastModifiedDate, CreatedBy, Remark
			, IsDirectPA, TVSRequestID, IsFromTVS, IsFromTW, IsFromCTS, RelevantCategoryID, IsFromOldPA, SpecialCC, CustomerClass, Priority)
    SELECT	tmpPa.CustID
		,	tmpPa.CTSCustID
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
        ,	tmpPa.SpecialCC 
        ,	cat.CustomerClass
        ,	cat.Priority
    FROM Temp_PA AS tmpPa
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON tmpPa.CustID = cls.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID
	WHERE cls.SportGroupID = CONST_SPORTGROUP_PA;
    
    UPDATE Temp_PA AS tmpPa
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationOldPA AS cls ON tmpPa.CustID = cls.CustID 
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID 
	SET tmpPa.IsFromOldPA = 1, tmpPa.IsDataChanged = 1;
    
    #=======UPDATE IF Change Probation Status: DataChangeType = 1 AND IsDataChanged = 1=============
	UPDATE Temp_PA AS tmpPa
		LEFT JOIN Temp_ExistPA AS tmpEc ON tmpPa.CustID = tmpEc.CustID AND tmpPa.CategoryGroup = tmpEc.CategoryGroup
    SET tmpPa.IsDataChanged = 1
    WHERE tmpPa.IsDataChanged = 0 AND tmpEc.CustID IS NULL;
    
    UPDATE Temp_PA AS tmpPa
		INNER JOIN Temp_ExistPA AS tmpEc ON tmpPa.RelevantCategoryGroup = tmpEc.CategoryGroup AND tmpPa.CustID = tmpEc.CustID # AND tmpEc.IsFromOldPA = 0
	SET 	tmpPa.DataChangeType = 1 #(CASE WHEN tmpPa.WinlossStatus = 1 THEN 2 ELSE 1 END)
		,	tmpPa.IsDataChanged = 1 # (CASE WHEN tmpPa.WinlossStatus = 1 THEN 0 ELSE 1 END)
        ,	tmpPa.OldCategoryID = tmpEc.ExistCategoryID
        ,	tmpPa.LastModifiedDate = IFNULL(tmpPa.LastModifiedDate,tmpEc.LastModifiedDate)
        ,	tmpPa.ActionType = CONST_ACTIONTYPE_UPDATE
        ,	tmpPa.CreatedBy = tmpEc.CreatedBy;  

    DELETE tmpEc
    FROM Temp_ExistPA AS tmpEc
		INNER JOIN Temp_PA AS tmpPa ON tmpPa.RelevantCategoryGroup = tmpEc.CategoryGroup AND tmpPa.WinlossStatus <> 1 AND tmpEc.IsFromOldPA = 0;

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
		FROM Temp_ExistPA AS tmpEc
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
        INNER JOIN Temp_PA AS tmpPa ON cls.CustID = tmpPa.CustID AND cls.CategoryID = tmpPa.OldCategoryID AND tmpPa.DataChangeType = 1
	SET 	cls.CTSCustID = tmpPa.CTSCustID
		,	cls.CategoryID =  tmpPa.CategoryID
		, 	cls.LastScannedDate = DATE(lv_CurrentDateTime);
	
    #================COVER WRAPER CC (VIP)================
    DROP TEMPORARY TABLE IF EXISTS Temp_VIPCust;
    CREATE TEMPORARY TABLE Temp_VIPCust(
			CustID			INT UNSIGNED
		,	CategoryID 		SMALLINT UNSIGNED
        ,	CustomerClass 	SMALLINT UNSIGNED
        ,	IsChanged		TINYINT(1)
		,	PRIMARY KEY Temp_WrapCC(CustID)
	);    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_WraperCC;
    CREATE TEMPORARY TABLE Temp_WraperCC(
			CustID				INT UNSIGNED
		,	LicVIP_CategoryID 	SMALLINT UNSIGNED
        ,	LicVIP_CC 			SMALLINT UNSIGNED
		,	PRIMARY KEY Temp_WrapCC(CustID)
	);  
    
    INSERT IGNORE INTO Temp_WraperCC(CustID, LicVIP_CategoryID, LicVIP_CC)
	SELECT	tmpPa.CustID
		,	(CASE WHEN cat.IsDangerProbation = 1 THEN CONST_LICVIPNORMAL_CATEGORYID ELSE CONST_LICVIPPROBLEM_CATEGORYID END)
		,	(CASE WHEN cat.IsDangerProbation = 1 THEN lv_LicVIPNormal_CC ELSE lv_LicVIPProblem_CC END)	
    FROM Temp_PA AS tmpPa 
		INNER JOIN CustomerCategory AS cat ON tmpPa.CategoryID = cat.CategoryID;
    
	INSERT IGNORE INTO Temp_VIPCust(CustID, CategoryID, CustomerClass, IsChanged)
    SELECT	cus.CustID
		,	tmp_Wr.LicVIP_CategoryID
		,	tmp_Wr.LicVIP_CC
        ,	(CASE WHEN (cls.CategoryID = lv_LicVIP_CategoryID) THEN 0 ELSE 1 END)
	FROM Temp_PA AS tmpPa
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpPa.CTSCustID = cus.CTSCustID AND cus.IsLicenseeVIP = 1
        INNER JOIN Temp_WraperCC AS tmp_Wr ON tmp_Wr.CustID = tmpPa.CustID
		LEFT JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON cls.CustID = tmpPa.CustID AND cls.CategoryID IN (CONST_LICVIPPROBLEM_CATEGORYID, CONST_LICVIPNORMAL_CATEGORYID);    

    UPDATE CTS_DataCenter.CTSCustomerClassification AS cls
		INNER JOIN Temp_VIPCust AS tmpVip ON cls.CustID = tmpVip.CustID AND tmpVip.IsChanged = 1
	SET cls.CategoryID = tmpVip.CategoryID
	WHERE cls.CategoryID IN (CONST_LICVIPPROBLEM_CATEGORYID, CONST_LICVIPNORMAL_CATEGORYID);
        
	UPDATE Temp_PA AS tmpPa 
		INNER JOIN Temp_VIPCust AS tmpVip ON tmpPa.CustID = tmpVip.CustID
	SET tmpPa.TargetCC = tmpVip.CustomerClass
    WHERE tmpPa.SpecialCC IS NULL;
	
    INSERT IGNORE INTO Temp_LastHistory(CustID, CategoryID, TargetCC)
    SELECT tmpPa.CustID, tmpHis.CategoryID, tmpHis.TargetCC
    FROM Temp_PA AS tmpPa,
    LATERAL (	SELECT h.CategoryID, h.TargetCC
				FROM CTS_DataCenter.CTSCustomerClassification_History AS h
                WHERE h.CustID = tmpPa.CustID 
                ORDER BY ID DESC
                LIMIT 1) AS tmpHis;
                
	UPDATE Temp_PA AS tmpPA
		INNER JOIN Temp_LastHistory AS tmpHis ON tmpPA.CustID = tmpHis.CustID
	SET tmpPA.IsDataChanged = 1
	WHERE tmpPA.CategoryGroup <> tmpHis.CategoryID OR tmpPA.TargetCC <> tmpHis.TargetCC; 
    
    #============INSERT NEW PA=================================    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
			CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsDirect, Remark, IsFromCTS, IsFromTVS, IsFromTW, TVSRequestID)
	SELECT 	tmpPa.CustID
		,	tmpPa.CTSCustID
		, 	tmpPa.SubscriberID
		, 	tmpPa.CategoryGroup AS CategoryID
		, 	CONST_SPORTGROUP_PA AS SportGroupID
		, 	NOW()
		, 	tmpPa.CreatedBy
		, 	IFNULL(tmpPa.LastModifiedDate, NOW()) AS LastModifiedDate
		, 	tmpPa.CreatedBy AS LastModifiedBy
		, 	NOW() AS LastScannedDate
        ,	tmpPa.IsDirectPA
        ,	tmpPa.Remark
        ,	tmpPa.IsFromCTS
        ,	tmpPa.IsFromTVS
        ,	tmpPa.IsFromTW
        ,	tmpPa.TVSRequestID
	FROM Temp_PA AS tmpPa
    WHERE tmpPa.DataChangeType = 0 OR tmpPa.IsFromOldPA = 1;   
  
    #=============INSERT HISTORY WHERE Category CHANGE OR Special Remove==================================================
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType
			, InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDirect, Remark, TVSRequestID, IsFromTVS, IsFromTW, IsFromCTS )
	SELECT 	tmpPa.CustID
		, 	tmpPa.CTSCustID
		, 	tmpPa.CategoryID
		, 	CONST_SPORTGROUP_PA AS SportGroupID
		, 	NOW() AS LastModifiedDate
		, 	tmpPa.CreatedBy AS LastModifiedBy
		, 	tmpPa.ActionType
		, 	NOW() AS InsertDate
		, 	tmpPa.TargetCC
		, 	(CASE	WHEN tmpPa.MatchID IS NOT NULL THEN 35
					WHEN tmpPa.IsDirectPA = 1 THEN 31 
					WHEN tmpPa.IsDirectPA = 0 THEN 32 END) AS SourceTypeID
		,  	1 AS IsDataChanged
		,	tmpPa.TargetDangerLevel AS TargetDangerLevel1
		,	tmpPa.TurnoverRM
		,	tmpPa.WinlossRM
		, 	tmpPa.BetCount
		, 	tmpPa.ActiveDays
        ,	tmpPa.IsDirectPA
        ,	tmpPa.Remark
        ,	tmpPa.TVSRequestID
        ,	tmpPa.IsFromTVS
        ,	tmpPa.IsFromTW
        ,	tmpPa.IsFromCTS
	FROM Temp_PA AS tmpPa
	WHERE tmpPa.IsDataChanged = 1 #OR (tmpPa.DataChangeType = 0)
    ORDER BY tmpPa.LastModifiedDate ASC, tmpPa.CategoryID ASC;

	INSERT INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate
		, TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDirect, Remark, TVSRequestID, IsFromTVS, IsFromTW, IsFromCTS)
	SELECT 		tmpPa.CustID
		,	tmpPa.CTSCustID
		,	tmpPa.CategoryID
		,	CONST_SPORTGROUP_PA AS SportGroupID
		,	IFNULL(tmpPa.LastModifiedDate,NOW())
		,	tmpPa.CreatedBy AS LastModifiedBy
		,	tmpPa.ActionType
		,	1 AS IsAuto 
		,	NOW() AS InsertDate
		,	tmpPa.TargetCC
		,	(CASE WHEN IsDirectPA = 1 THEN 31 
					WHEN IsDirectPA = 0 THEN 32 END) AS SourceTypeID
		,	tmpPa.IsDataChanged
		,	tmpPa.TargetDangerLevel
		,	tmpPa.TurnoverRM
		,	tmpPa.WinlossRM
		,	tmpPa.BetCount
		,	tmpPa.ActiveDays
		,	tmpPa.IsDirectPA
        ,	tmpPa.Remark
		,	tmpPa.TVSRequestID
        ,	tmpPa.IsFromTVS
        ,	tmpPa.IsFromTW
        ,	tmpPa.IsFromCTS
	FROM Temp_PA AS tmpPa;

    IF (ip_IsToQueue = 1) THEN
    
		# INSERT SMA PA TO QUEUE PA AS 
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationQueue(CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, CategoryID, CategoryGroup, LastDownlineCTSCustID
			, IsFromTVS, IsFromTW, IsFromCTS, ActionType, InsertTime)
		SELECT tmpPa.CTSCustID
			,	tmpPa.CustID
			,	tmpPa.RoleID
			,	tmpPa.SubscriberID
			,	tmpPa.CreatedBy
			,	tmpPa.Remark        
			,	tmpPa.CategoryID
			,	tmpPa.CategoryGroup
			,	0 AS LastDownlineCTSCustID
            ,	tmpPa.IsFromTVS AS IsFromTVS
            ,	tmpPa.IsFromTW AS IsFromTW
            ,	tmpPa.IsFromCTS AS IsFromCTS
			,	3 AS ActionType # 0: Mark PA
			,	CURRENT_TIMESTAMP(3) AS InsertTime
		FROM Temp_PA AS tmpPa        
		WHERE tmpPa.RoleID > 1
        ORDER BY tmpPa.LastModifiedDate, tmpPa.CategoryID;

		# WRITE USER LOG IF FROM PAM
         SELECT CreatedBy 
         INTO lv_CreatedBy
         FROM Temp_PA AS tmpPa WHERE IsFromCTS = 1 LIMIT 1;

         IF (lv_CreatedBy IS NOT NULL) THEN
			 SELECT LEFT(CONCAT('CustNo.:',COUNT(1),'_',GROUP_CONCAT(DISTINCT CTSCustID)),500)
			 INTO lv_LogInfo
			 FROM Temp_PA AS tmpPa;
             
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
    SELECT tmpPa.CTSCustID
		,	tmpPa.ToEvidenceID
		,	tmpPa.Remark
        ,	0 AS `Level`
        ,	tmpPa.CTSCustID
        ,	lv_CurrentDateTime AS CreatedDate
        ,	tmpPa.CreatedBy
    FROM Temp_PA AS tmpPa    
    WHERE (tmpPa.ToEvidenceID <> 0) AND (tmpPa.ToEvidenceID IS NOT NULL);
    #========INSERT EVIDENCE QUEUE=========
	 INSERT IGNORE INTO CTS_DataCenter.CustEvidenceAffectedQueueInsert(CTSCustID, EvidenceID, Remark, CreatedBy, Created)
	 SELECT tmpPa.CTSCustID
		,	tmpPa.ToEvidenceID
		,	tmpPa.Remark
        ,	tmpPa.CreatedBy
        ,	lv_CurrentDateTime AS CreatedDate
	FROM Temp_PA AS tmpPa
	WHERE tmpPa.DataChangeType = 0 OR tmpPa.IsFromOldPA = 1;  

	#=====RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS===========
	SELECT	DISTINCT 
			tmpPa.CustID
		,	tmpPa.CTSCustID
    FROM Temp_PA AS tmpPa; 

	# INSERT INTO CTS_Log.CTSDebugLog(SPName, InsertTime, OtherText, JsonString1)
    # SELECT 'CTS_DC_CustClassification_PA_Insert_DEBUG', CURRENT_TIMESTAMP(4), CONCAT('ip_InputType:',ip_InputType,' ,ip_IsToQueue:',ip_IsToQueue),ip_ProblemAccounts;
    
END$$
DELIMITER ;