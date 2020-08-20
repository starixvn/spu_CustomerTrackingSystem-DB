DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DC_GetAssociationCustomersByCTSCustIDList $$

CREATE PROCEDURE `CTS_DC_GetAssociationCustomersByCTSCustIDList`(IN ip_CTSCustIDList VARCHAR(2000))
BEGIN
	/*
		Created:	20200820@Long.Luu
		Task :		Get Associated Customers from CustIDList
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200820@Long.Luu: Created [Redmine ID: 139701]
		
		Param's Explanation (filtered by):
	*/
    
    DROP TABLE IF EXISTS TempAffectedDevices;
    CREATE TEMPORARY TABLE TempAffectedDevices(
			CTSCustID		BIGINT UNSIGNED
		,	DCSDeviceID 	BIGINT
        ,	INDEX IX_TempAffectedDevices_CTSCustIDDCSDeviceID (DCSDeviceID, CTSCustID)
	);
 
	DROP TEMPORARY TABLE IF EXISTS TempCTSCustIDs;
    CREATE TEMPORARY TABLE TempCTSCustIDs (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
    DROP TABLE IF EXISTS TempAssociations;
    CREATE TEMPORARY TABLE TempAssociations(
			RootCustId		BIGINT UNSIGNED
		,	AffectedCustId 	BIGINT UNSIGNED
        ,	INDEX IX_TempAssociations_RootCustId (RootCustId)
        ,	INDEX IX_TempAssociations_AffectedCustId (AffectedCustId)
	);
    
	SET @sql = CONCAT("INSERT INTO TempCTSCustIDs (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
	# Get devices list for root account
	INSERT INTO TempAffectedDevices(DCSDeviceID, CTSCustID)
	SELECT DISTINCT a.DCSDeviceID, t.CTSCustID
	FROM CTS_DataCenter.AssociationByDevice AS a
		INNER JOIN TempCTSCustIDs AS t ON a.CTSCustID = t.CTSCustID;
    
	# Get associated accounts
    INSERT INTO TempAssociations(RootCustId, AffectedCustId)
    SELECT DISTINCT t.CTSCustID, a.CTSCustID
	FROM CTS_DataCenter.AssociationByDevice AS a
		INNER JOIN TempAffectedDevices AS t ON a.DCSDeviceID = t.DCSDeviceID;
	
    SELECT 	c1.CustID AS FromCustId
		,	c2.CustID AS ToCustId
    FROM TempAssociations AS a
		INNER JOIN CTS_DataCenter.CTSCustomer AS c1 ON a.RootCustId = c1.CTSCustID
        INNER JOIN CTS_DataCenter.CTSCustomer AS c2 ON a.AffectedCustId = c2.CTSCustID;
        
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$
DELIMITER ;
