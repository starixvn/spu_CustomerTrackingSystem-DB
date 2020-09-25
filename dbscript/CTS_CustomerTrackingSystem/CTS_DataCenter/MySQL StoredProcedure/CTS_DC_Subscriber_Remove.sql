USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_Subscriber_Remove`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_Subscriber_Remove`(
		IN ip_SubscriberID		INT UNSIGNED
	,	IN ip_UserID 			INT

    , 	OUT op_ErrorMessage 	VARCHAR(200))
sp: BEGIN
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
    
    DECLARE lv_CurrentTime DATETIME DEFAULT CURRENT_DATE();
    
	DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    IF (IFNULL(ip_SubscriberID, 0) = 0) THEN
		SET op_ErrorMessage = 'Invalid SubscriberID to terminate';
		LEAVE sp;
	END IF;
    
	#========= TERMINATE SUBSCRIBER =========
    UPDATE 	CTS_Admin.Subscriber AS sub
	SET		sub.TerminatedDate = lv_CurrentTime
		,	sub.SubscriberStatus = -1
    WHERE sub.SubscriberID = ip_SubscriberID;
    
    #========= TERMINATE ALL SITE MAPPINGS =========
    UPDATE 	CTS_DataCenter.MappingSubscriberSite AS map
	SET		map.SubscriberStatus = -1
    WHERE map.SubscriberID = ip_SubscriberID;

	INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
	SELECT	26
	,	lv_SPName
	,	CONCAT('Terminate subscriber: SubID_', SubscriberID, '; SubName_', SubscriberName, '; SubPrefix_', SubscriberPrefix, '; SubType_', SubscriberType, '; IsTest_', IsTest)
	,	lv_CurrentTime
	,	ip_UserID
	FROM CTS_Admin.Subscriber
	WHERE SubscriberID = IFNULL(ip_SubscriberID, 0);

END$$

DELIMITER ;