/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_AssociationDetection_Agent_Detect`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_AssociationDetection_Agent_Detect`(
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
			- CALL CTS_DataCenter.CTS_DC_AssociationDetection_Agent_Detect('1,2,3');
	*/
    DECLARE CONST_DEVICE_RANGE 		BIGINT DEFAULT -800000000000;
    DECLARE CONST_AGENT_RANGE 		BIGINT DEFAULT -900000000000;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Cust;
	CREATE TEMPORARY TABLE 	Temp_Cust (
			CTSCustID 			BIGINT  PRIMARY KEY 
		,	CustID   			BIGINT	
        ,	Recommend			BIGINT
		,	INDEX 				Temp_Cust(CustID)
        ,	INDEX 				Temp_Cust_Recommend(Recommend)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Recommend;
	CREATE TEMPORARY TABLE 	Temp_Recommend (
			CTSCustID 			BIGINT  PRIMARY KEY 
        ,	Recommend			BIGINT
        ,	Processed 			BIT DEFAULT 0
        ,	INDEX 				IX_Temp_Recommend_Recommend(Recommend)
        ,	INDEX				IX_Temp_Recommend_Processed(Processed)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Graph;
	CREATE TEMPORARY TABLE 	Temp_Graph (
			OrigID 				BIGINT  
		,	DestID   			BIGINT
		,	PRIMARY KEY(OrigID, DestID)
		,	INDEX IX_Temp_Graph(DestID,OrigID)
	);
    
    
    INSERT IGNORE INTO Temp_Cust(CTSCustID, CustID, Recommend)
	SELECT 	cus.CTSCustID
		, 	cus.CustID
        ,	cus.Recommend
	FROM JSON_TABLE(CONCAT('[',ip_CTSCustIDs,']'),'$[*]' COLUMNS(NESTED PATH '$' COLUMNS (CTSCustID BIGINT UNSIGNED PATH '$'))) AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = tmp.CTSCustID 
														AND cus.IsInternal = 0
                                                        AND cus.RoleID = 1
                                                        AND cus.IsLicensee = 0;
    
    INSERT IGNORE INTO Temp_Recommend(CTSCustID, Recommend)
	SELECT 	cus.CTSCustID
        ,	cus.Recommend
	FROM Temp_Cust AS tmp
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CustID = tmp.Recommend 
														AND cus.IsInternal = 0
                                                        AND cus.CustSubID = 0;
    
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
	FROM Temp_Recommend AS cus
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID = cus.CTSCustID;    
		
	DROP TEMPORARY TABLE IF EXISTS Temp_Device;
	CREATE TEMPORARY TABLE 		Temp_Device (
			DCSDeviceID		BIGINT PRIMARY KEY
	);
        
	INSERT INTO Temp_Device(DCSDeviceID)
	SELECT 	DISTINCT
			DCSDeviceID
	FROM Temp_CustDevice;
    
    INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
	SELECT  cus.CTSCustID
		,	(CONST_DEVICE_RANGE + (-1*tmp.DCSDeviceID)) AS DestID
	FROM Temp_Device AS tmp
		INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON tmp.DCSDeviceID =  lv1.DCSDeviceID
		INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON lv1.CTSCustID = cus.CTSCustID AND cus.IsInternal = 0;
        
	
    /*******************2. Manual*************************/
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
	SELECT  tmp.CTSCustID AS OrigID
		, 	(CONST_AGENT_RANGE + (-1*CAST(ma.FromCTSCustID AS SIGNED))) AS DestID
	FROM Temp_Recommend AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.ToCTSCustID = tmp.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.FromCTSCustID AND cus.IsInternal = 0;
			 
	INSERT IGNORE INTO Temp_Graph(OrigID,DestID)
	SELECT  tmp.CTSCustID AS OrigID
		, 	(CONST_AGENT_RANGE + (-1*CAST(ma.ToCTSCustID AS SIGNED))) AS DestID
	FROM Temp_Recommend AS tmp 
		INNER JOIN CTS_DataCenter.AssociationByManual AS ma ON ma.FromCTSCustID  = tmp.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS cus ON cus.CTSCustID = ma.ToCTSCustID AND cus.IsInternal = 0;
    
    /*******************Return Data*************************/
	SELECT 	cus.CTSCustID AS FromID
        ,	grp.DestID AS ToID
    FROM Temp_Graph AS grp
		INNER JOIN Temp_Recommend AS re ON re.CTSCustID = grp.OrigID
        INNER JOIN Temp_Cust AS cus ON re.Recommend = cus.Recommend;
    
END$$

DELIMITER ;
