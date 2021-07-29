/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_InsertMainCustomerClassification`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_InsertMainCustomerClassification`(
		IN ip_NewClassification		JSON

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
                - 20210721@Irena.Vo: Fix bug no update data with CreatedDate < 20 Probation Last Day [Redmine ID: 158810]
                - 20210729@Long.Luu: Add up TW's new categories [Redmine ID: 155956]
                
		Param's Explanation (filtered by):
		Example:
				- CALL CTS_DataCenter.CTS_DC_InsertMainCustomerClassification('[{"CustId": "8","CategoryId":"203","CreatedTime":"2021-03-31 00:00:00","TurnoverRM":"100","WinlossRM":"10","BetCount":"15","ActiveDays":"10","LastXDaysMargin":100,"ProbationPeriodWinloss":100,"TaggingID":7,"TaggingType":2,"TWBetCount":10,"TWGroupBettingRate":0.5,"TWTicketRejectRate":0.5,"TWDesktopUsageRate":0.5}]',@opp);
	*/ 
    
    DECLARE	CONST_GROUP_PA 							INT DEFAULT 0;
	DECLARE	CONST_GROUP_NORMAL 						INT DEFAULT 200;
    
    DECLARE CONST_CATEGORY_NEWMEMBER 				INT DEFAULT 201;
	DECLARE	CONST_CATEGORY_NORMALMEMBER 			INT DEFAULT 202;
	DECLARE CONST_CATEGORY_SMART 					INT DEFAULT 203;
    DECLARE CONST_CATEGORY_HIGHRISK 				INT DEFAULT 204;
    DECLARE CONST_CATEGORY_VIP 						INT DEFAULT 205;
    DECLARE CONST_CATEGORY_PROBATION				INT DEFAULT 206;
    DECLARE CONST_CATEGORY_INACTIVE					INT DEFAULT 1000;
    DECLARE CONST_CATEGORY_NORMALINACTIVE			INT DEFAULT 1001;
    DECLARE CONST_CATEGORY_PROPUNTERINACTIVE 		INT DEFAULT 1002;
    
    DECLARE CONST_ACTIONTYPE_INSERT 				INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 				INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 				INT DEFAULT 2;
    DECLARE CONST_ACTIONTYPE_EXISTEDPA 				INT DEFAULT 3;
    DECLARE CONST_ACTIONTYPE_IGNOREPIN 				INT DEFAULT 4;
    DECLARE CONST_ACTIONTYPE_IGNOREPROBATION 		INT DEFAULT 5;
  
    DECLARE CONST_SOURCETYPE_LESSTHAN10TICKETS 		INT DEFAULT 1;
	DECLARE	CONST_SOURCETYPE_AFTER10TICKETS 		INT DEFAULT 2;
	DECLARE CONST_SOURCETYPE_SCANONSCHEDULE			INT DEFAULT 3;
    DECLARE CONST_SOURCETYPE_PASSPROBATION 			INT DEFAULT 4;
    DECLARE CONST_SOURCETYPE_FAILPROBATION 			INT DEFAULT 5;
    DECLARE CONST_SOURCETYPE_INACTIVENORMAL 		INT DEFAULT 18;
    DECLARE CONST_SOURCETYPE_INACTIVEPROPUNTER		INT DEFAULT 19;
    
	DECLARE lv_CreatedBy 				INT DEFAULT 10278938;
	DECLARE lv_CurrentDateTime 			DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_ToProbationLastDay 		DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 2 DAY);
    DECLARE lv_FromProbationLastDay 	DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 18 DAY);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_NewClassification;    
	CREATE TEMPORARY TABLE Temp_NewClassification(	  	
			CustID					BIGINT UNSIGNED	PRIMARY KEY
		, 	CTSCustID				BIGINT DEFAULT 0
		, 	SubscriberID			INT DEFAULT 0        
		,	IsLicensee				BIT 
		, 	TurnoverRM				DECIMAL(20,4)
		, 	WinlossRM				DECIMAL(20,4)
		, 	BetCount				BIGINT
		, 	ActiveDays				INT	
		, 	LastXDaysMargin   		DECIMAL(20,4)
		, 	ProbationPeriodWinloss 	DECIMAL(20,4)
		,	TaggingID				SMALLINT
		,	TaggingType				SMALLINT	
		, 	DWCateGroup				SMALLINT
		,	DWCateID				SMALLINT
		,	ExistedCateGroup 		SMALLINT
		,	ExistedCateID 			SMALLINT
		, 	NewCateGroup			SMALLINT
		,	NewCateID				SMALLINT
		,	SourceTypeID      		SMALLINT
        ,	IsDataChanged			BIT DEFAULT 1 /*0: No change category => No Action*/
		,	TargetCC				SMALLINT
		,	TargetDangerLevel1		SMALLINT
		,	TWBetCount				BIGINT
        ,	TWGroupBettingRate		DECIMAL(10,4)
        ,	TWTicketRejectRate		DECIMAL(10,4)
        ,	TWDesktopUsageRate		DECIMAL(10,4)
		, 	ActionType				SMALLINT DEFAULT 0 /* 0: Insert; 1: Update, 3: Ignore Exist PA, 4: Ignore PIN; 5: Not Pass Probation*/
        , 	INDEX    			    IX_Temp_NewClassification(CustID, DWCateGroup)
	); 
	  
	DROP TEMPORARY TABLE IF EXISTS Temp_OldClassification;    
	CREATE TEMPORARY TABLE Temp_OldClassification(	  
			CustID					BIGINT UNSIGNED	PRIMARY KEY
        ,	OldCateGroup 			SMALLINT
        ,	OldCateID 				SMALLINT
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;    
	CREATE TEMPORARY TABLE Temp_CustInfo(	  	
			CustID					BIGINT UNSIGNED PRIMARY KEY
        , 	CTSCustID				BIGINT DEFAULT 0   
        , 	SubscriberID			INT DEFAULT 0        
        ,	IsLicensee				BIT      
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustIgnoranceAction;    
	CREATE TEMPORARY TABLE Temp_CustIgnoranceAction(	  	
			CustID					BIGINT UNSIGNED	PRIMARY KEY
        , 	ActionType				SMALLINT      
	); 
    
    /* START */
	/* 1: PARSE RAW DATA */
	INSERT INTO Temp_NewClassification(CustID, DWCateGroup, DWCateID, TurnoverRM, WinlossRM, BetCount, ActiveDays, LastXDaysMargin, ProbationPeriodWinloss, TaggingID, TaggingType, TWBetCount, TWGroupBettingRate, TWTicketRejectRate, TWDesktopUsageRate)
	SELECT DISTINCT temp.CustID
				, 	temp.DWCateGroup
				,	IFNULL(tag.CategoryID, temp.DWCateGroup)
				, 	temp.TurnoverRM
				, 	temp.WinlossRM
				, 	temp.BetCount
				, 	temp.ActiveDays
				, 	temp.LastXDaysMargin
				, 	temp.ProbationPeriodWinloss
				,	IFNULL(temp.TaggingID, -99)
				, 	temp.TaggingType
                ,	temp.TWBetCount
                , 	temp.TWGroupBettingRate
                , 	temp.TWTicketRejectRate
                , 	temp.TWDesktopUsageRate
	FROM JSON_TABLE(ip_NewClassification,
		"$[*]" COLUMNS(
					CustID 					BIGINT UNSIGNED		PATH "$.CustId"
				, 	DWCateGroup				SMALLINT UNSIGNED	PATH "$.CategoryId"
				, 	TurnoverRM				DECIMAL(20,4)		PATH "$.TurnoverRM"
				, 	WinlossRM				DECIMAL(20,4)		PATH "$.WinlossRM"
				, 	BetCount				BIGINT				PATH "$.BetCount"
				, 	ActiveDays				INT					PATH "$.ActiveDays"		
				, 	LastXDaysMargin			DECIMAL(20,4)		PATH "$.LastXDaysMargin"		
				, 	ProbationPeriodWinloss	DECIMAL(20,4)		PATH "$.ProbationPeriodWinloss"
				, 	TaggingID				SMALLINT			PATH "$.TaggingID"
				, 	TaggingType				SMALLINT			PATH "$.TaggingType"	
				,	TWBetCount				BIGINT				PATH "$.TWBetCount"
				,	TWGroupBettingRate		DECIMAL(10,4)		PATH "$.TWGroupBettingRate"
				,	TWTicketRejectRate		DECIMAL(10,4)		PATH "$.TWTicketRejectRate"
				,	TWDesktopUsageRate		DECIMAL(10,4)		PATH "$.TWDesktopUsageRate"
		 )) AS 	temp
		LEFT JOIN TaggingToCategory AS tag ON tag.CategoryGroup = temp.DWCateGroup 
			AND tag.TaggingType = temp.TaggingType AND temp.TaggingID = tag.TaggingID
	WHERE temp.DWCateGroup <> 0;
    
	/* 2: EXCLUDE INTERNAL CUSTOMERS */    
	CALL CTS_DC_ExcludeCustByCondition('Temp_NewClassification');
	
	/* 3: FILL UP CUSTOMERS' INFO */
    INSERT INTO Temp_CustInfo(CustID, CTSCustID, SubscriberID, IsLicensee)
    SELECT 	DISTINCT temp.CustID, cust.CTSCustID, cust.SubscriberID
		, 	CASE WHEN map.SubscriberGroupID = 2 THEN 1 /*Licensee*/ ELSE 0 /*Credit/CN88*/ END AS IsLicensee
    FROM 	Temp_NewClassification AS temp 
		INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON temp.CustID = cust.CustID AND cust.CustSubID = 0
        INNER JOIN CTS_DataCenter.MappingSubscriberSite AS map ON map.SubscriberID = cust.SubscriberID;
        
    UPDATE Temp_NewClassification AS temp 
		INNER JOIN Temp_CustInfo AS cust ON temp.CustID = cust.CustID
	SET		temp.CTSCustID = cust.CTSCustID
		, 	temp.SubscriberID = cust.SubscriberID
        ,	temp.IsLicensee = cust.IsLicensee;
	
    /* 4: EXCLUDE CATEGORIES THAT SHOULD NOT BE UPDATED */
	/* 4.1: NOT PASS PROBATION RULES */    
    INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, ActionType)
    SELECT 	temp.CustID, CONST_ACTIONTYPE_IGNOREPROBATION
	FROM 	Temp_NewClassification AS temp
		INNER JOIN 	ProbationAccountMonitor AS pro ON temp.CustID = pro.CustID
    WHERE 	(temp.DWCateGroup IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK, CONST_CATEGORY_PROBATION) 
				AND pro.CreatedDate > lv_FromProbationLastDay) 
			OR (pro.CreatedDate >= lv_ToProbationLastDay);
    
	/* 4.2: EXCLUDE PIN CATEGORY */
    INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, ActionType)
    SELECT 	temp.CustID, CONST_ACTIONTYPE_IGNOREPIN
	FROM 	Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.PinCustomerCategory AS pin on pin.CTSCustID = temp.CTSCustID;
    
	/* 4.3: EXCLUDE PROBLEM ACCOUNTS */
    INSERT IGNORE INTO Temp_CustIgnoranceAction(CustID, ActionType)
    SELECT 	temp.CustID, CONST_ACTIONTYPE_EXISTEDPA
    FROM 	Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON cate.CustID = temp.CustID AND cate.SportGroupID = CONST_GROUP_PA;
    
    /* 4.4: UPDATE BACK TO Temp_NewClassification */
   	UPDATE 	Temp_NewClassification AS c 
		INNER JOIN Temp_CustIgnoranceAction AS i ON c.CustID = i.CustID
    SET 	c.ActionType = i.ActionType
		, 	c.IsDataChanged = 0;
    
	/* 5: GET CUSTOMERS' EXISTING CATEGORY */  
    INSERT INTO Temp_OldClassification(CustID, OldCateGroup, OldCateID)
    SELECT 	temp.CustID, cc.CategoryGroup, cate.CategoryID
    FROM 	Temp_NewClassification AS temp
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cate ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_NORMAL
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = cate.CategoryID
	WHERE 	temp.ActionType = CONST_ACTIONTYPE_INSERT;
    
    UPDATE 	Temp_NewClassification AS n
		LEFT JOIN Temp_OldClassification AS o ON n.CustID = o.CustID
	SET 	n.ExistedCateGroup = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateGroup END,
			n.ExistedCateID = CASE WHEN o.CustID IS NULL THEN CONST_CATEGORY_NEWMEMBER ELSE o.OldCateID END,
			n.ActionType = CASE WHEN o.CustID IS NULL THEN CONST_ACTIONTYPE_INSERT ELSE CONST_ACTIONTYPE_UPDATE END;
    
	/* 6: CHECK RULES FOR CLASSIFICATION */
    /* 6.1: ACTIVE ACCOUNTS --> MANAGE FOR NORMAL CASES */
	UPDATE 	Temp_NewClassification AS temp 
	SET 	temp.NewCateGroup = 
		(	CASE WHEN temp.ExistedCateGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER, CONST_CATEGORY_VIP, CONST_CATEGORY_INACTIVE) 
					AND temp.DWCateGroup IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK) 
				THEN CONST_CATEGORY_PROBATION
			ELSE temp.DWCateGroup END
		)
	WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) AND temp.DWCateGroup <> CONST_CATEGORY_INACTIVE;
	
    /* 6.2: ACTIVE ACCOUNTS --> ADD UP TAGGING */
	UPDATE 	Temp_NewClassification AS temp 
		LEFT JOIN TaggingToCategory AS tag ON tag.CategoryGroup = temp.NewCateGroup AND tag.TaggingType = temp.TaggingType AND temp.TaggingID = tag.TaggingID
	SET 	temp.NewCateID = IFNULL(tag.CategoryID, temp.NewCateGroup)
	WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) 
			AND temp.DWCateGroup <> CONST_CATEGORY_INACTIVE;
    
    /* 6.3: INACTIVE ACCOUNTS */
    UPDATE 	Temp_NewClassification AS temp 
    SET 	temp.NewCateID = 
		(	CASE WHEN temp.ExistedCateGroup IS NULL OR temp.ExistedCateGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER, CONST_CATEGORY_VIP) 
				THEN CONST_CATEGORY_NORMALINACTIVE
			WHEN temp.ExistedCateGroup IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK, CONST_CATEGORY_PROBATION) 
				THEN CONST_CATEGORY_PROPUNTERINACTIVE /*Pro Punter Inactive*/ 
			ELSE temp.ExistedCateID END
		)
    WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE) AND temp.DWCateGroup = CONST_CATEGORY_INACTIVE;
		
	/* 7: UPDATE SOURCE TYPE */   
	UPDATE 	Temp_NewClassification AS temp 
	SET 	temp.SourceTypeID = 
		(	CASE WHEN temp.ExistedCateGroup IS NULL AND temp.NewCateGroup = CONST_CATEGORY_NEWMEMBER 
				THEN CONST_SOURCETYPE_LESSTHAN10TICKETS
			 WHEN temp.ExistedCateGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_INACTIVE) AND temp.NewCateGroup NOT IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_INACTIVE) 
				THEN CONST_SOURCETYPE_AFTER10TICKETS
			 WHEN temp.ExistedCateGroup = CONST_CATEGORY_PROBATION AND temp.NewCateGroup IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK) 
				THEN CONST_SOURCETYPE_PASSPROBATION
			 WHEN (temp.ExistedCateGroup = CONST_CATEGORY_PROBATION AND temp.NewCateGroup = CONST_CATEGORY_PROBATION) 
				THEN CONST_SOURCETYPE_FAILPROBATION
			 WHEN (temp.ExistedCateGroup IS NULL OR temp.ExistedCateGroup IN (CONST_CATEGORY_NEWMEMBER, CONST_CATEGORY_NORMALMEMBER, CONST_CATEGORY_VIP)) AND temp.NewCateGroup = CONST_CATEGORY_INACTIVE 
				THEN CONST_SOURCETYPE_INACTIVENORMAL
			 WHEN temp.ExistedCateGroup IN (CONST_CATEGORY_SMART, CONST_CATEGORY_HIGHRISK, CONST_CATEGORY_PROBATION) AND temp.NewCateGroup = CONST_CATEGORY_INACTIVE 
				THEN CONST_SOURCETYPE_INACTIVEPROPUNTER
			 ELSE CONST_SOURCETYPE_SCANONSCHEDULE END
		)
	WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
	
    /* 8: UPDATE IsDataChanged */ 
    UPDATE 	Temp_NewClassification AS temp
	SET 	temp.IsDataChanged = (	CASE WHEN temp.NewCateID = temp.ExistedCateID AND temp.SourceTypeID <> CONST_SOURCETYPE_FAILPROBATION
										THEN 0 /*No update category*/ 
									ELSE temp.IsDataChanged END
								 )
	WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
    
	/* 9: UPDATE TARGET CC */
	UPDATE 	Temp_NewClassification AS temp 
		LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON sp.CTSCustID = temp.CTSCustID AND sp.CreatedFromFunction = 1
		LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS n ON n.CategoryID = temp.NewCateID
	SET 	temp.TargetCC = IFNULL(sp.CustomerClass, n.CustomerClass)
	WHERE 	temp.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
    
	/* 10: UPDATE TARGET DANGER LEVEL 1 */
	UPDATE 	Temp_NewClassification AS temp 
		INNER JOIN CTS_DataCenter.CategoryToDangerLevel AS d ON d.CategoryID = temp.NewCateID 
			AND d.IsLicensee = temp.IsLicensee AND d.TypeID = 1
	SET 	temp.TargetDangerLevel1 = d.DangerLevel;
    
	/* 11: UPDATE CATEGORY TO CTS */
	UPDATE 	CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_NewClassification AS temp ON temp.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_NORMAL
	SET   	cate.CTSCustID = temp.CTSCustID
		, 	cate.SubscriberID = temp.SubscriberID
		, 	cate.CategoryID = temp.NewCateID
		, 	cate.LastModifiedDate = lv_CurrentDateTime
		, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
	WHERE 	temp.ActionType = CONST_ACTIONTYPE_UPDATE;

	/* 12: INSERT NEW CATEGORY TO CTS */
	INSERT INTO CTS_DataCenter.CTSCustomerClassification (CustID, CTSCustID, SubscriberID, SportGroupID, 
		CategoryID, CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT DISTINCT temp.CustID
				, 	temp.CTSCustID
				, 	temp.SubscriberID
				, 	CONST_GROUP_NORMAL
				, 	temp.NewCateID
				,	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	lv_CurrentDateTime
				, 	lv_CreatedBy
				, 	DATE(lv_CurrentDateTime) AS LastScannedDate
	 FROM 	Temp_NewClassification AS temp
	 WHERE 	temp.ActionType = CONST_ACTIONTYPE_INSERT; 

	/* 13: REMOVE CUSTOMERS JUMPED FROM PROBATION TO ANOTHER CATEGORY */
	DELETE 	pro
	FROM 	CTS_DataCenter.ProbationAccountMonitor AS pro
		INNER JOIN Temp_NewClassification AS temp ON temp.CustID = pro.CustID AND pro.SportGroupID = CONST_GROUP_NORMAL
	WHERE 	temp.ActionType = CONST_ACTIONTYPE_UPDATE AND temp.ExistedCateGroup = CONST_CATEGORY_PROBATION 
		AND temp.NewCateGroup <> CONST_CATEGORY_PROBATION;
	
	/* 14: INSERT NEW PROBATION */
	INSERT IGNORE INTO CTS_DataCenter.ProbationAccountMonitor (CustID, CTSCustID, SportGroupID, TargetCategoryID, 
		FirstMargin, CreatedDate, CreatedBy, CreatedTime, LastScannedDate) 
	SELECT DISTINCT	temp.CustID
				, 	temp.CTSCustID
				, 	CONST_GROUP_NORMAL
				, 	temp.DWCateID
				, 	(CASE WHEN temp.TurnoverRM = 0 THEN 0 ELSE (temp.WinlossRM/temp.TurnoverRM) * 100 END)
				, 	DATE(lv_CurrentDateTime) AS CreatedDate
				, 	lv_CreatedBy
				, 	lv_CurrentDateTime
				,   DATE(lv_CurrentDateTime) AS LastScannedDate
	FROM 	Temp_NewClassification AS temp
	WHERE 	temp.NewCateGroup = CONST_CATEGORY_PROBATION 
			AND (temp.ActionType = CONST_ACTIONTYPE_INSERT 
				OR (temp.ActionType = CONST_ACTIONTYPE_UPDATE  AND temp.ExistedCateGroup <> CONST_CATEGORY_PROBATION));
	
	/* 15: WRITE LOG*/
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History (CustID, CTSCustID, CategoryID, SportGroupID, 
		LastModifiedDate, LastModifiedBy, TurnoverRM, WinlossRM, BetCount, ActiveDays, ActionType, IsAuto, InsertDate, 
        LastXDaysMargin, ProbationPeriodWinloss, TargetCC, SourceTypeID, FromCategoryID, ToCategoryID, IsDataChanged, 
        TaggingType, TargetDangerLevel1)
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
				, 	temp.ActionType
				, 	1 AS IsAuto
				, 	DATE(lv_CurrentDateTime)
				, 	temp.LastXDaysMargin
				, 	temp.ProbationPeriodWinloss
				,	temp.TargetCC 
				,   temp.SourceTypeID
				, 	temp.ExistedCateID 
				, 	temp.DWCateID
				,   temp.IsDataChanged
				,	temp.TaggingType
				,	temp.TargetDangerLevel1
	FROM 	Temp_NewClassification AS temp;
	   
	/* 16: RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS */
	SELECT DISTINCT CustId 
    FROM Temp_NewClassification 
    WHERE ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE);
    
END$$
DELIMITER ;