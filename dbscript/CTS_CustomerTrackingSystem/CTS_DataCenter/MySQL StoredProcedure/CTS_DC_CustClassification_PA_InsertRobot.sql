/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_PA_InsertRobot`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_InsertRobot`(
		IN 		ip_CustInfo 	JSON
)
    SQL SECURITY INVOKER
BEGIN
/*
		Created:	20220520@Aries.Nguyen
		Task :		Renovate PA Process
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
			- 20220520@Aries.Nguyen: Created [Redmine ID: #172561]
		
        Param's Explanation:

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_InsertRobot("1,2,3,4");
*/
	DECLARE	CONST_CATEGORYID_ROBOTUSERS 		INT DEFAULT 61;
    DECLARE	CONST_CATEGORYID_BADROBOTUSERS 		INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_GOODROBOTUSERS 	INT DEFAULT 164;
	
    DECLARE	CONST_CATEGORYID_ROBOTBETTING 		INT DEFAULT 63;
    DECLARE	CONST_CATEGORYID_GOODROBOTBETTING 	INT DEFAULT 166;
    DECLARE	CONST_CATEGORYID_BADROBOTBETTING 	INT DEFAULT 165;
    
    DECLARE	CONST_GROUP_PA 						INT DEFAULT 0;
    DECLARE CONST_SOURCETYPE_INSERTROBOTUSERS	INT DEFAULT 11;
    DECLARE lv_Now								DATETIME DEFAULT NOW();
    
	DROP TEMPORARY TABLE IF EXISTS Temp_PA;    
	CREATE TEMPORARY TABLE Temp_PA(	  
			CTSCustID				BIGINT UNSIGNED 
		,	CustID					BIGINT UNSIGNED 
		, 	SubscriberID			INT 
        ,	IsLicensee				BIT
        ,	IsRobotException 		BIT DEFAULT 0 
        
		,	CategoryID 				INT	
        ,	TargetCC				SMALLINT
		,	TargetDangerLevel		SMALLINT UNSIGNED
        
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT 
		,	RobotCounter			INT 
        
        ,	IsFromTW				BIT
		,	CreatedBy				BIT
        , 	PRIMARY KEY(CustID,CategoryID)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistCateRobot;    
	CREATE TEMPORARY TABLE Temp_ExistCateRobot(	  
			CustID			BIGINT UNSIGNED 
        ,	CategoryID 		INT	
        ,  	PRIMARY KEY(CustID,CategoryID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistCateRobot;    
	CREATE TEMPORARY TABLE Temp_ExistCateRobot(	  
			CustID			BIGINT UNSIGNED 
        ,	CategoryID 		INT	
        ,  	PRIMARY KEY(CustID,CategoryID)
    );
    
    INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, SubscriberID,IsLicensee,IsRobotException, CategoryID,TargetCC, TurnoverRM, WinlossRM, BetCount, ActiveDays,RobotCounter, IsFromTW,CreatedBy)
	SELECT	js.CustID
		,	cus.CTSCustID
		,	cus.SubscriberID
        ,	cus.IsLicensee
        ,   CASE WHEN (cus.IsLicensee = 0 AND cus.SubscriberID IN (2,130)) OR (cus.IsLicensee = 1 AND cus.CurrencyID IN (13,78)) THEN 1
				 ELSE 0 
			END AS IsRobotException
        
		, 	js.CategoryID
        ,	sp.CustomerClass AS TargetCC
        , 	js.TurnoverRM
        , 	js.WinlossRM
        , 	js.BetCount
        , 	js.ActiveDays
        ,	js.RobotCounter
        , 	js.IsFromTW
        ,	js.CreatedBy
	FROM JSON_TABLE(ip_CustInfo,
	"$[*]" COLUMNS( CustID 			BIGINT UNSIGNED		PATH "$.CustID"
                ,	CategoryID		BIGINT UNSIGNED		PATH "$.CategoryID"
                
                ,	RobotCounter	INT 				PATH "$.RobotCounter"
				,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
				,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
				, 	BetCount		BIGINT 				PATH "$.BetCount"
				, 	ActiveDays		INT 				PATH "$.ActiveDays"
                
                , 	IsFromTW		BOOLEAN 			PATH "$.IsFromTW"
                , 	CreatedBy		INT 				PATH "$.CreatedBy"
	)) AS js 
		INNER JOIN  CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = js.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0
		LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on cus.CTSCustID = pin.CTSCustID
        LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON cus.CustID = sp.CustID 
        LEFT JOIN CTS_DataCenter.CTSCustomerClassificationVVIP AS vip on cus.CTSCustID = vip.CTSCustID
	WHERE pin.CTSCustID IS NULL
		AND  vip.CTSCustID IS NULL; 

    INSERT INTO Temp_ExistCateRobot(CustID,CategoryID)
    SELECT 	clss.CustID
		,	clss.CategoryID
    FROM CTSCustomerClassification AS clss
    WHERE EXISTS (SELECT 1 
				  FROM Temp_PA AS tmp 
                  WHERE clss.CustID = tmp.CustID 
					AND   ((clss.CategoryID = CONST_CATEGORYID_ROBOTUSERS AND tmp.CategoryID IN (CONST_CATEGORYID_BADROBOTUSERS,CONST_CATEGORYID_GOODROBOTUSERS))
						OR (clss.CategoryID = CONST_CATEGORYID_ROBOTBETTING AND tmp.CategoryID IN (CONST_CATEGORYID_GOODROBOTBETTING,CONST_CATEGORYID_BADROBOTBETTING))
						OR (tmp.CategoryID = CONST_CATEGORYID_ROBOTUSERS AND clss.CategoryID IN (CONST_CATEGORYID_BADROBOTUSERS,CONST_CATEGORYID_GOODROBOTUSERS))
                        OR (tmp.CategoryID = CONST_CATEGORYID_ROBOTBETTING AND clss.CategoryID IN (CONST_CATEGORYID_GOODROBOTBETTING,CONST_CATEGORYID_BADROBOTBETTING))));
   
    DELETE clss
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
	WHERE EXISTS (SELECT 1 
				  FROM Temp_ExistCateRobot AS tmp 
                  WHERE clss.CustID = tmp.CustID 
					AND clss.CategoryID IN(CONST_CATEGORYID_ROBOTUSERS,CONST_CATEGORYID_ROBOTBETTING));
	
    DELETE pa
    FROM Temp_PA AS pa
	WHERE EXISTS (SELECT 1 
				  FROM Temp_ExistCateRobot AS tmp 
                  WHERE pa.CustID = tmp.CustID 
					AND pa.CategoryID IN(CONST_CATEGORYID_ROBOTUSERS,CONST_CATEGORYID_ROBOTBETTING)); 
    
    UPDATE Temp_PA AS pa
	INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON pa.CategoryID = cate.CategoryID
	SET pa.TargetCC	= CASE  WHEN pa.TargetCC IS NOT NULL THEN pa.TargetCC
							WHEN pa.CategoryID IN (CONST_CATEGORYID_GOODROBOTUSERS,CONST_CATEGORYID_GOODROBOTBETTING) AND pa.IsRobotException = 1 THEN cate.CustomerClassException
                            WHEN pa.TargetCC IS NULL THEN IFNULL(cate.CustomerClass, -99) 
							ELSE  -99 END 
	,	pa.CategoryID = CASE WHEN pa.CategoryID = CONST_CATEGORYID_GOODROBOTUSERS AND pa.IsRobotException = 1 THEN CONST_CATEGORYID_ROBOTUSERS
							 WHEN pa.CategoryID = CONST_CATEGORYID_GOODROBOTBETTING AND pa.IsRobotException = 1 THEN CONST_CATEGORYID_ROBOTBETTING
							 ELSE pa.CategoryID
							 END
            
	,	pa.TargetDangerLevel = CASE WHEN pa.CategoryID IN (CONST_CATEGORYID_GOODROBOTUSERS,CONST_CATEGORYID_GOODROBOTBETTING) AND pa.IsRobotException = 1 AND pa.IsLicensee = 1 THEN cate.ABIDangerLevelException_Licensee
									WHEN pa.CategoryID IN (CONST_CATEGORYID_GOODROBOTUSERS,CONST_CATEGORYID_GOODROBOTBETTING) AND pa.IsRobotException = 1 AND pa.IsLicensee = 0 THEN cate.ABIDangerLevelException_Credit
									WHEN pa.IsLicensee = 1 THEN cate.ABIDangerLevel_Licensee
									WHEN pa.IsLicensee = 0 THEN cate.ABIDangerLevel_Credit				
								END;
 
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID,CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate,IsFromTW, IsDirect)
	SELECT 	CustID
		,	CTSCustID
		, 	SubscriberID
		, 	CategoryID
		, 	CONST_GROUP_PA
		, 	lv_Now
		, 	CreatedBy
		, 	lv_Now
		, 	CreatedBy
		, 	DATE(lv_Now)
        ,	IsFromTW
        ,	1 AS IsDirect
	FROM Temp_PA AS pa;  
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays,IsDirect)
	SELECT 	CustID
		, 	CTSCustID
		, 	CategoryID
		, 	CONST_GROUP_PA
		, 	lv_Now
		, 	CreatedBy
		, 	1 AS ActionType
		, 	1
		, 	DATE(lv_Now)
		, 	TargetCC
		, 	CONST_SOURCETYPE_INSERTROBOTUSERS AS SourceTypeID
		,  	1 AS IsDataChanged
		,	RobotCounter
		,	TargetDangerLevel AS TargetDangerLevel1
		,	TurnoverRM
		,	WinlossRM
		, 	BetCount
		, 	ActiveDays
        ,	1 AS IsDirect
	FROM Temp_PA AS pa;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays,IsDirect)
	SELECT 	DISTINCT 
			CustID
		, 	CTSCustID
		, 	CategoryID 
		, 	CONST_GROUP_PA
		, 	lv_Now
		, 	CreatedBy
		, 	1 AS ActionType
		, 	1
		, 	DATE(lv_Now)
		, 	TargetCC
		, 	CONST_SOURCETYPE_INSERTROBOTUSERS AS SourceTypeID
		,   1 AS IsDataChanged
		,	RobotCounter
		,	TargetDangerLevel AS TargetDangerLevel1
        ,	TurnoverRM
		,	WinlossRM
		, 	BetCount
		, 	ActiveDays
		,	1 AS IsDirect
	FROM Temp_PA AS pa;


	SELECT CTSCustID
		,  CustID
    FROM Temp_PA;

END$$
DELIMITER ;