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
    DECLARE	CONST_CATEGORYID_ROBOTBETTING 		INT DEFAULT 63;
    DECLARE	CONST_CATEGORYID_GOODROBOTBETTING 	INT DEFAULT 166;
    DECLARE	CONST_CATEGORYID_BADROBOTBETTING 	INT DEFAULT 165;
    
    
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
		,	SRecommend 		INT UNSIGNED 
		,	MRecommend		INT UNSIGNED 
		,	Recommend 		INT UNSIGNED 
        , 	SubscriberID	INT 
        ,	IsLicensee		BIT
        ,	CategoryGroup   SMALLINT
     );
     
	DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;    
	CREATE TEMPORARY TABLE Temp_CustCategory (	  
			CTSCustID		BIGINT UNSIGNED
        ,   CustID			BIGINT UNSIGNED 
        
        ,	RoleID 			TINYINT 
		, 	SubscriberID	INT 
        ,	IsLicensee		BIT
        
        ,	CategoryGroup   SMALLINT
        ,   CategoryID		BIGINT UNSIGNED 
        ,	IsDirect		BIT
        ,	ReasonID 		INT
        ,	IsFromTVS 		BIT
        ,	IsFromTW 		BIT
        ,	IsFromPAM 		BIT
        
        
        ,	IsRobot 		BIT DEFAULT 0
		,	Turnover 		DECIMAL(20,4) 
		,	Winloss 		DECIMAL(20,4) 
		,	BetCount 		INT 
		,	ActiveDays 		TINYINT UNSIGNED 
        
		,	Remark			VARCHAR(500)
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
    
    INSERT INTO Temp_CustInfo(CTSCustID,CustID,SRecommend,MRecommend,Recommend,RoleID,SubscriberID,IsLicensee)
    SELECT 	cus.CTSCustID
		,	cus.CustID
        ,	cus.SRecommend
        ,	cus.MRecommend
        ,	cus.Recommend
        ,	cus.RoleID	 
		, 	cus.SubscriberID	 
        ,	cus.IsLicensee		
    FROM Temp_CustID AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
    
    /***********************Check Robot betting****************************/
    INSERT INTO Temp_CustCategory(CTSCustID, CustID, CategoryID,CategoryGroup, ReasonID ,IsDirect,IsRobot)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
		,	CONST_CATEGORYID_ROBOTBETTING AS CategoryID
        ,	CONST_CATEGORYID_ROBOTBETTING AS CategoryGroup
        ,	CONST_CATEGORYID_ROBOTBETTING AS ReasonID
        ,	1 AS IsDirect
        ,	1
    FROM  Temp_CustInfo AS tmp
    WHERE EXISTS (SELECT 1 FROM CTS_DataCenter.RobotDetection AS rb WHERE rb.CustID = tmp.CustID AND rb.IsDisabled = 0);
	
    INSERT INTO Temp_RobotCate(CustID, CategoryID,Turnover,Winloss,BetCount,ActiveDays)
    SELECT 	tmp.CustID
		,	CASE WHEN tbl.RobotType = CONST_ROBOTTYPE_OBSERVED THEN CONST_CATEGORYID_ROBOTBETTING
				WHEN tbl.RobotType = CONST_ROBOTTYPE_GOOD THEN CONST_CATEGORYID_GOODROBOTBETTING
                WHEN tbl.RobotType = CONST_ROBOTTYPE_BAD THEN CONST_CATEGORYID_BADROBOTBETTING
			END AS CategoryID
		,	tbl.Turnover 	
		,	tbl.Winloss 	
		,	tbl.BetCount 	
		,	tbl.ActiveDays 	
    FROM Temp_CustCategory AS tmp,
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
             
	UPDATE Temp_CustCategory AS tmp
    INNER JOIN Temp_RobotCate AS cate ON cate.CustID = tmp.CustID
    SET 	tmp.CategoryID = cate.CategoryID
		,	tmp.ReasonID = cate.CategoryID
        ,	tmp.Turnover = cate.Turnover 
		,	tmp.Winloss = cate.Winloss
		,	tmp.BetCount = 	cate.BetCount
		,	tmp.ActiveDays = cate.ActiveDays;
		
     /***********************Check PA from Old table****************************/
    INSERT INTO Temp_CustCategory(CTSCustID,CustID, CategoryID,CategoryGroup, IsDirect, ReasonID, Remark,IsFromTVS,IsFromTW,IsFromPAM)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	class.CategoryID
        ,	cate.CategoryGroup
		,	1 AS IsDirect
        ,	cate.ReasonID
        ,	class.Remark
        ,	class.IsFromTVS 		
        ,	class.IsFromTW 		
        ,	class.IsFromPAM 		
    FROM Temp_CustInfo AS tmp    
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationOldPA AS class ON class.CustID = tmp.CustID AND class.IsDirect = 1
        INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID AND cate.CategoryGroup != CONST_CATEGORYGROUP_ROBOT;
	
    /***********************Check affected PA from Upline****************************/
    INSERT INTO Temp_CustCategory(CTSCustID,CustID, CategoryID,CategoryGroup, IsDirect, ReasonID, Remark,IsFromTVS,IsFromTW,IsFromPAM)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	class.CategoryID
        ,	cate.CategoryGroup
		,	0 AS IsDirect
        ,	cate.ReasonID
        ,	class.Remark
        ,	class.IsFromTVS 		
        ,	class.IsFromTW 		
        ,	class.IsFromPAM 		
    FROM Temp_CustInfo AS tmp    
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS class ON class.CustID IN (tmp.SRecommend,tmp.MRecommend,tmp.Recommend) AND class.SportGroupID = CONST_GROUP_PA AND class.IsDirect = 1
        INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID AND cate.CategoryGroup != CONST_CATEGORYGROUP_ROBOT;
        
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
        ,	IsFromPAM 		
        
        ,	IsRobot 		
		,	Turnover 		
		,	Winloss 		
		,	BetCount 		
		,	ActiveDays 		
        
		,	Remark		
    FROM Temp_CustCategory;
END$$

DELIMITER ;

