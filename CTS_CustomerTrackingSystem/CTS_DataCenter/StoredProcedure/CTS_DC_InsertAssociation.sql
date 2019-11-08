DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_InsertAssociation $$

CREATE PROCEDURE CTS_DC_InsertAssociation (IN ip_AssociationList JSON)
BEGIN
	/*
		Created:	20191107@Harvey
		Task:		Insert Association [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
        
		Param's Explanation (filtered by):
        
        CALL CTS_DC_InsertAssociation ('[{"CTSCustID":1,"DCSDeviceID":1,"SubscriberID":2,"CreatedTime":"2019-11-07 15:02:02","InsertTime":"2019-11-07 15:02:02"}]')
	*/

    
    INSERT INTO `CTS_DataCenter`.`Association`
		(`CTSCustID`,
		`DCSDeviceID`,
		`SubscriberID`,
		`CreatedTime`,
		`InsertTime`)
	SELECT *
	FROM JSON_TABLE(ip_AssociationList,
		 "$[*]" COLUMNS(
		  CTSCustID 		BIGINT 			PATH "$.CTSCustID"         
		, DCSDeviceID		BIGINT			PATH "$.DCSDeviceID" 
        , SubscriberID		INT				PATH "$.SubscriberID" 
        , CreatedTime		TIMESTAMP(4)	PATH "$.CreatedTime"
        , InsertTime		TIMESTAMP(4) 	PATH "$.InsertTime" 
		 )) as tmpTable;      

END$$

DELIMITER ;