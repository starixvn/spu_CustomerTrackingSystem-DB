DELIMITER $$
USE CTS_DataCenter $$
DROP PROCEDURE IF EXISTS CTS_DC_Association_GetByCustList $$

CREATE PROCEDURE `CTS_DC_Association_GetByCustList`(IN ip_CTSCustIDList VARCHAR(2000))
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
			DCSDeviceID 	BIGINT PRIMARY KEY
	);
 
	DROP TEMPORARY TABLE IF EXISTS TempCTSCustIDs;
    CREATE TEMPORARY TABLE TempCTSCustIDs (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO TempCTSCustIDs (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
	# Get devices list for root account
	INSERT INTO TempAffectedDevices(DCSDeviceID)
	SELECT DISTINCT a.DCSDeviceID
	FROM CTS_DataCenter.AssociationByDevice AS a
		INNER JOIN TempCTSCustIDs AS t ON a.CTSCustID = t.CTSCustID;
    
	# Get associated accounts
    SELECT DISTINCT c.CustID
	FROM CTS_DataCenter.AssociationByDevice AS a
		INNER JOIN TempAffectedDevices AS t ON a.DCSDeviceID = t.DCSDeviceID        
        INNER JOIN CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID;
        
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
    
END$$
DELIMITER ;
