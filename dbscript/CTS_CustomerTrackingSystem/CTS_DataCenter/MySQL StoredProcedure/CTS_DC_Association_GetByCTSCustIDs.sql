/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Association_GetByCTSCustIDs`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Association_GetByCTSCustIDs`(
		IN ip_CTSCustIDList VARCHAR(2000)
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200820@Long.Luu
		Task :		Get Associated Customers from CustIDList
		DB:			CTS_DataCenter
		Original:
		Revisions:
			- 20200820@Long.Luu: Created [Redmine ID: #139701]
			- 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: #148723]
			- 20210622@Aries.Nguyen: Update coding convention [Redmine ID: #157203]
		
		Param's Explanation (filtered by):
	*/
    
    DROP TEMPORARY TABLE IF EXISTS Temp_AffectedDevices;
    CREATE TEMPORARY TABLE Temp_AffectedDevices(
			DCSDeviceID 	BIGINT PRIMARY KEY
	);
 
	DROP TEMPORARY TABLE IF EXISTS Temp_CTSCustIDs;
    CREATE TEMPORARY TABLE Temp_CTSCustIDs (
			CTSCustID 		BIGINT UNSIGNED PRIMARY KEY
    );
    
	SET @sql = CONCAT("INSERT INTO Temp_CTSCustIDs (CTSCustID) VALUES ('", REPLACE(ip_CTSCustIDList, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;
    
	# Get devices list for root account
	INSERT INTO Temp_AffectedDevices(DCSDeviceID)
	SELECT DISTINCT a.DCSDeviceID
	FROM CTS_DataCenter.AssociationByDevice AS a
		INNER JOIN Temp_CTSCustIDs AS t ON a.CTSCustID = t.CTSCustID;
    
	# Get associated accounts
    SELECT DISTINCT c.CustID
	FROM CTS_DataCenter.AssociationByDevice AS a
		INNER JOIN Temp_AffectedDevices AS t ON a.DCSDeviceID = t.DCSDeviceID        
        INNER JOIN CTS_DataCenter.CTSCustomer AS c ON a.CTSCustID = c.CTSCustID;
    
END$$
DELIMITER ;