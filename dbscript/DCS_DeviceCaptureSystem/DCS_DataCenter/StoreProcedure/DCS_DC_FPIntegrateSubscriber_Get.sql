/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_FPIntegrateSubscriber_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_FPIntegrateSubscriber_Get`(
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20250916@Casey.Huynh
	    Task : Get Subscriber which is integrated by AI FP
	    DB: DCS_DataCenter
	    Original:

	    Revisions:
            - 20250916@Casey.Huynh: Created [Redmine ID: #236716]
            
	    Param's Explanation (filtered by):
		Example:
			CALL DCS_DC_FPIntegrateSubscriber_Get();
    */
    
    SELECT	fs.SubscriberID
		,	fs.SubscriberName
	FROM DCS_DataCenter.FPIntegrateSubscriber AS fs;
    
END$$
DELIMITER ;