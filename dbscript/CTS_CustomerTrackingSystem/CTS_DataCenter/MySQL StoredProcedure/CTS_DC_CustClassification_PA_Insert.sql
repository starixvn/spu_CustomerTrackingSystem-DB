/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_PA_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_Insert`(
		IN ip_InputType			VARCHAR(20) 
    ,	IN ip_IsFromQueue		BOOLEAN
    ,   IN ip_ProblemAccounts 	JSON
    
    ,	OUT op_ErrorMessage 	VARCHAR(200)
)
    SQL SECURITY INVOKER

BEGIN
/*
		Created:	20200715@Long.Luu
		Task:		Insert for Problem Accounts
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20200715@Long.Luu [#136460]: Created
			- 20200828@Roger.Le [#140211]: Enhance Problem Account Category - Multiple Reason 
			- 20200908@Irena.Vo [#141020]: Exclude VVIP Customers, Pin 
            - 20201014@Irena.Vo [#141930]: Add Multi Problem Category, Remove old categoryid from NapCM
            - 20201019@Irena.Vo  [#141930]: Get distinct CustID List for lastest category
            - 20210115@Irena.Vo: Insert History Log [RedmineID: #145951]
			- 20210119@Aries.Nguyen: Write main error log - Rescan  [RedmineID: #149026]
			- 20210316@Irena.Vo: Write Robot User log more.  [RedmineID: #151374]
            - 20210419@Irena.Vo: Update Priority Robot User.  [RedmineID: #152250] 
            - 20210510@Casey.Huynh: Exclude Customer of Odd Feed Sites [Redmine ID: 154694]
            - 20210512@Casey.Huynh: Exclude Customer of Internal Account [Redmine ID: 154844]
            - 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [Redmine ID: 152965]
			- 20210625@Long.Luu: Refactor. Update logic  [Redmine ID: #157203]
			- 20210907@Long.Luu: Update Robot Users rules  [Redmine ID: #161232]
            - 20210922@Long.Luu: Split Classification History & Log  [Redmine ID: #161890]
			- 20211026@Aries.Nguyen: Archive inactive association [Redmine ID: #163087]
            - 20211116@Casey.Huynh: Sync Robot User Categories to Dangerous Setting [Redmine ID: #161665]
			- 20211115@Aries.Nguyen: Use ReasonID column instead of  DisplayOrder column [Redmine ID: #156935]
            - 20220210@Irena.Vo: Adjust logic for Update ABI Danger Level [#167746]
			- 20220214@Long.Luu: Support new category for Good & Bad Robot User [Redmine ID: #167726]
			- 20220414@Aries.Nguyen: Add new category/class for PA Probation [Redmine ID: #170468]
            - 20220519@Casey.Huynh: Renovate PA Process [RedmineID: #172061]
            
        Param's Explanation (filtered by):
			- ip_InputType: 1: Category, 2: Reason
        Example:
			
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_Insert('Category',0,'[
					{"CustID":3679910,"CTSCustID":16,"RoleID":1,"SubscriberID":130,"IsLicensee":1,"IsDirectPA":1,"IsFromTVS":0,"IsFromTW":0, "IsFromPAM":1,"IsRobot":0,"CategoryID":92,"CategoryGroup":92,"Remark":"Na test"
					,"CreatedBy":10278938,"WinlossStatus":0,"TurnoverRM":20000,"WinlossRM":-11000,"BetCount":100,"ActiveDays":10}]');
	*/   

    DECLARE lv_CurrentDateTime	DATETIME DEFAULT CURRENT_TIME(); 
    DECLARE	CONST_PA_SPORTGROUP TINYINT DEFAULT 0;
    DECLARE CONST_ACTIONTYPE_INSERT INT DEFAULT 0;
    DECLARE CONST_NORMAL_SPORTGROUP INT DEFAULT 200;
    DECLARE CONST_USERLOG_LOGTYPE SMALLINT DEFAULT 32;
    DECLARE CONST_SPNAME VARCHAR(100) DEFAULT 'CTS_DC_CustClassification_PA_Insert';
    DECLARE lv_LogInfo VARCHAR(500);
	DECLARE lv_CreatedBy INT UNSIGNED;
    DECLARE lv_NoOfCust INT;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistCategory ;
    CREATE TEMPORARY TABLE Temp_ExistCategory(		
			CustID 					INT UNSIGNED
		,	CTSCustID				BIGINT UNSIGNED
		,	CategoryID 				SMALLINT UNSIGNED
        ,	CategoryGroup			SMALLINT UNSIGNED
        ,	IsProbation				BOOLEAN
        ,	RelevantCategoryID 		SMALLINT UNSIGNED
        ,	RelevantCategoryGroup	SMALLINT UNSIGNED
        ,	RelevantIsProbation		BOOLEAN
        ,	OldCategoryID 			SMALLINT UNSIGNED
        ,	DataChangeType			TINYINT DEFAULT 0 	#0: New Category, 1:Change Pobation Status (Winloss), 2: No Change
        ,	IsFromOldPA				BOOLEAN DEFAULT 0
        ,	LastModifiedDate		DATETIME
        ,	CreatedBy				INT UNSIGNED
		,	Remark					VARCHAR(500)
		,	IsDirect				BOOLEAN			
		, 	WinlossStatus			SMALLINT /*LOSING  = 0 (PROBATION), KEEPSTATE = 1 (NOT CHANGE), WINNING = 2 (NOT PROBATION);*/
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT 
        ,	PRIMARY KEY PK_Temp_ExistCategory_CustID(CustID, CategoryID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustProbationStatus ;
    CREATE TEMPORARY TABLE Temp_CustProbationStatus(
			CustID 	INT UNSIGNED
        ,	IsProbationStatus BOOLEAN
	);
    
    

    /* Mapping Category */
    CALL CTS_DC_CustClassification_PA_MappingCategory_DEBUG1(ip_InputType,ip_ProblemAccounts);
   
    #=============REMOVE GENERAL CATEGORY BEFORE=============
    DELETE clss
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS tmpPA ON tmpPA.CustID = clss.CustID AND clss.SportGroupID = CONST_NORMAL_SPORTGROUP;        

    #=============REMOVE PA PROBATION LIST WHEN IsProbation = 0=============
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		INNER JOIN Temp_PA AS tmpPA ON tmpPA.CustID = pro.CustID
	WHERE IsProbation = 0;
    
    #=============GET EXISTING CATEGORY=============   
    INSERT IGNORE INTO Temp_ExistCategory(CustID, CTSCustID, CategoryID, CategoryGroup, IsProbation, RelevantCategoryID, LastModifiedDate
    , CreatedBy, Remark, IsDirect, WinlossStatus, TurnoverRM, WinlossRM, BetCount,ActiveDays )
    SELECT	tmpPA.CustID
		,	tmpPA.CTSCustID
        ,	cat.CategoryID
        ,	cat.CategoryGroup
        ,	cat.IsProbation
        ,	cat.RelevantCategoryID
        , 	cls.LastModifiedDate
        ,	cls.CreatedBy
        ,	tmpPA.Remark
        ,	cls.IsDirect
        ,	tmpPA.WinlossStatus
        ,	tmpPA.TurnoverRM
        ,	tmpPA.WinlossRM
		,	tmpPA.BetCount
        ,	tmpPA.ActiveDays
    FROM Temp_PA AS tmpPA
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cls ON tmpPA.CustID = cls.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID;
	
    INSERT IGNORE INTO Temp_ExistCategory(CustID, CTSCustID, CategoryID, CategoryGroup, IsProbation, RelevantCategoryID, LastModifiedDate, CreatedBy, Remark, IsDirect
		, WinlossStatus, TurnoverRM, WinlossRM, BetCount, ActiveDays)
    SELECT	tmpPA.CustID
		,	tmpPA.CTSCustID
        ,	cat.CategoryID
        ,	cat.CategoryGroup
        ,	cat.IsProbation
        ,	cat.RelevantCategoryID
        , 	cls.LastModifiedDate
        ,	cls.CreatedBy
        ,	cls.Remark
        ,	cls.IsDirect
		,	tmpPA.WinlossStatus
        ,	tmpPA.TurnoverRM
        ,	tmpPA.WinlossRM
		,	tmpPA.BetCount
        ,	tmpPA.ActiveDays
    FROM Temp_PA AS tmpPA
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationOldPA AS cls ON tmpPA.CustID = cls.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON cls.CategoryID = cat.CategoryID;
    
	UPDATE Temp_ExistCategory AS tmpEc
		INNER JOIN CTS_DataCenter.CustomerCategory AS cat ON tmpEc.RelevantCategoryID = cat.CategoryID
	SET tmpEc.RelevantCategoryGroup = cat.CategoryGroup;

    INSERT INTO Temp_CustProbationStatus 
    SELECT DISTINCT tmpPA.CustID
			, tmpPA.IsProbationStatus 
	FROM Temp_PA AS tmpPA;

	# UPDATE PA WHEN CHANGE PROBATION STATUS
    UPDATE IGNORE CTS_DataCenter.CTSCustomerClassification AS cls
        INNER JOIN Temp_ExistCategory AS tmpEc ON cls.CustID = tmpEc.CustID AND cls.CategoryID = tmpEc.CategoryID
		INNER JOIN Temp_CustProbationStatus AS tmCb ON tmCb.CustID = tmpEc.CustID AND (tmpEc.IsProbation <> tmCb.IsProbationStatus)       
	SET 	cls.CTSCustID = tmpEc.CTSCustID
		,	cls.CategoryID =  tmpEc.RelevantCategoryGroup
		, 	cls.LastModifiedBy = tmpEc.CreatedBy
		,	cls.Remark = tmpEc.Remark
		,   cls.LastModifiedDate = lv_CurrentDateTime
		, 	cls.LastScannedDate = DATE(lv_CurrentDateTime);
        
    #============INSERT NEW PA==================================
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
	CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate, IsDirect, Remark, IsFromCTS, IsFromTVS, IsFromTW)
	SELECT 	tmpPA.CustID
		,	tmpPA.CTSCustID
		, 	tmpPA.SubscriberID
		, 	(CASE 	WHEN tmpPA.IsProbationStatus = 1 AND tmpPA.RelevantIsProbation = 1 THEN  tmpPA.RelevantCategoryGroup
					WHEN (tmpPA.IsProbationStatus = 0 OR tmpPA.IsProbationStatus IS NULL) THEN  tmpPA.CategoryGroup 
					ELSE tmpPA.CategoryGroup 
			END) AS CategoryID
		, 	CONST_PA_SPORTGROUP AS SportGroupID
		, 	lv_CurrentDateTime
		, 	tmpPA.CreatedBy
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpPA.CreatedBy AS LastModifiedBy
		, 	DATE(lv_CurrentDateTime) AS LastScannedDate
        ,	tmpPA.IsDirectPA
        ,	tmpPA.Remark
        ,	tmpPA.IsFromCTS
        ,	tmpPA.IsFromTVS
        ,	tmpPA.IsFromTW
	FROM Temp_PA AS tmpPA
    WHERE tmpPA.DataChangeType = 0 ;   
    
    #=============INSERT HISTORY WHERE Category CHANGE OR Special Remove==================================================
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType
			, InsertDate, TargetCC, SourceTypeID, IsDataChanged, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays, IsDirect, Remark)
	SELECT 	DISTINCT 
			tmpPA.CustID
		, 	tmpPA.CTSCustID
		, 	(CASE 	WHEN tmpPA.IsProbationStatus = 1 AND tmpPA.RelevantIsProbation = 1 THEN  tmpPA.RelevantCategoryGroup
					WHEN (tmpPA.IsProbationStatus = 0 OR tmpPA.IsProbationStatus IS NULL) THEN  tmpPA.CategoryGroup 
					ELSE tmpPA.CategoryGroup 
			END) AS CategoryID
		, 	CONST_PA_SPORTGROUP
		, 	lv_CurrentDateTime AS LastModifiedDate
		, 	tmpPA.CreatedBy AS LastModifiedBy
		, 	CONST_ACTIONTYPE_INSERT AS ActionType
		, 	DATE(lv_CurrentDateTime) AS InsertDate
		, 	tmpPA.TargetCC
		, 	(CASE WHEN IsDirectPA = 1 THEN 31 
					WHEN IsDirectPA = 0 THEN 32 END) AS SourceTypeID
		,  	1 AS IsDataChanged
		,	tmpPA.TargetDangerLevel AS TargetDangerLevel1
		,	tmpPA.TurnoverRM
		,	tmpPA.WinlossRM
		, 	tmpPA.BetCount
		, 	tmpPA.ActiveDays
        ,	tmpPA.IsDirectPA
        ,	tmpPA.Remark
	FROM Temp_PA AS tmpPA
	WHERE tmpPA.DataChangeType = 0;

    IF (ip_IsFromQueue = 0) THEN
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
		WHERE tmpPA.RoleID > 1;

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
        ,	DATE(lv_CurrentDateTime) AS CreatedDate
        ,	tmpPA.CreatedBy
    FROM Temp_PA AS tmpPA;
    
    #========INSERT EVIDENCE QUEUE=========
     INSERT IGNORE INTO CTS_DataCenter.CustEvidenceAffectedQueueInsert(CTSCustID, EvidenceID, Remark, CreatedBy, Created)
     SELECT tmpPA.CTSCustID
		,	tmpPA.ToEvidenceID
		,	tmpPA.Remark
        ,	tmpPA.CreatedBy
        ,	DATE(lv_CurrentDateTime) AS CreatedDate
    FROM Temp_PA AS tmpPA;

	#=====RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS===========
	SELECT	DISTINCT 
			tmpPA.CustID
		,	tmpPA.CTSCustID
    FROM Temp_PA AS tmpPA; 

END$$
DELIMITER ;