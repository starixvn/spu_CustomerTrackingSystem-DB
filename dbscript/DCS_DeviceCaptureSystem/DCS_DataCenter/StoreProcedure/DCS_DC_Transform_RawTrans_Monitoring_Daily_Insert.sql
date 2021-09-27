/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_RawTrans_Monitoring_Daily_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_RawTrans_Monitoring_Daily_Insert`(
        IN ip_TransDate   DATETIME
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20210921@Terry.Nguyen
	    Task : Insert TransDate and Subscriber
	    DB: DCS_DataCenter
	    Original:

	    Revisions:		    
        
	    Param's Explanation (filtered by):

    */
	
    INSERT IGNORE INTO DCS_DataCenter.RawTransactionSummary(SubscriberId, TransDate, TransSum, SubscriberName)    
    SELECT 	SubscriberID
			, DATE_FORMAT(ip_TransDate,'%Y-%m-%d')
			, 0
			, SubscriberName 
    FROM CTS_Admin.Subscriber 
    WHERE DCSStatus = 1;
    
END$$
DELIMITER ;
