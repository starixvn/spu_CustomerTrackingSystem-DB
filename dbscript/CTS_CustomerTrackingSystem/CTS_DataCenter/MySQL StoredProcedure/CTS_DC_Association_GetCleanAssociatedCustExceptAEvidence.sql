/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP procedure IF EXISTS `CTS_DC_Association_GetCleanAssociatedCustExceptAEvidence`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetCleanAssociatedCustExceptAEvidence`(
        IN ip_CTSCustID     BIGINT UNSIGNED
    ,   IN ip_EvidenceID    SMALLINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200820@Aries.Nguyen
		Task :		Get associated custIDs of ip_CTSCustID of whom have more than 1 evidence including ip_EvidenceID
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200820@Aries.Nguyen: created [Redmine ID: 139701]  	
            - 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
        
		Param's Explanation (filtered by):
        
        CALL CTS_DC_Association_GetCleanAssociatedCustExceptAEvidence(9522,1); 
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevice;
    CREATE TEMPORARY TABLE Temp_AffectedDevice(
		DCSDeviceID 	BIGINT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    CREATE TEMPORARY TABLE Temp_Association (
		CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );    
        
    DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence;
    CREATE TEMPORARY TABLE Temp_CustEvidence (
			CTSCustID 		BIGINT UNSIGNED
		,	EvidenceID		SMALLINT
        ,	INDEX IX_Temp_CustEvidence_CTSCustID_EvidenceID(CTSCustID,EvidenceID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CleanCustID;
    CREATE TEMPORARY TABLE Temp_CleanCustID (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TEMPORARY TABLE IF EXISTS Temp_CustRetractEvidence;
    CREATE TEMPORARY TABLE Temp_CustRetractEvidence (
			CTSCustID 		BIGINT UNSIGNED 
        ,	EvidenceID		SMALLINT
    );

    # Get devices list for root account
	INSERT INTO Temp_AffectedDevice(DCSDeviceID)
	SELECT  DISTINCT 
            a.DCSDeviceID
	FROM CTS_DataCenter.AssociationByDevice AS a
	WHERE a.CTSCustID = ip_CTSCustID;
    
    # Get associated accounts (including the root custID)
    INSERT INTO Temp_Association(CTSCustID)
    SELECT  DISTINCT 
            a.CTSCustID
	FROM CTS_DataCenter.AssociationByDevice AS a
		INNER JOIN Temp_AffectedDevice AS t ON a.DCSDeviceID = t.DCSDeviceID;
    
    # Get customer evidences
    INSERT INTO Temp_CustEvidence(CTSCustID, EvidenceID)
    SELECT c.CTSCustID, c.EvidenceID
    FROM CTS_DataCenter.CustEvidence AS c
		INNER JOIN Temp_Association AS t ON c.CTSCustID = t.CTSCustID
	WHERE c.EvidenceID <> ip_EvidenceID;
    
    INSERT INTO Temp_CustRetractEvidence(CTSCustID, EvidenceID)
    SELECT  c.CTSCustID
        ,   c.EvidenceID
    FROM Temp_CustEvidence AS c
		INNER JOIN CTS_DataCenter.CustRetractEvidence AS r ON c.CTSCustID = r.CTSCustID AND c.EvidenceID = r.EvidenceID;

    DELETE c
    FROM Temp_CustEvidence AS c
		INNER JOIN Temp_CustRetractEvidence AS r ON c.CTSCustID = r.CTSCustID AND c.EvidenceID = r.EvidenceID;
        
    # Accounts that are clean
    INSERT INTO Temp_CleanCustID(CTSCustID)
    SELECT  DISTINCT 
            c.CTSCustID
	FROM Temp_Association AS c
		LEFT JOIN (	SELECT DISTINCT CTSCustID FROM Temp_CustEvidence) AS r ON c.CTSCustID = r.CTSCustID
	WHERE r.CTSCustID IS NULL ;
    
    SELECT  DISTINCT	
            c.CustID
    FROM Temp_CleanCustID AS a
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID;
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
    DROP TEMPORARY TABLE IF EXISTS Temp_Association;
    DROP TEMPORARY TABLE IF EXISTS Temp_CustEvidence;
    DROP TEMPORARY TABLE IF EXISTS Temp_CleanCustID;    
    
END$$

DELIMITER ;