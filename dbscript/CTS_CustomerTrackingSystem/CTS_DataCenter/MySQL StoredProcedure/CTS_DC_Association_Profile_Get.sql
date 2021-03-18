/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_Profile_Get_IPTest`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_Profile_Get_IPTest`(
		IN ip_CTSCustID 		BIGINT UNSIGNED
	,	IN ip_AssociationType	INT
	,	IN ip_AssociationStatus INT 
    ,	IN ip_AccountStatusIDs	VARCHAR(100)
	, 	IN ip_SiteIDs 			TEXT
    ,	IN ip_CategoryIDs		TEXT
    ,	IN ip_Skip 				INT
    ,	IN ip_Take 				INT
    
    ,	OUT op_TotalItems		INT
)
    SQL SECURITY INVOKER
sp : BEGIN
	/*
		Created:	20210202@Aries.Nguyen
		Task:		Get association account 
		DB:			CTS_DataCenter
        
		Revisions:
			- 20210202@Aries.Nguyen: Created [Redmine ID: #148908]
            - 20210221@Aries.Nguyen: Fix get wrong first association date by device [Redmine ID: #150223]
            - 20210316@Casey.Huynh: Get Customer Category Info [Redmine ID: #150457]
            - 20210317@Casey.Huynh: Count AssociationByIP to lv_TotalAccounts [Redmine ID: #131662]
            
		Param's Explanation (filtered by):
			- ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual, 4 - IP
            - ip_AssociationStatus: 0 - All, 1 - Linked, 2 - UnLinked
            - ip_AccountStatusIds: 1,11,2,3,4,12,13,14 - All,    1,11 - Open(1:Open, 11:Active),  2,3,4,12,13,14 - Closed (2:Disabled, 3:Closed, 4:Suspended, 12:Inactive, 13:View Only, 14:Suspended)
            - ip_CategoryIDs: 0, 51,205,206,...-Selected CategoryIDs (0-'No Category' Option)
        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_Profile_Get(33,0,0,'1,11,2,3,4,12,13,14',' 1,13','0,56,61,154,156,153,202,153,51,211,222,153,231',0,100, @a);
	*/
	DECLARE lv_CustID INT;
    DECLARE	lv_NoCategoryFilter BOOLEAN;
    
    IF ip_SiteIDs IS NULL OR ip_SiteIDs = '' OR ip_AccountStatusIDs IS NULL OR ip_AccountStatusIDs = '' THEN
		LEAVE sp;
    END IF;
    

    DROP TEMPORARY TABLE IF EXISTS Temp_Accounts;
    CREATE TEMPORARY TABLE 		Temp_Accounts (
			CustID 				BIGINT UNSIGNED
		,	CTSCustID			BIGINT UNSIGNED
        ,	CustSubId			INT UNSIGNED
		,	SiteID				INT UNSIGNED
        ,	SiteName			VARCHAR(50)
        ,	SubscriberID 		INT UNSIGNED
        ,	SubscriberName		VARCHAR(50)
        ,	Username			VARCHAR(50)
        ,	Username2			VARCHAR(50)
        ,	AssociationType 	INT
        , 	AssociationStatus	INT
        ,	AssociationTypeName	VARCHAR(50)
        ,	AssociationDate		DATETIME
		,	SharedDevices		INT DEFAULT 0
        ,	SharedIPs			INT DEFAULT 0
        ,	StatusId			INT
		,	StatusName			VARCHAR(20)
        ,	CustStatusID		INT
        ,	ParentIDs			VARCHAR(1000)
        ,	CategoryIDs			VARCHAR(1000)
		,	CategoryNames		VARCHAR(5000)
		,	CustomerClasses		VARCHAR(1000)
        , 	PRIMARY KEY(CTSCustID)
        ,	INDEX IX_Temp_Accounts_SiteID(SiteID)
        ,	INDEX IX_Temp_Accounts_CustStatusID(CustStatusID)
	);   
	
    DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociation;
    CREATE TEMPORARY TABLE 		Temp_CustAssociation (
			CTSCustID_Aff 		BIGINT UNSIGNED
        , 	AssociationType		INT
		, 	AssociationStatus	INT
        ,	AssociationDate		DATETIME
        , 	PRIMARY KEY (CTSCustID_Aff,AssociationType, AssociationStatus)
	);  
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustAssociationUnlinked;
    CREATE TEMPORARY TABLE 		Temp_CustAssociationUnlinked (
			CTSCustID_Aff 		BIGINT UNSIGNED
        , 	AssociationType		INT
        , 	AssociationStatus	INT
        ,	AssociationDate		DaTETIME
        , 	PRIMARY KEY (CTSCustID_Aff,AssociationType, AssociationStatus)
	);  
	
    DROP TEMPORARY TABLE IF EXISTS Temp_SiteID;
    CREATE TEMPORARY TABLE 		Temp_SiteID (
			SiteID 		INT UNSIGNED
        , 	PRIMARY KEY  (SiteID)
	);   
    
	DROP TEMPORARY TABLE IF EXISTS Temp_AccountStatusID;
    CREATE TEMPORARY TABLE 		Temp_AccountStatusID (
			AccountStatusID 		INT UNSIGNED
        , 	PRIMARY KEY  (AccountStatusID)
	);
	
	DROP TEMPORARY TABLE IF EXISTS Temp_Category;
    CREATE TEMPORARY TABLE 	Temp_Category (
			CategoryID 		SMALLINT UNSIGNED
		,	ParentID		SMALLINT UNSIGNED
		,	CategoryName	VARCHAR(50)
		,	CustomerClass	SMALLINT UNSIGNED
        , 	PRIMARY KEY  (CategoryID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustomerCategory;
    CREATE TEMPORARY TABLE 	Temp_CustomerCategory (
			CustID 			BIGINT UNSIGNED
		,	ParentID		SMALLINT UNSIGNED
		,	CategoryIDs		VARCHAR(1000)
		,	CategoryNames	VARCHAR(5000)
		,	CustomerClasses	VARCHAR(1000)
        , 	PRIMARY KEY  (CustID)
	);
    
	SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_SiteID (SiteID) VALUES ('", REPLACE(ip_SiteIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1; 
    
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_AccountStatusID (AccountStatusID) VALUES ('", REPLACE(ip_AccountStatusIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
    /*Customer Category:*/
    SET @sql = 	CONCAT("INSERT IGNORE INTO Temp_Category (CategoryID) VALUES ('", REPLACE(ip_CategoryIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;
    
    SET lv_NoCategoryFilter = (SELECT 1 FROM Temp_Category WHERE CategoryID = 0);
    
    DELETE	tmpCat
    FROM 	Temp_Category AS tmpCat
    WHERE 	tmpCat.CategoryID = -1;
    
    UPDATE Temp_Category AS tmpCat
		INNER JOIN CTS_DataCenter.CustomerCategory AS cc ON tmpCat.CategoryID = cc.CategoryID
		LEFT JOIN CTS_DataCenter.CategoryToCustomerClass AS ctc ON tmpCat.CategoryID = ctc.CategoryID
    SET tmpCat.CustomerClass = ctc.CustomerClass
		, tmpCat.CategoryName = cc.CategoryName
        , tmpCat.ParentID = cc.ParentID;
        
    /*<Customer Category Rule/>*/    
    SELECT CustID 
    INTO lv_CustID
    FROM CTS_DataCenter.CTSCustomer 
    WHERE CTSCustID = ip_CTSCustID;
    
    # ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual, 4 - IP
    IF ip_AssociationType = 0 OR ip_AssociationType = 1 THEN
		INSERT INTO Temp_CustAssociation(CTSCustID_Aff, AssociationType, AssociationStatus,  AssociationDate)
		SELECT 
				asCus.CTSCustID  
			,	1 AS AssociationType
            , 	1 AS AssociationStatus
			,	GREATEST(asDv.CreatedTime, asCus.CreatedTime)
		FROM CTS_DataCenter.AssociationByDevice AS asDv 
			INNER JOIN CTS_DataCenter.AssociationByDevice AS asCus ON asCus.DCSDeviceID =  asDv.DCSDeviceID  AND asCus.CTSCustID  !=   ip_CTSCustID
		WHERE asDv.CTSCustID = ip_CTSCustID
        ON DUPLICATE KEY UPDATE AssociationDate = LEAST(Temp_CustAssociation.AssociationDate, GREATEST(asDv.CreatedTime, asCus.CreatedTime)); 
    END IF;
    
    # ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual, 4 - IP
    IF ip_AssociationType = 0 OR ip_AssociationType = 3 THEN
		INSERT IGNORE INTO Temp_CustAssociation(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT 
				asMa.ToCTSCustID 
			,	3 AS AssociationType
            ,   1 AS AssociationStatus
			,	asMa.CreatedDate
		FROM CTS_DataCenter.AssociationByManual AS asMa 
		WHERE	asMa.FromCTSCustID =  ip_CTSCustID;
       
        
        INSERT IGNORE INTO Temp_CustAssociation(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT 
				asMa.FromCTSCustID
			,	3 AS AssociationType
            ,   1 AS AssociationStatus
			,	asMa.CreatedDate
		FROM CTS_DataCenter.AssociationByManual AS asMa 
		WHERE	asMa.ToCTSCustID =  ip_CTSCustID;
        
    END IF;

    # ip_AssociationType: 0 - ALL, 1 - Device, 2 - AI, 3 - Manual, 4 - IP
    IF ip_AssociationType = 0 OR ip_AssociationType = 2 THEN
		INSERT IGNORE INTO Temp_CustAssociation(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT 
				cust.CTSCustID 
			,	2 AS AssociationType
            ,	1 AS AssociationStatus
			,	asAI.CreatedDate
		FROM CTS_DataCenter.AssociationByAI AS asAI 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asAI.ToCustID AND cust.CustSubID = 0
		WHERE	asAI.FromCustID =  lv_CustID;
        
        INSERT IGNORE INTO Temp_CustAssociation(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT 
				cust.CTSCustID 
			,	2 AS AssociationType
            ,	1 AS AssociationStatus
			,	asAI.CreatedDate
		FROM CTS_DataCenter.AssociationByAI AS asAI 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asAI.FromCustID AND cust.CustSubID = 0
		WHERE	asAI.ToCustID =  lv_CustID;
    END IF;
    
	IF ip_AssociationType = 0 OR ip_AssociationType = 4 THEN
    SELECT lv_CustID;
		INSERT IGNORE INTO Temp_CustAssociation(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT 
				cust.CTSCustID 
			,	4 AS AssociationType
            ,	1 AS AssociationStatus
			,	asIP.CreatedDate
		FROM CTS_DataCenter.AssociationByIP AS asIP 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asIP.ToCustID AND cust.CustSubID = 0
		WHERE	asIP.FromCustID =  lv_CustID;
        
        INSERT IGNORE INTO Temp_CustAssociation(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
		SELECT 
				cust.CTSCustID 
			,	4 AS AssociationType
            ,	1 AS AssociationStatus
			,	asIP.CreatedDate
		FROM CTS_DataCenter.AssociationByIP AS asIP 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cust.CustID  = asIP.FromCustID AND cust.CustSubID = 0
		WHERE	asIP.ToCustID =  lv_CustID;
    END IF;
    

    #ip_AssociationStatus: 0 - All, 1 - Linked, 2 - UnLinked

	INSERT IGNORE INTO Temp_CustAssociationUnlinked (CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
	WITH CTE_AssociationRemove AS (
		SELECT asRe.ToCTSCustID AS CTSCustID_Aff
			,  asRe.CreatedDate
		FROM CTS_DataCenter.AssociationRemove AS asRe 
		WHERE asRe.FromCTSCustID = ip_CTSCustID
	)
	SELECT 	cte.CTSCustID_Aff
		,	tmp.AssociationType
		,	2 AS AssociationStatus
		,	cte.CreatedDate
	FROM CTE_AssociationRemove AS cte
	INNER JOIN Temp_CustAssociation AS tmp ON cte.CTSCustID_Aff = tmp.CTSCustID_Aff;        
        
	INSERT IGNORE INTO Temp_CustAssociationUnlinked (CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
	WITH CTE_AssociationRemove AS (
		SELECT asRe.FromCTSCustID AS CTSCustID_Aff
			,  asRe.CreatedDate
		FROM CTS_DataCenter.AssociationRemove AS asRe 
		WHERE asRe.ToCTSCustID = ip_CTSCustID
	)
	SELECT 	cte.CTSCustID_Aff
		,	tmp.AssociationType
		,	2 AS AssociationStatus
		,	cte.CreatedDate
	FROM CTE_AssociationRemove AS cte
	INNER JOIN Temp_CustAssociation AS tmp ON cte.CTSCustID_Aff = tmp.CTSCustID_Aff;
        
	DELETE cuAs 
	FROM Temp_CustAssociation AS cuAs 
	WHERE cuAs.CTSCustID_Aff IN (SELECT CTSCustID_Aff FROM Temp_CustAssociationUnlinked);
        
	INSERT IGNORE INTO Temp_CustAssociation(CTSCustID_Aff, AssociationType, AssociationStatus, AssociationDate)
	SELECT CTSCustID_Aff
		,	AssociationType
		,	AssociationStatus
		,	AssociationDate
	FROM Temp_CustAssociationUnlinked;

     IF ip_AssociationStatus = 2 THEN
		DELETE 
        FROM Temp_CustAssociation 
        WHERE Temp_CustAssociation.AssociationStatus != 2;
     END IF;
     
     IF ip_AssociationStatus = 1 THEN
		DELETE cuAs
        FROM Temp_CustAssociation  AS cuAs
            INNER JOIN Temp_CustAssociationUnlinked AS un ON un.CTSCustID_Aff = cuAs.CTSCustID_Aff AND un.AssociationStatus = cuAs.AssociationStatus;
     END IF;     
     
     INSERT IGNORE INTO Temp_Accounts(CTSCustID, CustId, CustSubID, SubscriberID, SubscriberName, UserName, UserName2, AssociationType, AssociationTypeName, AssociationDate, StatusId, StatusName, AssociationStatus, SiteID, SiteName)
     SELECT cust.CTSCustID
		,	cust.CustId
        ,	cust.CustSubID
		,	cust.SubscriberID
        ,	maSu.SubscriberName
        ,	cust.UserName
        ,	cust.UserName2
        ,	cuAs.AssociationType
        ,	sta.ItemName AS AssociationTypeName
        ,	cuAs.AssociationDate
        ,	CASE WHEN cust.CustStatusID IN (1,11) THEN 1
				 WHEN cust.CustStatusID IN (2,3,4,12,13,14) THEN 2
                 ELSE cust.CustStatusID END AS StatusId
		,   sta1.ItemName AS StatusName
        ,	cuAs.AssociationStatus
        ,	cust.SiteID
        ,	cust.Site AS SiteName
     FROM Temp_CustAssociation AS cuAs
        INNER JOIN CTS_DataCenter.CTSCustomer AS cust ON cuAs.CTSCustID_Aff = cust.CTSCustID
        LEFT JOIN  CTS_DataCenter.StaticList AS sta ON sta.ListID = 2 AND sta.ItemID = cuAs.AssociationType
	    LEFT JOIN  CTS_DataCenter.StaticList AS sta1 ON sta1.ListID = 1 AND sta1.ItemID = cust.CustStatusID
        LEFT JOIN  CTS_DataCenter.MappingSubscriberSite AS maSu ON maSu.SubscriberID = cust.SubscriberID AND maSu.SiteID = cust.SiteID
     ON DUPLICATE KEY UPDATE AssociationTypeName =  CONCAT(Temp_Accounts.AssociationTypeName, ', ', sta.ItemName),
							 AssociationDate = LEAST(Temp_Accounts.AssociationDate, cuAs.AssociationDate);
                             
    /*Customer Category: Get Customer Category Infor by Input Info*/                         
    INSERT INTO Temp_CustomerCategory(CustID, ParentID, CategoryIDs, CategoryNames, CustomerClasses)
	SELECT	tmpAcc.CustID
		,	GROUP_CONCAT(DISTINCT tmpCat.ParentID SEPARATOR ',')  AS CategoryIDs  
		,	GROUP_CONCAT(DISTINCT tmpCat.CategoryID SEPARATOR ',')  AS CategoryIDs  
        ,	GROUP_CONCAT(DISTINCT tmpCat.CategoryName SEPARATOR ',')  AS CategoryNames  
		,	GROUP_CONCAT(DISTINCT tmpCat.CustomerClass SEPARATOR ',') AS CustomerClasses		
	FROM	Temp_Accounts AS tmpAcc
		INNER JOIN CTS_DataCenter.CTSCustomerClassification AS cc ON tmpAcc.CustID = cc.CustID	AND CustSubID = 0	
		INNER JOIN Temp_Category AS	tmpCat ON tmpCat.CategoryID = cc.CategoryID
	GROUP BY tmpAcc.CustID;
    
    UPDATE Temp_Accounts AS tmpAcc
		INNER JOIN Temp_CustomerCategory AS tmpCC ON tmpAcc.CustID = tmpCC.CustID	AND CustSubID = 0
	SET	tmpAcc.CategoryIDs = tmpCC.CategoryIDs
		, tmpAcc.CategoryNames = tmpCC.CategoryNames
        , tmpAcc.CustomerClasses = tmpCC.CustomerClasses
        , tmpAcc.ParentIDs = tmpCC.ParentID;
	
    /*Customer Category: Remove Cust that Category is not in Input CategoryIDs*/
    DELETE 	tmpAcc
    FROM	Temp_Accounts AS tmpAcc
    WHERE	EXISTS (SELECT 1 FROM CTSCustomerClassification AS cc WHERE tmpAcc.CustID = cc.CustID)
			AND tmpAcc.CategoryIDs IS NULL;

    # Customer Category: WHEN ip_CategoryIDs Include item '0' - Remove Cust that NOT has Categroy Where Fitter Cat
	IF lv_NoCategoryFilter IS NULL THEN 
		DELETE 	tmpAcc
		FROM	Temp_Accounts AS tmpAcc
		WHERE	tmpAcc.CategoryIDs IS NULL;
    END IF;

	SELECT CTSCustID
	, 	CustId
	, 	CustSubID
	,	SubscriberID
	, 	SubscriberName
	, 	UserName
	, 	UserName2
	, 	AssociationTypeName
	, 	AssociationDate
	, 	StatusId
	, 	StatusName
	, 	AssociationStatus
	, 	SiteID
	, 	SiteName
    ,	tmpAcc.ParentIDs
	,	tmpAcc.CategoryIDs
	,	tmpAcc.CategoryNames
	,	tmpAcc.CustomerClasses
	FROM Temp_Accounts AS tmpAcc
	WHERE SiteID IN (SELECT SiteID FROM Temp_SiteID) 
		AND StatusId IN (SELECT AccountStatusID FROM Temp_AccountStatusID)
	ORDER BY  SiteName ASC, AssociationStatus ASC , StatusId ASC,  AssociationDate DESC
	LIMIT ip_Take
	OFFSET ip_Skip; 

	SELECT COUNT(1) 
	INTO op_TotalItems
	FROM Temp_Accounts
	WHERE SiteID IN (SELECT SiteID FROM Temp_SiteID) 
	AND StatusId IN (SELECT AccountStatusID FROM Temp_AccountStatusID);
    
END$$

DELIMITER ;