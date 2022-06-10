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
			- 20220520@Aries.Nguyen: Created [Redmine ID: #172561]
		
        Param's Explanation:

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_PA_ReScan("1,2,3,4");
	*/
    DECLARE	CONST_CATEGORYID_ROBOT 		INT DEFAULT 61;
    DECLARE	CONST_CATEGORYID_BADROBOT 	INT DEFAULT 163;
    DECLARE	CONST_CATEGORYID_GOODROBOT 	INT DEFAULT 164;
    

    DECLARE CONST_ROBOTTYPE_OBSERVED 	TINYINT UNSIGNED DEFAULT 0;
    DECLARE CONST_ROBOTTYPE_GOOD 		TINYINT UNSIGNED DEFAULT 1;
    DECLARE CONST_ROBOTTYPE_BAD 		TINYINT UNSIGNED DEFAULT 2;
    
    DECLARE	CONST_GROUP_PA 						INT DEFAULT 0;
	DECLARE	CONST_CATEGORYGROUP_ROBOT 			INT DEFAULT 61;
    
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
        ,	CategoryGroup   SMALLINT
     ); 
     
	DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;    
	CREATE TEMPORARY TABLE Temp_CustCategory (	  
			CTSCustID			BIGINT UNSIGNED
        ,   CustID				BIGINT UNSIGNED 
        
        ,	RoleID 				TINYINT 
		, 	SubscriberID		INT 
        ,	IsLicensee			BIT
        
        ,	CategoryGroup   	SMALLINT
        ,   CategoryID			BIGINT UNSIGNED 
        ,	IsDirect			BIT
        ,	IsFromTVS 			BIT DEFAULT 0
        ,	IsFromTW 			BIT DEFAULT 0
        ,	IsFromCTS 			BIT DEFAULT 0
        ,	IsFromAI 			BIT DEFAULT 0
        ,	TVSRequestID 		BIGINT UNSIGNED 
        
        
        ,	IsRobot 			BIT DEFAULT 0
		,	Turnover 			DECIMAL(20,4) 
		,	Winloss 			DECIMAL(20,4) 
		,	BetCount 			INT 
		,	ActiveDays 			TINYINT UNSIGNED 
        
        ,	LastModifiedDate	DATETIME
		,	Remark				VARCHAR(500)
		,	PRIMARY KEY(CustID,CategoryID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Robot;    
	CREATE TEMPORARY TABLE Temp_Robot (	  
			CustID			BIGINT UNSIGNED  PRIMARY KEY 
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_RobotCate;    
	CREATE TEMPORARY TABLE Temp_RobotCate (	  
			CustID			BIGINT UNSIGNED 
		, 	CategoryID		BIGINT UNSIGNED 
		,	Turnover 		DECIMAL(20,4) 
		,	Winloss 		DECIMAL(20,4) 
		,	BetCount 		INT 
		,	ActiveDays 		TINYINT UNSIGNED 
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
    
    /***********************Check Robot betting****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID,RoleID,SubscriberID,IsLicensee ,CategoryID,CategoryGroup,IsFromAI,IsDirect,IsRobot)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID 
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
		,	CONST_CATEGORYID_ROBOT AS CategoryID
        ,	CONST_CATEGORYID_ROBOT AS CategoryGroup
        ,	1 AS IsFromAI
        ,	1 AS IsDirect
        ,	1 AS IsRobot
    FROM  Temp_CustInfo AS tmp
    WHERE EXISTS (SELECT 1 FROM CTS_DataCenter.RobotDetection AS rb WHERE rb.CustID = tmp.CustID AND rb.IsDisabled = 0);

		
     /***********************Check PA from Old table****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID,CustID,RoleID,SubscriberID,IsLicensee,CategoryID,CategoryGroup, IsDirect, Remark,IsFromTVS,IsFromTW,IsFromCTS,LastModifiedDate,TVSRequestID,IsRobot)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	class.CategoryID
        ,	cate.CategoryGroup
		,	1 AS IsDirect
        ,	class.Remark
        ,	class.IsFromTVS 		
        ,	class.IsFromTW 		
        ,	class.IsFromCTS 
		,	class.LastModifiedDate
        ,	class.TVSRequestID
        ,	CASE WHEN class.CategoryID = CONST_CATEGORYGROUP_ROBOT THEN 1 ELSE 0 END AS IsRobot
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassificationOldPA AS class USE INDEX (PRIMARY) ON class.CustID = tmp.CustID AND class.IsDirect = 1
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID 
														  AND (cate.CategoryGroup NOT IN (CONST_CATEGORYGROUP_ROBOT,CONST_CATEGORYID_BADROBOT, CONST_CATEGORYID_GOODROBOT)
															 OR (cate.CategoryGroup IN (CONST_CATEGORYGROUP_ROBOT,CONST_CATEGORYID_BADROBOT, CONST_CATEGORYID_GOODROBOT) AND (class.IsFromCTS = 1 OR class.IsFromTVS = 1)))
	ON DUPLICATE KEY UPDATE  IsFromCTS = 1
                        ,	 Remark = class.Remark;	
	
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID,CustID,RoleID,SubscriberID,IsLicensee,CategoryID,CategoryGroup, IsDirect, Remark,IsFromTVS,IsFromTW,IsFromCTS,LastModifiedDate,TVSRequestID,IsRobot)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	class.CategoryID
        ,	cate.CategoryGroup
		,	1 AS IsDirect
        ,	class.Remark
        ,	class.IsFromTVS 		
        ,	class.IsFromTW 		 
        ,	class.IsFromCTS 	
        ,	class.LastModifiedDate
		,	class.TVSRequestID
        ,	CASE WHEN class.CategoryID = CONST_CATEGORYGROUP_ROBOT THEN 1 ELSE 0 END AS IsRobot
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification AS class USE INDEX (PRIMARY) ON class.CustID = tmp.CustID AND class.IsDirect = 1
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID 
															AND (cate.CategoryGroup NOT IN (CONST_CATEGORYGROUP_ROBOT,CONST_CATEGORYID_BADROBOT, CONST_CATEGORYID_GOODROBOT)
															 OR (cate.CategoryGroup  IN (CONST_CATEGORYGROUP_ROBOT,CONST_CATEGORYID_BADROBOT, CONST_CATEGORYID_GOODROBOT) AND (class.IsFromCTS = 1 OR class.IsFromTVS = 1)))
	ON DUPLICATE KEY UPDATE  IsFromCTS = 1
                        ,	 Remark = class.Remark;	
	 
    /***********************Check affected PA from Upline****************************/
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID,CustID,RoleID,SubscriberID,IsLicensee, CategoryID,CategoryGroup, IsDirect, Remark,IsFromTVS,IsFromTW,IsFromCTS,LastModifiedDate,TVSRequestID)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	class.CategoryID
        ,	cate.CategoryGroup
		,	0 AS IsDirect
        ,	class.Remark
        ,	class.IsFromTVS 		
        ,	class.IsFromTW 		
        ,	class.IsFromCTS 	
        ,	class.LastModifiedDate
        ,	class.TVSRequestID
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassificationOldPA AS class USE INDEX (PRIMARY)  ON class.CustID IN (tmp.SRecommend,tmp.MRecommend,tmp.Recommend) AND class.SportGroupID = CONST_GROUP_PA AND class.IsDirect = 1
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID AND cate.CategoryGroup NOT IN (CONST_CATEGORYGROUP_ROBOT,CONST_CATEGORYID_BADROBOT, CONST_CATEGORYID_GOODROBOT)
	WHERE NOT EXISTS (SELECT 1 FROM CTS_DataCenter.CTSCustomerClassificationVVIP AS vv WHERE vv.CustID = class.CustID);
    
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID,CustID,RoleID,SubscriberID,IsLicensee, CategoryID,CategoryGroup, IsDirect, Remark,IsFromTVS,IsFromTW,IsFromCTS,LastModifiedDate,TVSRequestID)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	tmp.RoleID
        ,	tmp.SubscriberID
		,	tmp.IsLicensee
        ,	class.CategoryID
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
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID AND cate.CategoryGroup NOT IN (CONST_CATEGORYGROUP_ROBOT,CONST_CATEGORYID_BADROBOT, CONST_CATEGORYID_GOODROBOT);
        
	SELECT 	CTSCustID
		,	CustID
		,	RoleID 			 
		, 	SubscriberID	 
        ,	IsLicensee		
        
		, 	CategoryID
        ,	CategoryGroup
        , 	IsDirect
		,	IsFromTVS 		
        ,	IsFromTW 		
        ,	IsFromCTS 	
        ,	IsFromAI	
        ,	TVSRequestID
        
        ,	IsRobot 		
		,	Turnover 		
		,	Winloss 		
		,	BetCount 		
		,	ActiveDays 		
        
        ,  	LastModifiedDate
		,	Remark		
    FROM Temp_CustCategory;
END$$

DELIMITER ;

