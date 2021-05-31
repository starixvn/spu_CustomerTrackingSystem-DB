/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_AssociatedAccountMonitor_UpdatePin`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_AssociatedAccountMonitor_UpdatePin`(
		IN ip_CTSCustID 		BIGINT
    ,	IN ip_SubscriberID 		INT
    ,	IN ip_CreatedBy 		INT
    ,	IN ip_IsPinCategory 	BIT
    
    ,	OUT op_ErrorMessage 	VARCHAR(200)
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20201014@Irena.Vo
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20201214-20201229@Irena.Vo: Add logic insert Pin/Unpin. Update logic SP. Update param name  [RedmineID: #145951]
            - 20210525@Irena.Vo: Change col name PinCustomerCategory: CustID -> CTSCustID [RedmineID: #152965]
		Param's Explanation:
	*/ 
    DECLARE lv_CurrentDateTime 	DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_SPName 			VARCHAR(200) DEFAULT 'CTS_DC_AssociatedAccountMonitor_UpdatePin'; 
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    /*Verify Pin category.*/
    IF (ip_IsPinCategory = 1) THEN
		INSERT INTO CTS_DataCenter.PinCustomerCategory(CTSCustID, CreatedTime) 
		SELECT ip_CTSCustID, lv_CurrentDateTime;
		 
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(21, lv_SPName, CONCAT('Pin CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentDateTime, ip_CreatedBy);
    END IF;   
    
    /*Verify Unpin category.*/
	IF (ip_IsPinCategory = 0) THEN 
		DELETE 	pin
		FROM 	CTS_DataCenter.PinCustomerCategory AS pin
		WHERE 	pin.CTSCustID = ip_CTSCustID;
		
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(22, lv_SPName, CONCAT('Unpin CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentDateTime, ip_CreatedBy);
    END IF; 
END$$
DELIMITER ;