DELIMITER $$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_InsertAssociation`(IN ip_AssociationList JSON)
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

    
    INSERT INTO `CTS_DataCenter`.`AssociationByDevice`
		(`CTSCustID`,
		`DCSDeviceID`,
		`SubscriberID`,
		`CreatedTime`,
		`InsertTime`)
	SELECT tmpTable.CTSCustID, tmpTable.DCSDeviceID, tmpTable.SubscriberID, tmpTable.CreatedTime, now()
	FROM JSON_TABLE(ip_AssociationList,
		 "$[*]" COLUMNS(
		  CTSCustID 		BIGINT 			PATH "$.CustId"         
		, DCSDeviceID		BIGINT			PATH "$.DeviceId" 
        , SubscriberID		INT				PATH "$.SubscriberId" 
        , CreatedTime		TIMESTAMP(4)	PATH "$.CreatedTime"        
		 )) as tmpTable;      

END$$
DELIMITER ;
