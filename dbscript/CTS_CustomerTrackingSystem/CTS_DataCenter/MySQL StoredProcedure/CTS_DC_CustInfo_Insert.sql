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

		Param's Explanation (filtered by):
        
		Example:
			- CALL CTS_DataCenter.CTS_DC_CTSCustomer_Insert ('[{"BatchId":1,"CustID":1,"CustStatusID":0,"Username":"SA-SD$","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":1,"Currency":"SD$","Srecommend":1,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"},{"BatchId":1,"CustId":2,"CustSubId":0,"Username":"SA-RM","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":2,"Currency":"RM","Srecommend":2,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"}]')
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
        ,	IsExisting 		BOOLEAN DEFAULT 0
        ,	INDEX			IX_Temp_CTSCustomer_SiteIDRoleID(RoleID, SiteID)
	);
    
	DROP TEMPORARY TABLE IF EXISTS Temp_CustExist;    
	CREATE TEMPORARY TABLE Temp_CustExist(
			CustID			INT
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_CustInfo;    
	CREATE TEMPORARY TABLE Temp_CustInfo(
			CustID			INT
		,	SubscriberID 	INT
		,	RegisterName	VARCHAR(50)
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
	
	INSERT INTO Temp_CustExist(CustID)
	SELECT  tmpCus.CustID
	FROM Temp_CTSCustomer AS tmpCus
		INNER JOIN	CTS_DataCenter.CTSCustomer AS cus ON tmpCus.CustID = cus.CustID AND tmpCus.CustSubID = cus.CustSubID;

    UPDATE Temp_CTSCustomer AS tmpCus
		INNER JOIN Temp_CustExist AS cus ON tmpCus.CustID = cus.CustID 
    SET tmpCus.IsExisting = 1;
    
	INSERT INTO Temp_CustInfo(CustID,SubscriberID, RegisterName)
	SELECT  tmpCus.CustID
		,	mss.SubscriberID
		,	SUBSTRING(tmpCus.UserName2, LOCATE('$',tmpCus.UserName2) + 1)
	FROM Temp_CTSCustomer AS tmpCus
		INNER JOIN	CTS_DataCenter.MappingSubscriberSite mss ON tmpCus.SiteID = mss.SiteID 
																AND ((mss.RoleMapping = 1 AND tmpCus.RoleID = 1)
																	OR (mss.RoleMapping = 2 AND tmpCus.RoleID > 1)
																	OR (mss.RoleMapping = 0));
	
	UPDATE Temp_CTSCustomer AS tmpCus
    INNER JOIN Temp_CustInfo AS cus ON tmpCus.CustID = cus.CustID
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
    WHERE	tmpCus.IsExisting = 0;
    
	SELECT	cus.CTSCustID
		,	cus.SubscriberID
    	,	cus.CustID
		,	cus.UserName
    	,	cus.RegisterName
    	,	cus.CustSubID
		,	tmpCus.IsExisting
    FROM	Temp_CTSCustomer AS tmpCus
		INNER JOIN 	CTS_DataCenter.CTSCustomer AS cus ON tmpCus.CustID = cus.CustID AND tmpCus.CustSubID = cus.CustSubID;    
END$$
DELIMITER ;