DELIMITER $$
USE `CTS_DataCenter`$$
DROP PROCEDURE IF EXISTS `CTS_DC_GetAssociatedCustIDsWithOtherEvidence`;

CREATE PROCEDURE `CTS_DC_GetAssociatedCustIDsWithOtherEvidence`(
		IN ip_CTSCustID 		BIGINT
	,	IN ip_EvidenceID 		SMALLINT
)
BEGIN
	/*
		Created:	20200820@Aries.Nguyen
		Task :		Get associated custIDs of ip_CTSCustID of whom have more than 1 evidence including ip_EvidenceID
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200820@Aries.Nguyen: created [Redmine ID: 139701]  	
        
		Param's Explanation (filtered by):
        
        CALL CTS_DC_GetCustIDsByAssociationDeviceCSTCustID(9522,1);
	*/
    
    DROP TABLE IF EXISTS TempAffectedDevices;
    CREATE TEMPORARY TABLE TempAffectedDevices(
		DCSDeviceID 	BIGINT PRIMARY KEY
	);
    
    DROP TEMPORARY TABLE IF EXISTS TempAssociations;
    CREATE TEMPORARY TABLE TempAssociations (
		CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );    
        
    DROP TEMPORARY TABLE IF EXISTS TempCustEvidence;
    CREATE TEMPORARY TABLE TempCustEvidence (
			CTSCustID 		BIGINT UNSIGNED
		,	EvidenceID		SMALLINT
        ,	INDEX TempCustEvidence_CTSCustIDEvidenceID(CTSCustID,EvidenceID)
    );
    
    DROP TEMPORARY TABLE IF EXISTS TempCleanCustID;
    CREATE TEMPORARY TABLE TempCleanCustID (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    # Get devices list for root account
	INSERT INTO TempAffectedDevices(DCSDeviceID)
	SELECT DISTINCT a.DCSDeviceID
	FROM CTS_DataCenter.AssociationByDevice AS a
	WHERE a.CTSCustID = ip_CTSCustID;
    
    # Get associated accounts (including the root custID)
    INSERT INTO TempAssociations(CTSCustID)
    SELECT DISTINCT a.CTSCustID
	FROM CTS_DataCenter.AssociationByDevice AS a
		INNER JOIN TempAffectedDevices AS t ON a.DCSDeviceID = t.DCSDeviceID;
    
    # Get customer evidences
    INSERT INTO TempCustEvidence(CTSCustID, EvidenceID)
    SELECT c.CTSCustID, c.EvidenceID
    FROM CTS_DataCenter.CustEvidence AS c
		INNER JOIN TempAssociations AS t ON c.CTSCustID = t.CTSCustID
	WHERE c.EvidenceID <> ip_EvidenceID;
        
	SET SQL_SAFE_UPDATES = 0;
    
    DELETE c
    FROM TempCustEvidence AS c
		INNER JOIN CTS_DataCenter.CustRetractEvidence AS r ON c.CTSCustID = r.CTSCustID AND c.EvidenceID = r.EvidenceID;
        
    # Accounts that are clean
    INSERT INTO TempCleanCustID(CTSCustID)
    SELECT DISTINCT c.CTSCustID
	FROM TempAssociations AS c
		LEFT JOIN (	SELECT DISTINCT CTSCustID
					FROM TempCustEvidence) AS r ON c.CTSCustID = r.CTSCustID
	WHERE r.CTSCustID IS NULL ;
    
    SELECT DISTINCT	c.CustID
    FROM TempCleanCustID AS a
		INNER JOIN CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID;
        
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    DROP TEMPORARY TABLE IF EXISTS TempAffectedDevices;
    DROP TEMPORARY TABLE IF EXISTS TempAssociations;
    DROP TEMPORARY TABLE IF EXISTS TempCustEvidence;
    DROP TEMPORARY TABLE IF EXISTS TempCleanCustID;    
    
END$$

DELIMITER ;

