/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_AssociatedGroup_Scan`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociatedGroup_Scan`(
		OUT	op_GroupID			BIGINT
	,	OUT	op_ABI				INT
    ,	OUT op_LastCTSCustID	BIGINT
)
    SQL SECURITY INVOKER
sp : BEGIN
	/* 
		Created:	20220705@Aries.Nguyen
		Task:		[CTS] Fraud Group Management [Redmine ID: #167748]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220705@Aries.Nguyen: Created [Redmine ID: #167748]
        
		Param's Explanation (filtered by):
	*/
    DECLARE lv_BatchSize 		BIGINT;
    DECLARE lv_LastGroupID 		BIGINT;
    DECLARE lv_LastCTSCustID 	BIGINT;
    
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 		Temp_Cust (
			CTSCustID 			BIGINT UNSIGNED PRIMARY KEY
		,	CustID 				BIGINT UNSIGNED
		,	AddGroupDate 		DATETIME
        ,	INDEX 				IX_Temp_Cust_CustID(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustDetected;
	CREATE TEMPORARY TABLE 		Temp_CustDetected (
			CTSCustID 			BIGINT UNSIGNED PRIMARY KEY
		,  	CustID 				BIGINT UNSIGNED 
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Device;
	CREATE TEMPORARY TABLE 	Temp_Device (
			DCSDeviceID			BIGINT PRIMARY KEY
		,	AddGroupDate 		DATETIME	
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AIGroup;
	CREATE TEMPORARY TABLE 	Temp_AIGroup (
			GroupID				BIGINT UNSIGNED PRIMARY KEY
		,	AddGroupDate 		DATETIME
	);
    
	SELECT ParameterValue 
    INTO lv_BatchSize 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 97;
    
    SELECT ParameterValue 
    INTO lv_LastGroupID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 98;
    
    SELECT ParameterValue 
    INTO lv_LastCTSCustID 
    FROM CTS_DataCenter.SystemParameter 
    WHERE ParameterID = 99;
    
    IF lv_LastGroupID IS NULL OR  lv_LastGroupID = 0 THEN
		SELECT GroupID  
		INTO lv_LastGroupID 
		FROM  CTS_DataCenter.AssociatedGroup
        WHERE IsDisable = 0
		ORDER BY GroupID ASC
        LIMIT 1;
        
        SET lv_LastCTSCustID = 0;
	END  IF;
    
    INSERT INTO Temp_Cust(CTSCustID,CustID,AddGroupDate)
    SELECT 	acc.CTSCustID
		,	cus.CustID
		,	acc.Created
    FROM CTS_DataCenter.AssociatedGroupAccount AS acc
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON acc.CTSCustID = cus.CTSCustID
    WHERE acc.GroupID = lv_LastGroupID 
		AND acc.CTSCustID > lv_LastCTSCustID
	LIMIT lv_BatchSize;
	
    IF NOT EXISTS (SELECT 1 FROM Temp_Cust) THEN
		SELECT 	GroupID  
			,	ABI
		INTO 	op_GroupID
			,	op_ABI
		FROM  CTS_DataCenter.AssociatedGroup
        WHERE IsDisable = 0
			AND GroupID > lv_LastGroupID
		ORDER BY GroupID ASC
        LIMIT 1;
        
		SET op_LastCTSCustID = 0;
        
        LEAVE sp;
    END IF;
    
    /**************************Device*******************************/
    INSERT IGNORE INTO Temp_Device(DCSDeviceID,AddGroupDate)
	SELECT 	dv.DCSDeviceID
		,	MIN(tmp.AddGroupDate) AS AddGroupDate
	FROM Temp_Cust AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON  dv.CTSCustID = tmp.CTSCustID
	GROUP BY dv.DCSDeviceID; 
    
    INSERT IGNORE INTO Temp_CustDetected(CTSCustID,CustID)
    SELECT 	cus.CTSCustID
		,	cus.CustID
    FROM  Temp_Device AS dv
		STRAIGHT_JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON dv.DCSDeviceID = lv1.DCSDeviceID
        STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS tkd ON tkd.CTSCustID = lv1.CTSCustID AND tkd.LastTicketDate >= dv.AddGroupDate 
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = lv1.CTSCustID
    WHERE NOT EXISTS (SELECT 1 
					  FROM AssociatedGroupAccount AS acc 
						INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON acc.GroupID =  ag.GroupID AND ag.IsDisable = 0
                      WHERE lv1.CTSCustID = acc.CTSCustID);
    
    
    /**************************Manual*******************************/
    INSERT IGNORE INTO Temp_CustDetected(CTSCustID,CustID)
	SELECT  cus.CTSCustID
		,	cus.CustID
	FROM Temp_Cust AS tmp 
		STRAIGHT_JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmp.CTSCustID
        STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS tkd ON tkd.CTSCustID = ma.FromCTSCustID AND tkd.LastTicketDate >= tmp.AddGroupDate 
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.FromCTSCustID
	WHERE NOT EXISTS (SELECT 1 
					  FROM AssociatedGroupAccount AS acc 
						INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON acc.GroupID =  ag.GroupID AND ag.IsDisable = 0
                      WHERE ma.FromCTSCustID = acc.CTSCustID);
    
    INSERT IGNORE INTO Temp_CustDetected(CTSCustID,CustID)
	SELECT  cus.CTSCustID
		,	cus.CustID
	FROM Temp_Cust AS tmp 
		STRAIGHT_JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID  = tmp.CTSCustID
        STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS tkd ON tkd.CTSCustID = ma.ToCTSCustID AND tkd.LastTicketDate >= tmp.AddGroupDate
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.ToCTSCustID
	WHERE NOT EXISTS (SELECT 1 
					  FROM AssociatedGroupAccount AS acc
						INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON acc.GroupID =  ag.GroupID AND ag.IsDisable = 0
                      WHERE ma.ToCTSCustID = acc.CTSCustID);
    
    
    /**************************AI*******************************/
    INSERT IGNORE INTO Temp_CustDetected(CTSCustID,CustID)
    SELECT  cus.CTSCustID
		,	cus.CustID
	FROM Temp_Cust AS tmp 
		STRAIGHT_JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmp.CustID
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.ToCustID AND cus.CustSubID = 0
        STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS tkd ON tkd.CTSCustID = cus.CTSCustID AND tkd.LastTicketDate >= tmp.AddGroupDate 
	WHERE NOT EXISTS (SELECT 1 
					  FROM AssociatedGroupAccount AS acc
						INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON acc.GroupID =  ag.GroupID AND ag.IsDisable = 0
                      WHERE cus.CTSCustID = acc.CTSCustID);
    
    INSERT IGNORE INTO Temp_CustDetected(CTSCustID,CustID)
    SELECT  cus.CTSCustID
		,	cus.CustID
	FROM Temp_Cust AS tmp 
		STRAIGHT_JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = tmp.CustID
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.FromCustID AND cus.CustSubID = 0
        STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS tkd ON tkd.CTSCustID = cus.CTSCustID AND tkd.LastTicketDate >= tmp.AddGroupDate 
	WHERE NOT EXISTS (SELECT 1 
					  FROM AssociatedGroupAccount AS acc 
						INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON acc.GroupID =  ag.GroupID AND ag.IsDisable = 0
                      WHERE cus.CTSCustID = acc.CTSCustID);
    
    /**************************AI Group*******************************/
    INSERT IGNORE INTO Temp_AIGroup(GroupID,AddGroupDate)
	SELECT asg.GroupID 
		,	MIN(tmp.AddGroupDate) AS AddGroupDate
	FROM Temp_Cust AS tmp 
		INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON  asg.CustID = tmp.CustID
	GROUP BY asg.GroupID; 
	
    INSERT IGNORE INTO Temp_CustDetected(CTSCustID,CustID)
    SELECT 	cus.CTSCustID
		,	cus.CustID
    FROM  Temp_AIGroup AS gp
		STRAIGHT_JOIN CTS_DataCenter.AssociationGroupByAI AS lv1 ON gp.GroupID = lv1.GroupID
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = lv1.CustID AND cus.CustSubID = 0
        STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS tkd ON tkd.CTSCustID = cus.CTSCustID AND tkd.LastTicketDate >= gp.AddGroupDate 
    WHERE NOT EXISTS (SELECT 1 
					  FROM AssociatedGroupAccount AS acc
						INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON acc.GroupID =  ag.GroupID AND ag.IsDisable = 0
                      WHERE cus.CTSCustID = acc.CTSCustID);
    
    /**************************IP*******************************/
    
    INSERT IGNORE INTO Temp_CustDetected(CTSCustID,CustID)
    SELECT  cus.CTSCustID
		,	cus.CustID
	FROM Temp_Cust AS tmp 
		STRAIGHT_JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmp.CustID
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.ToCustID AND cus.CustSubID = 0
        STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS tkd ON tkd.CTSCustID = cus.CTSCustID AND tkd.LastTicketDate >= tmp.AddGroupDate 
	WHERE NOT EXISTS (SELECT 1 
					  FROM AssociatedGroupAccount AS acc 
						INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON acc.GroupID =  ag.GroupID AND ag.IsDisable = 0
                      WHERE cus.CTSCustID = acc.CTSCustID);
    
    INSERT IGNORE INTO Temp_CustDetected(CTSCustID,CustID)
    SELECT  cus.CTSCustID
		,	cus.CustID
	FROM Temp_Cust AS tmp 
		STRAIGHT_JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmp.CustID
        STRAIGHT_JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.FromCustID AND cus.CustSubID = 0
        STRAIGHT_JOIN CTS_Archive.CTSCustomerAssociationStatus AS tkd ON tkd.CTSCustID = cus.CTSCustID AND tkd.LastTicketDate >= tmp.AddGroupDate 
	WHERE NOT EXISTS (SELECT 1 
					  FROM AssociatedGroupAccount AS acc 
						INNER JOIN CTS_DataCenter.AssociatedGroup AS ag ON acc.GroupID =  ag.GroupID AND ag.IsDisable = 0
                      WHERE cus.CTSCustID = acc.CTSCustID);

    
    SELECT MAX(CTSCustID)
    INTO op_LastCTSCustID
    FROM Temp_Cust;
    
    SET op_GroupID = lv_LastGroupID;
    
    SELECT ABI  
    INTO op_ABI
	FROM  CTS_DataCenter.AssociatedGroup
    WHERE GroupID = lv_LastGroupID
	LIMIT 1;
    
    SELECT 	CTSCustID
		,	CustID
    FROM Temp_CustDetected;
END$$
DELIMITER ;