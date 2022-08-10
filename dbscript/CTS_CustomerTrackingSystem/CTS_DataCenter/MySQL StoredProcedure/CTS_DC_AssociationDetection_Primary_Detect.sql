/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_Primary_Detect`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_Primary_Detect`(
		IN	ip_CTSCustIDs 			LONGTEXT
)
    SQL SECURITY INVOKER
sp:BEGIN 
	/*  
		Created:	20220727@Aries.Nguyen
		Task:		[CTS] Enhance Association Detection
		DB:			CTS_DataCenter
        
		Revisions:
			- 20220727@Aries.Nguyen: Created [Redmine ID: #175701]

		Param's Explanation (filtered by):

        Example:
			- CALL CTS_DataCenter.CTS_DC_AssociationDetection_Primary_Detect('1,2,3');
	*/
    DECLARE CONST_DEVICE_RANGE 		INT DEFAULT -1;
    DECLARE CONST_AIGROUP_RANGE 	BIGINT DEFAULT 10000000000;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 	Temp_Cust (
			CTSCustID 			BIGINT  PRIMARY KEY 
		,	CustID   			BIGINT	
		,	INDEX Temp_Cust(CustID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Graph;
	CREATE TEMPORARY TABLE 	Temp_Graph (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
        ,	AssociationType		SMALLINT		# 1-Device, 2-Manual, 3-AI, 4-AIGroup, 5-IP
		,	PRIMARY KEY(OrigID, DestID, AssociationType)
		,	INDEX IX_Temp_Graph(DestID,OrigID)
	);
    
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID)
	SELECT 	cus.CTSCustID
		, 	cus.CustID
	FROM JSON_TABLE(CONCAT('[',ip_CTSCustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID AND cus.IsInternal = 0;
    
    
    /*******************1. Device*************************/
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
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
	SELECT  cus.CTSCustID
		,	CONST_DEVICE_RANGE * tmp.DCSDeviceID AS DestID
		,	1 AS AssociationType
	FROM Temp_Device AS tmp
		INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON tmp.DCSDeviceID =  lv1.DCSDeviceID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON lv1.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;
        
	
    /*******************2. Manual*************************/
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	ma.FromCTSCustID AS DestID
        ,	2 AS AssociationType
	FROM Temp_Cust AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmp.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.FromCTSCustID AND cus.IsInternal = 0;
			
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	ma.ToCTSCustID AS DestID
        ,	2 AS AssociationType
	FROM Temp_Cust AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID  = tmp.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.ToCTSCustID AND cus.IsInternal = 0;
    
    /*******************3. AI*************************/
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	cus.CTSCustID AS DestID
        ,	3 AS AssociationType
	FROM Temp_Cust AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByAI AS ai ON ai.FromCustID = tmp.CustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ai.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
		
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	cus.CTSCustID AS DestID
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
		
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
	SELECT  cus.CTSCustID AS OrigID
		, 	(CONST_AIGROUP_RANGE + tmp.GroupID) AS DestID
        ,	4 AS AssociationType
	FROM Temp_AIGroup AS tmp 
		INNER JOIN CTS_DataCenter.AssociationGroupByAI AS asg ON tmp.GroupID = asg.GroupID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = asg.CustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
    
    /*******************5. IP*************************/
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	cus.CTSCustID AS DestID
        ,	5 AS AssociationType
	FROM Temp_Cust AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.FromCustID = tmp.CustID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.ToCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
        
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID,AssociationType)
	SELECT  tmp.CTSCustID AS OrigID
		, 	cus.CTSCustID AS DestID
        ,	5 AS AssociationType
	FROM Temp_Cust AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByIP AS ip ON ip.ToCustID = tmp.CustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = ip.FromCustID AND cus.CustSubID = 0 AND cus.IsInternal = 0;
	
    
    /*******************Return Data*************************/
	SELECT 	OrigID AS FromID
		,	DestID AS ToID
        ,	AssociationType
    FROM Temp_Graph;
    
END$$

DELIMITER ;
