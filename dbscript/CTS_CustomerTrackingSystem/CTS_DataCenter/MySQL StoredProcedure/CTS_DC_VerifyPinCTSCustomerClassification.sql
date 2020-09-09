USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_VerifyPinCTSCustomerClassification`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_VerifyPinCTSCustomerClassification`(
	    IN ip_CustID            INT UNSIGNED	
    ,   IN ip_CTSCustID			BIGINT UNSIGNED	
    ,	IN ip_SubscriberID		INT
	,	IN ip_CreatedBy 		INT
    ,   IN ip_IsPinCategory     BIT -- 0: Unpin, 1: Pin
    
    , 	OUT op_ErrorMessage 	VARCHAR(200)
)
sp: BEGIN
	/*
		Created:	20200908@Irena.Vo
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200909@Irena.Vo [Redmine ID: #141020]: Verify Pin Category
		Param's Explanation:
	*/ 
    DECLARE lv_CurrentTime DATETIME;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
	SET lv_CurrentTime = CURRENT_TIME();
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET SQL_SAFE_UPDATES = 0;
    
    -- Verify Pin category.
    IF (ip_IsPinCategory = 1) THEN
		-- Insert data with CustomerClass = -99 and CreatedFromFunction = 21
		INSERT INTO CTS_DataCenter.SpecialCustomerClass(CTSCustID, CustID, RootCTSCustID, SubscriberID, CreatedBy, CreatedDate, LastModifiedBy, LastModifiedDate, CreatedFromFunction)
		SELECT 	    ip_CTSCustID
				,	ip_CustID
				,	ip_CTSCustID
				,	ip_SubscriberID
				,	ip_CreatedBy
				,	lv_CurrentTime
				,   ip_CreatedBy
				,	lv_CurrentTime
				,   21; -- Pin  
		-- Insert log      
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(21, 'CTS_DC_VerifyPinCTSCustomerClassification', CONCAT('Pin CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentTime, ip_CreatedBy);
	END IF;   
    -- Verify Unpin category.
	IF (ip_IsPinCategory = 0) THEN 
        -- Remove CustomerClass after Unpin
		DELETE sc
		FROM CTS_DataCenter.SpecialCustomerClass AS sc
		WHERE sc.CTSCustID = ip_CTSCustID AND sc.CreatedFromFunction = 21;
		-- Insert log
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(22, 'CTS_DC_VerifyPinCTSCustomerClassification', CONCAT('Unpin CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentTime, ip_CreatedBy);
    END IF;   
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
END$$

DELIMITER ;