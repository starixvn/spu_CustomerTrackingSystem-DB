/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsServiceAdmin,ctsAPIAdmin" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_CustClassification_Queue_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_Queue_Get`(
		OUT op_QueueID					BIGINT UNSIGNED
	,	OUT op_LastDownlineCTSCustID 	BIGINT UNSIGNED
	,	OUT op_ActionType				TINYINT
    ,	OUT op_UplineRoleID				TINYINT
)
    SQL SECURITY INVOKER
BEGIN
	/* 
		Created:	20220601@Casey.Huynh	
		Task :		Renovate PA Process [Redmine ID: #172061]
		DB:			CTS_DataCenter
		Original: 
 
		Revisions:
			- 20220601@Casey.Huynh: Created [Redmine ID: #172061]

		Param's Explanation:
        
        Example: CALL CTS_DC_CustClassification_Queue_Get(@op_QueueID,@op_LastDownlineCTSCustID,@op_ActionType,@op_UplineRoleID); select @op_QueueID,@op_LastDownlineCTSCustID,@op_ActionType,@op_UplineRoleID;
	*/ 
	DECLARE lv_BatchSize				INT;
    DECLARE lv_QueueID					BIGINT UNSIGNED;
    DECLARE lv_LastDownlineCTSCustID 	BIGINT UNSIGNED;
    DECLARE lv_ActionType				TINYINT; #1: INSERT VVIP, 2:Remove VVIP, 3:INSERT PA, 4: UNMARK PA
    
	DECLARE lv_CTSCustID				BIGINT UNSIGNED;
    DECLARE lv_CustID					BIGINT UNSIGNED;
    DECLARE lv_SubscriberID				INT UNSIGNED;
    DECLARE lv_RoleID					TINYINT;
    
    
	DECLARE lv_CategoryID				INT;
    DECLARE lv_CategoryGroup			INT;
    
    DECLARE lv_CreatedBy 				INT;
    DECLARE lv_Remark 					VARCHAR(500);
	
    DECLARE lv_IsExceptDirectDownline 	TINYINT(1);
    DECLARE lv_IsFromTVS 				TINYINT(1);
    DECLARE lv_IsFromTW 				TINYINT(1);
    DECLARE lv_IsFromCTS 				TINYINT(1);
    DECLARE lv_TVSRequestID             BIGINT;

    SELECT sys.ParameterValue
    INTO lv_BatchSize
    FROM SystemParameter AS sys
    WHERE sys.ParameterID = 91;
    
    #=========GET QUEUE Info====================================
    SELECT 	que.ID, que.LastDownlineCTSCustID, que.ActionType
    
		,   que.CTSCustID, que.CustID, que.SubscriberID, que.RoleID
        
		, 	IFNULL(que.CategoryID,-1) AS CategoryID, IFNULL(que.CategoryGroup,-1) AS CategoryGroup
        
        , 	que.CreatedBy, IFNULL(que.Remark,'') AS Remark
        
        , 	IFNULL(que.IsExceptDirectDownline,0) AS IsExceptDirectDownline, que.IsFromTVS, que.IsFromTW, que.IsFromCTS, IFNULL(que.TVSRequestID,-1) AS TVSRequestID
    INTO 	lv_QueueID, lv_LastDownlineCTSCustID, lv_ActionType
		
        , 	lv_CTSCustID, lv_CustID , lv_SubscriberID, lv_RoleID
        
        , 	lv_CategoryID, lv_CategoryGroup
        
        , 	lv_CreatedBy, lv_Remark
        
        ,	lv_IsExceptDirectDownline, lv_IsFromTVS, lv_IsFromTW, lv_IsFromCTS, lv_TVSRequestID
    FROM CTS_DataCenter.CTSCustomerClassificationQueue AS que
    ORDER BY ID ASC
    LIMIT 1;    
	
    #====== Super RoleID = 4 Get By SRecommend===============
    IF lv_RoleID = 4 THEN
		SET @sqlstr = CONCAT('
		SELECT @gv_CTSCustID:=cus.CTSCustID AS CTSCustID
			,	cus.CustID AS CustID
            ,	cus.SubscriberID
            ,	cus.RoleID 
            ,	cus.IsLicensee
            
            ,	',lv_CategoryID,' AS CategoryID
            ,	',lv_CategoryGroup,' AS CategoryGroup
            
            ,	',lv_CreatedBy,' AS CreatedBy
            ,	"',lv_Remark,'" AS Remark
            
            ,	',lv_IsExceptDirectDownline,' AS IsExceptDirectDownline
            ,	',lv_IsFromTVS,' AS IsFromTVS
            ,	',lv_IsFromTW,' AS IsFromTW
            ,	',lv_IsFromCTS,' AS IsFromCTS
            ,	',lv_TVSRequestID,' AS TVSRequestID
   
            ,	',lv_LastDownlineCTSCustID,' AS LastDownlineCTSCustID
		FROM CTS_DataCenter.CTSCustomer AS cus USE INDEX(IX_CTSCustomer_SRecommend)
		WHERE CustSubID = 0 AND cus.SRecommend = ',lv_CustID,' AND cus.CTSCustID > ',lv_LastDownlineCTSCustID,' AND cus.RoleID != ', lv_RoleID,'
        ORDER BY cus.CTSCustID ASC
        LIMIT ',lv_BatchSize);
	
        PREPARE stmt1 FROM @sqlstr;
		EXECUTE stmt1;

    END IF;
	
    #====== Master RoleID = 3 Get By MRecommend===============
    IF lv_RoleID = 3 THEN 
		SET @sqlstr = CONCAT('
		SELECT @gv_CTSCustID:=cus.CTSCustID AS CTSCustID
			,	cus.CustID AS CustID
            ,	cus.SubscriberID
            ,	cus.RoleID 
            ,	cus.IsLicensee
            
            ,	',lv_CategoryID,' AS CategoryID
            ,	',lv_CategoryGroup,' AS CategoryGroup
            
            ,	',lv_CreatedBy,' AS CreatedBy
            ,	"',lv_Remark,'" AS Remark
            
            ,	',lv_IsExceptDirectDownline,' AS IsExceptDirectDownline
            ,	',lv_IsFromTVS,' AS IsFromTVS
            ,	',lv_IsFromTW,' AS IsFromTW
            ,	',lv_IsFromCTS,' AS IsFromCTS
            ,	',lv_TVSRequestID,' AS TVSRequestID
   
            ,	',lv_LastDownlineCTSCustID,' AS LastDownlineCTSCustID
		FROM CTS_DataCenter.CTSCustomer AS cus USE INDEX(IX_CTSCustomer_MRecommend)
		WHERE CustSubID = 0 AND cus.MRecommend = ',lv_CustID,' AND cus.CTSCustID > ',lv_LastDownlineCTSCustID,' AND cus.RoleID != ', lv_RoleID,'
        ORDER BY cus.CTSCustID ASC
        LIMIT ',lv_BatchSize);
        
        PREPARE stmt1 FROM @sqlstr;
		EXECUTE stmt1;
    END IF;
    
    #====== Agent RoleID = 2 GET by Recommend===============
    IF lv_RoleID = 2 THEN 
		SET @sqlstr = CONCAT('
		SELECT @gv_CTSCustID:=cus.CTSCustID AS CTSCustID
			,	cus.CustID AS CustID
            ,	cus.SubscriberID
            ,	cus.RoleID 
            ,	cus.IsLicensee
            
            ,	',lv_CategoryID,' AS CategoryID
            ,	',lv_CategoryGroup,' AS CategoryGroup
            
            ,	',lv_CreatedBy,' AS CreatedBy
            ,	"',lv_Remark,'" AS Remark
            
            ,	',lv_IsExceptDirectDownline,' AS IsExceptDirectDownline
            ,	',lv_IsFromTVS,' AS IsFromTVS
            ,	',lv_IsFromTW,' AS IsFromTW
            ,	',lv_IsFromCTS,' AS IsFromCTS
            ,	',lv_TVSRequestID,' AS TVSRequestID
   
            ,	',lv_LastDownlineCTSCustID,' AS LastDownlineCTSCustID
		FROM CTS_DataCenter.CTSCustomer AS cus USE INDEX(IX_CTSCustomer_Recommend)
		WHERE cus.CustSubID = 0 AND cus.Recommend = ',lv_CustID,' AND cus.CTSCustID > ',lv_LastDownlineCTSCustID,' AND cus.RoleID != ', lv_RoleID,'
        ORDER BY cus.CTSCustID ASC
        LIMIT ',lv_BatchSize);
        
		PREPARE stmt1 FROM @sqlstr;
		EXECUTE stmt1;
    END IF;        
    
      
    IF @gv_CTSCustID > lv_LastDownlineCTSCustID THEN    
		SET op_QueueID	= lv_QueueID;
		SET op_LastDownlineCTSCustID = @gv_CTSCustID;
		SET op_ActionType = lv_ActionType; 
		SET op_UplineRoleID = lv_RoleID;      
    ELSE
		SET op_QueueID	= NULL;
		SET op_LastDownlineCTSCustID = NULL;
		SET op_ActionType = NULL; 
		SET op_UplineRoleID = NULL;   
        
		DELETE que
		FROM CTS_DataCenter.CTSCustomerClassificationQueue AS que
        WHERE que.ID = lv_QueueID;
	END IF;
END$$

DELIMITER ;

