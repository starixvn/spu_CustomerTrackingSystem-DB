/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsService,ctsAPI" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_BySport_Rescan_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_BySport_Rescan_Get`(
		IN ip_CustIDs	LONGTEXT
       ,IN ip_SportID   SMALLINT
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20251113@Winfred.pham
		Task :		Renovate PA Process by sport
		DB:			CTS_DataCenter 
		Original: 
		Revisions:  
			- 20251113@Winfred.pham: [CTS] - Customer Classification - Classify by sport Saba Soccer Group Betting into CC3101-3201  [Redmine ID: #239955]

        Param's Explanation:

		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_BySport_Rescan_Get("1,2,3,4");
	*/ 
    DECLARE	CONST_PARENTID_PA						INT;
    DECLARE CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL			INT DEFAULT 9;
	DECLARE	CONST_INPUTFLOWID_BYSPORT_CATEGORY_PA			INT DEFAULT 375;
      
	DECLARE CONST_CREATEDBY_STARIXITID				INT DEFAULT 10278938;
    DECLARE CONST_ROLEID_MEMBER					    SMALLINT DEFAULT 1;
    
    SET CONST_PARENTID_PA 							= CTS_DataCenter.CTS_DC_CategoryTypeParent_Get ('CONST_PARENTID_PA');
	SET CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL		= CTS_DataCenter.CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL');
	SET CONST_INPUTFLOWID_BYSPORT_CATEGORY_PA		= CTS_DataCenter.CTS_DC_CategoryTypeParent_Get ('CONST_INPUTFLOWID_BYSPORT_RESCAN_PACATEGORY');
        
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
     ); 
         
    DROP TEMPORARY TABLE IF EXISTS Temp_CustCategory;    
	CREATE TEMPORARY TABLE Temp_CustCategory (	  
			CTSCustID				BIGINT UNSIGNED
        ,   CustID					BIGINT UNSIGNED 
        ,	CategoryID              INT  
        ,	RoleID 					TINYINT 
		, 	SubscriberID			INT UNSIGNED
        ,	IsLicensee				BIT
		,	Remark				    VARCHAR(500)
        ,   CreatedBy               INT UNSIGNED
        ,   CreatedDate        		DATETIME(3)
        ,   LastModifiedDate        DATETIME(3)
		,	InputFlowID	 			INT
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
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.CustID 
			AND cus.CustSubID = 0 
			AND cus.IsInternal = 0;
    /***********************Check PA from main table ****************************/   
    INSERT IGNORE INTO Temp_CustCategory(CTSCustID, CustID, CategoryID, RoleID, SubscriberID, IsLicensee, Remark, CreatedBy,  CreatedDate, LastModifiedDate, InputFlowID)
    SELECT tmp.CTSCustID					        AS CTSCustID
		,	tmp.CustID						        AS CustID
        ,	CASE WHEN cate.IsPAProbation THEN cate.RelevantCategoryID ELSE s.CategoryID END AS CategoryID
        ,	tmp.RoleID 						        AS RoleID
        ,	tmp.SubscriberID				        AS SubscriberID
		,	tmp.IsLicensee					        AS IsLicensee
        ,	s.Remark						        AS Remark
        ,	NULL		 					        AS CreatedBy
        ,	s.CreatedDate 					        AS CreatedDate
        ,	s.LastModifiedDate 				        AS LastModifiedDate
        ,   CONST_INPUTFLOWID_BYSPORT_CATEGORY_PA	AS InputFlowID
    FROM Temp_CustInfo AS tmp    
		STRAIGHT_JOIN CTS_DataCenter.CTSCustomerClassification_BySport AS s USE INDEX (PRIMARY) ON s.CustID = tmp.CustID AND s.ParentID = CONST_PARENTID_PA AND s.sportID = ip_SportID
		INNER JOIN CTS_DataCenter.CustomerCategory AS cate ON cate.CategoryID = s.CategoryID
	ON DUPLICATE KEY UPDATE  Remark = CASE WHEN  s.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN s.Remark ELSE Temp_CustCategory.Remark END
						,	LastModifiedDate = CASE WHEN s.LastModifiedDate < Temp_CustCategory.LastModifiedDate THEN s.LastModifiedDate ELSE Temp_CustCategory.LastModifiedDate END
                        ,	CreatedDate = CASE WHEN s.CreatedDate < Temp_CustCategory.CreatedDate THEN s.CreatedDate ELSE Temp_CustCategory.CreatedDate END; 
	/***********************Return****************************/ 
	SELECT cust.CTSCustID
		,	cust.CustID
		, 	cc.CategoryID
        ,	cat.CategoryName
		, 	cc.RoleID
		, 	cc.SubscriberID
		, 	cc.IsLicensee
		, 	cc.Remark
		, 	CASE WHEN cc.CreatedBy IS NULL THEN CONST_CREATEDBY_STARIXITID ELSE cc.CreatedBy END AS CreatedBy
        ,	cc.CreatedDate
		, 	cc.LastModifiedDate
		, 	CASE WHEN cc.CategoryID IS NULL THEN CONST_INPUTFLOWID_BYSPORT_INSERT_NORMAL ELSE cc.InputFlowID END AS InputFlowID
        ,   ccs.SportType AS DWSportType
	FROM Temp_CustInfo AS cust
		LEFT JOIN Temp_CustCategory AS cc ON cc.CustID = cust.CustID
        LEFT JOIN CTS_DataCenter.CustomerCategory AS cat ON cc.CategoryID = cat.CategoryID
        LEFT JOIN CTS_DataCenter.CustomerCategorySettings AS ccs ON cc.CategoryID = ccs.CategoryID
	WHERE cc.CustID IS NOT NULL
		OR (cc.CategoryID IS NULL AND cust.RoleID = CONST_ROLEID_MEMBER);
    
END$$

DELIMITER ;


