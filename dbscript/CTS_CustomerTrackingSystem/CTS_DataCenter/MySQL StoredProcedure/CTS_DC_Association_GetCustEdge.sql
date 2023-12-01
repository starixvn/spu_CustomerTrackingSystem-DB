/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb,ctsAPI" isFunction="0" isNested="1"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_GetCustEdge`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetCustEdge`(
		IN	ip_CustJson 		JSON
	,   IN  ip_HasDevice		BIT
    ,   IN  ip_HasAI			BIT
    ,   IN  ip_HasIP			BIT
)
    SQL SECURITY INVOKER
BEGIN 
	/*  
		Created:	20231117@Victoria.Le
		Task:		Enhance Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20231117@Victoria.Le: Initial Writing - Renovate Association Detection [Redmine ID: #192172]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_Association_GetCustEdge('1,2,3',1,0,0);
	*/
	DECLARE CONST_ASSTYPE_BETTINGPATTERN 	INT DEFAULT 2;
	DECLARE CONST_ASSBYAI_ACTIVESTATUS 		INT DEFAULT 1;    
    DECLARE CONST_ASSTYPE_IP 				INT DEFAULT 4;
	DECLARE CONST_ASSBYIP_ACTIVESTATUS 		INT DEFAULT 1; 
	#=============================================================================
	
	DROP TEMPORARY TABLE IF EXISTS Temp_CustNode;
	CREATE TEMPORARY TABLE 	Temp_CustNode (
			CTSCustID 			BIGINT  PRIMARY KEY 
		,	CustID   			BIGINT	
		,	INDEX IX_Temp_CustNode(CustID)
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Graph;
    CREATE TEMPORARY TABLE 	Temp_Graph (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
		,	AssociationType		SMALLINT 
		,	PRIMARY KEY(OrigID,DestID)
	);

	DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByAI_AssType;
	CREATE TEMPORARY TABLE 	Temp_AssociationByAI_AssType (
			AssTypeItemValue INT PRIMARY KEY            
	);
	
    DROP TEMPORARY TABLE IF EXISTS Temp_AssociationByIP_AssType;
	CREATE TEMPORARY TABLE 	Temp_AssociationByIP_AssType (
			AssTypeItemValue INT PRIMARY KEY            
	);
	#=============================================================================
	
	INSERT INTO Temp_AssociationByAI_AssType(AssTypeItemValue)
	SELECT atd.AssTypeItemValue
	FROM CTS_DataCenter.AssociationTypeSetting AS atd
	WHERE atd.AssTypeID = CONST_ASSTYPE_BETTINGPATTERN AND atd.AssTypeItemStatus = CONST_ASSBYAI_ACTIVESTATUS; 
	
	INSERT INTO Temp_AssociationByIP_AssType(AssTypeItemValue)
    SELECT atd.AssTypeItemValue
    FROM CTS_DataCenter.AssociationTypeSetting AS atd
    WHERE atd.AssTypeID = CONST_ASSTYPE_IP AND atd.AssTypeItemStatus = CONST_ASSBYIP_ACTIVESTATUS; 
	#=============================================================================
	
	INSERT IGNORE INTO Temp_CustNode(CTSCustID, CustID)
	SELECT 	js.CTSCustID
		, 	js.CustID
	FROM JSON_TABLE(ip_CustJson,
					 "$[*]" COLUMNS(
										CTSCustID 		BIGINT 		PATH "$.CTSCustID"
									,	CustID 			BIGINT 		PATH "$.CustID")) AS js;
    
	/*******************AssociationType = 1 >> Device*************************/
    IF ip_HasDevice = 1 THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_DeviceEdge1;
		CREATE TEMPORARY TABLE 		Temp_DeviceEdge1 (
				CTSCustID		BIGINT 
			,	DCSDeviceID		BIGINT 
			,	PRIMARY KEY	(CTSCustID, DCSDeviceID)
            ,	INDEX IX_Temp_DeviceEdge1_DCSDeviceID(DCSDeviceID)
		);
        
        DROP TEMPORARY TABLE IF EXISTS Temp_DeviceEdge2;
		CREATE TEMPORARY TABLE 		Temp_DeviceEdge2 (
				CTSCustID		BIGINT 
			,	DCSDeviceID		BIGINT 
			,	PRIMARY KEY	(CTSCustID, DCSDeviceID)
            ,	INDEX IX_Temp_DeviceEdge2_DestID(DCSDeviceID)
		);
		
		INSERT IGNORE INTO Temp_DeviceEdge1(CTSCustID, DCSDeviceID)
		SELECT 	cus.CTSCustID
			,	dv.DCSDeviceID
		FROM Temp_CustNode AS tmp
			INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON tmp.CTSCustID =  dv.CTSCustID;

		INSERT IGNORE INTO Temp_DeviceEdge2(CTSCustID, DCSDeviceID)
		SELECT DISTINCT 
				cus.CTSCustID
			,	dv.DCSDeviceID
		FROM Temp_DeviceEdge1 AS tmp
			INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.DCSDeviceID = tmp.DCSDeviceID 
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON dv.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;
        
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
		SELECT  LEAST(tmp1.CTSCustID,tmp2.CTSCustID) AS OrigID
			, 	GREATEST(tmp1.CTSCustID,tmp2.CTSCustID) AS DestID
			,	1 AS AssociationType
		FROM Temp_DeviceEdge1 AS tmp1
			INNER JOIN Temp_DeviceEdge2 AS tmp2 ON tmp1.DCSDeviceID = tmp2.DCSDeviceID;
	END IF;
	
    /*******************AssociationType = 3 >> AI*************************/
    IF ip_HasAI = 1 THEN
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
		SELECT  tmp.CTSCustID AS OrigID
			, 	cus.CTSCustID AS DestID
			,	3 AS AssociationType
		FROM Temp_CustNode AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmp.CustID 
																AND ai.AssType IN (SELECT tmpAt.AssTypeItemValue 
																					FROM Temp_AssociationByAI_AssType AS tmpAt)
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
			
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
		SELECT  tmp.CTSCustID AS OrigID
			, 	cus.CTSCustID AS DestID
			,	3 AS AssociationType
		FROM Temp_CustNode AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = tmp.CustID 
																AND ai.AssType IN (SELECT tmpAt.AssTypeItemValue 
																					FROM Temp_AssociationByAI_AssType AS tmpAt)
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.FromCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
		
		/*******************AssociationType = 4 >> Group AI*************************/
		DROP TEMPORARY TABLE IF EXISTS Temp_GroupEdge1;
		CREATE TEMPORARY TABLE 		Temp_GroupEdge1 (
				CustID			BIGINT 
			,	CTSCustID		BIGINT 
			,	GroupID			BIGINT 
			,	PRIMARY KEY	(CustID, CTSCustID, GroupID)
            ,	INDEX IX_Temp_GroupEdge1_GroupID(GroupID)
		);
		
        DROP TEMPORARY TABLE IF EXISTS Temp_GroupEdge2;
		CREATE TEMPORARY TABLE 		Temp_GroupEdge2 (
				CustID			BIGINT 
			,	CTSCustID		BIGINT 
			,	GroupID			BIGINT 
			,	PRIMARY KEY	(CustID, CTSCustID, GroupID)
             ,	INDEX IX_Temp_GroupEdge2_GroupID(GroupID)
		);
		
		INSERT IGNORE INTO Temp_GroupEdge1(CustID, CTSCustID, GroupID)
		SELECT DISTINCT
				cus.CustID
			,	cus.CTSCustID
			, 	asg.GroupID
		FROM Temp_CustNode AS tmp 
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON asg.CustID = tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = asg.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
		
		INSERT IGNORE INTO Temp_GroupEdge2(CustID, CTSCustID, GroupID)
		SELECT DISTINCT
				cus.CustID
			,	cus.CTSCustID
			, 	asg.GroupID
		FROM Temp_GroupEdge1 AS tmp 
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON asg.GroupID = tmp.GroupID AND asg.CustID != tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = asg.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
		
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
		SELECT  LEAST(tmp1.CTSCustID,tmp2.CTSCustID) AS OrigID
			, 	GREATEST(tmp1.CTSCustID,tmp2.CTSCustID) AS DestID
			,	4 AS AssociationType
		FROM Temp_GroupEdge1 AS tmp1
			INNER JOIN Temp_GroupEdge2 AS tmp2 ON tmp1.GroupID = tmp2.GroupID;
		
	END IF;
		
	/*******************AssociationType = 5 >> IP*************************/
	IF ip_HasIP = 1 THEN
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
		SELECT  tmp.CTSCustID AS OrigID
			, 	cus.CTSCustID AS DestID
			,	5 AS AssociationType
		FROM Temp_CustNode AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmp.CustID 
																AND ip.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByIP_AssType AS tmpAt)
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
			
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
		SELECT  tmp.CTSCustID AS OrigID
			, 	cus.CTSCustID AS DestID
			,	5 AS AssociationType
		FROM Temp_CustNode AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmp.CustID 
																AND ip.AssType IN (SELECT tmpAt.AssTypeItemValue FROM Temp_AssociationByIP_AssType AS tmpAt)
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.FromCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
		
	END IF;
	
END$$

DELIMITER ;