/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_InsertProblemAccount`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_InsertProblemAccount`(
		IN ip_ProblemAccounts 	JSON
    ,	IN ip_IsRescan 			BIT
    
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
            
        Param's Explanation (filtered by):
        Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_InsertProblemAccount('[{"CustID": 456, "ReasonID": 59, "RobotCounter": 0}]',0,@op_ErrorMessage);
	*/   
    DECLARE	CONST_CATEGORYID_ROBOTUSERS 		INT DEFAULT 61;
    DECLARE	CONST_CATEGORYID_BADROBOTUSERS 		INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_GOODROBOTUSERS 	INT DEFAULT 164;
    
    DECLARE CONST_ACTIONTYPE_INSERT 			INT DEFAULT 0;
	DECLARE	CONST_ACTIONTYPE_UPDATE 			INT DEFAULT 1;
	DECLARE CONST_ACTIONTYPE_REMOVE 			INT DEFAULT 2;
    DECLARE CONST_ACTIONTYPE_IGNOREPIN 			INT DEFAULT 4;
    
    DECLARE	CONST_GROUP_PA 						INT DEFAULT 0;
	DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
    
    DECLARE lv_CreatedBy 						INT DEFAULT 10278938;
    DECLARE lv_CurrentDateTime 					DATETIME DEFAULT CURRENT_TIME(); 
    
    /*  1: Get Mapping category*/
	CALL CTS_DC_CustClassification_MappingPACategory(ip_ProblemAccounts, 'NAP');
    
    /*	2: REMOVE GENERAL CATEGORY BEFORE	*/
    DELETE clss
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS pa ON pa.CustID = clss.CustID AND clss.SportGroupID = CONST_GROUP_NORMAL
	WHERE pa.ActionType = CONST_ACTIONTYPE_INSERT;
    
    /*	3: REMOVE PROBATION LIST BEFORE	*/
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
		INNER JOIN Temp_PA AS pa ON pa.CustID = pro.CustID
	WHERE pa.ActionType = CONST_ACTIONTYPE_INSERT;
    
    /*	4: REMOVE PA FROM NAP CM */
    DELETE clss
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS pa ON pa.CustID = clss.CustID AND clss.SportGroupID = CONST_GROUP_PA
        INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = clss.CategoryID
	WHERE pa.ActionType = CONST_ACTIONTYPE_REMOVE AND cate.SourceType = 'NAP';
    
    /*	5: REMOVE ROBOT USER CATEGORY	*/
    DELETE clss
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS pa ON pa.CustID = clss.CustID AND clss.SportGroupID = CONST_GROUP_PA 
	WHERE pa.ActionType = CONST_ACTIONTYPE_INSERT		
		AND ((clss.CategoryID = CONST_CATEGORYID_ROBOTUSERS AND pa.CategoryID IN (CONST_CATEGORYID_GOODROBOTUSERS,CONST_CATEGORYID_BADROBOTUSERS))
			OR (clss.CategoryID IN (CONST_CATEGORYID_GOODROBOTUSERS,CONST_CATEGORYID_BADROBOTUSERS) AND pa.CategoryID <> clss.CategoryID));
     
     /*	6: UPDATE PA FROM NAP CM */
     UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS pa on pa.CustID = clss.CustID AND clss.SportGroupID = CONST_GROUP_PA AND pa.CategoryID = clss.CategoryID 
	SET 	clss.CTSCustID = pa.CTSCustID
		, 	clss.SubscriberID  = pa.SubscriberID
		, 	clss.LastModifiedBy = lv_CreatedBy
		,   clss.LastModifiedDate = lv_CurrentDateTime
		, 	clss.LastScannedDate = DATE(lv_CurrentDateTime)
	WHERE pa.ActionType = CONST_ACTIONTYPE_UPDATE
		AND pa.CategoryID <> CONST_CATEGORYID_ROBOTUSERS;
        
	/*	7: UPDATE PA By Winloss Probation */
    UPDATE CTS_DataCenter.CTSCustomerClassification AS cate
		INNER JOIN Temp_ExistedClassification AS pa on pa.CustID = cate.CustID AND cate.SportGroupID = CONST_GROUP_PA AND pa.CategoryID = cate.CategoryID 
	SET 	cate.CTSCustID = pa.CTSCustID
		,	cate.CategoryID = pa.RelevantCategoryID
		, 	cate.LastModifiedBy = lv_CreatedBy
		,   cate.LastModifiedDate = lv_CurrentDateTime
		, 	cate.LastScannedDate = DATE(lv_CurrentDateTime)
	WHERE pa.IsChangeByWinloss = 1;
	
    /*	8: INSERT NEW PA FROM NAP CM */
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID, 
	CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	pa.CustID
		,	pa.CTSCustID
		, 	pa.SubscriberID
		, 	pa.CategoryID
		, 	0
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	DATE(lv_CurrentDateTime)
	FROM Temp_PA AS pa
    WHERE pa.ActionType = CONST_ACTIONTYPE_INSERT;      
	
    IF (ip_IsRescan = 1) THEN
		UPDATE Temp_PA AS pa 
		SET pa.SourceTypeID = CONST_SOURCETYPE_RESCANBYNAPPA;
	
    END IF;
    
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT 	DISTINCT 
			pa.CustID
		, 	pa.CTSCustID
		, 	pa.CategoryID
		, 	CONST_GROUP_PA
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	pa.ActionType
		, 	1
		, 	DATE(lv_CurrentDateTime)
		, 	pa.TargetCC
		, 	pa.SourceTypeID
		,  	pa.IsDataChanged
		,	pa.RobotCounter
		,	pa.TargetDangerLevel AS TargetDangerLevel1
		,	pa.TurnoverRM
		,	pa.WinlossRM
		, 	pa.BetCount
		, 	pa.ActiveDays
	FROM Temp_PA AS pa
	WHERE pa.IsDataChanged = 1;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT 	DISTINCT 
			pa.CustID
		, 	pa.CTSCustID
		, 	pa.CategoryID 
		, 	CONST_GROUP_PA
		, 	lv_CurrentDateTime
		, 	lv_CreatedBy
		, 	pa.ActionType
		, 	1
		, 	DATE(lv_CurrentDateTime)
		, 	pa.TargetCC
		, 	pa.SourceTypeID
		,   pa.IsDataChanged
		,	pa.RobotCounter
		,	pa.TargetDangerLevel AS TargetDangerLevel1
        ,	pa.TurnoverRM
		,	pa.WinlossRM
		, 	pa.BetCount
		, 	pa.ActiveDays
	FROM Temp_PA AS pa;
	
	/* 19: RETURN UPDATED CUSTOMERS TO SERVICE FOR FUTHER STEPS */
	SELECT	DISTINCT 
			pa.CustID
		,	pa.CTSCustID
    FROM Temp_PA AS pa 
    WHERE pa.ActionType IN (CONST_ACTIONTYPE_INSERT, CONST_ACTIONTYPE_UPDATE, CONST_ACTIONTYPE_REMOVE); 
END$$
DELIMITER ;