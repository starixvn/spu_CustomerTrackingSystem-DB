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
	AS
	SELECT *
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
		  SubscriberID 	INT 			PATH "$.SubscriberID"
		, CustID		BIGINT			PATH "$.CustID" 
		, CustSubID		BIGINT			PATH "$.CustSubID" 
		, UserName		VARCHAR(50)		PATH "$.UserName"
		, UserName2		VARCHAR(50) 	PATH "$.UserName2" 
		, Site			VARCHAR(20)	 	PATH "$.Site" 
		, RoleID		TINYINT		 	PATH "$.RoleID" 
		, Currency		VARCHAR(50) 	PATH "$.Currency" 
		, CurrencyID	INT			 	PATH "$.CurrencyID" 
		, SRecommend	BIGINT		 	PATH "$.SRecommend" 
		, MRecommend	BIGINT 			PATH "$.MRecommend" 
		, Recommend		BIGINT 			PATH "$.Recommend" 
		 )) as tmpTable;

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	UPDATE TempCTSCustomer cust
		INNER JOIN CTS_DataCenter.MappingSubscriberSite mss ON cust.Site = mss.SiteName 
	SET cust.SubscriberID = mss.SubscriberID;
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

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
	SELECT    SubscriberID
			, CustID
            , CustSubID
            , UserName
            , UserName2
            , Site
            , RoleID
            , Currency
            , CurrencyID
            , SRecommend
            , MRecommend
            , Recommend
	FROM TempCTSCustomer;

END$$
DELIMITER ;