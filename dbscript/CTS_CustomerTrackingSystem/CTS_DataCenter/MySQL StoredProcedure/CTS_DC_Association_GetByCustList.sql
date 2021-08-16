/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_GetByCustList`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetByCustList`(
	IN ip_CTSCustIDList TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200820@Long.Luu
		Task :		Get Associated Customers from CustIDList
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20200820@Long.Luu: Created [Redmine ID: 139701]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
		
		Param's Explanation (filtered by):
	*/
    
    DROP TEMPORARY TABLE IF EXISTS TempAffectedDevices;
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
    
END$$
DELIMITER ;
