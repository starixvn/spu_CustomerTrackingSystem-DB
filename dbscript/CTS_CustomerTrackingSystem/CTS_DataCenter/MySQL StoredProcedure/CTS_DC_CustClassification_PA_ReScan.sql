/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsService,ctsAPI" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_PA_ReScan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_PA_ReScan`(
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
		
        Param's Explanation:

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_ReScan("1,2,3,4");
	*/ 
    DECLARE	CONST_CATEGORYID_ROBOT 			INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_ROBOTLOSING 	INT DEFAULT 164;
    
    DECLARE	CONST_GROUP_PA 					INT DEFAULT 0;

    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustID;    
	CREATE TEMPORARY TABLE Temp_CustID (	  
			CustID              BIGINT UNSIGNED PRIMARY KEY 
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
			CTSCustID			BIGINT UNSIGNED
        ,   CustID				BIGINT UNSIGNED 
        
        ,	RoleID 				TINYINT 
		, 	SubscriberID		INT 
        ,	IsLicensee			BIT
        ,	IsLicenseeVIP		BIT
        
        ,	CategoryGroup   	SMALLINT
        ,   CategoryID			INT
        ,   CategoryIDSource	INT 
        ,	IsDirect			BIT
		
        ,	IsFromTVS 			BIT DEFAULT 0
        ,	IsFromTW 			BIT DEFAULT 0
        ,	IsFromCTS 			BIT DEFAULT 0
        ,	IsFromAI 			BIT DEFAULT 0
		,	IsFromImperva		BIT DEFAULT 0
		
        ,	TVSRequestID 		BIGINT UNSIGNED 
        ,	IsRobot 			BIT DEFAULT 0
        
        ,	LastModifiedDate	DATETIME
		,	Remark				VARCHAR(500)
		,	PRIMARY KEY(CustID,CategoryIDSource)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCateDate;    
	CREATE TEMPORARY TABLE Temp_CustCateDate (	  
			CustID				BIGINT UNSIGNED 
        ,	CategoryIDSource   	SMALLINT
        
        ,	Remark				VARCHAR(500)
        ,	LastModifiedDate	DATETIME
		,	PRIMARY KEY(CustID,CategoryIDSource)
	);
    
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_CustID (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;    
     
    INSERT  INTO Temp_CustInfo(CTSCustID,CustID,SRecommend,MRecommend,Recommend,RoleID,SubscriberID,IsLicensee,IsLicenseeVIP)
    SELECT 	cus.CTSCustID
		,	cus.CustID
        ,	CASE WHEN cus.SRecommend = 0 THEN -1 ELSE cus.SRecommend END AS SRecommend
        ,	CASE WHEN cus.MRecommend = 0 THEN -1 ELSE cus.MRecommend END AS MRecommend
        ,	CASE WHEN cus.Recommend = 0 THEN -1 ELSE cus.Recommend END AS Recommend
        ,	cus.RoleID	 
		, 	cus.SubscriberID	 
        ,	cus.IsLicensee	
        ,	cus.IsLicenseeVIP
    FROM Temp_CustID AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
    
	/***********************Check Robot Imperva****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID,RoleID,SubscriberID,IsLicensee,IsLicenseeVIP,CategoryID,CategoryIDSource, CategoryGroup,IsFromImperva,IsDirect,IsRobot,Remark,LastModifiedDate)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID 
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	tmp.IsLicenseeVIP
		,	CONST_CATEGORYID_ROBOT AS CategoryID
        ,	CONST_CATEGORYID_ROBOT AS CategoryIDSource
        ,	CONST_CATEGORYID_ROBOT AS CategoryGroup
        ,	1 AS IsFromImperva
        ,	1 AS IsDirect
        ,	1 AS IsRobot
		,	'Imperva' AS Remark
        ,	ri.CreateTime
    FROM  Temp_CustInfo AS tmp,
    LATERAL (SELECT CreateTime
			FROM CTS_DataCenter.RobotImperva
            WHERE CustID = tmp.CustID 
				AND IsScanned = 1
			ORDER BY CreateTime DESC
			LIMIT 1) AS ri;
	
    /***********************Check Robot betting****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID,RoleID,SubscriberID,IsLicensee,IsLicenseeVIP,CategoryID,CategoryIDSource, CategoryGroup,IsFromAI,IsDirect,IsRobot,Remark,LastModifiedDate)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID 
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	tmp.IsLicenseeVIP
		,	CONST_CATEGORYID_ROBOT AS CategoryID
        ,	CONST_CATEGORYID_ROBOT AS CategoryIDSource
        ,	CONST_CATEGORYID_ROBOT AS CategoryGroup
        ,	1 AS IsFromAI
        ,	1 AS IsDirect
        ,	1 AS IsRobot
        ,	NULL AS Remark
        ,	rd.LastModifiedDate
    FROM  Temp_CustInfo AS tmp,
    LATERAL (SELECT LastModifiedDate
			FROM CTS_DataCenter.RobotDetection 
            WHERE CustID = tmp.CustID
				AND  IsDisabled = 0
			ORDER BY LastModifiedDate DESC
			LIMIT 1) AS rd
	ON DUPLICATE KEY UPDATE IsFromAI = 1
						,	Remark = CASE WHEN rd.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN NULL ELSE Temp_CustCategory.Remark END
						,	LastModifiedDate = CASE WHEN rd.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN rd.LastModifiedDate ELSE Temp_CustCategory.LastModifiedDate END;
	
     /***********************Check PA from Old table****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID,CustID,RoleID,SubscriberID,IsLicensee,IsLicenseeVIP,CategoryID,CategoryIDSource,CategoryGroup, IsDirect, Remark,IsFromTVS,IsFromTW,IsFromCTS,LastModifiedDate,TVSRequestID,IsRobot)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	tmp.IsLicenseeVIP
        ,	class.CategoryID
        ,	CASE WHEN class.CategoryID IN (62,82,102,122,142,162) THEN 62
				 WHEN cate.IsPAProbation = 1 THEN cate.RelevantCategoryID
				 ELSE class.CategoryID END AS CategoryIDSource
        ,	cate.CategoryGroup
		,	class.IsDirect
        ,	class.Remark
        ,	class.IsFromTVS 		
        ,	class.IsFromTW 		
        ,	class.IsFromCTS 
		,	class.LastModifiedDate
        ,	class.TVSRequestID
        ,	CASE WHEN class.CategoryID IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING) THEN 1 ELSE 0 END AS IsRobot
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassificationOldCategory AS class USE INDEX (PRIMARY) ON class.CustID = tmp.CustID AND class.SportGroupID = CONST_GROUP_PA
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID 
														  AND (cate.CategoryGroup NOT IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING)
															 OR (cate.CategoryGroup IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING) AND (class.IsFromCTS = 1 OR class.IsFromTVS = 1)))
	ON DUPLICATE KEY UPDATE  IsFromCTS = 1
                        ,	 Remark = class.Remark;	
    
    INSERT IGNORE INTO Temp_CustCateDate(CustID,CategoryIDSource,Remark,LastModifiedDate)
    SELECT 	tmp.CustID
		,	tmp.CategoryIDSource
        ,	tmp.Remark
        ,	tmp.LastModifiedDate
    FROM Temp_CustCategory AS tmp
    WHERE tmp.IsDirect = 0;
    
    DELETE 
    FROM Temp_CustCategory AS tmp
    WHERE IsDirect = 0;
	
	
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID,CustID,RoleID,SubscriberID,IsLicensee,IsLicenseeVIP,CategoryID,CategoryIDSource,CategoryGroup, IsDirect, Remark,IsFromTVS,IsFromTW,IsFromCTS,LastModifiedDate,TVSRequestID,IsRobot)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	tmp.IsLicenseeVIP
        ,	class.CategoryID
        ,	CASE WHEN class.CategoryID IN (62,82,102,122,142,162) THEN 62
				 WHEN cate.IsPAProbation = 1 THEN cate.RelevantCategoryID
				 ELSE class.CategoryID END AS CategoryIDSource
        ,	cate.CategoryGroup
		,	1 AS IsDirect
        ,	class.Remark
        ,	class.IsFromTVS 		
        ,	class.IsFromTW 		 
        ,	class.IsFromCTS 	
        ,	class.LastModifiedDate
		,	class.TVSRequestID
        ,	CASE WHEN class.CategoryID IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING) THEN 1 ELSE 0 END AS IsRobot
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification AS class USE INDEX (PRIMARY) ON class.CustID = tmp.CustID AND class.SportGroupID = CONST_GROUP_PA AND class.IsDirect = 1
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID 
															AND (cate.CategoryGroup NOT IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING)
															 OR (cate.CategoryGroup  IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING) AND (class.IsFromCTS = 1 OR class.IsFromTVS = 1)))
	ON DUPLICATE KEY UPDATE  IsFromCTS = 1
                        ,	 Remark = class.Remark;	
	 
    /***********************Check affected PA from Upline****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID,CustID,RoleID,SubscriberID,IsLicensee,IsLicenseeVIP,CategoryID,CategoryIDSource,CategoryGroup, IsDirect, Remark,IsFromTVS,IsFromTW,IsFromCTS,LastModifiedDate,TVSRequestID)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	tmp.IsLicenseeVIP
        ,	class.CategoryID
		,	CASE WHEN class.CategoryID IN (62,82,102,122,142,162) THEN 62
				 WHEN cate.IsPAProbation = 1 THEN cate.RelevantCategoryID
				 ELSE class.CategoryID END AS CategoryIDSource
        ,	cate.CategoryGroup
		,	0 AS IsDirect
        ,	class.Remark
        ,	class.IsFromTVS 		
        ,	class.IsFromTW 		
        ,	class.IsFromCTS 	
        ,	class.LastModifiedDate
        ,	class.TVSRequestID
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassificationOldCategory AS class USE INDEX (PRIMARY)  ON class.CustID IN (tmp.SRecommend,tmp.MRecommend,tmp.Recommend) AND class.SportGroupID = CONST_GROUP_PA AND class.IsDirect = 1
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID AND cate.CategoryGroup NOT IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING)
	WHERE NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomerClassificationVVIP AS vv WHERE vv.CustID = class.CustID)
    ON DUPLICATE KEY UPDATE  Remark = CASE WHEN  class.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN class.Remark
										   ELSE Temp_CustCategory.Remark END
						,	LastModifiedDate = CASE WHEN class.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN class.LastModifiedDate
													ELSE Temp_CustCategory.LastModifiedDate END;
    
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID,CustID,RoleID,SubscriberID,IsLicensee,IsLicenseeVIP,CategoryID,CategoryIDSource,CategoryGroup, IsDirect, Remark,IsFromTVS,IsFromTW,IsFromCTS,LastModifiedDate,TVSRequestID)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	tmp.IsLicenseeVIP
        ,	class.CategoryID
		,	CASE WHEN class.CategoryID IN (62,82,102,122,142,162) THEN 62
				 WHEN cate.IsPAProbation = 1 THEN cate.RelevantCategoryID
				 ELSE class.CategoryID END AS CategoryIDSource
        ,	cate.CategoryGroup
		,	0 AS IsDirect
        ,	class.Remark
        ,	class.IsFromTVS 		
        ,	class.IsFromTW 		
        ,	class.IsFromCTS 	
        ,	class.LastModifiedDate
        ,	class.TVSRequestID
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification AS class USE INDEX (PRIMARY) ON class.CustID IN (tmp.SRecommend,tmp.MRecommend,tmp.Recommend) AND class.SportGroupID = CONST_GROUP_PA AND class.IsDirect = 1
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID AND cate.CategoryGroup NOT IN (CONST_CATEGORYID_ROBOT, CONST_CATEGORYID_ROBOTLOSING)
	ON DUPLICATE KEY UPDATE  Remark = CASE WHEN  class.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN class.Remark
										   ELSE Temp_CustCategory.Remark END
						,	LastModifiedDate = CASE WHEN class.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN class.LastModifiedDate
													ELSE Temp_CustCategory.LastModifiedDate END;
	
    UPDATE Temp_CustCategory AS cate
    INNER JOIN Temp_CustCateDate AS tmp ON cate.CustID = tmp.CustID AND cate.CategoryIDSource = tmp.CategoryIDSource
    SET 	cate.LastModifiedDate = tmp.LastModifiedDate
		,	cate.Remark = tmp.Remark;
    
	SELECT 	CTSCustID
		,	CustID
		,	RoleID 			 
		, 	SubscriberID	 
        ,	IsLicensee		
        ,	IsLicenseeVIP
        
		, 	CategoryID
        ,	CategoryGroup
        , 	IsDirect
		,	IsFromTVS 		
        ,	IsFromTW 		
        ,	IsFromCTS 	
        ,	IsFromAI	
		,	IsFromImperva
        ,	TVSRequestID
        
        ,	IsRobot 			
        
        ,  	LastModifiedDate
		,	Remark		
    FROM Temp_CustCategory;
 
END$$

DELIMITER ;

