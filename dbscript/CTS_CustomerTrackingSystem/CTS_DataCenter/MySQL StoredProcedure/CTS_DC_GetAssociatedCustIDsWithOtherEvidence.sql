USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_GetAssociatedCustIDsWithOtherEvidence`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetAssociatedCustIDsWithOtherEvidence`(
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
    
    SELECT DISTINCT c.CustID
    FROM TempAssociations AS t
		INNER JOIN CTS_DataCenter.CustEvidence AS e ON t.CTSCustID = e.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS c ON t.CTSCustID = c.CTSCustID
	WHERE e.EvidenceID <> ip_EvidenceID
    GROUP BY t.CTSCustID
    HAVING COUNT(1) > 0;
    
    DROP TEMPORARY TABLE IF EXISTS TempAffectedDevices;
    DROP TEMPORARY TABLE IF EXISTS TempAssociations;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
    
END$$

DELIMITER ;

