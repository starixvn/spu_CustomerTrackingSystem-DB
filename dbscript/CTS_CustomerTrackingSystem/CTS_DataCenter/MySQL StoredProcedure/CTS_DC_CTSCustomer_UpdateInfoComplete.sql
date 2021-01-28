/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_UpdateInfoComplete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_UpdateInfoComplete`(
		IN ip_LastUpdateTime	DATETIME(3)
	,	IN ip_LastUpdateCustID	INT
	,	IN ip_CustomerInfo	JSON
)
 SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200111@Casey.Huynh
		Task:		Update CTSCustomer Info Complete
		DB:			CTS_DataCenter
		Original:

		Revisions:
			-	20210115@Casey.Huynh: Created [Redmine ID: 148849]
		Param's Explanation (filtered by):
		
  Exampele: CALL CTS_DataCenter.CTS_DC_InsertCTSCustomer ('[{"BatchId":1,"CustId":1,"CustSubId":0,"Username":"SA-SD$","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":1,"Currency":"SD$","Srecommend":1,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"},{"BatchId":1,"CustId":2,"CustSubId":0,"Username":"SA-RM","Username2":null,"Site":"BEST-ODDS","SiteId":1,"RoleId":4,"CurrencyId":2,"Currency":"RM","Srecommend":2,"Mrecommend":0,"Recommend":0,"CreatedDate":"2020-04-24T03:18:00"}]')
	*/
	DECLARE     lv_No    INT    DEFAULT 1;
    DECLARE     lv_ErrorMessage2 VARCHAR(200) DEFAULT '';
    DECLARE		lv_ErrorMessage	VARCHAR(200) DEFAULT '';
 
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN   
		GET DIAGNOSTICS lv_No = NUMBER;
		GET DIAGNOSTICS CONDITION lv_No 
            lv_ErrorMessage = MESSAGE_TEXT;	
		
		IF(lv_No > 1) THEN
			SET lv_No = lv_No - 1;
			GET STACKED  DIAGNOSTICS CONDITION lv_No
				lv_ErrorMessage2 = MESSAGE_TEXT;	
        END IF;
			
		SET lv_ErrorMessage = CONCAT(lv_ErrorMessage,'; ',lv_ErrorMessage2);

		CALL CTS_Log.CTS_Log_ErrorLog_Insert('CTS_DC_CTSCustomer_UpdateInfoComplete',lv_ErrorMessage, JSON_OBJECT('parameter', ip_CustomerInfo));
    
		SIGNAL SQLSTATE '99999' SET MESSAGE_TEXT = lv_ErrorMessage;
    END;
 
	DROP TEMPORARY TABLE IF EXISTS TempCTSCustomer;
	CREATE TEMPORARY TABLE TempCTSCustomer(
			CustID			INT UNSIGNED        	
		,	SRecommend		INT UNSIGNED	 	
		,	MRecommend		INT UNSIGNED 			
		,	Recommend		INT UNSIGNED
        ,	Currency		VARCHAR(50) 	
		,	CurrencyID		INT
        ,	CustStatusID	TINYINT
		,	Danger1			TINYINT
		,	Danger2			TINYINT
		,	Danger3			TINYINT
  
		,	INDEX IX_TempCTSCustomer_CustID(CustID)
	);	
 
	INSERT INTO TempCTSCustomer(CustID, SRecommend, MRecommend, Recommend, Currency, CurrencyID, CustStatusID, Danger1, Danger2, Danger3)
	SELECT	js.CustID	
		,	js.SRecommend		
		,	js.MRecommend
		,	js.Recommend
        ,	js.Currency
		,	js.CurrencyID
		,	js.CustStatusID
		,	js.Danger1		
		,	js.Danger2		
		,	js.Danger3
		
	FROM JSON_TABLE(ip_CustomerInfo, 
		"$[*]" COLUMNS(
				CustID			INT UNSIGNED	PATH "$.CustID"            
            ,	SRecommend		INT UNSIGNED	PATH "$.SRecommend" 
			,	MRecommend		INT UNSIGNED 	PATH "$.MRecommend" 
			,	Recommend		INT UNSIGNED 	PATH "$.Recommend"
            ,	Currency		VARCHAR(50) 	PATH "$.Currency" 
			,	CurrencyID		INT		 		PATH "$.CurrencyID"
            ,	CustStatusID	TINYINT	 		PATH "$.CustStatusID" 
			,	Danger1			TINYINT	 		PATH "$.Danger1" 
			,	Danger2			TINYINT	 		PATH "$.Danger2" 
			,	Danger3			TINYINT	 		PATH "$.Danger3"		
			
		)
	) AS js;	
       
	UPDATE 		CTS_DataCenter.CTSCustomer AS ctsCust
	INNER JOIN 	TempCTSCustomer AS tempCust ON ctsCust.CustID = tempCust.CustID
	SET		ctsCust.SRecommend = tempCust.SRecommend
		,	ctsCust.MRecommend = tempCust.MRecommend
		, 	ctsCust.Recommend = tempCust.Recommend
        ,	ctsCust.Currency = tempCust.Currency
		,	ctsCust.CurrencyID = tempCust.CurrencyID
        ,	ctsCust.CustStatusID = tempCust.CustStatusID
		,	ctsCust.Danger1 = tempCust.Danger1
		,	ctsCust.Danger2 = tempCust.Danger2
		,	ctsCust.Danger3 = tempCust.Danger3
		,	ctsCust.ModifiedTime = NOW()
	WHERE	ctsCust.CustSubID = 0;
    
    #==================================================    	
	UPDATE	CTS_DataCenter.SystemParameter AS s
	SET		s.ParameterValue = ip_LastUpdateTime
	WHERE	s.ParameterID = 9 AND s.ParameterName = 'CTSCustomer_LastUpdateTime';
	
	UPDATE	CTS_DataCenter.SystemParameter AS s
	SET		s.ParameterValue = ip_LastUpdateCustID
	WHERE	s.ParameterID = 10 AND s.ParameterName = 'CTSCustomer_LastUpdateCustID';

END$$
DELIMITER ;