/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsService,ctsAPI" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Rescan_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Rescan_Get`(
		IN ip_CustIDs	LONGTEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20220520@Aries.Nguyen
		Task :		Renovate PA Process
		DB:			CTS_DataCenter 
		Original: 
		Revisions:  
			- 20220520@Aries.Nguyen: 	Created [Redmine ID: #172561]
            - 20220616@Aries.Nguyen: 	Cannot mark PA (affected by uplines) correctly with First Mark [Redmine ID: #174136]
            - 20220628@Aries.Nguyen: 	Update robot classification rule [Redmine ID: #174430]
			- 20220705@Long.Luu: 		Return IsLicenseeVIP info [Redmine ID: #174219]
            - 20221007@Harvey.Nguyen: 	Change CTSCustomerClassificationOldPA -> CTSCustomerClassificationOldCategory [Redmine ID: #178022]
			- 20230315@Victoria.Le:		Add Robot Imperva [Redmine ID: #184773]
			- 20230404@Victoria.Le		TVS Abnormal Bet and Abnormal Account - Add IsParlay,SportType,IssueTypeId [Redmine ID: #185319] 
			- 20230517@Victoria.Le:		New Category for Robot OCRD [Redmine ID: #186991]
            - 20240103@Thomas.Nguyen:   New Category for System Detect Unauthorized Login [RedmineID: #197710]
			- 20240620@Jonas.Huynh: 	Renovate CC [RedmineID: #205317]
            
        Param's Explanation:

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_Rescan_Get_UAT4("1,2,3,4");
	*/ 
    DECLARE	CONST_CATEID_UNAUTHORIZEDLOGIN			INT;
    DECLARE	CONST_CATEID_ROBOTUSER					INT;
    DECLARE	CONST_CATEID_ROBOTOCRD					INT;
    DECLARE	CONST_CATEID_EARLYWARNING				INT;
    DECLARE	CONST_CATEID_INITIALGB					INT;
    DECLARE CONST_CATEID_INITIALSMART				INT;
    DECLARE	CONST_PARENTID_PA						INT;

    DECLARE CONST_INPUTFLOWID_NORMAL				INT DEFAULT 9;
    DECLARE	CONST_INPUTFLOWID_POTENTIALPA			INT DEFAULT 8;
    DECLARE	CONST_INPUTFLOWID_ROBOT					INT DEFAULT 7;
	DECLARE	CONST_INPUTFLOWID_CATEGORY_PA			INT DEFAULT 115;
	DECLARE	CONST_INPUTFLOWID_REASON_PA				INT DEFAULT 116; 
      
	DECLARE	CONST_TVSREQUESTTYPE_PA					TINYINT DEFAULT 1; 
	DECLARE CONST_CREATEDBY_STARIXITID				INT DEFAULT 10278938;
    
    SET CONST_CATEID_UNAUTHORIZEDLOGIN	 			= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_UNAUTHORIZEDLOGIN');
    SET CONST_CATEID_ROBOTUSER	 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTUSER');
    SET CONST_CATEID_ROBOTOCRD	 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_ROBOTOCRD');
    SET CONST_CATEID_EARLYWARNING	 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_EARLYWARNING');
    SET CONST_CATEID_INITIALGB	 					= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALGB');
    SET CONST_CATEID_INITIALSMART	 				= CTS_DC_CategoryTypeParent_Get ('CONST_CATEID_INITIALSMART');
    SET CONST_PARENTID_PA 							= CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;    
	CREATE TEMPORARY TABLE Temp_CustID (	  
			CustID          BIGINT UNSIGNED PRIMARY KEY 	
     );
             
	DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;    
	CREATE TEMPORARY TABLE Temp_CustInfo (	  
			CTSCustID		BIGINT UNSIGNED PRIMARY KEY 
        ,   CustID			BIGINT UNSIGNED 
		,	RoleID 			TINYINT 
		,	SRecommend 		INT  
		,	MRecommend		INT  
		,	Recommend 		INT  
        , 	SubscriberID	INT 
        ,	IsLicensee		BIT 
        ,	IsLicenseeVIP	BIT 
        ,	CategoryGroup   SMALLINT
     ); 
     
	DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;    
	CREATE TEMPORARY TABLE Temp_CustCategory (	  
			CTSCustID				BIGINT UNSIGNED
        ,   CustID					BIGINT UNSIGNED 
        ,	CategoryID              INT UNSIGNED  
        ,	TVSReasonID             INT 
        ,	RoleID 					TINYINT 
		, 	SubscriberID			INT UNSIGNED
        ,	IsLicensee				BIT
		,	Remark				    VARCHAR(500)
        ,   CreatedBy               INT UNSIGNED
        ,	IsMarkedDirectly	    BIT        
        ,	IsFromTVS 				BIT DEFAULT 0
        ,	IsFromTW 				BIT DEFAULT 0
        ,	IsFromCTS 				BIT DEFAULT 0
        ,	IsFromAI 				BIT DEFAULT 0
		,	IsFromImperva			BIT DEFAULT 0
        ,   LastModifiedDate        DATETIME(3) 
		,	InputFlowID	 			INT
		,	PRIMARY KEY(CustID,CategoryID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategoryDuplicate; 
	CREATE TEMPORARY TABLE Temp_CustCategoryDuplicate (	  
			CustID          BIGINT UNSIGNED 	
		,	CategoryID      INT UNSIGNED  
        ,	TVSReasonID     INT 
        ,	InputFlowID	 	INT
		,	PRIMARY KEY(CustID,CategoryID)
     );
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
     
    INSERT  INTO Temp_CustInfo(CTSCustID,CustID,SRecommend,MRecommend,Recommend,RoleID,SubscriberID,IsLicensee)
    SELECT 	cus.CTSCustID
		,	cus.CustID
        ,	CASE WHEN cus.SRecommend = 0 THEN -1 ELSE cus.SRecommend END AS SRecommend
        ,	CASE WHEN cus.MRecommend = 0 THEN -1 ELSE cus.MRecommend END AS MRecommend
        ,	CASE WHEN cus.Recommend = 0 THEN -1 ELSE cus.Recommend END AS Recommend
        ,	cus.RoleID	 
		, 	cus.SubscriberID	 
        ,	cus.IsLicensee	
    FROM Temp_CustID AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
        
	/***********************Check Robot Imperva****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT tmp.CTSCustID				AS CTSCustID
		,	tmp.CustID					AS CustID
        ,	CONST_CATEID_ROBOTUSER 		AS CategoryID
        , 	NULL 						AS TVSReasonID
        ,	tmp.RoleID 					AS RoleID
        ,	tmp.SubscriberID			AS SubscriberID
		,	tmp.IsLicensee				AS IsLicensee
        ,	NULL 						AS Remark
        ,	NULL 						AS CreatedBy
        ,	1 							AS IsMarkedDirectly
		,	0 							AS IsFromTVS
        ,	0 							AS IsFromTW
        ,   0 							AS IsFromCTS
        ,	0 							AS IsFromAI
        ,	1 							AS IsFromImperva
        ,	s.CreateTime 				AS LastModifiedDate
        ,   CONST_INPUTFLOWID_ROBOT		AS InputFlowID
    FROM  Temp_CustInfo AS tmp,
    LATERAL (SELECT CreateTime
			 FROM CTS_DataCenter.RobotImperva
			 WHERE CustID = tmp.CustID 
			 ORDER BY CreateTime DESC
			 LIMIT 1) AS s;
	
    /***********************Check Robot Betting****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT tmp.CTSCustID				AS CTSCustID
		,	tmp.CustID					AS CustID
        ,	CONST_CATEID_ROBOTOCRD 		AS CategoryID
        , 	NULL 						AS TVSReasonID
        ,	tmp.RoleID 					AS RoleID
        ,	tmp.SubscriberID 			AS SubscriberID
		,	tmp.IsLicensee 				AS IsLicensee
        ,	NULL 						AS Remark
        ,	NULL 						AS CreatedBy
        ,	1							AS IsMarkedDirectly
		,	0 							AS IsFromTVS
        ,	0 							AS IsFromTW
        ,   0 							AS IsFromCTS
        ,	1 							AS IsFromAI
        ,	0 							AS IsFromImperva
        ,	s.CreatedDate 				AS LastModifiedDate
        ,   CONST_INPUTFLOWID_ROBOT		AS InputFlowID
    FROM  Temp_CustInfo AS tmp,
    LATERAL (SELECT CreatedDate
			 FROM CTS_DataCenter.RobotDetection 
			 WHERE CustID = tmp.CustID
				AND  PeriodRangeType = 200
				AND  IsDisabled = 0
			 ORDER BY CreatedDate DESC
			 LIMIT 1) AS s;
			
	INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT 	tmp.CTSCustID				AS CTSCustID
		,	tmp.CustID					AS CustID
        ,	CONST_CATEID_ROBOTUSER 		AS CategoryID
        , 	NULL						AS TVSReasonID
        ,	tmp.RoleID 					AS RoleID
        ,	tmp.SubscriberID			AS SubscriberID
		,	tmp.IsLicensee				AS IsLicensee
        ,	NULL 						AS Remark
        ,	NULL 						AS CreatedBy
        ,	1 							AS IsMarkedDirectly
		,	0 							AS IsFromTVS
        ,	0 							AS IsFromTW
        ,   0 							AS IsFromCTS
        ,	1 							AS IsFromAI
        ,	0 							AS IsFromImperva
        ,	s.CreatedDate  				AS LastModifiedDate
        ,   CONST_INPUTFLOWID_ROBOT		AS InputFlowID
    FROM  Temp_CustInfo AS tmp,
    LATERAL (SELECT CreatedDate
			 FROM CTS_DataCenter.RobotDetection 
             WHERE CustID = tmp.CustID
				AND  PeriodRangeType <> 200
				AND  IsDisabled = 0
			 ORDER BY CreatedDate DESC
			 LIMIT 1) AS s
	ON DUPLICATE KEY UPDATE IsFromAI = 1
						,	LastModifiedDate = CASE WHEN s.CreatedDate < Temp_CustCategory.LastModifiedDate THEN s.CreatedDate ELSE Temp_CustCategory.LastModifiedDate END;
	
    /***********************Check CTS RobotUser****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT tmp.CTSCustID				AS CTSCustID
		,	tmp.CustID					AS CustID
        ,	s.CategoryID 				AS CategoryID
        , 	NULL	 					AS TVSReasonID
        ,	tmp.RoleID 					AS RoleID
        ,	tmp.SubscriberID			AS SubscriberID
		,	tmp.IsLicensee				AS IsLicensee
        ,	s.Remark					AS Remark
        ,	NULL		 				AS CreatedBy
        ,	1 							AS IsMarkedDirectly
		,	0 							AS IsFromTVS
        ,	0 							AS IsFromTW
        ,   1 							AS IsFromCTS
        ,	0 							AS IsFromAI
        ,	0							AS IsFromImperva
        ,	s.CreatedDate 				AS LastModifiedDate
        ,   CONST_INPUTFLOWID_ROBOT		AS InputFlowID
    FROM  Temp_CustInfo AS tmp
		INNER JOIN CTS_DataCenter.CTSRobotUser AS s ON s.CustID = tmp.CustID
	WHERE s.IsDisabled = 0
	ON DUPLICATE KEY UPDATE IsFromCTS = 1
						,	LastModifiedDate = CASE WHEN s.CreatedDate < Temp_CustCategory.LastModifiedDate THEN s.CreatedDate ELSE Temp_CustCategory.LastModifiedDate END
                        ,	Remark = CASE WHEN s.CreatedDate < Temp_CustCategory.LastModifiedDate THEN s.Remark ELSE Temp_CustCategory.Remark END;
        
	/***********************Check TWRobotUser****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT tmp.CTSCustID				AS CTSCustID
		,	tmp.CustID					AS CustID
        ,	s.CategoryID 				AS CategoryID
        , 	NULL	 					AS TVSReasonID
        ,	tmp.RoleID 					AS RoleID
        ,	tmp.SubscriberID			AS SubscriberID
		,	tmp.IsLicensee				AS IsLicensee
        ,	NULL 						AS Remark
        ,	NULL		 				AS CreatedBy
        ,	1 							AS IsMarkedDirectly
		,	0 							AS IsFromTVS
        ,	1 							AS IsFromTW
        ,   0 							AS IsFromCTS
        ,	0 							AS IsFromAI
        ,	0							AS IsFromImperva
        ,	s.CreatedDate 				AS LastModifiedDate
        ,   CONST_INPUTFLOWID_ROBOT		AS InputFlowID
    FROM  Temp_CustInfo AS tmp
		INNER JOIN CTS_DataCenter.TWRobotUser AS s ON s.CustID = tmp.CustID
	WHERE s.IsDisabled = 0
   	ON DUPLICATE KEY UPDATE IsFromTW = 1
						,	LastModifiedDate = CASE WHEN s.CreatedDate < Temp_CustCategory.LastModifiedDate THEN s.CreatedDate ELSE Temp_CustCategory.LastModifiedDate END;
                        
	 /***********************Check System Detect Unauthorized Login****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT 	tmp.CTSCustID					AS CTSCustID
		,	tmp.CustID						AS CustID
        ,	CONST_CATEID_UNAUTHORIZEDLOGIN  AS CategoryID
        , 	NULL 							AS TVSReasonID
        ,	tmp.RoleID 						AS RoleID
        ,	tmp.SubscriberID				AS SubscriberID
		,	tmp.IsLicensee					AS IsLicensee
        ,	NULL 							AS Remark
        ,	NULL 							AS CreatedBy
        ,	1 								AS IsMarkedDirectly
		,	0 								AS IsFromTVS
        ,	0 								AS IsFromTW
        ,   1 								AS IsFromCTS
        ,	0 								AS IsFromAI
        ,	0 								AS IsFromImperva
        ,	s.DetectionDate 				AS LastModifiedDate
        ,   CONST_INPUTFLOWID_CATEGORY_PA	AS InputFlowID
    FROM  Temp_CustInfo AS tmp
    INNER JOIN CTS_DataCenter.CustomerLoginInfoDetection AS s ON s.CustID = tmp.CustID;
    
    /***********************Check TVS Void****************************/
	INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT tmp.CTSCustID					AS CTSCustID
		,	tmp.CustID						AS CustID
        ,	NULL 							AS CategoryID
        , 	s.TVSReasonID 					AS TVSReasonID
        ,	tmp.RoleID 						AS RoleID
        ,	tmp.SubscriberID				AS SubscriberID
 		,	tmp.IsLicensee					AS IsLicensee
        ,	NULL 							AS Remark
        ,	s.CreatedBy 					AS CreatedBy
        ,	1 								AS IsMarkedDirectly
 		,	1 								AS IsFromTVS
        ,	0 								AS IsFromTW
        ,   0 								AS IsFromCTS
        ,	0 								AS IsFromAI
		,	0								AS IsFromImperva
        ,	s.InsertedTime 				AS LastModifiedDate
        ,   CONST_INPUTFLOWID_REASON_PA 	AS InputFlowID
    FROM  Temp_CustInfo AS tmp
 		,	LATERAL (SELECT TVSReasonID, CreatedBy, InsertedTime
 					 FROM CTS_DataCenter.TVSVoidRequest 
 					 WHERE CustID = tmp.CustID
						AND RequestTypeID = CONST_TVSREQUESTTYPE_PA
					 ORDER BY ID DESC
					 LIMIT 1) AS s;
    
    /***********************Check affected PA from Upline****************************/   
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT tmp.CTSCustID					AS CTSCustID
		,	tmp.CustID						AS CustID
        ,	s.CategoryID					AS CategoryID
        , 	NULL 							AS TVSReasonID
        ,	tmp.RoleID 						AS RoleID
        ,	tmp.SubscriberID				AS SubscriberID
		,	tmp.IsLicensee					AS IsLicensee
        ,	s.Remark						AS Remark
        ,	s.CreatedBy 					AS CreatedBy
        ,	0 								AS IsMarkedDirectly
		,	s.IsFromTVS 					AS IsFromTVS
        ,	s.IsFromTW 						AS IsFromTW
        ,   s.IsFromCTS 					AS IsFromCTS
        ,	s.IsFromAI 						AS IsFromAI
        ,	s.IsFromImperva					AS IsFromImperva
        ,	s.CreatedDate 					AS LastModifiedDate
        ,   CONST_INPUTFLOWID_CATEGORY_PA	AS InputFlowID
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification AS s USE INDEX (PRIMARY) ON s.CustID IN (tmp.SRecommend,tmp.MRecommend,tmp.Recommend) 
					AND s.ParentID = CONST_PARENTID_PA 
                    AND s.IsAffectToDownline = 1
	ON DUPLICATE KEY UPDATE  Remark = CASE WHEN  s.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN s.Remark ELSE Temp_CustCategory.Remark END
						,	LastModifiedDate = CASE WHEN s.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN s.LastModifiedDate ELSE Temp_CustCategory.LastModifiedDate END
						,	CreatedBy = CASE WHEN s.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN s.CreatedBy ELSE Temp_CustCategory.CreatedBy END
                        ,	IsFromCTS = CASE WHEN s.IsFromCTS = 1 AND s.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN s.IsFromCTS ELSE Temp_CustCategory.IsFromCTS END;
	
    /*********************** Get completely PA Rescan  ****************************/
	INSERT INTO Temp_CustCategoryDuplicate (CustID, CategoryID, TVSReasonID, InputFlowID)
	SELECT CustID, CategoryID, TVSReasonID, InputFlowID
    FROM Temp_CustCategory;
     
	/***********************Check Early Warning****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT tmp.CTSCustID					AS CTSCustID
		,	tmp.CustID						AS CustID
        ,	CONST_CATEID_EARLYWARNING 		AS CategoryID
        , 	NULL 							AS TVSReasonID
        ,	tmp.RoleID 						AS RoleID
        ,	tmp.SubscriberID				AS SubscriberID
		,	tmp.IsLicensee					AS IsLicensee
        ,	NULL 							AS Remark
        ,	NULL 							AS CreatedBy
        ,	1 								AS IsMarkedDirectly
		,	0 								AS IsFromTVS
        ,	0 								AS IsFromTW
        ,   1 								AS IsFromCTS
        ,	0 								AS IsFromAI
        ,	0 								AS IsFromImperva
        ,	s.CreatedDate 					AS LastModifiedDate
        ,   CONST_INPUTFLOWID_POTENTIALPA	AS InputFlowID
    FROM  Temp_CustInfo AS tmp,
		LATERAL (SELECT cd.CreatedDate
				 FROM CTS_DataCenter.Customer_DangerousScore AS cd
				 WHERE cd.CustID = tmp.CustID 
					AND cd.ClassifiedScore IS NOT NULL
				 ORDER BY cd.ID ASC
				 LIMIT 1) AS s
	WHERE NOT EXISTS (SELECT 1 
					  FROM Temp_CustCategoryDuplicate AS cc 
                      WHERE cc.CustID = tmp.CustID 
						AND cc.InputFlowID IN (CONST_INPUTFLOWID_ROBOT, CONST_INPUTFLOWID_CATEGORY_PA, CONST_INPUTFLOWID_REASON_PA));

    /***********************Check Initial GroupBetting****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
	SELECT tmp.CTSCustID					AS CTSCustID
		,	tmp.CustID						AS CustID
        ,	CONST_CATEID_INITIALGB 			AS CategoryID
        , 	NULL 							AS TVSReasonID
        ,	tmp.RoleID 						AS RoleID	 
        ,	tmp.SubscriberID				AS SubscriberID	
		,	tmp.IsLicensee					AS IsLicensee
        ,	NULL 							AS Remark
        ,	NULL 							AS CreatedBy
        ,	1 								AS IsMarkedDirectly
		,	0 								AS IsFromTVS
        ,	1 								AS IsFromTW
        ,   0 								AS IsFromCTS
        ,	0 								AS IsFromAI
        ,	0 								AS IsFromImperva
        ,	s.CreatedDate 					AS LastModifiedDate
        ,   CONST_INPUTFLOWID_POTENTIALPA	AS InputFlowID
    FROM  Temp_CustInfo AS tmp
		INNER JOIN CTS_DataCenter.Customer_InitialGroupBetting AS s ON s.CustID = tmp.CustID
	WHERE NOT EXISTS (SELECT 1 
					  FROM Temp_CustCategoryDuplicate AS cc 
					  WHERE cc.CustID = tmp.CustID 
						AND cc.InputFlowID IN (CONST_INPUTFLOWID_ROBOT, CONST_INPUTFLOWID_CATEGORY_PA, CONST_INPUTFLOWID_REASON_PA));
        
	/***********************Check Initial Smart****************************/
	INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, TVSReasonID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy, IsMarkedDirectly, IsFromTVS, IsFromTW, IsFromCTS, IsFromAI, IsFromImperva, LastModifiedDate, InputFlowID)
    SELECT tmp.CTSCustID					AS CTSCustID
		,	tmp.CustID						AS CustID
        ,	CONST_CATEID_INITIALSMART 		AS CategoryID
        , 	NULL 							AS TVSReasonID
        ,	tmp.RoleID 						AS RoleID
        ,	tmp.SubscriberID				AS SubscriberID
		,	tmp.IsLicensee					AS IsLicensee
        ,	NULL 							AS Remark
        ,	NULL 							AS CreatedBy
        ,	1 								AS IsMarkedDirectly
		,	0 								AS IsFromTVS
        ,	1 								AS IsFromTW
        ,   0 								AS IsFromCTS
        ,	0 								AS IsFromAI
        ,	0 								AS IsFromImperva
        ,	s.InsertedTime 					AS LastModifiedDate
        ,   CONST_INPUTFLOWID_POTENTIALPA	AS InputFlowID
    FROM  Temp_CustInfo AS tmp
		INNER JOIN CTS_DataCenter.Customer_InitialSmart AS s ON s.CustID = tmp.CustID
	WHERE NOT EXISTS (SELECT 1 
					  FROM Temp_CustCategoryDuplicate AS cc 
					  WHERE cc.CustID = tmp.CustID 
						AND cc.InputFlowID IN (CONST_INPUTFLOWID_ROBOT, CONST_INPUTFLOWID_CATEGORY_PA, CONST_INPUTFLOWID_REASON_PA));
                        
	/***********************Return****************************/ 
	SELECT cust.CTSCustID
		,	cust.CustID
		, 	cc.CategoryID
		, 	cc.TVSReasonID
		, 	cc.RoleID
		, 	cc.SubscriberID
		, 	cc.IsLicensee
		, 	cc.Remark
		, 	CASE WHEN cc.CreatedBy IS NULL THEN CONST_CREATEDBY_STARIXITID ELSE cc.CreatedBy END
		, 	cc.IsMarkedDirectly
		, 	cc.IsFromTVS
		, 	cc.IsFromTW
		, 	cc.IsFromCTS
		, 	cc.IsFromAI
		, 	cc.IsFromImperva
		, 	cc.LastModifiedDate
		, 	CASE WHEN cc.CategoryID IS NULL THEN CONST_INPUTFLOWID_NORMAL ELSE cc.InputFlowID END AS InputFlowID
	FROM Temp_CustInfo AS cust
		LEFT JOIN Temp_CustCategory AS cc ON cc.CustID = cust.CustID
	WHERE cc.CustID IS NOT NULL
		OR (cc.CategoryID IS NULL AND cust.RoleID = 1);
    
END$$

DELIMITER ;


