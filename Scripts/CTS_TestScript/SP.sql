USE `MonDB`;
DROP procedure IF EXISTS `DBA_Dummy_CustClass`;

DELIMITER $$
USE `MonDB`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Dummy_CustClass`(
		IN 	ip_ListDump		LONGTEXT
	,	IN  ip_TotalItem	INT
)
    SQL SECURITY INVOKER
BEGIN 
	DECLARE 	lv_Iterate						INT DEFAULT 1;
    DECLARE 	lv_DummyID						BIGINT;
	DECLARE 	lv_AccountType 					VARCHAR(50); #	ENUM ('NewCustomer','Normal', 'Problem')
    DECLARE 	lv_CustStatusID					INT;
    DECLARE 	lv_Role							VARCHAR(50);# ('Super-4','Master-3','Agent-2','Member-1')
    
    DECLARE 	lv_IsInternal					SMALLINT DEFAULT 0;
	DECLARE 	lv_IsLicensee					SMALLINT DEFAULT 0;
    DECLARE 	lv_IsExeptionRobot				SMALLINT DEFAULT 0;
    DECLARE 	lv_LastTicketDate				DATETIME;
    
	DECLARE 	lv_CategoryID 					JSON;
    DECLARE 	lv_OldCategoryID 				JSON;
	DECLARE 	lv_SpecialCC					INT DEFAULT 0;
    DECLARE 	lv_IsPin						SMALLINT DEFAULT 0;
    DECLARE 	lv_HasAIRobot					SMALLINT DEFAULT 0;
	DECLARE 	lv_RobotType					VARCHAR(10);

	DECLARE 	lv_UplineSuper_CategoryID		JSON;  # [1,2,3]
    DECLARE 	lv_UplineSuper_OldCategoryID	JSON;  # [1,2,3]
	DECLARE 	lv_UplineMaster_CategoryID		JSON;  # [1,2,3]
    DECLARE 	lv_UplineMaster_OldCategoryID	JSON;  # [1,2,3]
	DECLARE 	lv_UplineAgent_CategoryID		JSON;  # [1,2,3]
    DECLARE 	lv_UplineAgent_OldCategoryID	JSON;  # [1,2,3]
    
    DECLARE 	lv_ParamID						INT;
   
    DECLARE 	lv_Super						INT DEFAULT 0;
    DECLARE 	lv_SuperUsername				VARCHAR(50);
    DECLARE 	lv_Master						INT DEFAULT 0;
	DECLARE 	lv_MasterUsername				VARCHAR(50);
    DECLARE 	lv_Agent						INT DEFAULT 0;
	DECLARE 	lv_AgentUsername				VARCHAR(50);
    DECLARE 	lv_CTSCustID					INT DEFAULT 0;
	DECLARE 	lv_SubscriberID					INT DEFAULT 0;
    DECLARE 	lv_Username						VARCHAR(50);
    
    DECLARE	 	lv_Done 						INT DEFAULT FALSE;
     
    DECLARE 	lv_ListCTSCustID				LONGTEXT;
	DECLARE		lv_ListCustID					LONGTEXT;
	DECLARE		lv_ListUsername					LONGTEXT;
	DECLARE		lv_UpLineInfo					JSON;
	DECLARE		lv_JsonPara						JSON;


	DECLARE cur CURSOR FOR 
	SELECT  na.ID,
			
			na.AccountType, na.CustStatusID, na.Role,
    
			na.IsInternal, na.IsLicensee, na.IsExeptionRobot, IFNULL(na.LastTicketDate,NOW()) AS LastTicketDate,
            
			na.CategoryID, na.OldCategoryID, na.SpecialCC, na.IsPin, na.HasAIRobot, na.RobotType,
            
			na.UplineSuper_CategoryID,na.UplineSuper_OldCategoryID, na.UplineMaster_CategoryID,na.UplineMaster_OldCategoryID, na.UplineAgent_CategoryID,na.UplineAgent_OldCategoryID,
            
            na.ParamID
    FROM JSON_TABLE(CONCAT('[',ip_ListDump,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (ID BIGINT UNSIGNED PATH '$'))) AS tmp
		LEFT JOIN MonDB.DBA_DummyData_CustClass AS na ON na.ID = tmp.ID;
        
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET lv_Done = TRUE;
    OPEN cur;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Param;
	CREATE TEMPORARY TABLE Temp_Param (
			ID 						BIGINT UNSIGNED NOT NULL AUTO_INCREMENT
		,	CTSCustID				BIGINT UNSIGNED
		,	CustID					BIGINT UNSIGNED
        ,	Username				VARCHAR(50)
        ,	RoleID					SMALLINT 
         ,	Role					VARCHAR(50)	
		,	SubscriberID 			SMALLINT
        ,	IsUpLine 				BIT DEFAULT 0
        
		,	PRIMARY KEY (ID)
	) ENGINE=InnoDB;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Result;
	CREATE TEMPORARY TABLE Temp_Result (
			DummyID 				BIGINT UNSIGNED
            
		,	ListCTSCustID			LONGTEXT
		,	ListCustID				LONGTEXT
        ,	ListUsername			LONGTEXT 
        ,	UpLineInfo				JSON 
        
		,	JsonPara				JSON
		,	PRIMARY KEY (DummyID)
	) ENGINE=InnoDB;
    
    IF ip_TotalItem IS NULL  THEN
		SET ip_TotalItem = 1;
    END IF;
    
    lv_loop_outer: LOOP
    
		TRUNCATE TABLE Temp_Param;
        SET lv_ListCTSCustID = NULL;
		SET	lv_ListCustID = NULL;
		SET	lv_ListUsername = NULL;
		SET	lv_UpLineInfo = NULL;
		SET	lv_JsonPara = NULL;
        
        SET lv_Iterate = 1;
        
		FETCH cur INTO lv_DummyID,
        
					   lv_AccountType, lv_CustStatusID, lv_Role,
        
					   lv_IsInternal, lv_IsLicensee, lv_IsExeptionRobot, lv_LastTicketDate,
                       
                       lv_CategoryID, lv_OldCategoryID, lv_SpecialCC, lv_IsPin, lv_HasAIRobot, lv_RobotType,
            
					   lv_UplineSuper_CategoryID,lv_UplineSuper_OldCategoryID, lv_UplineMaster_CategoryID,lv_UplineMaster_OldCategoryID, lv_UplineAgent_CategoryID,lv_UplineAgent_OldCategoryID,
                       
                       lv_ParamID;
		
        IF lv_Done THEN 
			LEAVE lv_loop_outer;
		END IF;

		IF lv_Role IN ('Master','Agent','Member') THEN
			CALL DBA_Dummy_CTSCustomer(lv_IsInternal,lv_IsLicensee,lv_IsExeptionRobot,'Super', 0,0,0,0, lv_Super,lv_SubscriberID,lv_SuperUsername);
             
            CALL DBA_Dummy_CTSCustomerClassification(lv_Super,lv_SubscriberID,
													 lv_IsLicensee,lv_IsExeptionRobot,lv_LastTicketDate,
                                                     lv_UplineSuper_CategoryID,lv_UplineSuper_OldCategoryID,lv_SpecialCC,lv_IsPin,lv_HasAIRobot,lv_RobotType);
			
		    INSERT INTO Temp_Param(CTSCustID,CustID,Username,SubscriberID,Role,RoleID,IsUpLine)
            VALUES(lv_Super,lv_Super,lv_SuperUsername,lv_SubscriberID,'Super',4,1);
		END IF;
       
		IF lv_Role IN ('Agent','Member') THEN
			CALL DBA_Dummy_CTSCustomer(lv_IsInternal,lv_IsLicensee,lv_IsExeptionRobot,'Master', lv_Super,0,0,0, lv_Master,lv_SubscriberID,lv_MasterUsername);
            CALL DBA_Dummy_CTSCustomerClassification(lv_Master,lv_SubscriberID,
													 lv_IsLicensee,lv_IsExeptionRobot,lv_LastTicketDate,
                                                     lv_UplineMaster_CategoryID,lv_UplineMaster_OldCategoryID,lv_SpecialCC,lv_IsPin,lv_HasAIRobot,lv_RobotType);
			
            INSERT INTO Temp_Param(CTSCustID,CustID,Username,SubscriberID,Role,RoleID,IsUpLine)
            VALUES(lv_Master,lv_Master,lv_MasterUsername,lv_SubscriberID,'Master',3,1);
		END IF; 
        
        IF lv_Role IN ('Member') THEN
			CALL DBA_Dummy_CTSCustomer(lv_IsInternal,lv_IsLicensee,lv_IsExeptionRobot,'Agent', lv_Super,lv_Master,0,0, lv_Agent,lv_SubscriberID,lv_AgentUsername);
            CALL DBA_Dummy_CTSCustomerClassification(lv_Agent,lv_SubscriberID,
													 lv_IsLicensee,lv_IsExeptionRobot,lv_LastTicketDate,
                                                     lv_UplineAgent_CategoryID,lv_UplineAgent_OldCategoryID,lv_SpecialCC,lv_IsPin,lv_HasAIRobot,lv_RobotType);
                                                     
			INSERT INTO Temp_Param(CTSCustID,CustID,Username,SubscriberID,Role,RoleID,IsUpLine)
            VALUES(lv_Agent,lv_Agent,lv_AgentUsername,lv_SubscriberID,'Agent',2,1);
		END IF;
        
        lv_loop_nested: LOOP
			IF lv_Iterate > ip_TotalItem THEN
				LEAVE lv_loop_nested;
			END IF;
			CALL DBA_Dummy_CTSCustomer(lv_IsInternal,lv_IsLicensee,lv_IsExeptionRobot,lv_Role, lv_Super,lv_Master,lv_Agent,lv_CustStatusID, lv_CTSCustID,lv_SubscriberID,lv_Username);
            CALL DBA_Dummy_CTSCustomerClassification(lv_CTSCustID,lv_SubscriberID,
													 lv_IsLicensee,lv_IsExeptionRobot,lv_LastTicketDate,
                                                     lv_CategoryID,lv_OldCategoryID,lv_SpecialCC,lv_IsPin,lv_HasAIRobot,lv_RobotType);
			INSERT INTO Temp_Param(CTSCustID,CustID,Username,SubscriberID,Role)
            VALUES(lv_CTSCustID,lv_CTSCustID,lv_Username,lv_SubscriberID,'lv_Role');
			SET lv_Iterate = lv_Iterate + 1;
        END LOOP;
        
        SELECT 	GROUP_CONCAT(CTSCustID) 
			,	GROUP_CONCAT(CustID) 
            ,	GROUP_CONCAT(Username) 
		INTO 	lv_ListCTSCustID
			,	lv_ListCustID
            ,	lv_ListUsername
		FROM Temp_Param 
		WHERE  IsUpLine = 0;
	
        SELECT JSON_OBJECTAGG(Role, CTSCustID)
        INTO lv_UpLineInfo
		FROM Temp_Param 
		WHERE  IsUpLine = 1;
         
        IF lv_ParamID > 0 THEN 
			SELECT JSON_ARRAYAGG(JSON_OBJECT(
						'CTSCustID', tmp.CTSCustID 
					,	'CustID', tmp.CustID 
					,	'RoleID', tmp.RoleID 
					,	'SubscriberID', tmp.SubscriberID 
					
					,	'CategoryID', pa.CategoryID 
					,	'CategoryGroup', pa.CategoryGroup 
					,	'ReasonID', pa.ReasonID 
					,	'EvidenceID', pa.EvidenceID  
					
					,	'WinlossStatus', pa.WinlossStatus 
					,	'TurnoverRM', pa.TurnoverRM 
					,	'WinlossRM', pa.WinlossRM  
					,	'BetCount', pa.BetCount 
					,	'ActiveDays', pa.ActiveDays 
					
					,	'DWCateGroup', pa.DWCateGroup 
					,	'TWBetCount', pa.TWBetCount 
					,	'TWGroupBettingRate', pa.TWGroupBettingRate  
					,	'TWTicketRejectRate', pa.TWTicketRejectRate 
					,	'TWDesktopUsageRate', pa.TWDesktopUsageRate 
					,	'TaggingID', pa.TaggingID 
					,	'TaggingType', pa.TaggingType 
					
					,	'CreatedBy', pa.CreatedBy 
					,	'Remark', pa.Remark)) AS param
			INTO lv_JsonPara
			FROM Temp_Param AS tmp 
			INNER JOIN MonDB.DBA_DummyData_Param AS pa ON pa.ID = lv_ParamID
            WHERE tmp.IsUpLine = 0;
        END IF;
        
        INSERT INTO Temp_Result(DummyID, ListCTSCustID, ListCustID, UpLineInfo,JsonPara )
        VALUES(lv_DummyID, lv_ListCTSCustID,lv_ListCustID,lv_UpLineInfo,lv_JsonPara);
	END LOOP;
	CLOSE cur;
	
    SELECT * 
    FROM Temp_Result;
END$$

DELIMITER ;
;



USE `MonDB`;
DROP procedure IF EXISTS `DBA_Dummy_CTSCustomerClassification`;

USE `MonDB`;
DROP procedure IF EXISTS `MonDB`.`DBA_Dummy_CTSCustomerClassification`;
;

DELIMITER $$
USE `MonDB`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Dummy_CTSCustomerClassification`(
		IN 		ip_CTSCustID		BIGINT UNSIGNED
	,   IN 		ip_SubscriberID		INT UNSIGNED
    
    ,   IN 		ip_IsLicensee		BIT
    ,   IN 		ip_IsRobotException BIT
    ,	IN		ip_LastTicketDate	DATETIME
    
    ,	IN		ip_Category			JSON
    ,	IN		ip_OldCategory		JSON
    ,   IN 		ip_SpecialCC		INT UNSIGNED
    ,   IN 		ip_IsPin			BIT
    ,   IN 		ip_HasAIRobot		BIT
	,   IN 		ip_RobotType 		VARCHAR(50)
    

)
    SQL SECURITY INVOKER
sp: BEGIN
	DECLARE	CONST_GROUP_NORMAL 					INT DEFAULT 200;
    DECLARE	CONST_GROUP_PROBLEM 				INT DEFAULT 0;
    DECLARE	CONST_GROUP_ROBOTUSER 				INT DEFAULT 61;
    DECLARE CONST_ACTIONTYPE_INSERT 			INT DEFAULT 0;
    
	DECLARE	CONST_CATEGORYID_GOODROBOT 	INT DEFAULT 164;
    
	DECLARE CONST_ROBOTTYPE_OBSERVED 	TINYINT UNSIGNED DEFAULT 0;
    DECLARE CONST_ROBOTTYPE_GOOD 		TINYINT UNSIGNED DEFAULT 1;
    DECLARE CONST_ROBOTTYPE_BAD 		TINYINT UNSIGNED DEFAULT 2;
    
	DECLARE lv_Username 			VARCHAR(50);
    DECLARE lv_SiteID   			INT;
	DECLARE	lv_SiteName 			VARCHAR(50);
    DECLARE	lv_SubscriberID			INT;
	DECLARE lv_MinDate 				DATETIME DEFAULT '2022-01-01 00:00:00';
	DECLARE lv_MaxDate 				DATETIME DEFAULT NOW();
	DECLARE lv_CreatedDate 			DATETIME;
    DECLARE lv_LastModifiedDate 	DATETIME;
    DECLARE lv_CreatedBy 			INT DEFAULT 10278938;
	DECLARE lv_SourceTypeID			INT DEFAULT 31; 
    
    SET lv_CreatedDate = TIMESTAMPADD(SECOND, FLOOR(RAND() * TIMESTAMPDIFF(SECOND, lv_MinDate, lv_MaxDate)), lv_MinDate);
    SET lv_LastModifiedDate = TIMESTAMPADD(SECOND, FLOOR(RAND() * TIMESTAMPDIFF(SECOND, lv_CreatedDate, lv_MaxDate)), lv_CreatedDate);
    
    IF ip_SpecialCC > 0 THEN 
		INSERT INTO CTS_DataCenter.SpecialCustomerClass
		(CTSCustID,CustID,RootCTSCustID,
		SubscriberID,CustomerClass,
		CreatedBy,CreatedDate,LastModifiedBy,LastModifiedDate,
		CreatedFromFunction)
		VALUES
		(ip_CTSCustID,ip_CTSCustID,ip_CTSCustID,
         ip_SubscriberID,ip_SpecialCC,
         lv_CreatedBy,lv_CreatedDate,lv_CreatedBy,lv_LastModifiedDate,
         0);
    END IF;
    
    IF ip_IsPin = 1 THEN 
		INSERT INTO CTS_DataCenter.PinCustomerCategory(CTSCustID,CreatedTime,CreatedBy)
		VALUES(ip_CTSCustID,lv_CreatedDate, lv_CreatedBy);
    END IF;
    
    IF ip_HasAIRobot = 1 THEN
		INSERT IGNORE INTO CTS_DataCenter.RobotDetection(CustID,PeriodRangeType,LastModifiedDate,IsDisabled)
		VALUES(ip_CTSCustID,1,lv_CreatedDate,0);
    END IF;
    
    IF ip_RobotType = 'Good' THEN
		INSERT IGNORE INTO CTS_DataCenter.RobotClassification(CustID,FromDate,ToDate,RobotType,Turnover,BetCount,ActiveDays)
		VALUES(ip_CTSCustID,lv_CreatedDate,lv_LastModifiedDate,CONST_ROBOTTYPE_GOOD,0,0,0);
    END IF;
    
    IF ip_RobotType = 'Bad' THEN
		INSERT IGNORE INTO CTS_DataCenter.RobotClassification(CustID,FromDate,ToDate,RobotType,Turnover,BetCount,ActiveDays)
		VALUES(ip_CTSCustID,lv_CreatedDate,lv_LastModifiedDate,CONST_ROBOTTYPE_BAD,0,0,0);
    END IF;

    INSERT INTO CTS_Archive.CTSCustomerAssociationStatus(CTSCustID,CustID,LastTicketDate,IsArchived,RollBackDate,Created)
	VALUES(ip_CTSCustID,ip_CTSCustID , ip_LastTicketDate,0,NULL,lv_CreatedDate);
    
     IF ip_OldCategory IS NOT NULL THEN
		INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassificationOldPA
		(CustID,CTSCustID,SubscriberID,
		SportGroupID,CategoryID,
		CreatedDate,LastModifiedDate,CreatedBy,LastModifiedBy,LastScannedDate,
		IsFromTVS,IsFromTW,IsFromPAM,IsDirect,TVSRequestID,
		Remark) 
		SELECT  ip_CTSCustID,ip_CTSCustID,ip_SubscriberID
			, 	CASE WHEN cate.ParentID = 50 THEN 0 ELSE 200 END AS SportGroupID, cate.CategoryID
			,	lv_CreatedDate,lv_LastModifiedDate,lv_CreatedBy,lv_CreatedBy,lv_LastModifiedDate
			,   0 AS IsFromTVS, 0 AS IsFromTW, 1 AS IsFromPAM, 1 AS IsDirect, 0 AS TVSRequestID
			,	'Text' AS Remark
		FROM JSON_TABLE(ip_OldCategory,'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CategoryID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = tmp.CategoryID;
     END IF;
    
    IF ip_Category IS NULL THEN
		LEAVE sp;
    END IF;
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification
	(CustID,CTSCustID,SubscriberID,
	SportGroupID,CategoryID,
    CreatedDate,LastModifiedDate,CreatedBy,LastModifiedBy,LastScannedDate,
	IsFromTVS,IsFromTW,IsFromPAM,IsDirect,TVSRequestID,
    Remark)
    SELECT  ip_CTSCustID,ip_CTSCustID,ip_SubscriberID
		, 	CASE WHEN cate.ParentID = 50 THEN 0 ELSE 200 END AS SportGroupID, cate.CategoryID
        ,	lv_CreatedDate,lv_LastModifiedDate,lv_CreatedBy,lv_CreatedBy,lv_LastModifiedDate
        ,   0 AS IsFromTVS, 0 AS IsFromTW, 1 AS IsFromPAM, 1 AS IsDirect, 0 AS TVSRequestID
        ,	'Text' AS Remark
	FROM JSON_TABLE(ip_Category,'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CategoryID BIGINT UNSIGNED PATH '$'))) AS tmp
	INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = tmp.CategoryID;
    
    IF EXISTS (SELECT 1 
			   FROM  JSON_TABLE(ip_Category,'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CategoryID BIGINT UNSIGNED PATH '$'))) AS tmp
               WHERE CategoryID = 210) THEN
		INSERT INTO CTS_DataCenter.CTSCustomerClassificationVVIP
        (CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, CategoryID, IsAffectToDownline, InsertTime) 
        VALUES (ip_CTSCustID, ip_CTSCustID, '1', ip_SubscriberID, lv_CreatedBy, 'Remark', 210, 1, NOW());

	END IF;
   
    
    INSERT IGNORE INTO CTS_DataCenter.CTSCustomerClassification_History
	(CustID,CTSCustID,
	SportGroupID,CategoryID,
    TargetCC,
    TargetDangerLevel1,IsDirect,TVSRequestID,
	TurnoverRM,WinlossRM,BetCount,ActiveDays,RobotCounter,
	SourceTypeID,IsDataChanged,ActionType,LastModifiedDate,LastModifiedBy,InsertDate,
	Remark)
	SELECT  ip_CTSCustID,ip_CTSCustID
		, 	CASE WHEN cate.ParentID = 50 THEN 0 ELSE 200 END AS SportGroupID, cate.CategoryID
        ,	CASE  WHEN ip_SpecialCC > 0 THEN ip_SpecialCC
				  WHEN cate.CategoryID IN (CONST_CATEGORYID_GOODROBOT) AND ip_IsRobotException = 1 THEN cate.CustomerClassException
			ELSE cate.CustomerClass END AS CustomerClass
		,	CASE WHEN cate.CategoryID IN (CONST_CATEGORYID_GOODROBOT) AND ip_IsRobotException = 1 AND ip_IsLicensee = 1 THEN cate.ABIDangerLevelException_Licensee
							 WHEN cate.CategoryID IN (CONST_CATEGORYID_GOODROBOT) AND ip_IsRobotException = 1 AND ip_IsLicensee = 0 THEN cate.ABIDangerLevelException_Credit
							 WHEN ip_IsLicensee = 1 THEN cate.ABIDangerLevel_Licensee
							 WHEN ip_IsLicensee = 0 THEN cate.ABIDangerLevel_Credit
			END AS DangerLevel, 0 AS IsDirect, 0 AS TVSRequestID
        ,	0 AS TurnoverRM, 0 AS  WinlossRM,0 AS  BetCount,0 AS  ActiveDays,0 AS  RobotCounter
        ,   lv_SourceTypeID,1 AS IsDataChanged, 0 AS ActionType, lv_CreatedDate,lv_CreatedBy, NOW() AS InsertDate
        ,	'Text' AS Remark
	FROM JSON_TABLE(CONCAT(ip_Category),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CategoryID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = tmp.CategoryID;
	
    
    INSERT IGNORE INTO CTS_DataCenter.CustEvidence(CTSCustID,EvidenceID,Level,Remark,FromCustID,CreatedBy,SourceType)
    SELECT ip_CTSCustID, cate.EvidenceID_Licensee,0 AS Level,'Text' AS Remark,ip_CTSCustID,lv_CreatedBy,0 AS SourceType
	FROM JSON_TABLE(CONCAT(ip_Category),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CategoryID BIGINT UNSIGNED PATH '$'))) AS tmp
	INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = tmp.CategoryID AND cate.EvidenceID_Licensee IS NOT NULL;
END$$

DELIMITER ;
;



USE `MonDB`;
DROP procedure IF EXISTS `DBA_Dummy_CTSCustomer`;

USE `MonDB`;
DROP procedure IF EXISTS `MonDB`.`DBA_Dummy_CTSCustomer`;
;

DELIMITER $$
USE `MonDB`$$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DBA_Dummy_CTSCustomer`(
		IN 	ip_IsInternal 		BIT
	,	IN 	ip_IsLicensee 		BIT
    ,	IN 	ip_IsExeptionRobot	BIT
    ,	IN 	ip_Role				VARCHAR(20)
    
    ,	IN 	ip_SRecommend		INT
	,	IN 	ip_MRecommend		INT 
    ,	IN 	ip_Recommend		INT
    ,	IN 	ip_CustStatusID		INT
    
    ,	OUT	op_CTSCustID		BIGINT
    ,	OUT	op_SubscriberID		BIGINT
    ,	OUT	op_Username			VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
	DECLARE lv_Username 		VARCHAR(50);
    DECLARE lv_SiteID   		INT;
	DECLARE	lv_SiteName 		VARCHAR(50);
    DECLARE	lv_SubscriberID		INT;
    DECLARE lv_CurrencyID		INT DEFAULT 1;
    DECLARE lv_RoleID			INT;
    DECLARE lv_SRecommend		INT;
    DECLARE lv_MRecommend		INT;
    DECLARE lv_Recommend		INT;
    
    SET lv_Username = CONCAT("Test_",MD5(RAND()));
    IF ip_IsInternal = 1 THEN
		SET lv_Username = CONCAT(lv_Username,'_CashOut');
    END IF;
	SET op_Username = lv_Username;
    
    IF ip_IsLicensee = 1 THEN
		SELECT 	SiteID
			,	SiteName
			,	SubscriberID
		INTO 	lv_SiteID
			, 	lv_SiteName
			, 	lv_SubscriberID
		FROM  CTS_DataCenter.MappingSubscriberSite 
        WHERE SiteID > 0 AND SubscriberGroupID = 2
		LIMIT 1;
        IF ip_IsExeptionRobot = 1 THEN SET lv_CurrencyID = 78; END IF;
    ELSE
		SELECT 	SiteID
			,	SiteName
			,	SubscriberID
		INTO 	lv_SiteID
			, 	lv_SiteName
			, 	lv_SubscriberID
		FROM  CTS_DataCenter.MappingSubscriberSite 
        WHERE (ip_IsExeptionRobot = 0 AND SiteID > 0 AND SubscriberGroupID  != 2 AND SubscriberID NOT IN  (2,130))
			OR (ip_IsExeptionRobot = 1 AND SiteID > 0 AND SubscriberGroupID != 2 AND SubscriberID  IN  (2,130))
		LIMIT 1;
    END IF;
    
    SET op_SubscriberID = lv_SubscriberID;
    
    IF ip_Role = 'Super' THEN
		SET lv_RoleID = 4;
		SET lv_MRecommend = 0;
		SET lv_Recommend = 0;
	ELSEIF  ip_Role = 'Master' THEN
		SET lv_RoleID = 3;
        SET lv_SRecommend = ip_SRecommend;
		SET lv_Recommend = 0;
    ELSEIF  ip_Role = 'Agent' THEN
		SET lv_SRecommend = ip_SRecommend;
        SET lv_MRecommend = ip_MRecommend;
		SET lv_RoleID = 2;
    ELSEIF  ip_Role = 'Member' THEN
		SET lv_RoleID = 1;
        SET lv_SRecommend = ip_SRecommend;
		SET lv_MRecommend = ip_MRecommend;
		SET lv_Recommend = ip_Recommend;
    END IF;

    INSERT INTO CTS_DataCenter.CTSCustomer(
			SubscriberID,SiteID,Site,Currency,CurrencyID,
			UserName,UserName2,RegisterName,CustSubID,
			SRecommend,MRecommend,Recommend,RoleID,
            CustStatusID, IsLicensee,IsInternal,
			LastLoginTime,CreatedDate,
			Danger1,Danger2,Danger3,InsertedTime,ModifiedTime)
	VALUES(lv_SubscriberID, lv_SiteID, lv_SiteName,lv_CurrencyID,lv_CurrencyID,
		   lv_Username, lv_Username,lv_Username, 0,
           lv_SRecommend,lv_MRecommend,lv_Recommend,lv_RoleID,
           ip_CustStatusID,ip_IsLicensee,ip_IsInternal,
           NOW(),NOW(),
           0,0,0,NOW(),NOW());
	
    SELECT LAST_INSERT_ID() INTO op_CTSCustID;
    
    UPDATE CTS_DataCenter.CTSCustomer
    SET CustID = op_CTSCustID
    WHERE CTSCustID = op_CTSCustID;
    
    IF ip_Role = 'Super' THEN
		UPDATE CTS_DataCenter.CTSCustomer
		SET SRecommend = op_CTSCustID
		WHERE CTSCustID = op_CTSCustID;
	ELSEIF  ip_Role = 'Master' THEN
		UPDATE CTS_DataCenter.CTSCustomer
		SET MRecommend = op_CTSCustID
		WHERE CTSCustID = op_CTSCustID;
    ELSEIF  ip_Role = 'Agent' THEN
		UPDATE CTS_DataCenter.CTSCustomer
		SET Recommend = op_CTSCustID
		WHERE CTSCustID = op_CTSCustID;
    END IF;
END$$

DELIMITER ;
;

