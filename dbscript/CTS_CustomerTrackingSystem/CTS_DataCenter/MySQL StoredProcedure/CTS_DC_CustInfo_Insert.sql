/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustInfo_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustInfo_Insert`(
	IN ip_CustomerList JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20191107@Harvey
		Task:		Insert Customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200704@Harvey: Handle updating/mapping customer on username for deposit
            - 20200603@Harvey: add column RegisterName for search nick name
            - 20200618@Harvey: use CustId as a key when update data (do not have new deposit in our db from now)
            - 20200625@Long.Luu: insert more customer info [Redmine ID: #136046]
            - 20201118@Aries.Nguyen: Add columns InsertedTime, ModifiedTime [RedmineID : #145271]
            - 20200111@Casey.Huynh: Remove SubscriberID from Json, Move Update Customer Info to other SP
			- 20200118@CaseyHuynh: Enhance CTSCustomer Flow - [Redmine: #148849]
            - 202101295@Casey.Huynh: Add Ignore to Update statement [Redmine ID: 149639]
            - 20210506@Casey.Huynh: Remove Error Message Log [Redmine ID: 154633]
			- 20210622@Aries.Nguyen: Update coding convention and improve locking [Redmine ID: #157203]
			- 20210804@Irena.Vo: Fix issue No rescan for existed Customer [Redmine ID: #159706]
            - 20220110@Casey.Huynh: HF Missing CustSub [Redmine ID: #167242]
            - 20220418@Casey.Huynh: Add and Remove VVIP for Downline [Redmine ID: #159013]
            - 20220511@Casey.Huynh: Missing ArchiveCust  [Redmine ID: #172615]
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustInfo_Insert ('[
				 {"BatchId":1,"CustID":10040738,"CustStatusID":1,"UserName":"HAIFARMB01151207","UserName2":"haifa$20297251","Site":"haifa","SiteID":44,"RoleID":1,"CurrencyID":13,"Currency":"RMB","SRecommend":4359240,"MRecommend":4359287,"Recommend":4359308,"CreatedDate":"2013-01-27 05:56:00.000","Danger1":0,"Danger2":0,"Danger3":0,"CustSubID":0}
				,{"BatchId":1,"CustID":15124347,"CustStatusID":1,"UserName":"HAIFARMB01554620","UserName2":"haifa$40834748","Site":"haifa","SiteID":44,"RoleID":1,"CurrencyID":13,"Currency":"RMB","SRecommend":4359240,"MRecommend":4359287,"Recommend":4359308,"CreatedDate":"2014-06-19 09:12:00.000","Danger1":0,"Danger2":0,"Danger3":0,"CustSubID":0}
				,{"BatchId":1,"CustID":18349232,"CustStatusID":1,"UserName":"HAIFARMB01897790","UserName2":"haifa$83884255","Site":"haifa","SiteID":44,"RoleID":1,"CurrencyID":13,"Currency":"RMB","SRecommend":4359240,"MRecommend":4359287,"Recommend":4359308,"CreatedDate":"2015-06-28 07:22:00.000","Danger1":0,"Danger2":0,"Danger3":0,"CustSubID":0}]');
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustomer;    
	CREATE TEMPORARY TABLE Temp_CTSCustomer( 	  
			SubscriberID 	INT 			
		,	CustID			INT	 UNSIGNED NOT NULL
        ,	CustStatusID	TINYINT
        ,	Danger1			TINYINT
        ,	Danger2			TINYINT
        ,	Danger3			TINYINT
		,	CustSubID		BIGINT			
		,	UserName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		,	UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		,	SiteID			INT
        ,	Site			VARCHAR(20) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		,	RoleID			TINYINT		 
		,	Currency		VARCHAR(50) 	
		,	CurrencyID		INT			 	
		,	SRecommend		INT	 UNSIGNED		 	
		,	MRecommend		INT	 UNSIGNED 			
		,	Recommend		INT	 UNSIGNED
        ,	CreatedDate		DATETIME
        ,	DuplicateType 	TINYINT DEFAULT 0#1-Dup(CustID and CustSubID), 2-Dup UserName(not dup CustID and CustSubID)
        ,	OldCTSCustID	BIGINT UNSIGNED
        
        ,	PRIMARY KEY PK_Temp_CTSCustomer(CustID, CustSubID)
        ,	INDEX IX_Temp_CTSCustomer_SiteIDRoleID(SiteID, RoleID)
        ,	INDEX IX_Temp_CTSCustomer_DuplicateType(DuplicateType)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustExist;    
	CREATE TEMPORARY TABLE Temp_CustExist(
			CustID			INT UNSIGNED
		,	CustSubID		INT
        
        ,	PRIMARY KEY PK_Temp_CustExist(CustID,CustSubID)
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_DupUserName;    
	CREATE TEMPORARY TABLE Temp_DupUserName(
			UserName		VARCHAR(50)
        ,	CustID			INT UNSIGNED
		,	CustSubID		INT UNSIGNED
        ,	OldCTSCustID	BIGINT UNSIGNED
        
        ,	PRIMARY KEY PK_Temp_DupUserName(UserName)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;    
	CREATE TEMPORARY TABLE Temp_CustInfo(
			CustID			INT UNSIGNED
		,	CustSubID		INT UNSIGNED
		,	SubscriberID 	INT UNSIGNED
		,	RegisterName	VARCHAR(50)
        
        ,	PRIMARY KEY PK_Temp_CustInfo(CustID,CustSubID)
	);

    INSERT INTO Temp_CTSCustomer(CustID, CustStatusID, Danger1, Danger2, Danger3, CustSubID, UserName, UserName2, SiteID
    , Site, RoleID, Currency, CurrencyID, SRecommend, MRecommend, Recommend, CreatedDate)
	SELECT		CustID	
			,	CustStatusID
			,	Danger1
			,	Danger2
			,	Danger3	
			,	CustSubID		
			,	UserName		
			,	(CASE WHEN UserName2 = 'null' THEN NULL ELSE UserName2 END) AS UserName2
			,	SiteID
			,	(CASE WHEN Site = 'null' THEN NULL ELSE Site END) AS Site
			,	RoleID		
			,	Currency		
			,	CurrencyID	
			,	SRecommend	
			,	MRecommend	
			,	Recommend	
			,	CreatedDate
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
				CustID			INT	 UNSIGNED	PATH "$.CustID" 
			,	CustStatusID	TINYINT			PATH "$.CustStatusID" 
			,	Danger1			TINYINT		 	PATH "$.Danger1" 
			,	Danger2			TINYINT		 	PATH "$.Danger2" 
			,	Danger3			TINYINT		 	PATH "$.Danger3" 
			,	CustSubID		BIGINT			PATH "$.CustSubID" 
			,	UserName		VARCHAR(50)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.UserName"
			,	UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.UserName2" 
			,	SiteID			INT 			PATH "$.SiteID" 
			,	Site			VARCHAR(20)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' 	PATH "$.Site" 
			,	RoleID			TINYINT		 	PATH "$.RoleID" 
			,	Currency		VARCHAR(50) 	PATH "$.Currency" 
			,	CurrencyID		INT			 	PATH "$.CurrencyID" 
			,	SRecommend		INT	 UNSIGNED	PATH "$.SRecommend" 
			,	MRecommend		INT	 UNSIGNED 	PATH "$.MRecommend" 
			,	Recommend		INT	 UNSIGNED 	PATH "$.Recommend" 
			,	CreatedDate		DATETIME	 	PATH "$.CreatedDate" 
			)
	) AS js;	   
    
	INSERT INTO Temp_CustExist(CustID, CustSubID)
	SELECT	tmpCus.CustID
		,	tmpCus.CustSubID        
	FROM Temp_CTSCustomer AS tmpCus
		INNER JOIN	CTS_DataCenter.CTSCustomer AS cus ON tmpCus.CustID = cus.CustID AND tmpCus.CustSubID = cus.CustSubID;
  
	INSERT INTO Temp_DupUserName(UserName, CustID, CustSubID, OldCTSCustID)
	SELECT  tmpCus.UserName		
		,	tmpCus.CustID
        ,	tmpCus.CustSubID
        ,	cus.CTSCustID
	FROM Temp_CTSCustomer AS tmpCus
		LEFT JOIN Temp_CustExist AS tmpEx ON tmpCus.CustID = tmpEx.CustID AND tmpCus.CustSubID = tmpEx.CustSubID
		INNER JOIN	CTS_DataCenter.CTSCustomer AS cus ON tmpCus.UserName = cus.UserName
	WHERE tmpEx.CustID IS NULL;

    UPDATE Temp_CTSCustomer AS tmpCus
		INNER JOIN Temp_CustExist AS tmpEx ON tmpCus.CustID = tmpEx.CustID AND tmpCus.CustSubID = tmpEx.CustSubID
    SET tmpCus.DuplicateType = 1;

    UPDATE Temp_CTSCustomer AS tmpCus
		INNER JOIN Temp_DupUserName AS tmpDun ON tmpCus.UserName = tmpDun.UserName
    SET tmpCus.DuplicateType = 2
		, tmpCus.OldCTSCustID = tmpDun.OldCTSCustID;
     
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomerDuplicate(SubscriberID, CustID, CustSubID, UserName, UserName2, SiteID, Site, RoleID, Currency, CurrencyID
			, SRecommend, MRecommend, Recommend, CreatedDate , RegisterName , CustStatusID , Danger1 ,Danger2 , Danger3 , InsertedTime , ModifiedTime, DuplicateType, OldCTSCustID)
	SELECT    tmpCus.SubscriberID
			, tmpCus.CustID
            , tmpCus.CustSubID
            , tmpCus.UserName
            , tmpCus.UserName2
            , tmpCus.SiteID
            , tmpCus.Site
            , tmpCus.RoleID
            , tmpCus.Currency
            , tmpCus.CurrencyID
            , tmpCus.SRecommend
            , tmpCus.MRecommend
            , tmpCus.Recommend
            , tmpCus.CreatedDate
            , tmpCus.RegisterName
            , tmpCus.CustStatusID
            , tmpCus.Danger1
            , tmpCus.Danger2
            , tmpCus.Danger3
            , CURRENT_TIMESTAMP(4) AS InsertedTime
            , CURRENT_TIMESTAMP(4) AS ModifiedTime
            , tmpCus.DuplicateType
            , tmpCus.OldCTSCustID
    FROM Temp_CTSCustomer AS tmpCus
    WHERE tmpCus.DuplicateType = 2;
    
    # Remove Duplicate UserName 
    DELETE tmpCus
    FROM Temp_CTSCustomer AS tmpCus
    WHERE tmpCus.DuplicateType = 2; 
    
	INSERT INTO Temp_CustInfo(CustID, CustSubID, SubscriberID, RegisterName)
	SELECT  tmpCus.CustID
		, 	tmpCus.CustSubID
		,	mss.SubscriberID
		,	SUBSTRING(tmpCus.UserName2, LOCATE('$',tmpCus.UserName2) + 1)
	FROM Temp_CTSCustomer AS tmpCus
		INNER JOIN	CTS_DataCenter.MappingSubscriberSite mss ON tmpCus.SiteID = mss.SiteID 
																AND ((mss.RoleMapping = 1 AND tmpCus.RoleID = 1)
																	OR (mss.RoleMapping = 2 AND tmpCus.RoleID > 1)
																	OR (mss.RoleMapping = 0));                                                                    
	UPDATE Temp_CTSCustomer AS tmpCus
    INNER JOIN Temp_CustInfo AS cus ON tmpCus.CustID = cus.CustID AND tmpCus.CustSubID = cus.CustSubID
	SET   tmpCus.SubscriberID = cus.SubscriberID
		, tmpCus.RegisterName = cus.RegisterName;        
	
	INSERT IGNORE INTO CTS_DataCenter.CTSCustomer(SubscriberID, CustID, CustSubID, UserName, UserName2, SiteID, Site, RoleID, Currency, CurrencyID
			, SRecommend, MRecommend, Recommend, CreatedDate , RegisterName , CustStatusID , Danger1 ,Danger2 , Danger3 , InsertedTime , ModifiedTime)
	SELECT    tmpCus.SubscriberID
			, tmpCus.CustID
            , tmpCus.CustSubID
            , tmpCus.UserName
            , tmpCus.UserName2
            , tmpCus.SiteID
            , tmpCus.Site
            , tmpCus.RoleID
            , tmpCus.Currency
            , tmpCus.CurrencyID
            , tmpCus.SRecommend
            , tmpCus.MRecommend
            , tmpCus.Recommend
            , tmpCus.CreatedDate
            , tmpCus.RegisterName
            , tmpCus.CustStatusID
            , tmpCus.Danger1
            , tmpCus.Danger2
            , tmpCus.Danger3
            , CURRENT_TIMESTAMP(4) AS InsertedTime
            , CURRENT_TIMESTAMP(4) AS ModifiedTime
    FROM	Temp_CTSCustomer AS tmpCus
    WHERE	tmpCus.DuplicateType = 0;
    
    /**********MARK VVIP IF DRIRECT UPLINE IS VVIP***************************/   
    /*=========GET VVIP FROM QUEUE================*/
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
    CREATE TEMPORARY TABLE Temp_Cust(
			CTSCustID		BIGINT 	UNSIGNED
        ,	CustID			BIGINT	UNSIGNED        
        ,	SubscriberID	INT UNSIGNED
        ,	RoleID			INT        
        ,	SRecommend		BIGINT	UNSIGNED
        ,	MRecommend		BIGINT	UNSIGNED
        ,	Recommend		BIGINT	UNSIGNED
        ,	DirectUpLine	BIGINT	UNSIGNED
		
        ,	PRIMARY KEY PK_Temp_Cust_CTSCustID(CTSCustID)
        ,	INDEX IX_DirectUpLine(DirectUpLine)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_VVIPCust;
    CREATE TEMPORARY TABLE Temp_VVIPCust(
			CTSCustID		BIGINT UNSIGNED
        ,	CustID			BIGINT	UNSIGNED
        ,	SubscriberID	INT UNSIGNED
        ,	RoleID			INT
        ,	CreatedBy		INT
        
        ,	PRIMARY KEY Temp_CustVVIP_CustID(CustID)
    ); 
	
    INSERT INTO Temp_Cust(CTSCustID, CustID, SubscriberID, RoleID, SRecommend, MRecommend, Recommend, DirectUpLine)
    SELECT 	cus.CTSCustID
		,	cus.CustID
        ,	cus.SubscriberID
        ,	cus.RoleID
        ,	cus.SRecommend
        ,	cus.MRecommend
        ,	cus.Recommend
        ,	(CASE WHEN cus.RoleID = 1 THEN cus.Recommend 
				WHEN cus.RoleID = 2 THEN cus.MRecommend
                WHEN cus.RoleID = 3 THEN cus.SRecommend END) AS DirectUpLine               
    FROM Temp_CTSCustomer AS tmpCus	
    INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON tmpCus.CustID = cus.CustID AND cus.CustSubID = 0 AND tmpCus.CustSubID = 0 AND tmpCus.RoleID < 4
    WHERE	tmpCus.DuplicateType = 0;
    
    INSERT INTO Temp_VVIPCust(CTSCustID, CustID, SubscriberID, CreatedBy, RoleID)
    SELECT DISTINCT tmpCus.CTSCustID, tmpCus.CustID, tmpCus.SubscriberID, vip.CreatedBy, tmpCus.RoleID
    FROM Temp_Cust AS tmpCus		
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationVVIP AS vip ON vip.CustID = tmpCus.DirectUpLine AND vip.IsAffectToDownline = 1;
    
    INSERT IGNORE INTO Temp_VVIPCust(CTSCustID, CustID, SubscriberID, CreatedBy, RoleID)
    SELECT DISTINCT tmpCus.CTSCustID, tmpCus.CustID, tmpCus.SubscriberID, que.CreatedBy, tmpCus.RoleID
    FROM Temp_Cust AS tmpCus		
		INNER JOIN CTS_DataCenter.CTSCustomerClassificationVVIPQueue AS que ON que.CustID IN (tmpCus.SRecommend, tmpCus.MRecommend, tmpCus.Recommend) AND que.ActionType = 1;
    
    DELETE tmpCus 
    FROM Temp_CTSCustomer AS tmpCus
		INNER JOIN Temp_VVIPCust AS tmpVip ON tmpCus.CustID = tmpVip.CustID 
	WHERE tmpCus.CustSubID = 0;
    
    /*****OUT PUT TO RESCAN CC************/
	SELECT	cus.CTSCustID
		,	cus.SubscriberID
    	,	cus.CustID
		,	cus.UserName
    	,	cus.RegisterName
		,	cus.RoleID
    	,	cus.CustSubID
    FROM	Temp_CTSCustomer AS tmpCus
		INNER JOIN 	CTS_DataCenter.CTSCustomer AS cus ON tmpCus.CustID = cus.CustID AND tmpCus.CustSubID = cus.CustSubID;    
        
	/*****OUT PUT TO INSERT VVIP************/    
    SELECT	tmpVip.CTSCustID
		,	tmpVip.CustID AS CustID
		,	tmpVip.RoleID AS RoleID
		,	tmpVip.SubscriberID AS SubscriberID
		,	tmpVip.CreatedBy AS CreatedBy        
	FROM Temp_VVIPCust AS tmpVip;
	
END$$
DELIMITER ;