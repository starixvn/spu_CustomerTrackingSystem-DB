/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedAccountMonitor_VerifyPin`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedAccountMonitor_VerifyPin`(
		IN ip_CustID			INT
	,	IN ip_CTSCustID			BIGINT UNSIGNED
	,	IN ip_SubscriberID		INT
	,	IN ip_CreatedBy			INT
	,	IN ip_IsPinCategory		BIT
	
	,	OUT op_ErrorMessage		VARCHAR(200)
)
    SQL SECURITY INVOKER
sp: BEGIN
	/*
		Created:	20200908@Irena.Vo
		Task :		Insert CTSCustomer Category
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200909@Irena.Vo [Redmine ID: #141020]: Verify Pin Category
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
			- 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
			
		Param's Explanation:
	*/ 
    DECLARE lv_CurrentTime DATETIME DEFAULT CURRENT_TIME();
    DECLARE lv_SPName VARCHAR(200) DEFAULT 'CTS_DC_AssociatedAccountMonitor_VerifyPin'; 
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN         
        GET DIAGNOSTICS CONDITION 1 op_ErrorMessage = MESSAGE_TEXT;
    END;
    
    # Verify Pin category.
    IF (ip_IsPinCategory = 1) THEN
		# Insert data with CustomerClass = -99 and CreatedFromFunction = 21
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

		# Insert log      
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(21, lv_SPName, CONCAT('Pin CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentTime, ip_CreatedBy);
    END IF;   
    
    # Verify Unpin category.
	IF (ip_IsPinCategory = 0) THEN 
        # Remove CustomerClass after Unpin
		DELETE sc
		FROM CTS_DataCenter.SpecialCustomerClass AS sc
		WHERE sc.CustID = ip_CustID AND sc.CreatedFromFunction = 21;

		# Insert log
		INSERT INTO CTS_Admin.UserLog(LogTypeID, SPName, LogInfo, CreatedDate, CreatedBy)
		VALUES(22, lv_SPName, CONCAT('Unpin CTSCustomerClassification: ip_CTSCustID_', ip_CTSCustID, ';ip_SubscriberID_', ip_SubscriberID), lv_CurrentTime, ip_CreatedBy);
    END IF; 
    
END$$	
DELIMITER ;