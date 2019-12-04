DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_InsertCTSCustomer $$

CREATE PROCEDURE CTS_DC_InsertCTSCustomer (IN ip_CustomerList JSON)
BEGIN
	/*
		Created:	20191107@Harvey
		Task:		Insert Customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_DC_InsertCTSCustomer ('[{"CustID":1,"CustSubID":2,"UserName":"harvey","UserName2":"harvey123","Site":"CN88","RoleID":2,"Currency":"UUS","CurrencyID":20,"SRecommend":2,"MRecommend":3,"Recommend":4}]')
	*/

	DROP TEMPORARY TABLE IF EXISTS TempCTSCustomer;
    
	CREATE TEMPORARY TABLE TempCTSCustomer
	( 	SubscriberID 	INT 			
		, CustID		BIGINT			
		, CustSubID		BIGINT			
		, UserName		VARCHAR(50) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci'
		, UserName2		VARCHAR(50) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci'
		, Site			VARCHAR(20) CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_general_ci'
		, RoleID		TINYINT		 
		, Currency		VARCHAR(50) 	
		, CurrencyID	INT			 	
		, SRecommend	BIGINT		 	
		, MRecommend	BIGINT 			
		, Recommend		BIGINT
        );
    
    INSERT INTO TempCTSCustomer
	SELECT SubscriberID 	
		, CustID		
		, CustSubID		
		, UserName		
		, CASE WHEN UserName2 = 'null' THEN NULL ELSE UserName2 END
		, CASE WHEN Site = 'null' THEN NULL ELSE Site END	
		, RoleID		
		, Currency		
		, CurrencyID	
		, SRecommend	
		, MRecommend	
		, Recommend	
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
		  SubscriberID 	INT 			PATH "$.SubscriberId"
		, CustID		BIGINT			PATH "$.CustId" 
		, CustSubID		BIGINT			PATH "$.CustSubId" 
		, UserName		VARCHAR(50)		PATH "$.Username"
		, UserName2		VARCHAR(50) 	PATH "$.Username2" 
		, Site			VARCHAR(20)	 	PATH "$.Site" 
		, RoleID		TINYINT		 	PATH "$.RoleId" 
		, Currency		VARCHAR(50) 	PATH "$.Currency" 
		, CurrencyID	INT			 	PATH "$.CurrencyId" 
		, SRecommend	BIGINT		 	PATH "$.Srecommend" 
		, MRecommend	BIGINT 			PATH "$.Mrecommend" 
		, Recommend		BIGINT 			PATH "$.Recommend" 
		 )) as tmpTable;

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	UPDATE TempCTSCustomer cust
		INNER JOIN CTS_DataCenter.MappingSubscriberSite mss ON cust.Site = mss.SiteName 
	SET cust.SubscriberID = mss.SubscriberID;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

UPDATE CTS_DataCenter.CTSCustomer ctsCust
        INNER JOIN TempCTSCustomer tempCust ON tempCust.UserName2 = ctsCust.UserName2 
SET 
    ctsCust.SubscriberID 	= tempCust.SubscriberID,
    ctsCust.CustID 			= tempCust.CustID,
    ctsCust.CustSubID 		= tempCust.CustSubID,
    ctsCust.UserName 		= tempCust.UserName,
    ctsCust.Site 			= tempCust.Site,
    ctsCust.RoleID 			= tempCust.RoleID,
    ctsCust.Currency 		= tempCust.Currency,
    ctsCust.CurrencyID 		= tempCust.CurrencyID,
    ctsCust.SRecommend 		= tempCust.SRecommend,
    ctsCust.MRecommend 		= tempCust.MRecommend;

    INSERT INTO `CTS_DataCenter`.`CTSCustomer`
				(`SubscriberID`,
				`CustID`,
				`CustSubID`,
				`UserName`,
				`UserName2`,
				`Site`,
				`RoleID`,
				`Currency`,
				`CurrencyID`,
				`SRecommend`,
				`MRecommend`,
				`Recommend`)
	SELECT    tempCust.SubscriberID
			, tempCust.CustID
            , tempCust.CustSubID
            , tempCust.UserName
            , tempCust.UserName2
            , tempCust.Site
            , tempCust.RoleID
            , tempCust.Currency
            , tempCust.CurrencyID
            , tempCust.SRecommend
            , tempCust.MRecommend
            , tempCust.Recommend
	FROM TempCTSCustomer tempCust
		LEFT JOIN CTS_DataCenter.CTSCustomer ctsCust on tempCust.UserName2 = ctsCust.UserName2
	WHERE ctsCust.UserName2 IS NULL;

END$$
DELIMITER ;