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
        
        CALL CTS_DC_InsertCTSCustomer ('[{"SubscriberID":1,"CustID":1,"HeadCustID":2,"UserName":"harvey","UserName2":"harvey123","Site":"77333","RoleID":2,"Currency":"UUS","SRecommend":2,"MRecommend":3,"Recommend":4}]')
	*/

    INSERT INTO `CTSCustomer`
				(`SubscriberID`,
				`CustID`,
				`HeadCustID`,
				`UserName`,
				`UserName2`,
				`Site`,
				`RoleID`,
				`Currency`,
				`CurrencyID`,
				`SRecommend`,
				`MRecommend`,
				`Recommend`)
	SELECT *
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
		  SubscriberID 	INT 			PATH "$.SubscriberID"
		, CustID		BIGINT			PATH "$.CustID" 
        , HeadCustID	BIGINT			PATH "$.HeadCustID" 
        , UserName		VARCHAR(50)		PATH "$.UserName"
        , UserName2		VARCHAR(50) 	PATH "$.UserName2" 
        , Site			BIGINT		 	PATH "$.Site" 
        , RoleID		TINYINT		 	PATH "$.RoleID" 
        , Currency		VARCHAR(50) 	PATH "$.Currency" 
        , CurrencyID	INT			 	PATH "$.CurrencyID" 
        , SRecommend	BIGINT		 	PATH "$.SRecommend" 
        , MRecommend	BIGINT 			PATH "$.MRecommend" 
        , Recommend		BIGINT 			PATH "$.Recommend" 
		 )) as tmpTable;      

END$$
DELIMITER ;