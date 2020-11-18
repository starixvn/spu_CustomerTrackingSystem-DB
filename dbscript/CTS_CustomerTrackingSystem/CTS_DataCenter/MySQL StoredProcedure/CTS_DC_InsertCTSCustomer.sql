/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DataCenter.CTS_DC_InsertCTSCustomer $$

CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_InsertCTSCustomer`(IN ip_CustomerList json)
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
            - 20201118@Aries.Nguyen: Add columns InsertedTime, ModifiedTime
        
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_DC_InsertCTSCustomer ('[{"BatchId":1,"CustId":1,"CustSubId":0,"Username":"SA-SD$","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":1,"Currency":"SD$","Srecommend":1,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"},{"BatchId":1,"CustId":2,"CustSubId":0,"Username":"SA-RM","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":2,"Currency":"RM","Srecommend":2,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"}]')
	*/
    DECLARE err_message text DEFAULT '';
	DECLARE err_no int DEFAULT 0;
    DECLARE cod_name varchar(10) DEFAULT '';
	
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
		GET DIAGNOSTICS CONDITION 1	
			err_message = MESSAGE_TEXT
            ,err_no = MYSQL_ERRNO
            ,cod_name = RETURNED_SQLSTATE;
		
        INSERT INTO CTS_Log.ErrorLog(EventName, InsertedTime, Message, Err_No, Description)
        VALUES('CTS_DC_InsertCTSCustomer', NOW(), err_message, err_no, JSON_OBJECT('err_message', err_message, 'err_no', err_no, 'cod_name', cod_name, 'parameter', ip_CustomerList));
        
	END;
    
    
	DROP TEMPORARY TABLE IF EXISTS TempCTSCustomer;
    
	CREATE TEMPORARY TABLE TempCTSCustomer
	( 	  SubscriberID 	INT 			
		, CustID		INT	 UNSIGNED	
        , CustStatusID	TINYINT
        , Danger1		TINYINT
        , Danger2		TINYINT
        , Danger3		TINYINT
		, CustSubID		BIGINT			
		, UserName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        , RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, SiteID		INT
        , Site			VARCHAR(20) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		, RoleID		TINYINT		 
		, Currency		VARCHAR(50) 	
		, CurrencyID	INT			 	
		, SRecommend	INT	 UNSIGNED		 	
		, MRecommend	INT	 UNSIGNED 			
		, Recommend		INT	 UNSIGNED
        , CreatedDate	DATETIME
        , INDEX			IX_TempCTSCustomer_UserName2(UserName2)
        );
    
    INSERT INTO TempCTSCustomer
	SELECT SubscriberID 	
		, CustID	
        , CustStatusID
        , Danger1
        , Danger2
        , Danger3	
		, CustSubID		
		, UserName		
		, CASE WHEN UserName2 = 'null' THEN NULL ELSE UserName2 END
        , NULL
        , SiteID
		, CASE WHEN Site = 'null' THEN NULL ELSE Site END	
		, RoleID		
		, Currency		
		, CurrencyID	
		, SRecommend	
		, MRecommend	
		, Recommend	
        , CreatedDate
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
		  SubscriberID 	INT 			PATH "$.SubscriberId"
		, CustID		INT	 UNSIGNED	PATH "$.CustId" 
        , CustStatusID	TINYINT		 	PATH "$.CustStatusID" 
        , Danger1		TINYINT		 	PATH "$.Danger1" 
        , Danger2		TINYINT		 	PATH "$.Danger2" 
        , Danger3		TINYINT		 	PATH "$.Danger3" 
		, CustSubID		BIGINT			PATH "$.CustSubId" 
		, UserName		VARCHAR(50)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.Username"
		, UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.Username2" 
        , SiteID		INT 			PATH "$.SiteId" 
		, Site			VARCHAR(20)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' 	PATH "$.Site" 
		, RoleID		TINYINT		 	PATH "$.RoleId" 
		, Currency		VARCHAR(50) 	PATH "$.Currency" 
		, CurrencyID	INT			 	PATH "$.CurrencyId" 
		, SRecommend	INT	 UNSIGNED	PATH "$.Srecommend" 
		, MRecommend	INT	 UNSIGNED 	PATH "$.Mrecommend" 
		, Recommend		INT	 UNSIGNED 	PATH "$.Recommend" 
        , CreatedDate	DATETIME	 	PATH "$.CreatedDate" 
		 )) as tmpTable;
         
	 UPDATE	TempCTSCustomer
     SET	RegisterName = SUBSTRING(UserName2, LOCATE('$',UserName2) + 1);

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		UPDATE 		TempCTSCustomer cust
		INNER JOIN	CTS_DataCenter.MappingSubscriberSite mss 
					ON cust.SiteID = mss.SiteID 
                    AND ((mss.RoleMapping = 1 AND cust.RoleID = 1)
						OR (mss.RoleMapping = 2 AND cust.RoleID > 1)
						OR (mss.RoleMapping = 0))
		SET 		cust.SubscriberID 	= 	mss.SubscriberID;
        
	UPDATE 		CTS_DataCenter.CTSCustomer ctsCust
	INNER JOIN	TempCTSCustomer tempCust 
				ON ctsCust.CustID = tempCust.CustID
				AND ctsCust.CustSubID = tempCust.CustSubID 
	SET 
		  ctsCust.UserName 		= tempCust.UserName
		, ctsCust.UserName2		= tempCust.UserName2
        , ctsCust.SubscriberID	= tempCust.SubscriberID
        , ctsCust.SiteID 		= tempCust.SiteID
		, ctsCust.Site 			= tempCust.Site
		, ctsCust.RoleID 		= tempCust.RoleID
		, ctsCust.Currency 		= tempCust.Currency
		, ctsCust.CurrencyID 	= tempCust.CurrencyID
		, ctsCust.SRecommend 	= tempCust.SRecommend
		, ctsCust.MRecommend 	= tempCust.MRecommend
        , ctsCust.Recommend 	= tempCust.Recommend
        , ctsCust.CreatedDate 	= tempCust.CreatedDate
        , ctsCust.RegisterName 	= tempCust.RegisterName
        , ctsCust.CustStatusID 	= tempCust.CustStatusID
        , ctsCust.Danger1 		= tempCust.Danger1
        , ctsCust.Danger2 		= tempCust.Danger2
        , ctsCust.Danger3 		= tempCust.Danger3
        , ctsCust.ModifiedTime  = NOW();

	INSERT INTO CTS_DataCenter.CTSCustomer(SubscriberID, CustID, CustSubID, UserName, UserName2, SiteID, Site, RoleID, Currency, CurrencyID, SRecommend, MRecommend, Recommend, CreatedDate,RegisterName,CustStatusID,Danger1,Danger2,Danger3,InsertedTime,ModifiedTime)
	SELECT    tempCust.SubscriberID
			, tempCust.CustID
            , tempCust.CustSubID
            , tempCust.UserName
            , tempCust.UserName2
            , tempCust.SiteID
            , tempCust.Site
            , tempCust.RoleID
            , tempCust.Currency
            , tempCust.CurrencyID
            , tempCust.SRecommend
            , tempCust.MRecommend
            , tempCust.Recommend
            , tempCust.CreatedDate
            , tempCust.RegisterName
            , tempCust.CustStatusID
            , tempCust.Danger1
            , tempCust.Danger2
            , tempCust.Danger3
            , NOW()
            , NOW()
    FROM TempCTSCustomer tempCust
		LEFT JOIN CTS_DataCenter.CTSCustomer ctsCust 
			ON tempCust.CustID = ctsCust.CustID 
				AND tempCust.CustSubID = ctsCust.CustSubID
	WHERE ctsCust.CustID IS NULL;

END$$
DELIMITER ;