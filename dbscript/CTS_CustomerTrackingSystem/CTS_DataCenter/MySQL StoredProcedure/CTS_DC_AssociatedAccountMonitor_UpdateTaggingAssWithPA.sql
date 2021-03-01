/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_AssociatedAccountMonitor_UpdateTaggingAssWithPA`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedAccountMonitor_UpdateTaggingAssWithPA`(IN ip_CustID int,IN ip_CTSCustID bigint,IN ip_SubscriberID int,IN ip_CreatedBy int,IN ip_IsExcludedTagAssPA bit,OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20210226@Jonas.Huynh
		Task :		Insert/Remove Mark Tagging By Association With PA
		DB:			CTS_DataCenter
		Original: 
		Revisions:
            - 20210226@Jonas.Huynh: Created  [RedmineID: #150454]
           
		Param's Explanation:
	*/ 
    DECLARE lv_CurrentDateTime DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_AssociatedAccountMonitor_UpdateTaggingAssWithPA'; 
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    -- Insert Tagging Associated Exclusion With PA.
    IF (ip_IsExcludedTagAssPA = 1) THEN
		INSERT INTO CTS_DataCenter.TaggingExclusion(CustID, CreatedTime) 
		SELECT 	    ip_CustID,	lv_CurrentDateTime;
		 
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(30, lv_SPName, CONCAT('Unmark Tagging By Association With PA: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentDateTime, ip_CreatedBy);
    END IF;   
    
    -- Remove Tagging Associated Exclusion With PA.
	IF (ip_IsExcludedTagAssPA = 0) THEN 
		DELETE tagging
		FROM CTS_DataCenter.TaggingExclusion AS tagging
		WHERE tagging.CustID = ip_CustID;
		
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(31, lv_SPName, CONCAT('Mark Tagging By Association With PA: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentDateTime, ip_CreatedBy);
    END IF; 
    
END$$

DELIMITER ;