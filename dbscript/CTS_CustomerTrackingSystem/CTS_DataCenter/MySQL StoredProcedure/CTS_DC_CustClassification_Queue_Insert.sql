/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Queue_Insert`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_Queue_Insert`(    	
     	IN ip_CTSCustID			BIGINT UNSIGNED
    ,	IN ip_CustID			BIGINT UNSIGNED
    ,	IN ip_SubscriberID		INT
	,	IN ip_CategoryID		SMALLINT
    , 	IN ip_Remark 			VARCHAR(300)
	,	IN ip_CreatedBy 		INT
    ,	IN ip_RoleID			TINYINT
    ,	IN ip_ActionType		TINYINT 
)
    SQL SECURITY INVOKER 
BEGIN
	/*
		Created:	20220418@Casey.Huynh	
		Task :		Insert CustClassificationDownline
		DB:			CTS_DataCenter
		Original: 
CTS_DC_CustClassification_Get
		Revisions:
			- 20220418@Casey.Huynh: Add and Remove VVIP for Downline [Redmine ID: #159013]

		Param's Explanation:
        ip_ActionType: 1-Insert, 2-Remove
        
        Example: 
        CALL CTS_DC_CustClassificationQueue_Insert(2998,179747,2,110,'Test Insert',78,3,1);
	*/ 
	
    DECLARE lv_MinCTSCustID		BIGINT UNSIGNED;

    #====== Super RoleID = 4===============
    IF ip_RoleID = 4 THEN 
		SELECT IFNULL(cus.CTSCustID-1, ip_CTSCustID)
        INTO lv_MinCTSCustID
		FROM CTS_DataCenter.CTSCustomer AS cus
		WHERE cus.CustID <> ip_CustID AND CustSubID = 0 AND cus.SRecommend = ip_CustID
        ORDER BY cus.CTSCustID ASC
        LIMIT 1;
    END IF;
	
    #====== Master RoleID = 3===============
    IF ip_RoleID = 3 THEN 
		SELECT IFNULL(cus.CTSCustID-1, ip_CTSCustID)
        INTO lv_MinCTSCustID
		FROM CTS_DataCenter.CTSCustomer AS cus
		WHERE cus.CustID <> ip_CustID AND CustSubID = 0 AND cus.MRecommend = ip_CustID
        ORDER BY cus.CTSCustID ASC
        LIMIT 1;
    END IF;
    
    #====== Agent RoleID = 2===============
    IF ip_RoleID = 2 THEN 
		SELECT IFNULL(cus.CTSCustID-1, ip_CTSCustID)
        INTO lv_MinCTSCustID
		FROM CTS_DataCenter.CTSCustomer AS cus
		WHERE cus.CustID <> ip_CustID AND CustSubID = 0 AND cus.Recommend = ip_CustID
        ORDER BY cus.CTSCustID ASC
        LIMIT 1;
    END IF;

	INSERT INTO CTS_DataCenter.CTSCustomerClassificationDownlineQueue(CTSCustID, CustID, RoleID, SubscriberID, CreatedBy, Remark, CategoryID, LastDownlineCTSCustID, ActionType, InsertTime)
    SELECT ip_CTSCustID, ip_CustID, ip_RoleID, ip_SubscriberID, ip_CreatedBy, ip_Remark, ip_CategoryID, lv_MinCTSCustID AS LastDownlineCTSCustID, ip_ActionType, CURRENT_TIMESTAMP(3);
    
END$$
DELIMITER ;