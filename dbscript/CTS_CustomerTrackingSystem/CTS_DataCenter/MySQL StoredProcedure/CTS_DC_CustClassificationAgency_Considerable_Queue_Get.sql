/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CustClassificationAgency_Considerable_Queue_Get`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassificationAgency_Considerable_Queue_Get`(		
		IN ip_BatchSize INT 
	,	OUT op_LastID BIGINT
)
SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250725@Winfred.Pham
		Task:	 Get Agent cust List and scan Type from Customer Considerable Danger Queue    
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250725@Winfred.Pham: 	Created [Redmine ID: #186799]
                
		Param's Explanation :
        
		Example:
			CALL CTS_DC_CustClassificationAgency_Considerable_Queue_Get(@ip_BatchSize:=100,OUT op_LastID :=@op_LastID);
	*/
    DECLARE lv_MaxScanQueueID	BIGINT UNSIGNED DEFAULT 0;

    SELECT sys.ParameterValue
    INTO lv_MaxScanQueueID
    FROM CTS_DataCenter.SystemParameter AS sys
    WHERE ParameterID = 194;  

    DROP TEMPORARY TABLE IF EXISTS Temp_AgentQueue;
    CREATE TEMPORARY TABLE Temp_AgentQueue(
			ID 			BIGINT 
		,	CustID		BIGINT
		,	ScanType	TINYINT 
    ); 
            
	INSERT IGNORE INTO Temp_AgentQueue (ID, CustID, ScanType) 
	SELECT ID, CustID, ip_ScanType 
	FROM CTS_DataCenter.CustomerConsiderableDangerQueue
	WHERE ID <= lv_MaxScanQueueID
		AND CustID IS NOT NULL
		AND CustID > 0
	ORDER BY ID
	LIMIT ip_BatchSize;   

	SELECT MAX(ID)
    INTO op_LastID
    FROM Temp_AgentQueue AS tAq;

	SELECT DISTINCT tAq.CustID, cus.CTSCustID, cus.RoleID, cus.SubscriberID, cate.CategoryID, cus.IsLicensee, tAq.ScanType
    FROM Temp_AgentQueue AS tAq
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tAq.CustID
        ,LATERAL	(
                        SELECT cls.CustID, cls.ParentID, cls.CategoryID
                        FROM CTS_DataCenter.CTSCustomerClassificationAgency AS cls
                            INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS cate ON cls.CategoryID = cate.CategoryID AND cate.IsActive = 1
                        WHERE cls.CustID = cus.CustID
                        ORDER BY  cate.CustomerClassPriority ASC 
                                , cls.LastModifiedDate DESC
                        LIMIT 1
                    ) AS cate
	WHERE tAq.ScanType = 1;
		
	SELECT DISTINCT tAq.CustID, cus.CTSCustID, cus.RoleID, cus.SubscriberID, cate.CategoryID, cus.IsLicensee, tAq.ScanType
    FROM Temp_AgentQueue AS tAq
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tAq.CustID
        ,LATERAL	(
                        SELECT cls.CustID, cls.ParentID, cls.CategoryID
                        FROM CTS_DataCenter.CTSCustomerClassificationAgency AS cls
                            INNER JOIN CTS_DataCenter.CustomerCategoryAgency AS cate ON cls.CategoryID = cate.CategoryID AND cate.IsActive = 1
                        WHERE cls.CustID = cus.CustID
                        ORDER BY  cate.CustomerClassPriority ASC 
                                , cls.LastModifiedDate DESC
                        LIMIT 1
                    ) AS cate
	WHERE tAq.ScanType = 2 AND 
		NOT EXISTS (SELECT 1 FROM Temp_AgentQueue AS tmp WHERE tmp.CustID = tAq.CustID AND tmp.ScanType = 1);

END$$
DELIMITER ;