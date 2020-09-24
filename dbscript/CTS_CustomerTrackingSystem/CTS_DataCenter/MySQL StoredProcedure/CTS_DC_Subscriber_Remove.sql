USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_Subscriber_Remove`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_Subscriber_Remove`(
		IN ip_SubscriberID		INT UNSIGNED

    , 	OUT op_ErrorMessage 	VARCHAR(200))
BEGIN
/*
		Created:	20200914@Roger.Le
		Task :		Function add new subscriber
		DB:			CTS_DataCenter && CTS_Admin
		Original: 
		Revisions:
            - [20200914@Roger.Le][138102]: Created 
            - [20200924@Lex.Khuat][138102]: Spec changes, terminating now deactivates whole sub including all sites
            
            
		Param's Explanation:
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT CURRENT_DATE();
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	-- Update subscriber
    UPDATE 	CTS_Admin.Subscriber AS sub
	SET		sub.TerminatedDate = lv_CurrentDate
		,	sub.SubscriberStatus = -1
    WHERE sub.SubscriberID = ip_SubscriberID;
    
    -- Update subscriber mapping
    UPDATE 	CTS_DataCenter.MappingSubscriberSite AS map
	SET		map.SubscriberStatus = -1
    WHERE map.SubscriberID = ip_SubscriberID;

END$$

DELIMITER ;

