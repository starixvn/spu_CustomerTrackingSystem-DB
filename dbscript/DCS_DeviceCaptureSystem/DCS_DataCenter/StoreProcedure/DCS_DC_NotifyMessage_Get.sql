/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `DCS_DC_NotifyMessage_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `DCS_DC_NotifyMessage_Get`(
		IN ip_NotifyMessageID	INT UNSIGNED
	,	IN ip_NotifyType		VARCHAR(100)
	,	IN ip_BatchSize 		INT
)
    SQL SECURITY INVOKER
BEGIN
    /*
	    Created: 20230615@Jonathan.Doan
	    Task : Get NotifyMessage
	    DB: DCS_DataCenter
	    Original:

	    Revisions:		    
			-	20230615@Jonathan.Doan: Created [Redmine ID: 189732]
            
	    Param's Explanation (filtered by):
        
        Example: CALL DCS_DC_NotifyMessage_Get('MonitorTransaction', 3);
    */
    
	SELECT	ID
		,	GroupID
		,	Title
		,	Message
		,	MoreInfo
    FROM DCS_DataCenter.NotifyMessage
    WHERE NotifyType = ip_NotifyType
		AND IsNotified = 0
		AND (ip_NotifyMessageID IS NULL OR ID = ip_NotifyMessageID)
    LIMIT ip_BatchSize;
    
END$$
DELIMITER ;
