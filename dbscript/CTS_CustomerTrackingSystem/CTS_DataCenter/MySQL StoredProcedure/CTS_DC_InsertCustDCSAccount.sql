DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_InsertCustDCSAccount $$

CREATE PROCEDURE CTS_DC_InsertCustDCSAccount (IN ip_CustDCSAccountList JSON)
BEGIN
	/*
		Created:	20191107@Harvey
		Task:		Insert CustDCSAccount [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
        
        CALL CTS_DC_InsertCustDCSAccount ('[{"CTSCustID":1,"AccountID":1,"SubscriberID":2,"InsertTime":"2019-11-07 15:02:02"}]')
	*/

    INSERT INTO `CTS_DataCenter`.`CustDCSAccount`
				(`CTSCustID`,
				`AccountID`,
				`SubscriberID`,
				`InsertTime`)
	SELECT *
	FROM JSON_TABLE(ip_CustDCSAccountList,
		 "$[*]" COLUMNS(
		  CTSCustID 		BIGINT 			PATH "$.CTSCustID"         
		, AccountID			BIGINT			PATH "$.AccountID" 
        , SubscriberID		INT				PATH "$.SubscriberID" 
        , InsertTime		TIMESTAMP(4) 	PATH "$.InsertTime" 
		 )) as tmpTable;      

END$$

DELIMITER ;