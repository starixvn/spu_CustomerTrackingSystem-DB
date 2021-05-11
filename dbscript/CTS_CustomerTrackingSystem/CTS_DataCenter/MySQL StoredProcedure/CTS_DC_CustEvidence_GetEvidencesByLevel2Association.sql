/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI" isFunction="0" isNested="0"></info>*/ 
DROP PROCEDURE IF EXISTS `CTS_DC_CustEvidence_GetEvidencesByLevel2Association`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustEvidence_GetEvidencesByLevel2Association`(       
        IN ip_CustIDs TEXT
)
    SQL SECURITY INVOKER
BEGIN

	/*
		Created:	20210301@Harvey.Nguyen
		Task:		Get all evidences by Custs for level 2 [Redmine ID: 150456]
		DB:			CTS_DataCenter
		Original:

		Revisions:
           - 20210301@Harvey.Nguyen: Created  [Redmine ID: #150917]
		   - 20210308@Jonas.Huynh: Update logic SP [Redmine ID: #150917]
           - 20210427@Aries.Nguyen: Enhance performance [Redmine ID: #152509] 
           
		Param's Explanation (filtered by):			
        Example:
            - CALL CTS_DataCenter.CTS_DC_CustEvidence_GetEvidencesByLevel2Association('17004');
	*/
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Root_Customer;
    CREATE TEMPORARY TABLE Temp_Root_Customer(
		 	CTSCustID		BIGINT UNSIGNED  
		,	CustID          BIGINT UNSIGNED
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Root_Device;
	CREATE TEMPORARY TABLE 		Temp_Root_Device (
			CustID          BIGINT UNSIGNED
		,	CTSCustID 		BIGINT UNSIGNED 
		,	DCSDeviceID		BIGINT UNSIGNED 
		, 	PRIMARY KEY(CTSCustID, DCSDeviceID)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Root_Device_Level1;
	CREATE TEMPORARY TABLE 		Temp_Root_Device_Level1 (
			CustID          	BIGINT UNSIGNED
		,	CTSCustID			BIGINT UNSIGNED 
		,   DeviceLevel1 		BIGINT UNSIGNED
		,	PRIMARY KEY (DeviceLevel1, CTSCustID)
        ,	INDEX IX_Temp_Root_Device_Level1_DeviceLevel1(DeviceLevel1)
	);  
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level1;
	CREATE TEMPORARY TABLE 		Temp_Device_Level1 (
		    DeviceLevel1 		BIGINT UNSIGNED
		,	PRIMARY KEY (DeviceLevel1)
	); 
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level1_Cust;
	CREATE TEMPORARY TABLE 		Temp_Device_Level1_Cust (
			Level2				BIGINT UNSIGNED 
		,   DeviceLevel1 		BIGINT UNSIGNED
		,	PRIMARY KEY (DeviceLevel1, Level2)
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1;
	CREATE TEMPORARY TABLE 		Temp_Association_Level1 (
			CustID          	BIGINT UNSIGNED
		,	CTSCustID			BIGINT UNSIGNED 
		,   Level1 				BIGINT UNSIGNED 
		,	PRIMARY KEY(CTSCustID, Level1)
        ,	INDEX IX_Temp_Association_Level1(Level1)
	); 
    
	DROP TEMPORARY TABLE IF EXISTS   Temp_Association_Level2;
    CREATE TEMPORARY TABLE Temp_Association_Level2(
			CustID          	BIGINT UNSIGNED
		, 	CTSCustID			BIGINT UNSIGNED  
		,	Level2				BIGINT UNSIGNED
        ,	PRIMARY KEY(CTSCustID,Level2)
        ,	INDEX IX_Temp_Association_Level2(Level2)
	);
    
    DROP TEMPORARY TABLE IF EXISTS   Temp_Level2;
    CREATE TEMPORARY TABLE Temp_Level2 (
			CustID		BIGINT UNSIGNED
		,	Level2		BIGINT UNSIGNED
        ,	PRIMARY KEY(Level2)
	);
    
    DROP TEMPORARY TABLE IF EXISTS   Temp_Level2_Evidence;
    CREATE TEMPORARY TABLE Temp_Level2_Evidence (
			CustID		BIGINT UNSIGNED
		,	Level2		BIGINT UNSIGNED
		,	EvidenceID	INT
        ,	CreatedDate	DATETIME
        ,	PRIMARY KEY(Level2, EvidenceID)
	);
    
    SET @sql = 	CONCAT("INSERT INTO Temp_Root_Customer (CustID) VALUES ('", REPLACE(ip_CustIDs, ",", "'),('"),"');");
	PREPARE 	stmt1 FROM @sql;
	EXECUTE 	stmt1;   
    
    UPDATE      Temp_Root_Customer AS temp
		INNER JOIN  CTS_DataCenter.CTSCustomer AS tcust ON tcust.CustID = temp.CustID AND tcust.CustSubID = 0
    SET         temp.CTSCustID = tcust.CTSCustID;
    
	# Get root device has association
	INSERT INTO Temp_Root_Device(CustID,CTSCustID,DCSDeviceID)
	SELECT 	root.CustID
		,	root.CTSCustID
		,	dv.DCSDeviceID
	FROM Temp_Root_Customer AS root 
		INNER JOIN CTS_DataCenter.AssociationByDevice AS dv ON dv.CTSCustID =  root.CTSCustID
	WHERE EXISTS (SELECT 1 FROM DeviceAssociationDay AS da WHERE da.DCSDeviceID = dv.DCSDeviceID);
	
    #Get association level 1
    INSERT IGNORE INTO Temp_Association_Level1(CustID, CTSCustID,Level1)
	SELECT	dv.CustID
		,	dv.CTSCustID
		,	lv1.CTSCustID
	FROM Temp_Root_Device AS dv
		INNER JOIN CTS_DataCenter.AssociationByDevice AS lv1 ON dv.DCSDeviceID =  lv1.DCSDeviceID AND dv.CTSCustID != lv1.CTSCustID;
	
    INSERT IGNORE INTO Temp_Root_Device_Level1(CustID, CTSCustID, DeviceLevel1)
	SELECT  lv1.CustID
		,	lv1.CTSCustID
		, 	asDv.DCSDeviceID
	FROM Temp_Association_Level1 AS lv1
		INNER JOIN CTS_DataCenter.AssociationByDevice AS asDv ON asDv.CTSCustID = lv1.Level1
	WHERE NOT EXISTS (SELECT 1 FROM Temp_Root_Device AS roDv WHERE lv1.CTSCustID =  roDv.CTSCustID AND asDv.DCSDeviceID = roDv.DCSDeviceID)
		AND  EXISTS (SELECT 1 FROM DeviceAssociationDay AS da WHERE da.DCSDeviceID = asDv.DCSDeviceID);
	
    INSERT INTO Temp_Device_Level1(DeviceLevel1)
    SELECT DISTINCT DeviceLevel1 FROM Temp_Root_Device_Level1;
     
    INSERT INTO Temp_Device_Level1_Cust(DeviceLevel1, Level2)
    SELECT 	dv.DeviceLevel1
		,	lv2.CTSCustID
	FROM Temp_Device_Level1 AS dv 
		INNER JOIN CTS_DataCenter.AssociationByDevice AS lv2 ON dv.DeviceLevel1 =  lv2.DCSDeviceID
	WHERE EXISTS (SELECT 1 FROM CTS_DataCenter.CustEvidence AS ev FORCE INDEX (IX_CustEvidence_Level_CTSCustID) WHERE ev.CTSCustID = lv2.CTSCustID AND ev.Level = 0);
     
    INSERT IGNORE INTO Temp_Association_Level2(CustID, CTSCustID, Level2)
	SELECT 	roDv.CustID
		,	roDv.CTSCustID
		, 	lv2.Level2
	FROM Temp_Root_Device_Level1 AS roDv
		INNER JOIN Temp_Device_Level1_Cust AS lv2 ON roDv.DeviceLevel1 =  lv2.DeviceLevel1
	WHERE NOT EXISTS (SELECT 1 FROM Temp_Association_Level1 AS lv1 WHERE lv1.CTSCustID = roDv.CTSCustID and  lv1.Level1 = lv2.Level2);
    
    INSERT INTO Temp_Level2(Level2)
    SELECT DISTINCT Level2
    FROM Temp_Association_Level2;
    
    UPDATE Temp_Level2 AS lv2
    INNER JOIN CTS_DataCenter.CTSCustomer cust ON cust.CTSCustID = lv2.Level2
    SET lv2.CustID = cust.CustID;
    
    INSERT INTO Temp_Level2_Evidence(CustID, Level2, EvidenceID, CreatedDate)
    SELECT 	lv2.CustID
		,	lv2.Level2
		,	ev.EvidenceID
        ,	ev.CreatedDate
    FROM Temp_Level2 AS lv2 
		INNER JOIN CTS_DataCenter.CustEvidence AS ev FORCE INDEX (IX_CustEvidence_Level_CTSCustID) ON ev.CTSCustID = lv2.Level2 AND Level = 0;
    
    SELECT  ev.CustID		AS CustId
		,	e.EvidenceCode	AS EvidenceCode
		,	e.EvidenceName	AS EvidenceName
		,	lv2.CustID 		AS Level0CustId
		,	ev.CreatedDate	AS CreatedDate
		,	2				AS AssociatedLevel
    FROM Temp_Association_Level2 AS lv2
		INNER JOIN Temp_Level2_Evidence AS ev ON lv2.Level2 = ev.Level2
        INNER JOIN Evidence AS e ON ev.EvidenceID = e.EvidenceID;
        
	DROP TEMPORARY TABLE IF EXISTS Temp_Root_Customer;
    DROP TEMPORARY TABLE IF EXISTS Temp_Root_Device;
    DROP TEMPORARY TABLE IF EXISTS Temp_Root_Device_Level1;
    DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level1;
    DROP TEMPORARY TABLE IF EXISTS Temp_Device_Level1_Cust;
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level1;
    DROP TEMPORARY TABLE IF EXISTS Temp_Association_Level2;
    DROP TEMPORARY TABLE IF EXISTS Temp_Level2;
    DROP TEMPORARY TABLE IF EXISTS Temp_Level2_Evidence;
        
END$$

DELIMITER ;