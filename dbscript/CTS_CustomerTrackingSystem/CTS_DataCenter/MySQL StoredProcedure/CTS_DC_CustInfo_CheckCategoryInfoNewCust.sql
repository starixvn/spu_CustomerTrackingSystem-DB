/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_CheckCategoryInfoNewCust`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_CheckCategoryInfoNewCust`(
	OUT op_LastCTSCustID 	BIGINT UNSIGNED
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
            - 20220614@Aries.Nguyen: CTS - Classify Category for new Customer (all roles) is not Latest [Redmine ID: #174084]
            - 20220616@Aries.Nguyen: Cannot mark PA (affected by uplines) correctly with First Mark [Redmine ID: #174136]
            - 20220628@Aries.Nguyen: Update robot classification rule [Redmine ID: #174430]
			- 202208018@Long.Luu: Use IsDangerProbation in stead of IsPAProbation [Redmine ID: #174219]
		
        Param's Explanation:

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_CheckCategoryInfoNewCust(@op_LastCTSCustID);SELECT @op_LastCTSCustID;
	*/
    DECLARE lv_LastCTSCustID 	BIGINT UNSIGNED;
    DECLARE lv_BatchSize 		INT UNSIGNED;
    DECLARE lv_MaxCTSCustID 	BIGINT UNSIGNED;
     
	DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;
    CREATE TEMPORARY TABLE Temp_CustInfo(
			CTSCustID		BIGINT 	UNSIGNED PRIMARY KEY
        ,	CustID			BIGINT	UNSIGNED
        ,	CustSubID		INT	UNSIGNED
        ,	UserName		VARCHAR(50) 
        ,	RegisterName	VARCHAR(50) 
        ,	SubscriberID	INT UNSIGNED
        ,	RoleID			INT        
        ,	SRecommend		BIGINT	UNSIGNED
        ,	MRecommend		BIGINT	UNSIGNED
        ,	Recommend		BIGINT	UNSIGNED
        ,	DirectUpLine	BIGINT	UNSIGNED
		,	IsLicensee		BIT
        
        ,	CreatedBy		INT
        ,	INDEX PK_Temp_CustInfo_CustID(CustID)
        ,	INDEX IX_Temp_CustInfo_DirectUpLine(DirectUpLine)
    );
	
    DROP TEMPORARY TABLE IF EXISTS Temp_VVIPCust;
    CREATE TEMPORARY TABLE Temp_VVIPCust(
			CTSCustID		BIGINT UNSIGNED  PRIMARY KEY 
		,	CustID			BIGINT	UNSIGNED
		,	CreatedBy		INT
        ,	INDEX PK_Temp_VVIPCust_CustID(CustID)
    ); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_VVIPCust_Depth;
    CREATE TEMPORARY TABLE Temp_VVIPCust_Depth(
			CTSCustID		BIGINT UNSIGNED  PRIMARY KEY 
		,	CustID			BIGINT UNSIGNED
		,	CreatedBy		INT
    ); 
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;    
	CREATE TEMPORARY TABLE Temp_CustCategory (	  
			CTSCustID		    BIGINT UNSIGNED 
        ,   CustID			    BIGINT UNSIGNED 
        ,   CategoryID		    INT
        ,   CategoryIDSource	INT  
        ,   CategoryGroup	    INT
		,   Remark			    VARCHAR(500)
		,	IsFromTVS		    BIT
        ,	IsFromTW		    BIT
        ,	IsFromCTS		    BIT
        ,	CreatedBy		    INT
		,	LastModifiedDate	DATETIME
        ,	PRIMARY KEY(CustID,CategoryIDSource)
	);
    
    
    
    SELECT ParameterValue 
    INTO lv_LastCTSCustID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 92;
    
    SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 93; 

    INSERT INTO Temp_CustInfo(CTSCustID, CustID, CustSubID, UserName, RegisterName, SubscriberID, RoleID, SRecommend, MRecommend, Recommend, DirectUpLine,IsLicensee)
    SELECT 	cus.CTSCustID
		,	cus.CustID
        ,	cus.CustSubID
        ,	cus.UserName
        ,	cus.RegisterName
        ,	cus.SubscriberID
        ,	cus.RoleID
        ,	cus.SRecommend
        ,	cus.MRecommend
        ,	cus.Recommend
        ,	(CASE WHEN cus.RoleID = 1 THEN cus.Recommend 
				WHEN cus.RoleID = 2 THEN cus.MRecommend
                WHEN cus.RoleID = 3 THEN cus.SRecommend END) AS DirectUpLine   
		,	cus.IsLicensee
    FROM CTS_DataCenter.CTSCustomer AS cus 
    WHERE cus.CustSubID = 0
        AND cus.IsInternal = 0
        AND cus.CTSCustID > lv_LastCTSCustID
	LIMIT lv_BatchSize;
    
    SELECT MAX(CTSCustID)
    INTO op_LastCTSCustID
    FROM Temp_CustInfo;
    
    IF op_LastCTSCustID IS NULL THEN
		SET op_LastCTSCustID = lv_LastCTSCustID;
    END IF;
    
    INSERT IGNORE INTO Temp_VVIPCust(CTSCustID,CustID,CreatedBy)
    SELECT  tmp.CTSCustID
		,	tmp.CustID
		,	vip.CreatedBy
    FROM Temp_CustInfo AS tmp		
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationVVIP AS vip ON vip.CustID = tmp.DirectUpLine AND vip.IsAffectToDownline = 1;
    
    INSERT IGNORE INTO Temp_VVIPCust(CTSCustID,CustID,CreatedBy)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
		,	que.CreatedBy
    FROM Temp_CustInfo AS tmp		
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationQueue AS que ON que.CustID IN (tmp.SRecommend, tmp.MRecommend, tmp.Recommend) AND que.ActionType = 1;
	
    INSERT IGNORE INTO Temp_VVIPCust_Depth(CTSCustID,CreatedBy)
	SELECT 	tmp.CTSCustID
		,	vv.CreatedBy
    FROM Temp_CustInfo AS tmp		
		INNER JOIN Temp_VVIPCust AS vv ON vv.CustID IN (tmp.SRecommend, tmp.MRecommend, tmp.Recommend);
        
	INSERT IGNORE INTO Temp_VVIPCust(CTSCustID,CustID,CreatedBy)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
		,	tmp.CreatedBy
    FROM Temp_VVIPCust_Depth AS tmp;
    
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID,CategoryIDSource,CategoryGroup, Remark, CreatedBy,IsFromTVS,IsFromTW,IsFromCTS,LastModifiedDate)
    SELECT 	tmp.CTSCustID
		,	tmp.CustID
        ,	class.CategoryID
        ,	CASE WHEN class.CategoryID IN (62,82,102,122,142,162) THEN 62
				 WHEN cate.IsDangerProbation = 1 THEN cate.RelevantCategoryID
				 ELSE class.CategoryID END AS CategoryIDSource
        ,	cate.CategoryGroup 
        ,	class.Remark 
        ,	class.CreatedBy
        ,	class.IsFromTVS
        ,	class.IsFromTW
        ,	class.IsFromCTS
        ,	class.LastModifiedDate
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification AS class USE INDEX (PRIMARY) ON class.CustID IN (tmp.SRecommend,tmp.MRecommend,tmp.Recommend) AND class.SportGroupID = 0 
        STRAIGHT_JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = class.CategoryID AND cate.CategoryGroup != 163;
	 
    SELECT	tmp.CTSCustID
		,	tmp.CustID          
        ,	tmp.CustSubID  
        ,	tmp.UserName  
        ,	tmp.RegisterName  
		,	tmp.RoleID  
		,	tmp.SubscriberID  
		,	vip.CreatedBy          
	FROM Temp_CustInfo AS tmp
		INNER JOIN Temp_VVIPCust AS vip ON tmp.CTSCustID = vip.CTSCustID;

     
    SELECT 	cate.CTSCustID		
        ,   cate.CustID	
		,  	tmp.RoleID
        ,  	tmp.SubscriberID
        ,  	tmp.IsLicensee
         
        ,   cate.CategoryID		
		,	cate.CategoryGroup
		,   cate.Remark		
        ,	cate.CreatedBy
        ,	cate.IsFromTVS
        ,	cate.IsFromTW
        ,	cate.IsFromCTS
        ,	 cate.LastModifiedDate
    FROM Temp_CustCategory AS cate
		LEFT JOIN Temp_CustInfo AS tmp ON tmp.CustID = cate.CustID
	WHERE NOT EXISTS (SELECT 1 FROM Temp_VVIPCust AS vv WHERE cate.CTSCustID = vv.CTSCustID); 
    
    SELECT 	tmp.CTSCustID		
        ,   tmp.CustID	 
    FROM Temp_CustInfo AS tmp
    WHERE NOT EXISTS (SELECT 1 FROM Temp_VVIPCust AS vv WHERE tmp.CTSCustID = vv.CTSCustID)
		AND NOT EXISTS (SELECT 1 FROM Temp_CustCategory AS cate WHERE cate.CustID = tmp.CustID);
	
END$$
DELIMITER ;