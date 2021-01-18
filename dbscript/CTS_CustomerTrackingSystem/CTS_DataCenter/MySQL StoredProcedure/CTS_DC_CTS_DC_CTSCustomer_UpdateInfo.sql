/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTS_DC_CTSCustomer_UpdateInfo`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTS_DC_CTSCustomer_UpdateInfo`(
		ip_LastUpdateTime	DATETIME
	,	ip_LastUpdateCustID	INT
	,	IN ip_CustIDList	TEXT
)
 SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200111@Casey.Huynh
		Task:		Update CTSCustomer
		DB:			CTS_DataCenter
		Original:

		Revisions:
	 
		Param's Explanation (filtered by):
		
  Exampele: CALL CTS_DataCenter.CTS_DC_InsertCTSCustomer ('[{"BatchId":1,"CustId":1,"CustSubId":0,"Username":"SA-SD$","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":1,"Currency":"SD$","Srecommend":1,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"},{"BatchId":1,"CustId":2,"CustSubId":0,"Username":"SA-RM","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":2,"Currency":"RM","Srecommend":2,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"}]')
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
		VALUES('CTS_DC_CTS_DC_CTSCustomer_Update', NOW(), err_message, err_no, JSON_OBJECT('err_message', err_message, 'err_no', err_no, 'cod_name', cod_name, 'parameter', ip_CustomerList));
	END;
 
	DROP TEMPORARY TABLE IF EXISTS TempCTSCustomer;
 
	CREATE TEMPORARY TABLE TempCTSCustomer(		
		CustID			INT UNSIGNED	
		,	CustStatusID	TINYINT
		,	Danger1			TINYINT
		,	Danger2			TINYINT
		,	Danger3			TINYINT
		,	CustSubID		BIGINT			
		,	UserName		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		,	UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		,	SiteID			INT
		,	Site			VARCHAR(20) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
		,	RoleID			TINYINT	 
		,	Currency		VARCHAR(50) 	
		,	CurrencyID		INT		 	
		,	SRecommend		INT UNSIGNED	 	
		,	MRecommend		INT UNSIGNED 			
		,	Recommend		INT UNSIGNED
		,	IsUpdateType	TINYINT DEFAULT 0 /*1: update (SiteID,UserName2,UserName), 0: Other*/
        , 	SubscriberID 	INT
        ,	RegisterName	VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'
        ,	CTSCustID		BIGINT UNSIGNED
  
		,	INDEX IX_TempCTSCustomer_CustID(CustID)
        ,	INDEX IX_TempCTSCustomer_CustID(CTSCustID, SubscriberID, UserName, UserName2)
	);	
 
	INSERT INTO TempCTSCustomer(CustID, CustStatusID, Danger1, Danger2, Danger3, CustSubID, UserName, UserName2
								, SiteID, Site, RoleID, Currency, CurrencyID, SRecommend, MRecommend, Recommend)
	SELECT	js.CustID	
		,	js.CustStatusID
		,	js.Danger1
		,	js.Danger2
		,	js.Danger3	
		,	js.CustSubID		
		,	js.UserName		
		,	(CASE WHEN js.UserName2 = 'null' THEN NULL ELSE js.UserName2 END) AS UserName2
		,	js.SiteID
		,	(CASE WHEN js.Site = 'null' THEN NULL ELSE js.Site END) AS Site
		,	js.RoleID		
		,	js.Currency		
		,	js.CurrencyID	
		,	js.SRecommend	
		,	js.MRecommend	
		,	js.Recommend
	FROM JSON_TABLE(ip_CustomerList, 
		"$[*]" COLUMNS(	
				CustID			INT UNSIGNED	PATH "$.CustId" 
			,	CustStatusID	TINYINT	 		PATH "$.CustStatusID" 
			,	Danger1			TINYINT	 		PATH "$.Danger1" 
			,	Danger2			TINYINT	 		PATH "$.Danger2" 
			,	Danger3			TINYINT	 		PATH "$.Danger3" 
			,	CustSubID		BIGINT			PATH "$.CustSubId" 
			,	UserName		VARCHAR(50)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.Username"
			,	UserName2		VARCHAR(50) CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI'	PATH "$.Username2"
			,	SiteID			INT 			PATH "$.SiteId" 
			,	Site			VARCHAR(20)	CHARACTER SET 'UTF8MB4' COLLATE 'UTF8MB4_UNICODE_CI' 	PATH "$.Site"		
			,	RoleID			TINYINT	 		PATH "$.RoleId" 
			,	Currency		VARCHAR(50) 	PATH "$.Currency" 
			,	CurrencyID		INT		 		PATH "$.CurrencyId" 
			,	SRecommend		INT UNSIGNED	PATH "$.Srecommend" 
			,	MRecommend		INT UNSIGNED 	PATH "$.Mrecommend" 
			,	Recommend		INT UNSIGNED 	PATH "$.Recommend"
		)
	) AS js;
	
    UPDATE 		TempCTSCustomer AS tempCust
    LEFT JOIN 	CTS_DataCenter.CTSCustomer AS ctsCust
				ON tempCust.CustID = ctsCust.CustID AND tempCust.CustSubID = ctsCust.CustSubID               
	SET			tempCust.CTSCustID = ctsCust.CTSCustID   
				, IsUpdateType = CASE WHEN ctsCust.CustID IS NULL THEN -1
									  WHEN (tempCust.SiteID != ctsCust.SiteID OR tempCust.UserName2 != ctsCust.UserName2  
											OR tempCust.UserName != ctsCust.UserName OR tempCust.UserName != ctsCust.UserName 
                                            OR tempCust.RoleID != ctsCust.RoleID ) THEN 1 END;
    
    UPDATE 		CTS_DataCenter.CTSCustomer AS ctsCust
    INNER JOIN	TempCTSCustomer AS tempCust
				ON ctsCust.CTSCustID = tempCust.CTSCustID
	INNER JOIN	CTS_DataCenter.MappingSubscriberSite mss 
				ON tempCust.SiteID = mss.SiteID 
				AND ((mss.RoleMapping = 1 AND tempCust.RoleID = 1)
					OR (mss.RoleMapping = 2 AND tempCust.RoleID > 1)
					OR (mss.RoleMapping = 0))
	SET 	ctsCust.SubscriberID = mss.SubscriberID
		,	ctsCust.SiteID = tempCust.SiteID
		,	ctsCust.Site = tempCust.Site
		,	ctsCust.UserName = tempCust.UserName
		,	ctsCust.UserName2 = tempCust.UserName2                
		,	ctsCust.RoleID = tempCust.RoleID
		,	ctsCust.RegisterName = SUBSTRING(tempCust.UserName2, LOCATE('$',tempCust.UserName2) + 1)                
	WHERE		ctsCust.IsUpdateType = 1;
    
	UPDATE 		CTS_DataCenter.CTSCustomer AS ctsCust
	INNER JOIN 	TempCTSCustomer AS tempCust ON ctsCust.CTSCustID = tempCust.CTSCustID
	SET 	ctsCust.RoleID = tempCust.RoleID
		,	ctsCust.Currency = tempCust.Currency
		,	ctsCust.CurrencyID = tempCust.CurrencyID
		,	ctsCust.CustStatusID = tempCust.CustStatusID
		,	ctsCust.Danger1 = tempCust.Danger1
		,	ctsCust.Danger2 = tempCust.Danger2
		,	ctsCust.Danger3 = tempCust.Danger3
        ,   ctsCust.SRecommend = tempCust.SRecommend
		,	ctsCust.MRecommend = tempCust.MRecommend
		, 	ctsCust.Recommend = tempCust.Recommend
		,	ctsCust.ModifiedTime = NOW();

	#=====ReTransform==============================
    UPDATE		DCS_DataCenter.Account AS acc	
    INNER JOIN	TempCTSCustomer AS tmpCust
				ON acc.LoginName = tmpCust.RegisterName
				AND	acc.SubscriberID = tmpCust.SubscriberID
	SET			acc.IsCTSTransformed = 0
	WHERE		acc.IsCTSTransformed = -1; 
    
	UPDATE		DCS_DataCenter.Account AS acc	
    INNER JOIN	TempCTSCustomer AS tmpCust
				ON acc.LoginName = tmpCust.UserName
                AND acc.SubscriberID = tmpCust.SubscriberID
	SET			acc.IsCTSTransformed = 0
	WHERE		acc.IsCTSTransformed = -1;
    
    #==================================================
    	
		UPDATE	CTS_DataCenter.SystemParameter AS s
        SET		s.ParamaterValue = ip_LastUpdateTime
		WHERE	s.ParameterID = 9 AND s.ParameterName = 'CTSCustomer_LastUpdateTime';

		SELECT	s.ParamaterValue AS LastUpdateCustID
		FROM	CTS_DataCenter.SystemParameter AS s
		WHERE	s.ParameterID = 10 AND s.ParameterName = 'CTSCustomer_LastUpdateCustID';
    
END$$
DELIMITER ;