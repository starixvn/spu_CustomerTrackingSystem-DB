/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_PA_InsertRobot`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_InsertRobot`(
		IN 		ip_CustInfo 	JSON
	,	in		ip_IsRescan		BIT
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
            - 20220628@Aries.Nguyen: Update robot classification rule [Redmine ID: #174430]
		
        Param's Explanation: 

		Example:
			-CALL CTS_DataCenter.CTS_DC_CustClassification_PA_InsertRobot('[{"CustID":3698310,"CategoryID":61,"RobotCounter":11,"TurnoverRM":null,"WinlossRM":null,"BetCount":null,"ActiveDays":null,"IsFromTW":true,"CreatedBy":10278938},{"CustID":3698310,"CategoryID":166,"RobotCounter":null,"TurnoverRM":53580.0000,"WinlossRM":-319.0800,"BetCount":1649,"ActiveDays":16,"IsFromTVS":true,"TVSRequestID":1111,"CreatedBy":10278938}]');

*/
    DECLARE	CONST_CATEGORYID_ROBOT 				INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_ROBOTLOSING 		INT DEFAULT 164;
    
    DECLARE	CONST_GROUP_PA 						INT DEFAULT 0;
    DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
    
	DECLARE CONST_SOURCETYPE_RESCANROBOT		INT DEFAULT 36;
    DECLARE CONST_SOURCETYPE_INSERTROBOT		INT DEFAULT 37;
    
    DECLARE CONST_SOURCETYPE_PROBLEMDIRECT		INT DEFAULT 31;
    DECLARE CONST_SOURCETYPE_PROBLEMAFFECT		INT DEFAULT 32;
    DECLARE	CONST_ACTIONTYPE_UPDATE 			INT DEFAULT 1;
    
    DECLARE lv_Now								DATETIME DEFAULT NOW();
    DECLARE lv_CreatedBy 						INT DEFAULT 10278938;

	DROP TEMPORARY TABLE IF EXISTS Temp_PA;    
	CREATE TEMPORARY TABLE Temp_PA(	  
			CTSCustID				BIGINT UNSIGNED 
		,	CustID					BIGINT UNSIGNED 
		, 	SubscriberID			INT 
        ,	IsLicensee				BIT
        
		,	CategoryID 				INT	
        ,	ReasonID				INT DEFAULT 36     
        ,	TargetCC				SMALLINT
		,	TargetDangerLevel		SMALLINT UNSIGNED
        
        ,	TurnoverRM				DECIMAL(20,4)
        ,	WinlossRM				DECIMAL(20,4)
        , 	BetCount				BIGINT 
        , 	ActiveDays				INT 
		,	RobotCounter			INT 
        , 	WinlossStatus			SMALLINT /*LOSING  = 0,KEEPSTATE = 1, WINNING = 2;*/
         
        ,	IsFromTW				BIT
        ,	IsFromCTS				BIT
        ,	IsFromAI				BIT
        ,	IsFromTVS				BIT
        ,	TVSRequestID			BIGINT UNSIGNED 
        ,	IsDirect				BIT
        ,	IsDataChanged			BIT DEFAULT 1
        ,	IsExisted				BIT DEFAULT 0
        
        ,	Remark					VARCHAR(500)
		,	CreatedBy				INT UNSIGNED
        ,	CreatedDate				DATETIME
        
		,	IsPin					BIT DEFAULT 0
        ,	IsVVIP					BIT DEFAULT 0
        , 	PRIMARY KEY(CustID,CategoryID)
    );  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistCate;    
	CREATE TEMPORARY TABLE Temp_ExistCate(	  
			CustID				BIGINT UNSIGNED 
        ,	CategoryID 			INT	
        , 	RelevantCategoryID 	SMALLINT UNSIGNED
        
        , 	IsPAProbation		BIT 
        , 	IsChangeWinloss		BIT DEFAULT 0
        ,	IsRobot				BIT DEFAULT 0
        ,	IsFromTW			BIT
		,	IsFromCTS			BIT
        ,	IsFromAI			BIT
        ,	IsFromTVS			BIT
        ,	TVSRequestID		BIGINT UNSIGNED 
        ,	IsDirect			BIT
        ,	Remark				VARCHAR(500)
		,	CreatedBy			INT UNSIGNED
        ,	CreatedDate			DATETIME
        ,  	PRIMARY KEY(CustID,CategoryID)
    );
    
    INSERT IGNORE INTO Temp_PA(CustID, CTSCustID, SubscriberID,IsLicensee, CategoryID,TargetCC, TurnoverRM, WinlossRM, BetCount, ActiveDays,RobotCounter,WinlossStatus, IsFromTW,IsFromCTS,IsFromAI,IsFromTVS,TVSRequestID,IsDirect,Remark,CreatedBy,IsPin,IsVVIP,CreatedDate)
	SELECT	js.CustID
		,	cus.CTSCustID
		,	cus.SubscriberID
        ,	cus.IsLicensee
        
		, 	CASE WHEN js.WinlossStatus = 0 THEN CONST_CATEGORYID_ROBOTLOSING
			ELSE CONST_CATEGORYID_ROBOT END AS CategoryID
        ,	sp.CustomerClass AS TargetCC
        , 	js.TurnoverRM
        , 	js.WinlossRM
        , 	js.BetCount
        , 	js.ActiveDays
        ,	js.RobotCounter
        ,	js.WinlossStatus
        
        , 	IFNULL(js.IsFromTW,0) AS IsFromTW
		,	IFNULL(js.IsFromCTS,0) AS IsFromCTS		
        ,	IFNULL(js.IsFromAI,0) AS IsFromAI
        ,	IFNULL(js.IsFromTVS,0) AS IsFromTVS 		
        ,	js.TVSRequestID	
        ,	IFNULL(js.IsDirect,0) AS IsDirect	
        ,	js.Remark
        ,	js.CreatedBy
        ,	CASE WHEN pin.CTSCustID IS NOT NULL THEN 1 
				 ELSE 0 END AS IsPin
		,	CASE WHEN vip.CTSCustID IS NOT NULL THEN 1 
				 ELSE 0 END AS IsVVIP 
		, lv_Now AS CreatedDate
	FROM JSON_TABLE(ip_CustInfo,
	"$[*]" COLUMNS( CustID 			BIGINT UNSIGNED		PATH "$.CustID"                
                ,	RobotCounter	INT 				PATH "$.RobotCounter"
                
                ,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus"	
				,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
				,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
				, 	BetCount		BIGINT 				PATH "$.BetCount"
				, 	ActiveDays		INT 				PATH "$.ActiveDays"
                
                , 	IsFromTW		BOOLEAN 			PATH "$.IsFromTW"
                , 	IsFromCTS		BOOLEAN 			PATH "$.IsFromCTS"
                , 	IsFromAI		BOOLEAN 			PATH "$.IsFromAI"
                , 	IsFromTVS		BOOLEAN 			PATH "$.IsFromTVS"
                , 	TVSRequestID	BIGINT UNSIGNED 	PATH "$.TVSRequestID"
                , 	IsDirect		BOOLEAN 			PATH "$.IsDirect"
                
                 , 	Remark			VARCHAR(500)		PATH "$.Remark"
                , 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
	)) AS js 
		INNER JOIN  CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = js.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0
		LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on cus.CTSCustID = pin.CTSCustID
        LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON cus.CustID = sp.CustID 
        LEFT JOIN CTS_DataCenter.CTSCustomerClassificationVVIP AS vip on cus.CTSCustID = vip.CTSCustID
	ON DUPLICATE KEY UPDATE  RobotCounter = IFNULL(Temp_PA.RobotCounter, js.RobotCounter)
						,	 TurnoverRM = IFNULL(Temp_PA.TurnoverRM, js.TurnoverRM)  
                        ,	 WinlossRM = IFNULL(Temp_PA.WinlossRM, js.WinlossRM)  
                        ,	 BetCount = IFNULL(Temp_PA.BetCount, js.BetCount)  
                        ,	 ActiveDays = IFNULL(Temp_PA.ActiveDays, js.ActiveDays)
                        ,	 IsFromTW = CASE WHEN js.IsFromTW = 1 THEN 1 ELSE Temp_PA.IsFromTW END
                        ,	 IsFromCTS = CASE WHEN js.IsFromCTS = 1 THEN 1 ELSE Temp_PA.IsFromCTS END
                        ,	 IsFromAI = CASE WHEN js.IsFromAI = 1 THEN 1 ELSE Temp_PA.IsFromAI END
                        ,	 IsFromTVS = CASE WHEN js.IsFromTVS = 1 THEN 1 ELSE Temp_PA.IsFromTVS END
                        ,	 TVSRequestID = CASE WHEN js.TVSRequestID IS NOT NULL AND Temp_PA.TVSRequestID IS NULL  THEN js.TVSRequestID ELSE Temp_PA.TVSRequestID END
                        ,	 IsDirect = CASE WHEN js.IsDirect = 1 THEN 1 ELSE Temp_PA.IsDirect END
                        ,	 Remark = CASE WHEN js.IsFromCTS = 1 THEN js.Remark ELSE Temp_PA.Remark END
                        ,	 CreatedBy = CASE WHEN js.IsFromCTS = 1 THEN js.CreatedBy ELSE Temp_PA.CreatedBy END;
	
    CALL CTS_DataCenter.CTS_DC_CustClassification_PA_RemoveOldTVSRequest();
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationOldPA(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID,IsFromTW,IsFromCTS,IsFromAI,IsFromTVS,TVSRequestID, IsDirect,Remark,CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	pa.CustID
		,	pa.CTSCustID
		, 	pa.SubscriberID
        
		, 	pa.CategoryID
		, 	CONST_GROUP_PA AS SportGroupID
        ,	pa.IsFromTW
        ,	pa.IsFromCTS
        ,	pa.IsFromAI
		,	pa.IsFromTVS
		,	pa.TVSRequestID
        ,	pa.IsDirect
        ,	pa.Remark
        
		, 	lv_Now AS CreatedDate
		, 	pa.CreatedBy
		, 	lv_Now AS LastModifiedDate
		, 	CreatedBy AS  LastModifiedBy
		, 	DATE(lv_Now) AS LastScannedDate
	FROM Temp_PA AS pa
    WHERE pa.IsFromTVS = 1 
		AND (pa.IsVVIP =  1 OR pa.IsPin = 1);
    
    DELETE 
    FROM Temp_PA AS pa
    WHERE pa.IsVVIP =  1 
		OR pa.IsPin = 1;
    
    /***********************Handle update existed PA by winloss*******************************/
    INSERT IGNORE INTO Temp_ExistCate(CustID,CategoryID,RelevantCategoryID,IsPAProbation,IsChangeWinloss,IsRobot,IsFromTW,IsFromCTS,IsFromAI,IsFromTVS,TVSRequestID,IsDirect,Remark,CreatedBy,CreatedDate) 
    SELECT 	clss.CustID
		,	clss.CategoryID
        ,	cate.RelevantCategoryID
        ,	cate.IsPAProbation
        ,	CASE WHEN tmp.WinlossStatus = 1 THEN 0 /*No Change*/
				 WHEN tmp.WinlossStatus = 0 AND cate.IsPAProbation = 0 THEN 1  /*Lose + PA => Update */
				 WHEN tmp.WinlossStatus = 0 AND cate.IsPAProbation = 1 THEN 0  /*Lose + Probation =>  No Change*/
                 WHEN tmp.WinlossStatus = 2 AND cate.IsPAProbation = 0 THEN 0  /*Win + PA => No Change  */
                 WHEN tmp.WinlossStatus = 2 AND cate.IsPAProbation = 1 THEN 1  /*Win + Probation => Update */
			END AS IsChangeWinloss
        ,	CASE WHEN clss.CategoryID IN (CONST_CATEGORYID_ROBOT,CONST_CATEGORYID_ROBOTLOSING) THEN 1
				 ELSE 0 END AS IsRobot
        ,	clss.IsFromTW		
		, 	clss.IsFromCTS	
        , 	clss.IsFromAI	
        , 	clss.IsFromTVS	
        , 	clss.TVSRequestID	
		, 	clss.IsDirect	
        ,	clss.Remark
        ,	clss.CreatedBy
        ,	clss.CreatedDate
    FROM Temp_PA AS tmp  
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON clss.CustID = tmp.CustID AND clss.SportGroupID = CONST_GROUP_PA
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.RelevantCategoryID IS NOT NULL;
	
    UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
    INNER JOIN Temp_ExistCate AS tmp ON tmp.CustID = clss.CustID AND  clss.SportGroupID = CONST_GROUP_PA AND tmp.CategoryID = clss.CategoryID 
    SET 	clss.CategoryID = tmp.RelevantCategoryID
        ,	clss.LastModifiedBy = lv_CreatedBy
    WHERE tmp.IsChangeWinloss = 1 
		AND tmp.IsRobot = 0;
	
    UPDATE Temp_PA AS pa
    SET pa.CategoryID = CONST_CATEGORYID_ROBOTLOSING
    WHERE EXISTS (SELECT 1 
				  FROM Temp_ExistCate AS ex
                  WHERE ex.CustID = pa.CustID 
					AND ex.IsChangeWinloss = 0
                    AND ex.IsPAProbation = 1
                    AND ex.IsRobot = 0);
  
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, IsAuto, InsertDate, TargetCC, SourceTypeID, IsDataChanged,TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays)
	SELECT  pa.CustID
		, 	pa.CTSCustID
		, 	cate.RelevantCategoryID
		, 	CONST_GROUP_PA AS SportGroupID
		, 	NOW() AS LastModifiedDate
		, 	lv_CreatedBy AS LastModifiedBy
		, 	CONST_ACTIONTYPE_UPDATE AS ActionType
		, 	1 AS IsAuto
		, 	NOW() AS InsertDate
		, 	tbl.CustomerClass AS TargetCC
		, 	CASE WHEN cate.IsDirect = 1 THEN CONST_SOURCETYPE_PROBLEMDIRECT
				 ELSE CONST_SOURCETYPE_PROBLEMAFFECT END AS SourceTypeID
		,   IsDataChanged
        ,	CASE WHEN pa.IsLicensee = 1 THEN tbl.ABIDangerLevel_Licensee  
				 ELSE tbl.ABIDangerLevel_Credit END AS TargetDangerLevel1
        ,	pa.TurnoverRM
        ,	pa.WinlossRM
        , 	pa.BetCount
        , 	pa.ActiveDays
	FROM Temp_ExistCate AS cate
		INNER JOIN Temp_PA AS pa ON pa.CustID = cate.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS tbl ON cate.RelevantCategoryID = tbl.CategoryID 
    WHERE cate.IsChangeWinloss = 1 
		AND IsRobot = 0;
    
    DELETE
    FROM Temp_ExistCate
    WHERE IsRobot = 0;
    
    /***********************Handle update/insert Robot by winloss*******************************/
    UPDATE IGNORE Temp_PA AS pa
	INNER JOIN Temp_ExistCate AS ex ON pa.CustID = ex.CustID  
    SET 	pa.CategoryID =  CASE WHEN pa.WinlossStatus =  1 THEN ex.CategoryID
							 ELSE pa.CategoryID END
		,   pa.IsDataChanged = CASE WHEN pa.WinlossStatus != 1 AND pa.CategoryID != ex.CategoryID  THEN 1
									ELSE 0 END;

    UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
    INNER JOIN Temp_PA AS pa ON  pa.CustID = clss.CustID AND clss.CategoryID IN (CONST_CATEGORYID_ROBOT,CONST_CATEGORYID_ROBOTLOSING)
    SET 	clss.CategoryID =  clss.CategoryID   
		,	clss.Remark =  CASE WHEN pa.IsFromCTS = 1 THEN pa.Remark ELSE clss.Remark END  
		,	clss.IsFromTW =   CASE WHEN pa.IsFromTW = 1 THEN pa.IsFromTW ELSE clss.IsFromTW END  
        ,	clss.IsFromCTS =  CASE WHEN pa.IsFromCTS = 1 THEN pa.IsFromCTS ELSE clss.IsFromCTS END  
        ,	clss.IsFromAI =  CASE WHEN pa.IsFromAI = 1 THEN pa.IsFromAI ELSE clss.IsFromAI END  
        ,	clss.IsFromTVS =  CASE WHEN pa.IsFromTVS = 1 THEN pa.IsFromTVS ELSE clss.IsFromTVS END  
        ,	clss.TVSRequestID =  CASE WHEN pa.TVSRequestID IS NOT NULL AND pa.TVSRequestID != 0 THEN pa.TVSRequestID ELSE clss.TVSRequestID END  
        ,	clss.IsDirect = CASE WHEN pa.IsDirect = 1 THEN pa.IsDirect ELSE clss.IsDirect END
		,	pa.IsExisted = 1;
    
	DELETE 
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
    WHERE EXISTS (SELECT 1 
				  FROM  Temp_PA AS pa  
                  WHERE pa.CustID = clss.CustID  
					AND pa.IsDataChanged = 1
					AND clss.SportGroupID = CONST_GROUP_NORMAL);
                    
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	WHERE EXISTS (SELECT 1 
				  FROM  Temp_PA AS pa  
                  WHERE pa.CustID = pro.CustID  
					AND pa.IsDataChanged = 1);
                    
    UPDATE Temp_PA AS pa
	INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON pa.CategoryID = cate.CategoryID
	SET pa.TargetCC	= CASE  WHEN pa.TargetCC IS NOT NULL THEN pa.TargetCC
							WHEN pa.TargetCC IS NULL THEN IFNULL(cate.CustomerClass, -99) 
							ELSE  -99 END 
	,	pa.TargetDangerLevel = CASE WHEN pa.IsLicensee = 1 THEN cate.ABIDangerLevel_Licensee
									WHEN pa.IsLicensee = 0 THEN cate.ABIDangerLevel_Credit				
								END;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(CustID, CTSCustID, SubscriberID, CategoryID, SportGroupID,IsFromTW,IsFromCTS,IsFromAI,IsFromTVS,TVSRequestID, IsDirect,Remark,CreatedDate, CreatedBy, LastModifiedDate, LastModifiedBy, LastScannedDate)
	SELECT 	pa.CustID
		,	pa.CTSCustID
		, 	pa.SubscriberID
        
		, 	pa.CategoryID
		, 	CONST_GROUP_PA AS SportGroupID
        ,	pa.IsFromTW
        ,	pa.IsFromCTS
        ,	pa.IsFromAI
		,	pa.IsFromTVS
		,	pa.TVSRequestID
        ,	pa.IsDirect
        ,	pa.Remark
        
		, 	pa.CreatedDate
		, 	pa.CreatedBy
		, 	lv_Now AS LastModifiedDate
		, 	CreatedBy AS  LastModifiedBy
		, 	DATE(lv_Now) AS LastScannedDate
	FROM Temp_PA AS pa
    WHERE pa.IsDataChanged =  1
		AND pa.IsExisted = 0;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays,IsDirect,Remark,IsFromTW,IsFromCTS,IsFromAI,IsFromTVS,TVSRequestID)
	SELECT 	pa.CustID
		, 	pa.CTSCustID
		, 	pa.CategoryID
		, 	CONST_GROUP_PA AS SportGroupID
		, 	lv_Now AS LastModifiedDate
		, 	pa.CreatedBy AS LastModifiedBy
		, 	1 AS ActionType
		, 	DATE(lv_Now) AS InsertDate
		, 	pa.TargetCC
		, 	CASE WHEN ip_IsRescan = 1 THEN CONST_SOURCETYPE_RESCANROBOT 
				 ELSE CONST_SOURCETYPE_INSERTROBOT END AS SourceTypeID
		,  	pa.IsDataChanged
		,	pa.RobotCounter
		,	pa.TargetDangerLevel AS TargetDangerLevel1
		,	pa.TurnoverRM
		,	pa.WinlossRM
		, 	pa.BetCount
		, 	pa.ActiveDays
        ,	pa.IsDirect
        ,	pa.Remark
        ,	pa.IsFromTW
        ,	pa.IsFromCTS
        ,	pa.IsFromAI
		,	pa.IsFromTVS
		,	pa.TVSRequestID  
	FROM Temp_PA AS pa
    WHERE pa.IsDataChanged =  1; 
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(CustID, CTSCustID, CategoryID, SportGroupID, LastModifiedDate, LastModifiedBy, ActionType, InsertDate, TargetCC, SourceTypeID, IsDataChanged, RobotCounter, TargetDangerLevel1,TurnoverRM, WinlossRM, BetCount, ActiveDays,IsDirect,Remark,IsFromTW,IsFromCTS,IsFromAI,IsFromTVS,TVSRequestID)
	SELECT 	pa.CustID
		, 	pa.CTSCustID
		, 	pa.CategoryID
		, 	CONST_GROUP_PA AS SportGroupID
		, 	lv_Now AS LastModifiedDate
		, 	pa.CreatedBy AS LastModifiedBy
		, 	1 AS ActionType
		, 	DATE(lv_Now) AS InsertDate
		, 	pa.TargetCC
		, 	CASE WHEN ip_IsRescan = 1 THEN CONST_SOURCETYPE_RESCANROBOT 
				 ELSE CONST_SOURCETYPE_INSERTROBOT END AS SourceTypeID
		,  	pa.IsDataChanged
		,	pa.RobotCounter
		,	pa.TargetDangerLevel AS TargetDangerLevel1
		,	pa.TurnoverRM
		,	pa.WinlossRM
		, 	pa.BetCount
		, 	pa.ActiveDays
        ,	pa.IsDirect
		,	pa.Remark
        ,	pa.IsFromTW
        ,	pa.IsFromCTS
        ,	pa.IsFromAI
		,	pa.IsFromTVS
		,	pa.TVSRequestID
	FROM Temp_PA AS pa;


	SELECT 	DISTINCT 
			CTSCustID
		,  	CustID
    FROM Temp_PA;

END$$
DELIMITER ;