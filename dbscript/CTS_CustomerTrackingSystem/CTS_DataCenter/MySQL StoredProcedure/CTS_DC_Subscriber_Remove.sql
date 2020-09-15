DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_Subscriber_Remove $$


CREATE PROCEDURE `CTS_DC_Subscriber_Remove`(
		IN ip_SubscriberID	INT UNSIGNED
    ,	IN ip_SiteID			INT    
    
    , 	OUT op_ErrorMessage 	VARCHAR(200))
BEGIN
/*
		Created:	20200914@Roger.Le
		Task :		Function add new subscriber
		DB:			CTS_DataCenter && CTS_Admin
		Original: 
		Revisions:
			- 20200914@Roger.Le: Created [Redmine ID: #138102]
            
		Param's Explanation:
	*/
    
    DECLARE lv_CurrentDate DATETIME DEFAULT CURRENT_DATE();
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	-- Update subscriber
    UPDATE 	CTS_Admin.Subscriber AS sub
	SET	
			sub.TerminatedDate = lv_CurrentDate
		,	sub.SubscriberStatus = -1
    WHERE sub.SubscriberID = ip_SubscriberID;
    
    -- Update subscriber mapping
    UPDATE 	CTS_DataCenter.MappingSubscriberSite AS map
	SET	map.SubscriberStatus = -1
    WHERE map.SubscriberID = ip_SubscriberID 
			AND map.SiteID = ip_SiteID;
    
END$$
DELIMITER ;