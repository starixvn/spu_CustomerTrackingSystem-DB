/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassification_PA_InsertRobot`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_InsertRobot`(
		IN 		ip_CustInfo 	JSON
	,	IN		ip_IsRescan		BIT
)
    SQL SECURITY INVOKER
BEGIN
/* 
		Created:	20220520@Aries.Nguyen
		Task :		Renovate PA Process
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
			- 20220520@Aries.Nguyen: 	Created [Redmine ID: #172561] 
			- 20220628@Aries.Nguyen: 	Update robot classification rule [Redmine ID: #174430]
			- 20220708@Aries.Nguyen: 	[CTS] Add new category/class for Lic BA and Lic VIP [Redmine ID: #174219]
			- 20200817@Casey.Huynh: 	Remove Hardcode CC [Redmine ID: #175698]
			- 20221007@Harvey.Nguyen: 	Change CTSCustomerClassificationOldPA -> CTSCustomerClassificationOldCategory [Redmine ID: #178022]
			- 20230315@Victoria.Le:		Add Robot Imperva [Redmine ID: #184773]
			- 20230404@Victoria.Le:		TVS Abnormal Bet and Abnormal Account - Add IsParlay,SportType,IssueTypeID [Redmine ID: #185319] 
            - 20230516@Casey.Huynh:		New Category for Robot OCRD [RedmineID: #186991]
			- 20231009@Casey.Huynh:		Fixed Issue Duplicate Rescan Robot Log [RedmineID: #193049]
            
        Param's Explanation: 

		Example:
			CALL CTS_DC_CustClassification_PA_InsertRobot_xtest('[{"CustID":1309,"CategoryID":163,"RobotCounter":null,"IsFromTW":false,
				"IsFromCTS":false,"IsFromAI":true,"IsFromImperva":true,"IsFromTVS":false,"TVSRequestID":0,"IsParlay":null,"SportType":null,
				"IssueTypeID":0,"IsDirect":true,"Remark":"Imperva","CreatedBy":10278938,"TurnoverRM":null,"WinlossRM":null,"WinlossStatus":null,
				"BetCount":null,"ActiveDays":null}
				,{"CustID":1309,"CategoryID":165,"RobotCounter":null,"IsFromTW":false,"IsFromCTS":false,"IsFromAI":true,
				"IsFromImperva":false,"IsFromTVS":false,"TVSRequestID":0,"IsParlay":null,"SportType":null,"IssueTypeID":0,"IsDirect":true,"Remark":null,
				"CreatedBy":10278938,"TurnoverRM":null,"WinlossRM":null,"WinlossStatus":null,"BetCount":null,"ActiveDays":null}]', true);
*/
    DECLARE	CONST_CATEGORYID_ROBOTUSER 				INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_ROBOTUSER_LOSING 		INT DEFAULT 164;
	DECLARE	CONST_CATEGORYID_ROBOTOCRD 				INT DEFAULT 165;
    DECLARE	CONST_CATEGORYID_ROBOTOCRD_LOSING 		INT DEFAULT 166;
    
    DECLARE	CONST_CATEGORYID_LICVIPPROBLEM 		INT DEFAULT 3;
    DECLARE	CONST_CATEGORYID_LICVIP				INT DEFAULT 4;
    DECLARE CONST_SPORTGROUP_NORMAL 			INT DEFAULT 200;
    DECLARE	CONST_CATEGORY_RISKY 				INT DEFAULT 203;
    DECLARE	CONST_CATEGORY_SMART				INT DEFAULT 204;
    
    DECLARE	CONST_CATEGORYID_VIPNORMAL 			INT DEFAULT 4;
    
    DECLARE	CONST_GROUP_PA 						INT DEFAULT 0;
    
	DECLARE CONST_SOURCETYPE_RESCANROBOT		INT DEFAULT 36;
    DECLARE CONST_SOURCETYPE_INSERTROBOT		INT DEFAULT 37;
    
    DECLARE	CONST_ACTIONTYPE_UPDATE 			INT DEFAULT 1;
    
    DECLARE lv_Now								DATETIME DEFAULT NOW();
    DECLARE lv_CreatedBy 						INT DEFAULT 10278938;
    DECLARE lv_CC_LicVipProblem					SMALLINT;
    DECLARE lv_CC_LicVip						SMALLINT;

	DROP TEMPORARY TABLE IF EXISTS Temp_PA;    
	CREATE TEMPORARY TABLE Temp_PA(	  
			CTSCustID				BIGINT UNSIGNED 
		,	CustID					BIGINT UNSIGNED 
		, 	SubscriberID			INT 
        ,	IsLicensee				BIT
        
		,	CategoryID 				INT	
        ,	ReasonID				INT 
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
		,	IsFromImperva			BIT
		
        ,	TVSRequestID			BIGINT UNSIGNED 
        ,	IsDirect				BIT
        ,	IsDataChanged			BIT DEFAULT 1
        ,	IsExisted				BIT DEFAULT 0
        
        ,	Remark					VARCHAR(500)
		,	CreatedBy				INT UNSIGNED
        ,	CreatedDate				DATETIME
        
		,	IsPin					BIT DEFAULT 0
        ,	IsVVIP					BIT DEFAULT 0
        ,	IsLicenseeVIP			BIT DEFAULT 0
		,	IsParlay 				BIT DEFAULT NULL 
		,	SportType				SMALLINT DEFAULT NULL 
		,	IssueTypeID 			TINYINT DEFAULT NULL 
        
		, 	PRIMARY KEY(CustID, CategoryID)
    );  
     
    DROP TEMPORARY TABLE IF EXISTS Temp_ExistCate;    
	CREATE TEMPORARY TABLE Temp_ExistCate(	  
			CustID				BIGINT UNSIGNED 
        ,	CategoryID 			INT	
        , 	RelevantCategoryID 	SMALLINT UNSIGNED
        ,	SportGroupID		SMALLINT UNSIGNED
        
        , 	IsPAProbation		BIT 
        , 	IsChangeWinloss		BIT DEFAULT 0
        ,	RobotCategoryID		SMALLINT UNSIGNED
        ,	IsFromTW			BIT
		,	IsFromCTS			BIT
        ,	IsFromAI			BIT
        ,	IsFromTVS			BIT
		,	IsFromImperva		BIT
        ,	TVSRequestID		BIGINT UNSIGNED 
        ,	IsDirect			BIT
        ,	Remark				VARCHAR(500)
		,	CreatedBy			INT UNSIGNED
        ,	CreatedDate			DATETIME
		,	IsParlay 			BIT DEFAULT NULL 
		,	SportType			SMALLINT DEFAULT NULL 
		,	IssueTypeID 		TINYINT DEFAULT NULL 
        ,  	PRIMARY KEY(CustID,CategoryID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_4xCC;    
	CREATE TEMPORARY TABLE Temp_4xCC(
		CustomerClass  SMALLINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_4xCC_02;    
	CREATE TEMPORARY TABLE Temp_4xCC_02(
		CustomerClass  SMALLINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_LastHistory;
    CREATE TEMPORARY TABLE Temp_LastHistory(
			CustID		INT UNSIGNED PRIMARY KEY
        ,	CategoryID	SMALLINT UNSIGNED
        ,	TargetCC	SMALLINT UNSIGNED
	);    
    #=================================================
	SELECT cat.CustomerClass INTO lv_CC_LicVipProblem FROM CTS_DataCenter.CustomerCategory AS cat WHERE cat.CategoryID = CONST_CATEGORYID_LICVIPPROBLEM;
    SELECT cat.CustomerClass INTO lv_CC_LicVip FROM CTS_DataCenter.CustomerCategory AS cat WHERE cat.CategoryID = CONST_CATEGORYID_LICVIP;
    
    INSERT INTO Temp_4xCC(CustomerClass)
    SELECT DISTINCT CustomerClass FROM CTS_DataCenter.CustomerCategory AS cat WHERE cat.CategoryID IN (234,254,264,274);
    
    INSERT INTO Temp_4xCC_02(CustomerClass) 
    SELECT tmp.CustomerClass FROM Temp_4xCC AS tmp;
   
   #=================================================
    INSERT IGNORE INTO Temp_PA(
			CustID
		, 	CTSCustID
		, 	SubscriberID
		,	IsLicensee
		, 	CategoryID
		,	TargetCC
		, 	TurnoverRM
		, 	WinlossRM
		, 	BetCount
		, 	ActiveDays
		,	RobotCounter
		,	WinlossStatus
		, 	IsFromTW
		,	IsFromCTS
		,	IsFromAI
		,	IsFromTVS
		,	IsFromImperva
		,	TVSRequestID
		,	IsDirect
		,	Remark
		,	CreatedBy
		,	IsPin
		,	IsVVIP
		,	IsLicenseeVIP
		,	CreatedDate
		,	IsParlay
		,	SportType
		,	IssueTypeID
		,	ReasonID
	)
	SELECT	js.CustID
		,	cus.CTSCustID
		,	cus.SubscriberID
		,	cus.IsLicensee
		, 	(CASE WHEN js.CategoryID = CONST_CATEGORYID_ROBOTOCRD  AND (js.WinlossStatus != 0 OR js.WinlossStatus IS NULL) THEN CONST_CATEGORYID_ROBOTOCRD
				 WHEN js.CategoryID = CONST_CATEGORYID_ROBOTOCRD  AND js.WinlossStatus = 0 THEN CONST_CATEGORYID_ROBOTOCRD_LOSING 
                 WHEN (js.WinlossStatus != 0 OR js.WinlossStatus IS NULL) THEN CONST_CATEGORYID_ROBOTUSER
				 WHEN js.WinlossStatus = 0 THEN CONST_CATEGORYID_ROBOTUSER_LOSING 
                 END) AS CategoryID
		,	sp.CustomerClass AS TargetCC
		, 	js.TurnoverRM
		, 	js.WinlossRM
		, 	js.BetCount 
		, 	js.ActiveDays
		,	js.RobotCounter
		,	CASE WHEN js.WinlossStatus IS NULL THEN 2
			ELSE js.WinlossStatus END AS WinlossStatus
		 
		, 	IFNULL(js.IsFromTW,0) AS IsFromTW
		,	IFNULL(js.IsFromCTS,0) AS IsFromCTS		
		,	IFNULL(js.IsFromAI,0) AS IsFromAI
		,	IFNULL(js.IsFromTVS,0) AS IsFromTVS 		
		,	IFNULL(js.IsFromImperva,0) AS IsFromImperva 
		,	js.TVSRequestID

		,	IFNULL(js.IsDirect,0) AS IsDirect	
		,	js.Remark
		,	js.CreatedBy
		,	CASE WHEN pin.CTSCustID IS NOT NULL THEN 1 
				 ELSE 0 END AS IsPin
		,	CASE WHEN vip.CTSCustID IS NOT NULL THEN 1 
				 ELSE 0 END AS IsVVIP 
		,	cus.IsLicenseeVIP
		, 	lv_Now AS CreatedDate
		,	js.IsParlay
		,	js.SportType
		,	js.IssueTypeID
		,	CASE WHEN js.IssueTypeID = 13 THEN 10500
				 ELSE 36 END AS ReasonID
	FROM JSON_TABLE(ip_CustInfo,
	"$[*]" COLUMNS( CustID 			BIGINT UNSIGNED		PATH "$.CustID"                
				,	RobotCounter	INT 				PATH "$.RobotCounter"
				,	CategoryID	    SMALLINT UNSIGNED	PATH "$.CategoryID"
                
				,	WinlossStatus	SMALLINT 			PATH "$.WinlossStatus"	
				,	TurnoverRM		DECIMAL(20,4)		PATH "$.TurnoverRM"
				,	WinlossRM		DECIMAL(20,4) 		PATH "$.WinlossRM"
				, 	BetCount		BIGINT 				PATH "$.BetCount"
				, 	ActiveDays		INT 				PATH "$.ActiveDays"

				, 	IsFromTW		BOOLEAN 			PATH "$.IsFromTW"
				, 	IsFromCTS		BOOLEAN 			PATH "$.IsFromCTS"
				, 	IsFromAI		BOOLEAN 			PATH "$.IsFromAI"
				, 	IsFromTVS		BOOLEAN 			PATH "$.IsFromTVS"
				,	IsFromImperva	BOOLEAN				PATH "$.IsFromImperva"
				, 	TVSRequestID	BIGINT UNSIGNED 	PATH "$.TVSRequestID"
				, 	IsDirect		BOOLEAN 			PATH "$.IsDirect"

				, 	Remark			VARCHAR(500)		PATH "$.Remark"
				, 	CreatedBy		INT UNSIGNED		PATH "$.CreatedBy"
				,	IsParlay		BOOLEAN				PATH "$.IsParlay"
				,	SportType		SMALLINT			PATH "$.SportType"
				,	IssueTypeID		TINYINT				PATH "$.IssueTypeID"
	)) AS js 
		INNER JOIN  CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = js.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0
		LEFT JOIN CTS_DataCenter.PinCustomerCategory AS pin on cus.CTSCustID = pin.CTSCustID
        LEFT JOIN CTS_DataCenter.SpecialCustomerClass AS sp ON cus.CustID = sp.CustID 
        LEFT JOIN CTS_DataCenter.CTSCustomerClassificationVVIP AS vip on cus.CTSCustID = vip.CTSCustID
	ON DUPLICATE KEY UPDATE RobotCounter = IFNULL(Temp_PA.RobotCounter, js.RobotCounter)
						,	TurnoverRM = IFNULL(Temp_PA.TurnoverRM, js.TurnoverRM)  
						,	WinlossRM = IFNULL(Temp_PA.WinlossRM, js.WinlossRM)  
						,	BetCount = IFNULL(Temp_PA.BetCount, js.BetCount)  
						,	ActiveDays = IFNULL(Temp_PA.ActiveDays, js.ActiveDays)
						,	IsFromTW = CASE WHEN js.IsFromTW = 1 THEN 1 ELSE Temp_PA.IsFromTW END
						,	IsFromCTS = CASE WHEN js.IsFromCTS = 1 THEN 1 ELSE Temp_PA.IsFromCTS END
						,	IsFromAI = CASE WHEN js.IsFromAI = 1 THEN 1 ELSE Temp_PA.IsFromAI END
						,	IsFromTVS = CASE WHEN js.IsFromTVS = 1 THEN 1 ELSE Temp_PA.IsFromTVS END
						,	IsFromImperva = CASE WHEN js.IsFromImperva = 1 THEN 1 ELSE Temp_PA.IsFromImperva END
						,	IsDirect = CASE WHEN js.IsDirect = 1 THEN 1 ELSE Temp_PA.IsDirect END
						,	IsParlay = CASE WHEN Temp_PA.TVSRequestID IS NULL 
													AND (js.TVSRequestID > 0 OR (js.TVSRequestID IS NULL AND js.IssueTypeID = 11))
														THEN js.IsParlay 
												ELSE Temp_PA.IsParlay END
						,	SportType = CASE WHEN Temp_PA.TVSRequestID IS NULL 
													AND (js.TVSRequestID > 0 OR (js.TVSRequestID IS NULL AND js.IssueTypeID = 11))
														THEN js.SportType 
												ELSE Temp_PA.SportType END
						,	CreatedBy = CASE WHEN Temp_PA.TVSRequestID IS NULL 
													AND (js.TVSRequestID > 0 OR (js.TVSRequestID IS NULL AND js.IssueTypeID = 11))
														THEN js.CreatedBy 
												ELSE Temp_PA.CreatedBy END
						,	IssueTypeID = CASE WHEN Temp_PA.TVSRequestID IS NULL 
													AND (js.TVSRequestID > 0 OR (js.TVSRequestID IS NULL AND js.IssueTypeID = 11))
														THEN js.IssueTypeID 
												ELSE Temp_PA.IssueTypeID END
						,	TVSRequestID = CASE WHEN Temp_PA.TVSRequestID IS NULL 
													AND (js.TVSRequestID > 0 OR (js.TVSRequestID IS NULL AND js.IssueTypeID = 11))
														THEN js.TVSRequestID 
												ELSE Temp_PA.TVSRequestID END
						;
						-- ,	Remark = CASE WHEN js.IsFromCTS = 1 THEN js.Remark ELSE Temp_PA.Remark END;

    CALL CTS_DataCenter.CTS_DC_CustClassification_PA_RemoveOldTVSRequest();
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationOldCategory(
			CustID
		, 	CTSCustID
		, 	SubscriberID
		, 	CategoryID
		, 	SportGroupID
		,	IsFromTW
		,	IsFromCTS
		,	IsFromAI
		,	IsFromTVS
		,	IsFromImperva
		,	TVSRequestID
		, 	IsDirect
		,	Remark
		,	CreatedDate
		, 	CreatedBy
		, 	LastModifiedDate
		, 	LastModifiedBy
		, 	LastScannedDate
		,	IsParlay
		,	SportType
		,	IssueTypeID
	)
			
	SELECT 	pa.CustID
		,	pa.CTSCustID
		, 	pa.SubscriberID

		, 	pa.CategoryID
		, 	CONST_GROUP_PA AS SportGroupID
		,	pa.IsFromTW
		,	pa.IsFromCTS
		,	pa.IsFromAI
		,	pa.IsFromTVS
		,	pa.IsFromImperva
		,	pa.TVSRequestID
		,	pa.IsDirect
		,	pa.Remark

		, 	lv_Now AS CreatedDate
		, 	pa.CreatedBy
		, 	lv_Now AS LastModifiedDate
		, 	CreatedBy AS  LastModifiedBy
		, 	DATE(lv_Now) AS LastScannedDate
		,	pa.IsParlay
		,	pa.SportType
		,	pa.IssueTypeID
	FROM Temp_PA AS pa
    WHERE pa.IsFromTVS = 1 
		AND (pa.IsVVIP =  1 OR pa.IsPin = 1);
    
    DELETE 
    FROM Temp_PA AS pa
    WHERE pa.IsVVIP =  1 
		OR pa.IsPin = 1;
    
    /***********************Handle update existed PA by winloss*******************************/
    INSERT IGNORE INTO Temp_ExistCate(
			CustID
		,	CategoryID
		,	RelevantCategoryID
		,	SportGroupID
		,	IsPAProbation
		,	IsChangeWinloss
		,	RobotCategoryID
		,	IsFromTW
		,	IsFromCTS
		,	IsFromAI
		,	IsFromTVS
		,	IsFromImperva
		,	TVSRequestID
		,	IsDirect
		,	Remark
		,	CreatedBy
		,	CreatedDate
		,	IsParlay
		,	SportType
		,	IssueTypeID
	) 
    SELECT 	clss.CustID
		,	clss.CategoryID
		,	cate.RelevantCategoryID
		,	clss.SportGroupID
		,	cate.IsPAProbation
		,	CASE WHEN tmp.WinlossStatus = 1 AND clss.CategoryID IN (CONST_CATEGORYID_VIPNORMAL)  THEN 1 
				 WHEN tmp.WinlossStatus = 1 AND clss.CategoryID NOT IN (CONST_CATEGORYID_VIPNORMAL) THEN 0 /*No Change*/
				 WHEN tmp.WinlossStatus = 0 AND cate.IsPAProbation = 0 THEN 1  /*Lose + PA => Update */
				 WHEN tmp.WinlossStatus = 0 AND cate.IsPAProbation = 1 THEN 0  /*Lose + Probation =>  No Change*/
				 WHEN tmp.WinlossStatus = 2 AND cate.IsPAProbation = 0 THEN 0  /*Win + PA => No Change  */
				 WHEN tmp.WinlossStatus = 2 AND cate.IsPAProbation = 1 THEN 1  /*Win + Probation => Update */
			END AS IsChangeWinloss
		,	CASE WHEN clss.CategoryID IN (CONST_CATEGORYID_ROBOTUSER,CONST_CATEGORYID_ROBOTUSER_LOSING,CONST_CATEGORYID_ROBOTOCRD,CONST_CATEGORYID_ROBOTOCRD_LOSING) THEN clss.CategoryID
				 ELSE 0 END AS RobotCategoryID
		,	clss.IsFromTW		
		, 	clss.IsFromCTS	
		, 	clss.IsFromAI	
		, 	clss.IsFromTVS
		,	clss.IsFromImperva
		, 	clss.TVSRequestID
		, 	clss.IsDirect	
		,	clss.Remark
		,	clss.CreatedBy
		,	clss.CreatedDate
		,	clss.IsParlay
		,	clss.SportType
		,	clss.IssueTypeID
    FROM Temp_PA AS tmp  
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS clss ON clss.CustID = tmp.CustID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON clss.CategoryID = cate.CategoryID AND cate.RelevantCategoryID IS NOT NULL;
	
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationOldCategory(
			CustID
		, 	CTSCustID
		, 	SubscriberID
		, 	SportGroupID
		, 	CategoryID
		, 	Remark
		, 	CreatedDate
		, 	CreatedBy
		, 	LastModifiedDate
		, 	LastModifiedBy
		, 	LastScannedDate
		, 	IsFromTVS
		, 	IsFromTW
		, 	IsFromCTS
		, 	IsDirect
		, 	InsertTime
		, 	TVSRequestID
		,	IsParlay
		,	SportType
		,	IssueTypeID
	) 
	SELECT 	clss.CustID
		, 	clss.CTSCustID
		, 	clss.SubscriberID
		, 	clss.SportGroupID
		, 	clss.CategoryID
		, 	clss.Remark
		, 	clss.CreatedDate
		, 	clss.CreatedBy
		, 	clss.LastModifiedDate
		, 	clss.LastModifiedBy
		, 	clss.LastScannedDate
		, 	clss.IsFromTVS
		, 	clss.IsFromTW
		, 	clss.IsFromCTS
		, 	clss.IsDirect
		, 	CURRENT_TIMESTAMP(3) AS InsertTime
		, 	clss.TVSRequestID
		,	clss.IsParlay
		,	clss.SportType
		,	clss.IssueTypeID
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS tmpPa ON tmpPa.CustID = clss.CustID AND clss.SportGroupID = CONST_SPORTGROUP_NORMAL
        INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON cc.CategoryID = clss.CategoryID
	WHERE cc.CategoryGroup IN (CONST_CATEGORY_RISKY, CONST_CATEGORY_SMART);
    
    UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
    INNER JOIN Temp_ExistCate AS tmp ON tmp.CustID = clss.CustID AND tmp.CategoryID = clss.CategoryID 
    SET 	clss.CategoryID = tmp.RelevantCategoryID
        ,	clss.LastModifiedBy = lv_CreatedBy
    WHERE tmp.IsChangeWinloss = 1;
	
    UPDATE Temp_PA AS pa
    SET pa.CategoryID = CASE WHEN pa.CategoryID = CONST_CATEGORYID_ROBOTUSER THEN CONST_CATEGORYID_ROBOTUSER_LOSING
							WHEN pa.CategoryID = CONST_CATEGORYID_ROBOTOCRD THEN CONST_CATEGORYID_ROBOTOCRD_LOSING 
                            ELSE pa.CategoryID END	
    WHERE EXISTS (SELECT 1 
				  FROM Temp_ExistCate AS ex
                  WHERE ex.CustID = pa.CustID 
					AND ex.IsChangeWinloss = 0
                    AND ex.IsPAProbation = 1
                    AND ex.RobotCategoryID = 0);
  
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(
			CustID
		, 	CTSCustID
		, 	CategoryID
		, 	SportGroupID
		, 	LastModifiedDate
		, 	LastModifiedBy
		, 	ActionType
		, 	IsAuto
		, 	InsertDate
		, 	TargetCC
		, 	SourceTypeID
		, 	IsDataChanged
		,	TargetDangerLevel1
		,	TurnoverRM
		, 	WinlossRM
		, 	BetCount
		, 	ActiveDays
		
		,	IsDirect
		,	Remark
		,	IsFromTW
		,	IsFromCTS
		,	IsFromAI
		,	IsFromTVS
		,	IsFromImperva
		,	TVSRequestID
		,	IsParlay
		,	SportType
		,	IssueTypeID
	)
	SELECT  pa.CustID
		, 	pa.CTSCustID
		, 	cate.RelevantCategoryID
		, 	cate.SportGroupID
		, 	lv_Now AS LastModifiedDate
		, 	lv_CreatedBy AS LastModifiedBy
		, 	CONST_ACTIONTYPE_UPDATE AS ActionType
		, 	1 AS IsAuto
		, 	lv_Now AS InsertDate
		, 	CASE WHEN pa.TargetCC IS NOT NULL THEN pa.TargetCC
				 WHEN pa.IsLicenseeVIP = 1 AND tbl.IsDangerProbation = 0 THEN lv_CC_LicVipProblem
				 WHEN pa.IsLicenseeVIP = 1 AND tbl.IsDangerProbation = 1 THEN lv_CC_LicVip
			ELSE tbl.CustomerClass END AS TargetCC
		, 	CONST_SOURCETYPE_RESCANROBOT  AS SourceTypeID
		,   IsDataChanged
		,	CASE WHEN pa.IsLicensee = 1 THEN tbl.ABIDangerLevel_Licensee  
				 ELSE tbl.ABIDangerLevel_Credit END AS TargetDangerLevel1
		,	pa.TurnoverRM
		,	pa.WinlossRM
		, 	pa.BetCount
		, 	pa.ActiveDays
		
		,	cate.IsDirect
		,	cate.Remark
		,	cate.IsFromTW
		,	cate.IsFromCTS
		,	cate.IsFromAI
		,	cate.IsFromTVS
		,	cate.IsFromImperva
		,	cate.TVSRequestID
		,	cate.IsParlay
		,	cate.SportType
		,	cate.IssueTypeID
	FROM Temp_ExistCate AS cate
		INNER JOIN Temp_PA AS pa ON pa.CustID = cate.CustID
        INNER JOIN CTS_DataCenter.CustomerCategory AS tbl ON cate.RelevantCategoryID = tbl.CategoryID 
    WHERE cate.IsChangeWinloss = 1 
        AND cate.SportGroupID != 100;
    
    DELETE tmp
    FROM Temp_ExistCate AS tmp
    WHERE tmp.RobotCategoryID = 0;
    
    /***********************Handle update/insert Robot by winloss*******************************/
    UPDATE IGNORE Temp_PA AS pa
		INNER JOIN Temp_ExistCate AS ex ON pa.CustID = ex.CustID  
    SET 	pa.CategoryID =  CASE 	WHEN pa.WinlossStatus =  1 AND ex.CategoryID = CONST_CATEGORYID_ROBOTUSER	AND pa.CategoryID  IN (CONST_CATEGORYID_ROBOTOCRD, CONST_CATEGORYID_ROBOTOCRD_LOSING) THEN CONST_CATEGORYID_ROBOTOCRD
									WHEN pa.WinlossStatus =  1 AND ex.CategoryID = CONST_CATEGORYID_ROBOTUSER_LOSING	AND pa.CategoryID  IN (CONST_CATEGORYID_ROBOTOCRD, CONST_CATEGORYID_ROBOTOCRD_LOSING) THEN CONST_CATEGORYID_ROBOTOCRD_LOSING         
									WHEN pa.WinlossStatus =  1 AND ex.CategoryID = CONST_CATEGORYID_ROBOTOCRD	AND pa.CategoryID IN (CONST_CATEGORYID_ROBOTUSER, CONST_CATEGORYID_ROBOTUSER_LOSING) THEN CONST_CATEGORYID_ROBOTUSER  
									WHEN pa.WinlossStatus =  1 AND ex.CategoryID = CONST_CATEGORYID_ROBOTOCRD_LOSING	AND pa.CategoryID IN (CONST_CATEGORYID_ROBOTUSER, CONST_CATEGORYID_ROBOTUSER_LOSING) THEN CONST_CATEGORYID_ROBOTUSER_LOSING  
							 ELSE pa.CategoryID END
		,   pa.IsDataChanged = CASE WHEN pa.WinlossStatus != 1 OR pa.CategoryID != ex.CategoryID  THEN 1
									ELSE 0 END;

    UPDATE CTS_DataCenter.CTSCustomerClassification AS clss
		INNER JOIN Temp_PA AS pa ON  pa.CustID = clss.CustID 
					AND ((clss.CategoryID IN (CONST_CATEGORYID_ROBOTUSER,CONST_CATEGORYID_ROBOTUSER_LOSING) AND pa.CategoryID IN (CONST_CATEGORYID_ROBOTUSER,CONST_CATEGORYID_ROBOTUSER_LOSING))
                    OR (clss.CategoryID IN (CONST_CATEGORYID_ROBOTOCRD,CONST_CATEGORYID_ROBOTOCRD_LOSING) AND pa.CategoryID IN (CONST_CATEGORYID_ROBOTOCRD,CONST_CATEGORYID_ROBOTOCRD_LOSING)))
    SET 	clss.CategoryID =  pa.CategoryID   
		-- ,	clss.Remark =  CASE WHEN pa.IsFromCTS = 1 OR pa.IsFromImperva = 1 THEN pa.Remark ELSE clss.Remark END  
		,	clss.IsFromTW =   CASE WHEN pa.IsFromTW = 1 THEN pa.IsFromTW ELSE clss.IsFromTW END  
		,	clss.IsFromCTS =  CASE WHEN pa.IsFromCTS = 1 THEN pa.IsFromCTS ELSE clss.IsFromCTS END  
		,	clss.IsFromAI =  CASE WHEN pa.IsFromAI = 1 THEN pa.IsFromAI ELSE clss.IsFromAI END  
		,	clss.IsFromTVS =  CASE WHEN pa.IsFromTVS = 1 THEN pa.IsFromTVS ELSE clss.IsFromTVS END  
		,	clss.IsFromImperva =  CASE WHEN pa.IsFromImperva = 1 THEN pa.IsFromImperva ELSE clss.IsFromImperva END  
		,	clss.IsDirect = CASE WHEN pa.IsDirect = 1 THEN pa.IsDirect ELSE clss.IsDirect END
		,	pa.IsExisted = 1
		;

	DELETE 
    FROM CTS_DataCenter.CTSCustomerClassification AS clss
    WHERE EXISTS (SELECT 1 
				  FROM  Temp_PA AS pa  
                  WHERE pa.CustID = clss.CustID  
					AND pa.IsDataChanged = 1
					AND clss.SportGroupID = CONST_SPORTGROUP_NORMAL);
                    
    DELETE pro
    FROM CTS_DataCenter.ProbationAccountMonitor AS pro
	WHERE EXISTS (SELECT 1 
				  FROM  Temp_PA AS pa  
                  WHERE pa.CustID = pro.CustID  
					AND pa.IsDataChanged = 1);
        
    UPDATE Temp_PA AS pa
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON pa.CategoryID = cate.CategoryID
	SET pa.TargetCC	= CASE  WHEN pa.TargetCC IS NOT NULL AND pa.TargetCC NOT IN (SELECT tmp.CustomerClass FROM Temp_4xCC AS tmp) THEN pa.TargetCC
							WHEN pa.IsLicenseeVIP = 1 AND pa.CategoryID IN (CONST_CATEGORYID_ROBOTUSER,CONST_CATEGORYID_ROBOTOCRD) THEN lv_CC_LicVipProblem
                            WHEN pa.IsLicenseeVIP = 1 AND pa.CategoryID IN (CONST_CATEGORYID_ROBOTUSER_LOSING,CONST_CATEGORYID_ROBOTOCRD_LOSING) THEN lv_CC_LicVip
							WHEN pa.TargetCC IS NULL OR pa.TargetCC IN (SELECT tmp.CustomerClass FROM Temp_4xCC_02 AS tmp) THEN IFNULL(cate.CustomerClass, -99) 
							ELSE  -99 END 
	,	pa.TargetDangerLevel = CASE WHEN pa.IsLicensee = 1 THEN cate.ABIDangerLevel_Licensee
									WHEN pa.IsLicensee = 0 THEN cate.ABIDangerLevel_Credit				
						END;

    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification(
			CustID
		, 	CTSCustID
		, 	SubscriberID
		, 	CategoryID
		, 	SportGroupID
		,	IsFromTW
		,	IsFromCTS
		,	IsFromAI
		,	IsFromTVS
		,	IsFromImperva
		,	TVSRequestID
		, 	IsDirect
		,	Remark
		,	CreatedDate
		, 	CreatedBy
		, 	LastModifiedDate
		, 	LastModifiedBy
		, 	LastScannedDate
		,	IsParlay
		,	SportType
		,	IssueTypeID
	)
	SELECT 	pa.CustID
		,	pa.CTSCustID
		, 	pa.SubscriberID

		, 	pa.CategoryID
		, 	CONST_GROUP_PA AS SportGroupID
		,	pa.IsFromTW
		,	pa.IsFromCTS
		,	pa.IsFromAI
		,	pa.IsFromTVS
		,	pa.IsFromImperva
		,	pa.TVSRequestID
		,	pa.IsDirect
		,	pa.Remark

		, 	pa.CreatedDate
		, 	pa.CreatedBy
		, 	lv_Now AS LastModifiedDate
		, 	CreatedBy AS  LastModifiedBy
		, 	DATE(lv_Now) AS LastScannedDate
		,	pa.IsParlay
		,	pa.SportType
		,	pa.IssueTypeID
	FROM Temp_PA AS pa
    WHERE pa.IsDataChanged =  1
		AND pa.IsExisted = 0;
 
	INSERT IGNORE INTO Temp_LastHistory(CustID, CategoryID, TargetCC)
    SELECT	tmpPa.CustID
		,	tmpHis.CategoryID
        ,	tmpHis.TargetCC
    FROM Temp_PA AS tmpPa,
    LATERAL (	SELECT h.CategoryID, h.TargetCC
				FROM CTS_DataCenter.CTSCustomerClassification_History AS h
                WHERE h.CustID = tmpPa.CustID 
                ORDER BY ID DESC
                LIMIT 1) AS tmpHis;
    
	UPDATE Temp_PA AS tmpPA
		INNER JOIN Temp_LastHistory AS tmpHis ON tmpPA.CustID = tmpHis.CustID
	SET tmpPA.IsDataChanged = 1
		, tmpPA.IsExisted = 0
	WHERE tmpPA.CategoryID <> tmpHis.CategoryID OR tmpPA.TargetCC <> tmpHis.TargetCC;     

    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History(
			CustID
		, 	CTSCustID
		, 	CategoryID
		, 	SportGroupID
		, 	LastModifiedDate
		, 	LastModifiedBy
		, 	ActionType
		, 	InsertDate
		, 	TargetCC
		, 	SourceTypeID
		, 	IsDataChanged
		, 	RobotCounter
		, 	TargetDangerLevel1
		,	TurnoverRM
		, 	WinlossRM
		, 	BetCount
		, 	ActiveDays
		,	IsDirect
		,	Remark
		,	IsFromTW
		,	IsFromCTS
		,	IsFromAI
		,	IsFromTVS
		,	IsFromImperva
		,	TVSRequestID
		,	IsParlay
		,	SportType
		,	IssueTypeID
	)
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
		,	pa.IsFromImperva
		,	pa.TVSRequestID  
		,	pa.IsParlay
		,	pa.SportType
		,	pa.IssueTypeID
	FROM Temp_PA AS pa
    WHERE pa.IsDataChanged =  1 AND pa.IsExisted = 0; 
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_Log(
			CustID
		, 	CTSCustID
		, 	CategoryID
		, 	SportGroupID
		, 	LastModifiedDate
		, 	LastModifiedBy
		, 	ActionType
		, 	InsertDate
		, 	TargetCC
		, 	SourceTypeID
		, 	IsDataChanged
		, 	RobotCounter
		, 	TargetDangerLevel1
		,	TurnoverRM
		, 	WinlossRM
		, 	BetCount
		, 	ActiveDays
		,	IsDirect
		,	Remark
		,	IsFromTW
		,	IsFromCTS
		,	IsFromAI
		,	IsFromTVS
		,	IsFromImperva
		,	TVSRequestID
		,	IsParlay
		,	SportType
		,	IssueTypeID
	)
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
		,	pa.IsFromImperva
		,	pa.TVSRequestID
		,	pa.IsParlay
		,	pa.SportType
		,	pa.IssueTypeID
	FROM Temp_PA AS pa;

	SELECT 	DISTINCT 
			CTSCustID
		,  	CustID
    FROM Temp_PA;

END$$
DELIMITER ;