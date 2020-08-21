USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_GetCustIDsByAssociationDeviceCSTCustID`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetCustIDsByAssociationDeviceCSTCustID`(
  IN ip_CTSCustID BIGINT,
  IN ip_EvidenceID SMALLINT(6)
)
sp:BEGIN
	/*
		Created:	Aries.Nguyen
		Task :		
		DB:			CTS_DataCenter
		Original:

		Revisions:
        - 20200820@Aries: Get list custID by association device with CTSCustID, EvidenceID  	
		Param's Explanation (filtered by):
        
        CALL CTS_DC_GetCustIDsByAssociationDeviceCSTCustID(9522,1);
	*/
    DECLARE isExist_CustEvidence BIT;
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    -- Check ip_CTSCustID and ip_EvidenceID are exists
    SET isExist_CustEvidence = (SELECT  EXISTS(SELECT 1 FROM CustEvidence WHERE CTSCustID = ip_CTSCustID AND EvidenceID = ip_EvidenceID));
	
    IF isExist_CustEvidence = 0
    THEN
		SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
        LEAVE sp;
    END IF;
    
    DROP TEMPORARY TABLE IF EXISTS tempAssociationCTSCustIDs;
    CREATE TEMPORARY TABLE tempAssociationCTSCustIDs (
		CTSCustID BIGINT PRIMARY KEY
    );
    
    -- Get list CTSCustID association by device with ip_CTSCustID
    INSERT INTO tempAssociationCTSCustIDs
	SELECT CTSCustID
    FROM AssociationByDevice
	WHERE DCSDeviceID IN (SELECT  DCSDeviceID
						  FROM  AssociationByDevice
						  WHERE CTSCustID = ip_CTSCustID)
		  AND CTSCustID != ip_CTSCustID;
    
    
    DROP TEMPORARY TABLE IF EXISTS tempEvidenceCTSCustIDs;
    CREATE TEMPORARY TABLE tempEvidenceCTSCustIDs (
		CTSCustID BIGINT PRIMARY KEY
    );
    
    -- Get list CTSCustID association by device with ip_CTSCustID and ip_EvidenceID
    INSERT INTO tempEvidenceCTSCustIDs
    SELECT CTSCustID 
    FROM CustEvidence 
    WHERE CTSCustID NOT IN (SELECT CTSCustID FROM  CustRetractEvidence WHERE  EvidenceID = ip_EvidenceID)
		  AND CTSCustID IN (SELECT CTSCustID FROM tempAssociationCTSCustIDs) 
		  AND EvidenceID = ip_EvidenceID;
    
    
    -- Get list custId association
    SELECT CustID FROM CTSCustomer
    WHERE CTSCustID IN (SELECT CTSCustID FROM tempEvidenceCTSCustIDs);
    
    
    -- Release temporary table (information_schema.INNODB_TEMP_TABLE_INFO)
    DROP TEMPORARY TABLE IF EXISTS tempAssociationCTSCustIDs;
    DROP TEMPORARY TABLE IF EXISTS tempEvidenceCTSCustIDs;
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$

DELIMITER ;

