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
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_InsertRobot('[{"CustID":1,"CategoryID":61}]');
*/
	DECLARE	CONST_CATEGORYID_ROBOT 		INT DEFAULT 61;
    DECLARE	CONST_CATEGORYID_BADROBOT 	INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_GOODROBOT 	INT DEFAULT 164;
    
    DECLARE CONST_ROBOTTYPE_OBSERVED 	TINYINT UNSIGNED DEFAULT 0;
    DECLARE CONST_ROBOTTYPE_GOOD 		TINYINT UNSIGNED DEFAULT 1;
    DECLARE CONST_ROBOTTYPE_BAD 		TINYINT UNSIGNED DEFAULT 2;
    
    DECLARE	CONST_GROUP_PA 						INT DEFAULT 0;
    DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
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
        ,	IsFromCTS				BIT
        ,	IsFromAI				BIT
        ,	IsDirect				BIT
        ,	IsDataChanged			BIT DEFAULT 1
        
        ,	Remark					VARCHAR(500)
		,	CreatedBy				INT UNSIGNED
        , 	PRIMARY KEY(CustID,CategoryID)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotClassification;    
	CREATE TEMPORARY TABLE Temp_RobotClassification (	  
			CustID			BIGINT UNSIGNED 
		, 	CategoryID		BIGINT UNSIGNED 
		,	Turnover 		DECIMAL(20,4) 
		,	Winloss 		DECIMAL(20,4) 
		,	BetCount 		INT 
		,	ActiveDays 		TINYINT UNSIGNED 
		,	PRIMARY KEY(CustID,CategoryID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistCateRobot;    
	CREATE TEMPORARY TABLE Temp_ExistCateRobot(	  
			CustID			BIGINT UNSIGNED 
        ,	CategoryID 		INT	
        ,	IsFromTW		BIT
		,	IsFromCTS		BIT
        ,	IsFromAI		BIT
        ,	IsDirect		BIT
        ,	Remark			VARCHAR(500)
		,	CreatedBy		INT UNSIGNED
        ,  	PRIMARY KEY(CustID,CategoryID)
    );
    
    INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, SubscriberID,IsLicensee,IsRobotException, CategoryID,TargetCC, TurnoverRM, WinlossRM, BetCount, ActiveDays,RobotCounter, IsFromTW,IsFromCTS,IsFromAI,IsDirect,Remark,CreatedBy)
	SELECT	js.CustID
		,	cus.CTSCustID
		,	cus.SubscriberID
        ,	cus.IsLicensee
        ,   CASE WHEN (cus.IsLicensee = 0 AND cus.SiteID = 16) OR (cus.IsLicensee = 1 AND cus.CurrencyID IN (6,13)) THEN 1
				 ELSE 0 
			END AS IsRobotException
        
		, 	CONST_CATEGORYID_ROBOT AS CategoryID
        ,	sp.CustomerClass AS TargetCC
        , 	js.TurnoverRM
        , 	js.WinlossRM
        , 	js.BetCount
        , 	js.ActiveDays
        ,	js.RobotCounter
        , 	IFNULL(js.IsFromTW,0) AS IsFromTW
		,	IFNULL(js.IsFromCTS,0) AS IsFromCTS		
        ,	IFNULL(js.IsFromAI,0) AS IsFromAI
        ,	IFNULL(js.IsDirect,0) AS IsDirect	
        ,	js.Remark
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
                , 	IsFromCTS		BOOLEAN 			PATH "$.IsFromCTS"
                , 	IsFromAI		BOOLEAN 			PATH "$.IsFromAI"
                , 	IsDirect		BOOLEAN 			PATH "$.IsDirect"
                
                 , 	Remark			VARCHAR(500)		PATH "$.Remark"
                , 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
	)) AS js 
		INNER JOIN  CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = js.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0
		LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on cus.CTSCustID = pin.CTSCustID
        LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON cus.CustID = sp.CustID 
        LEFT JOIN CTS_DataCenter.CTSCustomerClassificationVVIP AS vip on cus.CTSCustID = vip.CTSCustID
	WHERE pin.CTSCustID IS NULL
		AND  vip.CTSCustID IS NULL
	ON DUPLICATE KEY UPDATE  RobotCounter = IFNULL(Temp_PA.RobotCounter, js.RobotCounter)
						,	 TurnoverRM = IFNULL(Temp_PA.TurnoverRM, js.TurnoverRM)  
                        ,	 WinlossRM = IFNULL(Temp_PA.WinlossRM, js.WinlossRM)  
                        ,	 BetCount = IFNULL(Temp_PA.BetCount, js.BetCount)  
                        ,	 ActiveDays = IFNULL(Temp_PA.ActiveDays, js.ActiveDays)
                        ,	 IsFromTW = CASE WHEN js.IsFromTW = 1 THEN 1 ELSE Temp_PA.IsFromTW END
                        ,	 IsFromCTS = CASE WHEN js.IsFromCTS = 1 THEN 1 ELSE Temp_PA.IsFromCTS END
                        ,	 IsFromAI = CASE WHEN js.IsFromAI = 1 THEN 1 ELSE Temp_PA.IsFromAI END
                        ,	 IsDirect = CASE WHEN js.IsDirect = 1 THEN 1 ELSE Temp_PA.IsDirect END
                        ,	 Remark = CASE WHEN js.IsFromCTS = 1 THEN js.Remark ELSE Temp_PA.Remark END
                        ,	 CreatedBy = CASE WHEN js.IsFromCTS = 1 THEN js.CreatedBy ELSE Temp_PA.CreatedBy END;
	
    INSERT IGNORE INTO Temp_RobotClassification(CustID, CategoryID,Turnover,Winloss,BetCount,ActiveDays)
    SELECT 	tmp.CustID
		,	CASE WHEN tbl.RobotType = CONST_ROBOTTYPE_OBSERVED THEN CONST_CATEGORYID_ROBOT
				WHEN tbl.RobotType = CONST_ROBOTTYPE_GOOD THEN CONST_CATEGORYID_GOODROBOT 
                WHEN tbl.RobotType = CONST_ROBOTTYPE_BAD THEN CONST_CATEGORYID_BADROBOT
			END AS CategoryID
		,	tbl.Turnover 	
		,	tbl.Winloss 	
		,	tbl.BetCount 	
		,	tbl.ActiveDays 	
    FROM Temp_PA AS tmp,
		LATERAL(SELECT 	rb.RobotType
					,	rb.Turnover 	
					,	rb.Winloss 	
					,	rb.BetCount 	
					,	rb.ActiveDays 	
				FROM CTS_DataCenter.RobotClassification AS rb 
                WHERE rb.CustID = tmp.CustID
                ORDER BY rb.CustID ASC
					,	 rb.FromDate DESC
				LIMIT 1) AS tbl;
    
    UPDATE Temp_PA AS pa
	INNER JOIN Temp_RobotClassification AS tw ON pa.CustID = tw.CustID
    SET 	pa.CategoryID = tw.CategoryID
		,	pa.TurnoverRM = tw.Turnover
        ,	pa.WinlossRM = tw.Winloss
        ,	pa.BetCount = tw.BetCount
        ,	pa.ActiveDays = tw.ActiveDays;
    
    INSERT IGNORE INTO Temp_ExistCateRobot(CustID,CategoryID,IsFromTW,IsFromCTS,IsFromAI,IsDirect,Remark,CreatedBy) 
    SELECT 	clss.CustID
		,	clss.CategoryID
        ,	clss.IsFromTW		
		, 	clss.IsFromCTS	
        , 	clss.IsFromAI	
		, 	clss.IsDirect	
        ,	clss.Remark
        ,	clss.CreatedBy
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
    WHERE EXISTS (SELECT 1 
				  FROM Temp_PA AS tmp 
                  WHERE clss.CustID = tmp.CustID 
					AND  clss.CategoryID IN (CONST_CATEGORYID_ROBOT,CONST_CATEGORYID_BADROBOT,CONST_CATEGORYID_GOODROBOT));
	
	UPDATE Temp_PA AS pa
	INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON pa.CategoryID = cate.CategoryID
	SET pa.TargetCC	= CASE  WHEN pa.TargetCC IS NOT NULL THEN pa.TargetCC
							WHEN pa.CategoryID IN (CONST_CATEGORYID_GOODROBOT) AND pa.IsRobotException = 1 THEN cate.CustomerClassException
                            WHEN pa.TargetCC IS NULL THEN IFNULL(cate.CustomerClass, -99) 
							ELSE  -99 END 
	,	pa.CategoryID = CASE WHEN pa.CategoryID = CONST_CATEGORYID_GOODROBOT AND pa.IsRobotException = 1 THEN CONST_CATEGORYID_ROBOT
							 ELSE pa.CategoryID
							 END
	,	pa.TargetDangerLevel = CASE WHEN pa.CategoryID IN (CONST_CATEGORYID_GOODROBOT) AND pa.IsRobotException = 1 AND pa.IsLicensee = 1 THEN cate.ABIDangerLevelException_Licensee
									WHEN pa.CategoryID IN (CONST_CATEGORYID_GOODROBOT) AND pa.IsRobotException = 1 AND pa.IsLicensee = 0 THEN cate.ABIDangerLevelException_Credit
									WHEN pa.IsLicensee = 1 THEN cate.ABIDangerLevel_Licensee
									WHEN pa.IsLicensee = 0 THEN cate.ABIDangerLevel_Credit				
								END;
     
    UPDATE IGNORE Temp_PA AS pa
    SET pa.IsDataChanged =  0
	WHERE EXISTS (SELECT 1 
				  FROM  Temp_ExistCateRobot AS ex  
                  WHERE pa.CustID = ex.CustID  
					AND (pa.CategoryID = ex.CategoryID OR (pa.CategoryID = CONST_CATEGORYID_ROBOT AND ex.CategoryID IN (CONST_CATEGORYID_BADROBOT,CONST_CATEGORYID_GOODROBOT))));
    
	UPDATE IGNORE Temp_PA AS pa
	INNER JOIN Temp_ExistCateRobot AS ex ON pa.CustID = ex.CustID  
    SET pa.CategoryID =  ex.CategoryID
    WHERE pa.IsDataChanged =  0
		AND pa.CategoryID = CONST_CATEGORYID_ROBOT 
        AND ex.CategoryID IN (CONST_CATEGORYID_BADROBOT,CONST_CATEGORYID_GOODROBOT);
	
    UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
    INNER JOIN Temp_PA AS pa ON  pa.CustID = clss.CustID AND pa.CategoryID = clss.CategoryID AND pa.IsDataChanged = 0
    SET 	clss.CreatedBy = CASE WHEN pa.IsFromCTS = 1 THEN pa.CreatedBy ELSE clss.CreatedBy END  
		,	clss.Remark =  CASE WHEN pa.IsFromCTS = 1 THEN pa.Remark ELSE clss.Remark END  
		,	clss.IsFromTW =   CASE WHEN pa.IsFromTW = 1 THEN pa.IsFromTW ELSE clss.IsFromTW END  
        ,	clss.IsFromCTS =  CASE WHEN pa.IsFromCTS = 1 THEN pa.IsFromCTS ELSE clss.IsFromCTS END  
        ,	clss.IsFromAI =  CASE WHEN pa.IsFromAI = 1 THEN pa.IsFromAI ELSE clss.IsFromAI END  
        ,	clss.IsDirect = CASE WHEN pa.IsDirect = 1 THEN pa.IsDirect ELSE clss.IsDirect END ;
    
	UPDATE IGNORE Temp_PA AS pa
	INNER JOIN Temp_ExistCateRobot AS ex ON pa.CustID = ex.CustID AND pa.CategoryID != ex.CategoryID AND pa.IsDataChanged = 1
    SET 	pa.Remark = CASE WHEN ex.IsFromCTS = 1 THEN ex.Remark ELSE pa.Remark END
        ,	pa.CreatedBy = CASE WHEN ex.IsFromCTS = 1 THEN ex.CreatedBy ELSE pa.CreatedBy END
        ,	pa.IsFromCTS = CASE WHEN ex.IsFromCTS = 1 THEN ex.IsFromCTS ELSE pa.IsFromCTS END
        ,	pa.IsFromAI = CASE WHEN ex.IsFromAI = 1 THEN ex.IsFromAI ELSE pa.IsFromAI END
        ,	pa.IsFromTW = CASE WHEN ex.IsFromTW = 1 THEN ex.IsFromTW ELSE pa.IsFromTW END
        ,	pa.IsDirect = CASE WHEN ex.IsDirect = 1 THEN ex.IsDirect ELSE pa.IsDirect END;
        
	DELETE 
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
    WHERE EXISTS (SELECT 1 
				  FROM  Temp_PA AS pa  
                  WHERE pa.CustID = clss.CustID  
					AND pa.IsDataChanged = 1
					AND (clss.CategoryID IN (CONST_CATEGORYID_ROBOT,CONST_CATEGORYID_BADROBOT,CONST_CATEGORYID_GOODROBOT) OR clss.SportGroupID = CONST_GROUP_NORMAL));
    
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	WHERE EXISTS (SELECT 1 
				  FROM  Temp_PA AS pa  
                  WHERE pa.CustID = pro.CustID  
					AND pa.IsDataChanged = 1);
        
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID,IsFromTW,IsFromCTS,IsFromAI, IsDirect,Remark,CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	pa.CustID
		,	pa.CTSCustID
		, 	pa.SubscriberID
        
		, 	pa.CategoryID
		, 	CONST_GROUP_PA AS SportGroupID
        ,	pa.IsFromTW
        ,	pa.IsFromCTS
        ,	pa.IsFromAI
        ,	pa.IsDirect
        ,	pa.Remark
        
		, 	lv_Now AS CreatedDate
		, 	pa.CreatedBy
		, 	lv_Now AS LastModifiedDate
		, 	CreatedBy AS  LastModifiedBy
		, 	DATE(lv_Now) AS LastScannedDate
	FROM Temp_PA AS pa
    WHERE pa.IsDataChanged =  1;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays,IsDirect,Remark)
	SELECT 	pa.CustID
		, 	pa.CTSCustID
		, 	pa.CategoryID
		, 	CONST_GROUP_PA AS SportGroupID
		, 	lv_Now AS LastModifiedDate
		, 	pa.CreatedBy AS LastModifiedBy
		, 	1 AS ActionType
		, 	DATE(lv_Now) AS InsertDate
		, 	pa.TargetCC
		, 	CONST_SOURCETYPE_INSERTROBOTUSERS AS SourceTypeID
		,  	pa.IsDataChanged
		,	pa.RobotCounter
		,	pa.TargetDangerLevel AS TargetDangerLevel1
		,	pa.TurnoverRM
		,	pa.WinlossRM
		, 	pa.BetCount
		, 	pa.ActiveDays
        ,	pa.IsDirect
        ,	pa.Remark
	FROM Temp_PA AS pa
    WHERE pa.IsDataChanged =  1;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays,IsDirect,Remark)
	SELECT 	pa.CustID
		, 	pa.CTSCustID
		, 	pa.CategoryID
		, 	CONST_GROUP_PA AS SportGroupID
		, 	lv_Now AS LastModifiedDate
		, 	pa.CreatedBy AS LastModifiedBy
		, 	1 AS ActionType
		, 	DATE(lv_Now) AS InsertDate
		, 	pa.TargetCC
		, 	CONST_SOURCETYPE_INSERTROBOTUSERS AS SourceTypeID
		,  	pa.IsDataChanged
		,	pa.RobotCounter
		,	pa.TargetDangerLevel AS TargetDangerLevel1
		,	pa.TurnoverRM
		,	pa.WinlossRM
		, 	pa.BetCount
		, 	pa.ActiveDays
        ,	pa.IsDirect
		,	pa.Remark
	FROM Temp_PA AS pa;


	SELECT 	DISTINCT 
			CTSCustID
		,  	CustID
    FROM Temp_PA;

END$$
DELIMITER ;