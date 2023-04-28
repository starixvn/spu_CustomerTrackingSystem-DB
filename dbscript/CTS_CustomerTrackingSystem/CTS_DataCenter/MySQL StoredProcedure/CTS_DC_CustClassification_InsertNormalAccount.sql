/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_InsertNormalAccount`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_InsertNormalAccount`(
		IN ip_NewClassification 	JSON    
    ,	OUT op_ErrorMessage 		VARCHAR(200)
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20200901@Lex.Khuat
		Task:		Auto insert main customer categories for Customer Classification
		DB:			CTS_DataCenter
		Original:
		Revisions: 
				- 20200901@Lex.Khuat: Created [Redmine ID: #137550]
				- 20200908@Irena.Vo: Enhance Exclude VVIP Customers, Pin category  [Redmine ID: #141020]
				- 20201001@Irena.Vo: Insert Probation Management flow [Redmine ID: #145954]
                - 20201022@Irena.Vo: Enhance SP & correct logic. [Redmine ID: #142546]
                - 20201116@Irena.Vo: Only distinct CustID list for general & Update LastScannedDate for Probation List. [Redmine ID: #145028]
                - 20201201@Aries.Nguyen: Update metadata for goSQL. Remove transaction isolation level REPEATABLE READ and READ UNCOMMITTED. [Redmine ID: #145954]
			    - 20210115@Irena.Vo: Insert History Log  [RedmineID: #145951]
				- 20210118@Casey.Huynh: Add New PA Rule NewMember(231,232,233) [RedmineID: #148908]
				- 20210226@Casey.Huynh: Add New PA Rule [RedmineID: 150455]
                - 20210401@Irena.Vo: Write log for Update Danger Level. Enhance logic SP. [RedmineID: #152249]
                - 20210415@Casey.Huynh: Ignore Probation Account Monitor if not meet the scan schedule [RedmineID: #153491]
                - 20210510@Casey.Huynh: Exclude Customer of Odd Feed Sites [Redmine ID: 154694]
                - 20210512@Casey.Huynh: Exclude Customer of Internal Account [Redmine ID: 154844]
                - 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [Redmine ID: 152965]
				- 20210608@Casey.Huynh: Add Inactive Category (1001, 1002). Remove redundant New member log after Remove PA [Redmine ID: 156465]
				- 20210722@Long.Luu: Refactor. Update logic [Redmine ID: #157203]
				- 20210804@Irena.Vo: Fix issue no view History log [Redmine ID: #159706]
				- 20210729@Long.Luu: Add up TW's new categories. Fix get duplicated Fail probation log [Redmine ID: 155956]
				- 20210920@Aries.Nguyen: Split history log  [Redmine ID: #161890]
				- 20211122@Irena.Vo: Process Licensee info by site [Redmine ID: #161665]
                - 20220705@Long.Luu: Switching for Licensee VIP & BA Categories [Redmine ID: #174219]                
                - 20220817@Long.Luu: Rearrange CC's IDs [Redmine ID: #175698]
                - 20221110@Casey.Huynh: Update logic for checking Category in OldCategory table [Redmine ID: #178022]
				- 202230426@Long.Luu: Adjust Probation's period from 20 to 15 [Redmine ID: #187433]
                - 20230428@Jonas.Huynh: Realtime Renovation [Redmine ID: #186678]
                
		Param's Explanation (filtered by):
        
        Example:
				- CALL CTS_DataCenter.CTS_DC_CustClassification_InsertNormalAccount('[{"CustId": "43600693","CategoryId":"1000","CreatedTime":"2021-03-31 00:00:00","TurnoverRM":"100","WinlossRM":"10","BetCount":"15","ActiveDays":"10","TaggingID":10,"TaggingType":1,"PerformanceTime":"2021-03-31 00:00:00"}]',@or);
*/ 
    DECLARE	CONST_GROUP_PA 								INT DEFAULT 0;
    DECLARE	CONST_GROUP_WRAPPER							INT DEFAULT 100;
	DECLARE	CONST_GROUP_NORMAL 							INT DEFAULT 200;
    
    DECLARE CONST_CATEGORY_NEWMEMBER 					INT DEFAULT 201;
	DECLARE	CONST_CATEGORY_NORMALMEMBER 				INT DEFAULT 202;
	DECLARE CONST_CATEGORY_SMART 						INT DEFAULT 203;
    DECLARE CONST_CATEGORY_HIGHRISK 					INT DEFAULT 204;
    DECLARE CONST_CATEGORY_VIP 							INT DEFAULT 205;
    DECLARE CONST_CATEGORY_PROBATION					INT DEFAULT 206;
    DECLARE CONST_CATEGORY_INACTIVE						INT DEFAULT 1000;
    DECLARE CONST_CATEGORY_NORMALINACTIVE				INT DEFAULT 1001;
    DECLARE CONST_CATEGORY_PROPUNTERINACTIVE 			INT DEFAULT 1002;
    
    DECLARE CONST_ACTIONTYPE_INSERT 					INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 					INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 					INT DEFAULT 2;
    DECLARE CONST_ACTIONTYPE_EXISTEDPA 					INT DEFAULT 3;
    DECLARE CONST_ACTIONTYPE_IGNOREPIN 					INT DEFAULT 4;
    DECLARE CONST_ACTIONTYPE_IGNOREPROBATION 			INT DEFAULT 5;
  
    DECLARE CONST_SOURCETYPE_SAMECATEGORY 				INT DEFAULT 0;
    DECLARE CONST_SOURCETYPE_LESSTHAN10TICKETS 			INT DEFAULT 1;
	DECLARE	CONST_SOURCETYPE_AFTER10TICKETS 			INT DEFAULT 2;
	DECLARE CONST_SOURCETYPE_SCANONSCHEDULE				INT DEFAULT 3;
    DECLARE CONST_SOURCETYPE_PASSPROBATION 				INT DEFAULT 4;
    DECLARE CONST_SOURCETYPE_FAILPROBATION 				INT DEFAULT 5;
    DECLARE CONST_SOURCETYPE_INACTIVENORMAL 			INT DEFAULT 18;
    DECLARE CONST_SOURCETYPE_INACTIVEPROPUNTER			INT DEFAULT 19;
    
    DECLARE	CONST_LICBACATEGORY							INT DEFAULT 2;
    DECLARE	CONST_LICVIP_DANGEROUSCATEGORY				INT DEFAULT 3;
    DECLARE	CONST_LICVIP_SUSPICIOUSCATEGORY				INT DEFAULT 4;    
    DECLARE	CONST_VVIPCATEGORY							INT DEFAULT 210;    
    
	DECLARE lv_CreatedBy 								INT DEFAULT 10278938;
	DECLARE lv_CurrentDateTime 							DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_FromProbationLastDay 					DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY);
	DECLARE lv_ToProbationLastDay 						DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY);
    DECLARE lv_LicBACC									SMALLINT UNSIGNED;
    DECLARE lv_LicBAPriority							SMALLINT UNSIGNED;
    DECLARE lv_LicVIPCC_Danger							SMALLINT UNSIGNED;
    DECLARE lv_LicVIPCC_Suspicious						SMALLINT UNSIGNED;
    DECLARE lv_VVIPCC									SMALLINT UNSIGNED;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification(	  	
			CustID						BIGINT UNSIGNED	PRIMARY KEY
		, 	CTSCustID					BIGINT DEFAULT 0
		, 	SubscriberID				INT DEFAULT 0        
		,	IsLicensee					BIT 
        ,	IsLicenseeVIP				BIT
        ,	IsLicenseeBA				BIT
		, 	TurnoverRM					DECIMAL(20,4)
		, 	WinlossRM					DECIMAL(20,4)
		, 	BetCount					BIGINT
		, 	ActiveDays					INT	
        ,	TWBetCount					BIGINT
        ,	TWGroupBettingRate			DECIMAL(10,4)
        ,	TWTicketRejectRate			DECIMAL(10,4)
        ,	TWDesktopUsageRate			DECIMAL(10,4)
		,	TaggingID					SMALLINT
		,	TaggingType					SMALLINT	
		, 	DWCateGroup					SMALLINT
		,	DWCateID					SMALLINT
        ,	OldCateGroup 				SMALLINT
        ,	OldCateID 					SMALLINT
        ,	OldIsDangerProbation		BIT DEFAULT 0
      	, 	NewCateGroup				SMALLINT
		,	NewCateID					SMALLINT
        ,	NewIsDangerProbation		BIT DEFAULT 0
		,	SourceTypeID      			SMALLINT
		,	IsDataChanged				BIT DEFAULT 1 /*0: No change category => No Action*/
        ,	OldTargetCC					SMALLINT
        ,	TargetCC					SMALLINT
		,	TargetDangerLevel			SMALLINT
		,   SpecialCC	       			INT  
        ,	SpecialCCName				VARCHAR(50)
		,   SpecialCCPriority   		SMALLINT DEFAULT -1
		,   SpecialCCDangerProbation   	BIT DEFAULT NULL
		, 	ActionType					SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN; 5: Not satisfy Pass Probation*/
        ,	PerformanceTime				DATETIME
		, 	INDEX    			    	IX_Temp_NewClassification(CustID, DWCateGroup)  
	); 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_ExistedCustomers;    
	CREATE TEMPORARY TABLE Temp_ExistedCustomers(	  	
			CustID					BIGINT UNSIGNED PRIMARY KEY
        , 	CTSCustID				BIGINT
        , 	SubscriberID			INT     
        ,	IsLicensee				BIT        
        ,	IsLicenseeVIP			BIT       
        ,	IsLicenseeBA			BIT    
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ProbationCustomers;    
	CREATE TEMPORARY TABLE Temp_ProbationCustomers(	  	
			CustID					BIGINT UNSIGNED	PRIMARY KEY
        , 	ScanDate				DATE      
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustIgnoranceAction;    
	CREATE TEMPORARY TABLE Temp_CustIgnoranceAction(	  	
			CustID					BIGINT UNSIGNED	PRIMARY KEY
        , 	ActionType				SMALLINT      
	); 
	
    DROP TEMPORARY TABLE IF EXISTS Temp_OldClassification;    
	CREATE TEMPORARY TABLE Temp_OldClassification(	  
			CustID					BIGINT UNSIGNED	PRIMARY KEY
        ,	OldCateGroup 			SMALLINT
        ,	OldCateID 				SMALLINT
        ,	OldIsDangerProbation	BIT DEFAULT 0
        ,	FromOldCategory			BOOLEAN DEFAULT 0	
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_OldCustomerClass;    
	CREATE TEMPORARY TABLE Temp_OldCustomerClass(	  
			CustID					BIGINT UNSIGNED	PRIMARY KEY
        ,	CustomerClass 			SMALLINT
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_UpdateCustomerClass;    
	CREATE TEMPORARY TABLE Temp_UpdateCustomerClass(	  
			CustID					BIGINT UNSIGNED	PRIMARY KEY
        ,	CustomerClass 			SMALLINT
	); 
     
    /* START */
    /* INIT */    
    SELECT CustomerClass, Priority 
    INTO lv_LicBACC, lv_LicBAPriority
    FROM CustomerCategory WHERE CategoryID = CONST_LICBACATEGORY;
    
    SELECT CustomerClass
    INTO lv_LicVIPCC_Danger
    FROM CustomerCategory WHERE CategoryID = CONST_LICVIP_DANGEROUSCATEGORY;
    
    SELECT CustomerClass
    INTO lv_LicVIPCC_Suspicious
    FROM CustomerCategory WHERE CategoryID = CONST_LICVIP_SUSPICIOUSCATEGORY;    
    
    SELECT CustomerClass
    INTO lv_VVIPCC
    FROM CustomerCategory WHERE CategoryID = CONST_VVIPCATEGORY;
    
	/* 1: PARSE RAW DATA */
	INSERT IGNORE INTO Temp_NewClassification(CustID,DWCateGroup,TurnoverRM,WinlossRM,BetCount,ActiveDays,TWBetCount,TWGroupBettingRate,TWTicketRejectRate,TWDesktopUsageRate,
		TaggingID,TaggingType,PerformanceTime)
	SELECT DISTINCT temp.CustID
				, 	temp.DWCateGroup
                , 	temp.TurnoverRM
                , 	temp.WinlossRM
                , 	temp.BetCount
                , 	temp.ActiveDays
                ,	temp.TWBetCount
                , 	temp.TWGroupBettingRate
                , 	temp.TWTicketRejectRate
                , 	temp.TWDesktopUsageRate
                ,	IFNULL(temp.TaggingID, -99)
                , 	temp.TaggingType
                ,	temp.PerformanceTime
	 FROM JSON_TABLE(ip_NewClassification,
		"$[*]" COLUMNS(
				CustID 					BIGINT UNSIGNED		PATH "$.CustId"
			, 	DWCateGroup				SMALLINT UNSIGNED	PATH "$.CategoryId"
            , 	TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
            , 	WinlossRM				DECIMAL(20,4)		PATH "$.WinlossRM"
            , 	BetCount				BIGINT				PATH "$.BetCount"
            , 	ActiveDays				INT					PATH "$.ActiveDays"		
            ,	TWBetCount				BIGINT				PATH "$.TWBetCount"
			,	TWGroupBettingRate		DECIMAL(10,4)		PATH "$.TWGroupBettingRate"
			,	TWTicketRejectRate		DECIMAL(10,4)		PATH "$.TWTicketRejectRate"
			,	TWDesktopUsageRate		DECIMAL(10,4)		PATH "$.TWDesktopUsageRate"
            , 	TaggingID				SMALLINT			PATH "$.TaggingID"
            , 	TaggingType				SMALLINT			PATH "$.TaggingType"	
			, 	PerformanceTime			DATETIME			PATH "$.PerformanceTime"
		 )) AS 	temp
	 WHERE temp.DWCateGroup <> 0;
	
    /* 2: EXCLUDE INTERNAL CUSTOMERS */      
    CALL CTS_DC_ExcludeCustByCondition('Temp_NewClassification');
    
    /* 3: GENERATE CUSTOMERS' INFO */
    INSERT IGNORE INTO Temp_ExistedCustomers(CustID, CTSCustID, SubscriberID, IsLicensee, IsLicenseeVIP, IsLicenseeBA)
    SELECT 	DISTINCT cust.CustID
		, 	cust.CTSCustID
        , 	cust.SubscriberID
		, 	CASE WHEN mss.SubscriberGroupID = 2 THEN 1 ELSE 0 END AS IsLicensee
        ,	cust.IsLicenseeVIP
        ,	cust.IsLicenseeBA
    FROM Temp_NewClassification AS temp 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
        INNER JOIN CTS_DataCenter.MappingSubscriberSite AS mss ON mss.SiteID = cust.SiteID;
        
    UPDATE Temp_NewClassification AS temp 
		INNER JOIN Temp_ExistedCustomers AS ec ON temp.CustID = ec.CustID
	SET		temp.CTSCustID = ec.CTSCustID
		, 	temp.SubscriberID = ec.SubscriberID
        ,	temp.IsLicensee = ec.IsLicensee
        ,	temp.IsLicenseeVIP = ec.IsLicenseeVIP
        ,	temp.IsLicenseeBA = ec.IsLicenseeBA;
        
	 UPDATE Temp_NewClassification AS t
		INNER JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CustID = t.CustID
		LEFT JOIN CTS_DataCenter.CustomerCategory AS c ON sp.CustomerClass = c.CustomerClass
	SET t.SpecialCC = sp.CustomerClass,
		t.SpecialCCName = c.CustomerClassName,
		t.SpecialCCPriority = c.Priority,
        t.SpecialCCDangerProbation = c.IsDangerProbation;
    
    /*4: GET PROBATION CUSTOMERS */
    INSERT IGNORE INTO Temp_ProbationCustomers(CustID, ScanDate)
    SELECT DISTINCT pro.CustID, pro.CreatedDate
    FROM 	Temp_NewClassification AS temp
		INNER JOIN 	ProbationAccountMonitor AS pro ON temp.CustID = pro.CustID AND pro.SportGroupID = CONST_GROUP_NORMAL;
    
    /* 5: EXCLUDE CATEGORIES THAT SHOULD NOT BE UPDATED */
	/* 5.1: NOT PASS PROBATION RULES */ 
    INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, ActionType)
    SELECT DISTINCT	temp.CustID, CONST_ACTIONTYPE_IGNOREPROBATION
	FROM 	Temp_NewClassification AS temp 
		INNER JOIN Temp_ProbationCustomers AS pro ON temp.CustID = pro.CustID
    WHERE 	(temp.DWCateGroup IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK,CONST_CATEGORY_PROBATION) AND pro.ScanDate > lv_FromProbationLastDay) 
			OR (pro.ScanDate >= lv_ToProbationLastDay);

    /* 5.2: EXCLUDE PIN CATEGORY */
    INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, ActionType)
    SELECT DISTINCT temp.CustID, CONST_ACTIONTYPE_IGNOREPIN
	FROM Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CTSCustID = temp.CTSCustID;
    
	/* 5.3: EXCLUDE PROBLEM ACCOUNTS */
    INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, ActionType)
    SELECT DISTINCT temp.CustID, CONST_ACTIONTYPE_EXISTEDPA
    FROM Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = CONST_GROUP_PA;
     
    /* 5.4: UPDATE BACK TO Temp_NewClassification */
	/* 5.4.1: HAS ACTION + NO VIEW LOG FAIL PROBATION FOR > 20 LAST DAYS */ 
    UPDATE Temp_NewClassification AS temp
		INNER JOIN  Temp_ProbationCustomers AS pro ON pro.CustID = temp.CustID
	SET 	temp.IsDataChanged = 0
    WHERE 	(temp.DWCateGroup = CONST_CATEGORY_PROBATION AND pro.ScanDate < lv_FromProbationLastDay);
    
    /* 5.4.2: NO ACTION + VIEW LOG FOR IGNORE CASES */ 
   	UPDATE Temp_NewClassification AS temp 
		INNER JOIN Temp_CustIgnoranceAction AS ig ON temp.CustID = ig.CustID
    SET 	temp.ActionType = ig.ActionType
		, 	temp.IsDataChanged = 0;
	
    /* 6: GENERATE CATEGORY */
    /* 6.1: UPDATE DW CATEGORY */
    UPDATE Temp_NewClassification AS temp 
		LEFT JOIN TaggingToCategory AS tag ON tag.CategoryGroup = temp.DWCateGroup AND tag.TaggingType = temp.TaggingType AND temp.TaggingID = tag.TaggingID
	SET 	temp.DWCateID = IFNULL(tag.CategoryID,temp.DWCateGroup);
    
	/* 6.2: UPDATE EXISTED CATEGORY */  
    INSERT IGNORE INTO Temp_OldClassification(CustID, OldCateGroup, OldCateID, OldIsDangerProbation)
    SELECT DISTINCT temp.CustID, cc.CategoryGroup, cate.CategoryID, cc.IsDangerProbation
    FROM Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_NORMAL
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_IGNOREPROBATION);

    #====GET OLD LASTEST CATEGORY FROM OLD CATEGORY IS NORMAL CATEGORY========
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomerClassificationOldCategory;
    CREATE TEMPORARY TABLE Temp_CTSCustomerClassificationOldCategory(
			CustID		BIGINT UNSIGNED
		,	CategoryID	INT
    );
    
    INSERT IGNORE INTO Temp_CTSCustomerClassificationOldCategory(CustID, CategoryID)
    SELECT tmpLtr.CustID
		,  tmpLtr.CategoryID        
    FROM Temp_NewClassification AS temp
	, LATERAL	
        (	SELECT CustID, CategoryID, SportGroupID
			FROM CTS_DataCenter.CTSCustomerClassificationOldCategory AS cate 
			WHERE temp.CustID = cate.CustID
			ORDER BY cate.CreatedDate DESC
       ) tmpLtr 
	WHERE tmpLtr.SportGroupID = CONST_GROUP_NORMAL AND temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_IGNOREPROBATION);

    INSERT IGNORE INTO Temp_OldClassification(CustID, OldCateGroup, OldCateID, OldIsDangerProbation, FromOldCategory)
    SELECT DISTINCT temp.CustID, cc.CategoryGroup, cc.CategoryID, cc.IsDangerProbation, 1 AS FromOldCategory
    FROM Temp_NewClassification AS temp
		INNER JOIN Temp_CTSCustomerClassificationOldCategory AS tmpOc ON temp.CustID = tmpOc.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = tmpOc.CategoryID;
    #===========================================================================
    UPDATE Temp_NewClassification AS n
		LEFT JOIN Temp_OldClassification AS o ON n.CustID = o.CustID
	SET n.OldCateGroup = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateGroup END,
		n.OldCateID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateID END,
		n.OldIsDangerProbation = CASE WHEN o.CustID IS NULL THEN 1 ELSE o.OldIsDangerProbation END,
        n.ActionType = CASE WHEN o.CustID IS NULL OR FromOldCategory = 1 THEN CONST_ACTIONTYPE_INSERT ELSE CONST_ACTIONTYPE_UPDATE END
	WHERE n.ActionType IN (CONST_ACTIONTYPE_INSERT);
    
    UPDATE Temp_NewClassification AS n
		LEFT JOIN Temp_OldClassification AS o ON n.CustID = o.CustID
	SET n.OldCateGroup = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateGroup END,
		n.OldCateID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateID END
	WHERE n.ActionType IN (CONST_ACTIONTYPE_IGNOREPROBATION);
    
    /* 6.3: UPDATE NEW CATEGORY */    
    UPDATE 	Temp_NewClassification AS temp 
	SET 	temp.NewCateGroup = (CASE WHEN temp.OldCateGroup IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_NORMALMEMBER,CONST_CATEGORY_VIP,CONST_CATEGORY_INACTIVE) 
											AND temp.DWCateGroup IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK) THEN CONST_CATEGORY_PROBATION 
									  ELSE temp.DWCateGroup 
								  END)
	 WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_SOURCETYPE_FAILPROBATION);
	
    /* 6.3.1: UPDATE NEW CATEGORY - ACTIVE */    
	UPDATE 	Temp_NewClassification AS temp 
		LEFT JOIN TaggingToCategory AS tag ON tag.CategoryGroup = temp.NewCateGroup AND tag.TaggingType = temp.TaggingType AND temp.TaggingID = tag.TaggingID
	SET 	temp.NewCateID = IFNULL(tag.CategoryID, temp.NewCateGroup)
	 WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) AND temp.DWCateGroup <> CONST_CATEGORY_INACTIVE; /*Exclude Inactive category*/
    
    /* 6.3.2: UPDATE NEW CATEGORY - INACTIVE */    
    UPDATE 	Temp_NewClassification AS temp 
    SET 	temp.NewCateID = (CASE WHEN temp.OldCateGroup IS NULL OR temp.OldCateGroup IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_NORMALMEMBER,CONST_CATEGORY_VIP) THEN CONST_CATEGORY_NORMALINACTIVE
								   WHEN temp.OldCateGroup IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK,CONST_CATEGORY_PROBATION) THEN CONST_CATEGORY_PROPUNTERINACTIVE
								   ELSE temp.OldCateID
                              END)
    WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) AND temp.DWCateGroup = CONST_CATEGORY_INACTIVE; 
    
     /* 6.3.3: UPDATE NewIsDangerProbation */    
    UPDATE 	Temp_NewClassification AS temp 
		INNER JOIN CustomerCategory AS c ON temp.NewCateID = c.CategoryID
    SET 	temp.NewIsDangerProbation = c.IsDangerProbation;
    
    /* 7: GENERATE SOURCE TYPE */    
    UPDATE 	Temp_NewClassification AS temp 
	SET 	temp.SourceTypeID = (CASE WHEN (temp.OldCateGroup IS NULL OR temp.OldCateGroup = CONST_CATEGORY_NEWMEMBER) AND temp.NewCateGroup = CONST_CATEGORY_NEWMEMBER THEN CONST_SOURCETYPE_LESSTHAN10TICKETS
									 WHEN temp.OldCateGroup IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_INACTIVE) AND temp.NewCateGroup NOT IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_INACTIVE) THEN CONST_SOURCETYPE_AFTER10TICKETS 
									 WHEN temp.OldCateGroup = CONST_CATEGORY_PROBATION AND temp.NewCateGroup IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK) THEN CONST_SOURCETYPE_PASSPROBATION
									 WHEN temp.OldCateGroup = CONST_CATEGORY_PROBATION AND temp.NewCateGroup = CONST_CATEGORY_PROBATION THEN CONST_SOURCETYPE_FAILPROBATION
                                     WHEN (temp.OldCateGroup IS NULL OR temp.OldCateGroup IN (CONST_CATEGORY_NEWMEMBER,CONST_CATEGORY_NORMALMEMBER,CONST_CATEGORY_VIP)) AND temp.NewCateGroup = CONST_CATEGORY_INACTIVE THEN CONST_SOURCETYPE_INACTIVENORMAL 
                                     WHEN temp.OldCateGroup IN (CONST_CATEGORY_SMART,CONST_CATEGORY_HIGHRISK,CONST_CATEGORY_PROBATION) AND temp.NewCateGroup = CONST_CATEGORY_INACTIVE THEN CONST_SOURCETYPE_INACTIVEPROPUNTER
                                     WHEN temp.OldCateGroup = temp.NewCateGroup THEN CONST_SOURCETYPE_SAMECATEGORY
                                     ELSE CONST_SOURCETYPE_SCANONSCHEDULE
								END)
	WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);     

    /* 8: GENERATE DATA NO CHANGED */   
    UPDATE 	Temp_NewClassification AS temp
	SET 	temp.IsDataChanged = (CASE WHEN temp.NewCateID = temp.OldCateID AND temp.SourceTypeID <> CONST_SOURCETYPE_FAILPROBATION THEN 0 /*No update category*/ ELSE temp.IsDataChanged END)
	WHERE 	temp.ActionType = CONST_ACTIONTYPE_UPDATE;     
    
    /* 9: GENERATE TARGET CC */
    UPDATE Temp_NewClassification AS tmp 
		LEFT JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = tmp.NewCateID
	SET 	tmp.TargetCC = CASE  
								WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCPriority <> -1)
										THEN CASE
												WHEN cate.CustomerClass = lv_VVIPCC THEN lv_VVIPCC                                                
												WHEN tmp.IsLicenseeVIP = 1 AND cate.Priority > tmp.SpecialCCPriority AND tmp.SpecialCCDangerProbation = 1 THEN lv_LicVIPCC_Suspicious
												WHEN tmp.IsLicenseeVIP = 1 AND cate.Priority > tmp.SpecialCCPriority AND tmp.SpecialCCDangerProbation IS NOT NULL THEN lv_LicVIPCC_Danger
												WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 THEN lv_LicVIPCC_Suspicious
												WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 THEN lv_LicVIPCC_Danger                                                
												WHEN tmp.IsLicenseeBA = 1 AND tmp.SpecialCCPriority <> -1 AND tmp.SpecialCCPriority < lv_LicBAPriority THEN tmp.SpecialCC  
												WHEN tmp.IsLicenseeBA = 1 AND cate.Priority > lv_LicBAPriority THEN lv_LicBACC                                            
												WHEN tmp.SpecialCCPriority <> -1 AND cate.Priority > tmp.SpecialCCPriority THEN tmp.SpecialCC
												ELSE cate.CustomerClass
											END
								ELSE tmp.SpecialCC
							END
	WHERE 	tmp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_IGNOREPROBATION);
	
    /* 9 PLUS:  */
    INSERT INTO Temp_OldCustomerClass(CustID)
    SELECT DISTINCT temp.CustID
    FROM Temp_NewClassification AS temp
	WHERE temp.IsDataChanged  = 0;
    
    INSERT IGNORE INTO Temp_UpdateCustomerClass(CustID,CustomerClass)
    WITH CTE_LatestLog AS (
		SELECT h.CustID, MAX(h.LastModifiedDate) AS LatestInsertDate
		FROM Temp_OldCustomerClass AS t
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON t.CustID = h.CustID
		GROUP BY h.CustID
	),
    CTE_LatestHistory AS (
		SELECT h.CustID, h.TargetCC
		FROM CTE_LatestLog AS l
			INNER JOIN CTS_DataCenter.CTSCustomerClassification_History AS h ON l.CustID = h.CustID AND l.LatestInsertDate = h.LastModifiedDate
	)
    SELECT 	cte.CustID
		,	cte.TargetCC
	FROM CTE_LatestHistory AS cte;
        
	UPDATE Temp_UpdateCustomerClass AS c
		INNER JOIN Temp_NewClassification AS t ON c.CustID = t.CustID
	SET t.OldTargetCC = c.CustomerClass;
    
    UPDATE Temp_NewClassification AS tmp
		INNER JOIN CustomerCategory AS cate ON tmp.OldCateID = cate.CategoryID
    SET tmp.TargetCC = 	CASE  
							WHEN (tmp.SpecialCC IS NULL) OR (tmp.SpecialCCPriority <> -1)
									THEN CASE
											WHEN cate.CustomerClass = lv_VVIPCC THEN lv_VVIPCC
											WHEN tmp.IsLicenseeVIP = 1 AND cate.Priority > tmp.SpecialCCPriority AND tmp.SpecialCCDangerProbation = 1 THEN lv_LicVIPCC_Suspicious
											WHEN tmp.IsLicenseeVIP = 1 AND cate.Priority > tmp.SpecialCCPriority AND tmp.SpecialCCDangerProbation IS NOT NULL THEN lv_LicVIPCC_Danger
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 1 THEN lv_LicVIPCC_Suspicious
											WHEN tmp.IsLicenseeVIP = 1 AND cate.IsDangerProbation = 0 THEN lv_LicVIPCC_Danger
											WHEN tmp.IsLicenseeBA = 1 AND tmp.SpecialCCPriority <> -1 AND tmp.SpecialCCPriority < lv_LicBAPriority THEN tmp.SpecialCC    
											WHEN tmp.IsLicenseeBA = 1 AND cate.Priority > lv_LicBAPriority THEN lv_LicBACC                                            
											WHEN tmp.SpecialCCPriority <> -1 AND cate.Priority > tmp.SpecialCCPriority THEN tmp.SpecialCC
											ELSE cate.CustomerClass
										END
							ELSE tmp.SpecialCC
						END
		,	tmp.NewCateID = tmp.OldCateID
        , 	tmp.NewCateGroup = tmp.OldCateGroup
        ,	tmp.NewIsDangerProbation = cate.IsDangerProbation
    WHERE tmp.ActionType = CONST_ACTIONTYPE_IGNOREPROBATION;
        
    UPDATE Temp_NewClassification
    SET IsDataChanged = 1
		,	SourceTypeID = (CASE 
								WHEN  NewCateGroup IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK) 
									THEN CONST_SOURCETYPE_PASSPROBATION
								WHEN NewCateGroup = CONST_CATEGORY_INACTIVE AND NewCateID = CONST_CATEGORY_NORMALINACTIVE 
									THEN CONST_SOURCETYPE_INACTIVENORMAL 
								WHEN NewCateGroup = CONST_CATEGORY_INACTIVE AND NewCateID = CONST_CATEGORY_PROPUNTERINACTIVE 
									THEN CONST_SOURCETYPE_INACTIVEPROPUNTER
								ELSE CONST_SOURCETYPE_SCANONSCHEDULE
							END)
		,	ActionType = CONST_ACTIONTYPE_UPDATE
    WHERE IsDataChanged = 0 
		AND ((TargetCC <> OldTargetCC) OR (OldCateID <> NewCateID))
		AND (SourceTypeID IN (CONST_SOURCETYPE_SAMECATEGORY, CONST_SOURCETYPE_FAILPROBATION,CONST_SOURCETYPE_LESSTHAN10TICKETS )
			OR ActionType = CONST_ACTIONTYPE_IGNOREPROBATION);
            
     
    /* 10: GENERATE TARGET DANGER LEVEL */
    UPDATE Temp_NewClassification AS temp 
		INNER JOIN CTS_DataCenter.CategoryToDangerLevel AS d ON d.CategoryID = temp.NewCateID AND d.IsLicensee = temp.IsLicensee AND d.TypeID = 1
    SET 	temp.TargetDangerLevel = d.DangerLevel
    WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
    
    
    /* 11: UPDATE CTS CLASSIFICATION */
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_NORMAL
	SET   	cate.CTSCustID = temp.CTSCustID
		, 	cate.SubscriberID = temp.SubscriberID
		, 	cate.CategoryID = temp.NewCateID
		, 	cate.LastModifiedDate = lv_CurrentDateTime
		, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
    WHERE temp.ActionType = CONST_ACTIONTYPE_UPDATE;
    
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_WRAPPER
	SET   	cate.CategoryID = 	CASE 
									WHEN temp.NewIsDangerProbation = 1 THEN CONST_LICVIP_SUSPICIOUSCATEGORY
                                    ELSE CONST_LICVIP_DANGEROUSCATEGORY 
								END
	WHERE cate.CategoryID IN (CONST_LICVIP_SUSPICIOUSCATEGORY,CONST_LICVIP_DANGEROUSCATEGORY)
		AND temp.IsDataChanged = 1;
	
    /* 12: INSERT CTS CLASSIFICATION */
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification
	(CustID,CTSCustID,SubscriberID,SportGroupID,CategoryID,CreatedDate,CreatedBy,LastModifiedDate,LastModifiedBy,LastScannedDate)
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	temp.SubscriberID
		, 	CONST_GROUP_NORMAL
		, 	temp.NewCateID
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime) AS LastScannedDate
	 FROM Temp_NewClassification AS temp
     WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT; 

    /* 13: REMOVE DATA */
    # DELETE FOR OLD NORMAL 
    DELETE del
    FROM CTS_DataCenter.CTSCustomerClassificationOldCategory AS del
		INNER JOIN Temp_NewClassification AS temp ON del.CustID = temp.CustID AND del.SportGroupID = CONST_GROUP_NORMAL
    WHERE temp.ActionType = CONST_ACTIONTYPE_INSERT;
    
    # FOR PASS PROBATION    
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		INNER JOIN Temp_NewClassification AS temp on temp.CustID = pro.CustID AND pro.SportGroupID = CONST_GROUP_NORMAL
	WHERE temp.ActionType = CONST_ACTIONTYPE_UPDATE AND temp.OldCateGroup = CONST_CATEGORY_PROBATION AND temp.NewCateGroup <> CONST_CATEGORY_PROBATION;   
    
    /* 14: INSERT NEW PROBATION */
    INSERT IGNORE INTO CTS_DataCenter.ProbationAccountMonitor
	(CustID,CTSCustID,SportGroupID,TargetCategoryID,FirstMargin,CreatedDate,CreatedBy,CreatedTime,LastScannedDate) 
	SELECT DISTINCT temp.CustID
		, 	temp.CTSCustID
		, 	CONST_GROUP_NORMAL
		, 	temp.DWCateID
		, 	(CASE WHEN temp.TurnoverRM = 0 THEN 0 ELSE (temp.WinlossRM/temp.TurnoverRM) * 100 END) AS FirstMargin
		, 	DATE(lv_CurrentDateTime) AS CreatedDate
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		,   DATE(lv_CurrentDateTime) AS LastScannedDate
	FROM Temp_NewClassification AS temp
	WHERE temp.NewCateGroup = CONST_CATEGORY_PROBATION 
		AND (temp.ActionType = CONST_ACTIONTYPE_INSERT 
			OR (temp.ActionType = CONST_ACTIONTYPE_UPDATE AND temp.OldCateGroup <> CONST_CATEGORY_PROBATION));

    /* 15: WRITE HISTORY LOG (VIEW ON WEB) */
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
	(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, TWBetCount, TWGroupBettingRate, TWTicketRejectRate, TWDesktopUsageRate
    , ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged, TaggingType, TargetDangerLevel1, PerformanceTime)
	SELECT DISTINCT	temp.CustID
				, 	temp.CTSCustID
				, 	temp.NewCateID
				, 	CONST_GROUP_NORMAL
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.TurnoverRM
				, 	temp.WinlossRM
				, 	temp.BetCount
				, 	temp.ActiveDays
                ,	temp.TWBetCount
                , 	temp.TWGroupBettingRate
                , 	temp.TWTicketRejectRate
                , 	temp.TWDesktopUsageRate
				, 	temp.ActionType
				, 	1
				, 	DATE(lv_CurrentDateTime)
				,	temp.TargetCC 
				,   temp.SourceTypeID
				, 	temp.OldCateID 
				, 	temp.DWCateID
				,   temp.IsDataChanged
				,	temp.TaggingType
				,	temp.TargetDangerLevel AS TargetDangerLevel1
                ,	temp.PerformanceTime
	FROM 	Temp_NewClassification AS temp
	WHERE temp.IsDataChanged  = 1;
	

    /* 16: WRITE HISTORY LOG (TRACE DATA) */
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log
	(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, TWBetCount, TWGroupBettingRate, TWTicketRejectRate, TWDesktopUsageRate
    , ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged, TaggingType, TargetDangerLevel1, PerformanceTime)
	SELECT DISTINCT	temp.CustID
				, 	temp.CTSCustID
				, 	temp.NewCateID
				, 	CONST_GROUP_NORMAL
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	temp.TurnoverRM
				, 	temp.WinlossRM
				, 	temp.BetCount
				, 	temp.ActiveDays
                ,	temp.TWBetCount
                , 	temp.TWGroupBettingRate
                , 	temp.TWTicketRejectRate
                , 	temp.TWDesktopUsageRate
				, 	temp.ActionType
				, 	1
				, 	DATE(lv_CurrentDateTime)
				,	temp.TargetCC 
				,   temp.SourceTypeID
				, 	temp.OldCateID 
				, 	temp.DWCateID
				,   temp.IsDataChanged
				,	temp.TaggingType
				,	temp.TargetDangerLevel AS TargetDangerLevel1
                ,	temp.PerformanceTime
	FROM 	Temp_NewClassification AS temp;
    
	/* 17: RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS */
	SELECT DISTINCT temp.CustId 
    FROM Temp_NewClassification AS temp 
    WHERE temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
    
END$$
DELIMITER ;