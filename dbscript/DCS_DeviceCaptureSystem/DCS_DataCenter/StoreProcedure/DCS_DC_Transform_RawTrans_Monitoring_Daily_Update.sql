/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_Transform_RawTrans_Monitoring_Daily_Update`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_Transform_RawTrans_Monitoring_Daily_Update`(
		IN ip_SubscriberId INT,
        IN ip_TransDate   DATETIME,
        IN ip_TransSum		INT,
        IN ip_SubscriberName VARCHAR(50)
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20210921@Terry.Nguyen
	    Task : Update TransSum
	    DB: DCS_DataCenter
	    Original:

	    Revisions:		    
        
	    Param's Explanation (filtered by):

    */
	 
    REPLACE INTO DCS_DataCenter.RawTransactionSummary(SubscriberId, TransDate, TransSum, SubscriberName)
    VALUE (ip_SubscriberId, ip_TransDate, ip_TransSum, ip_SubscriberName);
    
END$$
DELIMITER ;
