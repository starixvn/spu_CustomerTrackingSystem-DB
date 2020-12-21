/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_AssociatedAccountMonitor_UpdatePin`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedAccountMonitor_UpdatePin`(IN ip_CustID int,IN ip_CTSCustID bigint,IN ip_SubscriberID int,IN ip_CreatedBy int,IN ip_IsPinCategory bit,OUT op_ErrorMessage varchar(200))
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20201014@Irena.Vo
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
            - 20201214@Irena.Vo: Add logic insert Pin/Unpin  [RedmineID: #145951]
            - 20201221@Irena.Vo: Update logic SP  [RedmineID: #145951]
            
		Param's Explanation:
	*/ 
    DECLARE lv_CurrentTime DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_AssociatedAccountMonitor_UpdatePin'; 
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    -- Verify Pin category.
    IF (ip_IsPinCategory = 1) THEN
		INSERT INTO CTS_DataCenter.PinCustomerCategory(CustID, CreatedTime) 
		SELECT 	    ip_CustID,	lv_CurrentTime;
		 
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(21, lv_SPName, CONCAT('Pin CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentTime, ip_CreatedBy);
    END IF;   
    
    -- Verify Unpin category.
	IF (ip_IsPinCategory = 0) THEN 
		DELETE pin
		FROM CTS_DataCenter.PinCustomerCategory AS pin
		WHERE pin.CustID = ip_CustID;
		
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(22, lv_SPName, CONCAT('Unpin CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentTime, ip_CreatedBy);
    END IF; 
    
END$$

DELIMITER ;