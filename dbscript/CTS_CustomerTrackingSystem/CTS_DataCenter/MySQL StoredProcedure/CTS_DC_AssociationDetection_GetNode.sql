/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService,ctsWeb,ctsAPI" isFunction="0" isNested="1"></info>*/

DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_GetNode`;
DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_GetNode`(
		IN	ip_CTSCustIDs 		LONGTEXT
	,   IN  ip_HasDevice		BIT
    ,   IN  ip_HasManual		BIT
    ,   IN  ip_HasAI			BIT
    ,   IN  ip_HasIP			BIT
	,	IN	ip_TableName		VARCHAR(50)
    ,	IN	ip_CustOrigRange	BIGINT
    ,	IN	ip_CustDestRange	BIGINT
    ,	IN	ip_DeviceRange		BIGINT
    ,	IN	ip_AIGroupRange		BIGINT
)
    SQL SECURITY INVOKER
sp:BEGIN 
	/*  
		Created:	20221006@Aries.Nguyen
		Task:		[CTS] Modify rule of Hedging Detection on MM
		DB:			CTS_DataCenter
        
		Revisions:
			- 20221006@Aries.Nguyen: Created [Redmine ID: #178310]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DC_AssociationDetection_GetNode(lv_CTSCustIDs,1,1,1,1,"Temp_Graph",0,0,CONS_Range1,CONS_Range2);
	*/    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 	Temp_Cust (
			CTSCustID 			BIGINT  PRIMARY KEY 
		,	CustID   			BIGINT	
		,	INDEX Temp_Cust(CustID)
	);
    
    SET @sql = 	CONCAT("DROP TEMPORARY TABLE IF EXISTS ",ip_TableName,";");
    PREPARE stmt1 FROM  @sql;
    EXECUTE stmt1; 
	DEALLOCATE PREPARE stmt1;
     
    #AssociationType: 1-Device, 2-Manual, 3-AI, 4-AIGroup, 5-IP
    SET @sql = 	CONCAT("CREATE TEMPORARY TABLE 	",ip_TableName," (
								OrigID 				BIGINT  
							,	DestID   			BIGINT
							,	Weight 				BIGINT 
                            ,	ParentOrigID 		BIGINT 
                            ,	IsRoot 				BIT DEFAULT 0 
							,	AssociationType		SMALLINT
							,	PRIMARY KEY(OrigID, DestID,AssociationType, Weight)
							,	INDEX IX_Temp_Graph(DestID)
						);");
                        
    PREPARE stmt1 FROM  @sql;
    EXECUTE stmt1; 
	DEALLOCATE PREPARE stmt1;

    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID)
	SELECT 	cus.CTSCustID
		, 	cus.CustID
	FROM JSON_TABLE(CONCAT('[',ip_CTSCustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID AND cus.IsInternal = 0;
    
    
    /*******************1. Device*************************/
    IF ip_HasDevice = 1 THEN
		DROP TEMPORARY TABLE IF EXISTS Temp_CustDevice;
		CREATE TEMPORARY TABLE 		Temp_CustDevice (
				CTSCustID			BIGINT UNSIGNED  
			,	DCSDeviceID  		BIGINT UNSIGNED 
			,	PRIMARY KEY(DCSDeviceID, CTSCustID)
		); 
			
		INSERT IGNORE INTO Temp_CustDevice(CTSCustID, DCSDeviceID)
		SELECT 	cus.CTSCustID 
			, 	dv.DCSDeviceID
		FROM Temp_Cust AS cus
			INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;    
			
		DROP TEMPORARY TABLE IF EXISTS Temp_Device;
		CREATE TEMPORARY TABLE 		Temp_Device (
				DCSDeviceID		BIGINT PRIMARY KEY
		);
			
		INSERT INTO Temp_Device(DCSDeviceID)
		SELECT 	DISTINCT
				DCSDeviceID
		FROM Temp_CustDevice;
		
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (ip_CustOrigRange + cus.CTSCustID)
			,	(ip_DeviceRange + tmp.DCSDeviceID) AS DestID
			,	0 AS Weight
			,	1 AS AssociationType
		FROM Temp_Device AS tmp
			INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON tmp.DCSDeviceID =  lv1.DCSDeviceID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON lv1.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;
	END IF;
	
    /*******************2. Manual*************************/
    IF ip_HasManual = 1 THEN
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (ip_CustOrigRange + tmp.CTSCustID) AS OrigID
			, 	(ip_CustDestRange + ma.FromCTSCustID) AS DestID
			,	0 AS Weight
			,	2 AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmp.CTSCustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.FromCTSCustID AND cus.IsInternal = 0;
				
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (ip_CustOrigRange + tmp.CTSCustID) AS OrigID
			, 	(ip_CustDestRange + ma.ToCTSCustID) AS DestID
			,	0 AS Weight
			,	2 AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID  = tmp.CTSCustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.ToCTSCustID AND cus.IsInternal = 0;
    END IF;
    /*******************3. AI*************************/
    IF ip_HasAI = 1 THEN
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (ip_CustOrigRange + tmp.CTSCustID) AS OrigID
			, 	(ip_CustDestRange + cus.CTSCustID) AS DestID
			,	0 AS Weight
			,	3 AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
			
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (ip_CustOrigRange + tmp.CTSCustID) AS OrigID
			, 	(ip_CustDestRange + cus.CTSCustID) AS DestID
			,	0 AS Weight
			,	3 AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.ToCustID = tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.FromCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
		
		/*******************4. Group AI*************************/
		DROP TEMPORARY TABLE IF EXISTS Temp_AssGroupByAI;
		CREATE TEMPORARY TABLE Temp_AssGroupByAI (
				GroupID BIGINT UNSIGNED
			,	CustID	BIGINT UNSIGNED
			, 	PRIMARY KEY (GroupID,CustID)
		);
		
		DROP TEMPORARY TABLE IF EXISTS Temp_AIGroup;
		CREATE TEMPORARY TABLE 	Temp_AIGroup (
				GroupID		BIGINT UNSIGNED PRIMARY KEY
		);
		
		INSERT IGNORE INTO Temp_AssGroupByAI(GroupID, CustID)
		SELECT	asg.GroupID 
			,	asg.CustID 
		FROM	Temp_Cust AS cus 
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON asg.CustID = cus.CustID;

		INSERT IGNORE INTO Temp_AIGroup(GroupID)
		SELECT 	GroupID
		FROM Temp_AssGroupByAI;   
			
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (ip_CustOrigRange + cus.CTSCustID) AS OrigID
			, 	(ip_AIGroupRange + tmp.GroupID) AS DestID
			,	0 AS Weight
			,	4 AS AssociationType
		FROM Temp_AIGroup AS tmp 
			INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON tmp.GroupID = asg.GroupID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = asg.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
    END IF;
    /*******************5. IP*************************/
    IF ip_HasIP = 1 THEN
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (ip_CustOrigRange + tmp.CTSCustID) AS OrigID
			, 	(ip_CustDestRange + cus.CTSCustID) AS DestID
			,	0 AS Weight
			,	5 AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
			
		INSERT IGNORE INTO Temp_Graph(OrigID,DestID,Weight,AssociationType)
		SELECT  (ip_CustOrigRange + tmp.CTSCustID) AS OrigID
			, 	(ip_CustDestRange + cus.CTSCustID) AS DestID
			,	0 AS Weight
			,	5 AS AssociationType
		FROM Temp_Cust AS tmp 
			INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmp.CustID
			INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.FromCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
	END IF;
END$$
DELIMITER ;
