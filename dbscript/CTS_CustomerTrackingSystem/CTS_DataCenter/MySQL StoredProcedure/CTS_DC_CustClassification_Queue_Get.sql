/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_Queue_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustClassification_Queue_Get`(   
)
    SQL SECURITY INVOKER 
BEGIN
	/*
		Created:	20220418@Casey.Huynh	
		Task :		Insert CustClassificationDownline
		DB:			CTS_DataCenter
		Original: 

		Revisions:
			- 20220418@Casey.Huynh: Add and Remove VVIP for Downline [Redmine ID: #159013]

		Param's Explanation:
        
        Example: CALL CTS_DC_CustClassificationQueue_Get();
	*/ 
	DECLARE lv_BatchSize		INT;
    DECLARE lv_QueueID			BIGINT UNSIGNED;
    DECLARE lv_CustID			BIGINT UNSIGNED;
    DECLARE lv_CTSCustID		BIGINT UNSIGNED;
    DECLARE lv_SubscriberID		INT UNSIGNED;
	DECLARE lv_CategoryID		SMALLINT;
    DECLARE lv_Remark 			VARCHAR(300);
	DECLARE lv_CreatedBy 		INT;
    DECLARE lv_RoleID			TINYINT;
    DECLARE lv_ActionType		TINYINT;
    DECLARE lv_LastDownlineCTSCustID BIGINT UNSIGNED;
    
    #===========================================================
    SELECT sys.ParameterValue
    INTO lv_BatchSize
    FROM SystemParameter AS sys
    WHERE sys.ParameterID = 91;
    
    #=========GET QUEUE Info====================================
    SELECT que.ID, que.CTSCustID, que.CustID, que.RoleID, que.SubscriberID, que.CreatedBy, que.Remark, que.CategoryID, que.LastDownlineCTSCustID, que.ActionType
    INTO lv_QueueID, lv_CTSCustID, lv_CustID, lv_RoleID, lv_SubscriberID, lv_CreatedBy, lv_Remark, lv_CategoryID, lv_LastDownlineCTSCustID, lv_ActionType
    FROM CTS_DataCenter.CTSCustomerClassificationDownlineQueue AS que
    ORDER BY ID ASC
    LIMIT 1;    

    #====== Super RoleID = 4 Get By SRecommend===============
    IF lv_RoleID = 4 THEN
		SELECT @gv_CTSCustID:=cus.CTSCustID AS CTSCustID
			,	cus.CustID AS CustID
            ,	lv_SubscriberID AS SubscriberID
            ,	lv_CreatedBy AS CreatedBy
            ,	lv_Remark AS Remark
            ,	lv_CategoryID AS CategoryID
            ,	lv_LastDownlineCTSCustID AS LastDownlineCTSCustID
		FROM CTS_DataCenter.CTSCustomer AS cus
		WHERE cus.CustID <> lv_CustID AND CustSubID = 0 AND cus.SRecommend = lv_CustID AND cus.CTSCustID > lv_LastDownlineCTSCustID
        ORDER BY cus.CTSCustID ASC
        LIMIT lv_BatchSize;
    END IF;
	
    #====== Master RoleID = 3 Get By MRecommend===============
    IF lv_RoleID = 3 THEN 
		SELECT 	@gv_CTSCustID:=cus.CTSCustID AS CTSCustID
			,	cus.CustID AS CustID
            ,	lv_SubscriberID AS SubscriberID
            ,	lv_CreatedBy AS CreatedBy
            ,	lv_Remark AS Remark
            ,	lv_CategoryID AS CategoryID
            ,	lv_LastDownlineCTSCustID AS LastDownlineCTSCustID
		FROM CTS_DataCenter.CTSCustomer AS cus
		WHERE cus.CustID <> lv_CustID AND CustSubID = 0 AND cus.MRecommend = lv_CustID AND cus.CTSCustID > lv_LastDownlineCTSCustID
        ORDER BY cus.CTSCustID ASC
        LIMIT lv_BatchSize;
    END IF;
    
    #====== Agent RoleID = 2 GET by Recommend===============
    IF lv_RoleID = 2 THEN 
		SELECT	@gv_CTSCustID:=cus.CTSCustID AS CTSCustID
			,	cus.CustID AS CustID
            ,	lv_SubscriberID AS SubscriberID
            ,	lv_CreatedBy AS CreatedBy
            ,	lv_Remark AS Remark
            ,	lv_CategoryID AS CategoryID
            ,	lv_LastDownlineCTSCustID AS LastDownlineCTSCustID
		FROM CTS_DataCenter.CTSCustomer AS cus
		WHERE cus.CustID <> lv_CustID AND CustSubID = 0 AND cus.Recommend = lv_CustID AND cus.CTSCustID > lv_LastDownlineCTSCustID
        ORDER BY cus.CTSCustID ASC
        LIMIT lv_BatchSize;
    END IF;    
  
    IF @gv_CTSCustID > lv_LastDownlineCTSCustID THEN
		SELECT	lv_ActionType AS ActionType
			,	lv_RoleID AS UplineRoleID
            , 	lv_QueueID AS QueueID;
    ELSE
		SELECT NULL AS ActionType, NULL AS RoleID;
		DELETE que
		FROM CTS_DataCenter.CTSCustomerClassificationDownlineQueue AS que
        WHERE que.ID = lv_QueueID;
	END IF;
    
END$$
DELIMITER ;