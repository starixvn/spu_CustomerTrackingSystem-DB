/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Monitoring_MissingCustomer_Complete`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Monitoring_MissingCustomer_Complete`(
	IN ip_ResolvedIDs		TEXT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20241213@Jonas.Huynh
		Task:		Missing Customer [Redmine ID: 214157]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20241213@Jonas.Huynh: Missing Customer [Redmine ID: 214157]
            
		Param's Explanation (filtered by):
            
		Example:
			- CALL CTS_DataCenter.CTS_DC_Monitoring_MissingCustomer_Complete(1);

	*/  
	DROP TEMPORARY TABLE IF EXISTS Temp_ResolvedIDs;    
	CREATE TEMPORARY TABLE Temp_ResolvedIDs( 	  
		ID		BIGINT	 UNSIGNED PRIMARY KEY
	);
	
    SET @sql = CONCAT("INSERT INTO Temp_ResolvedIDs (ID) VALUES ('", REPLACE(ip_ResolvedIDs, ",", "'),('"),"');");
	PREPARE stmt1 FROM @sql;
	EXECUTE stmt1;

	UPDATE CTS_DataCenter.JobMonitoring_IncorrectData AS a
		INNER JOIN CTS_DataCenter.Temp_ResolvedIDs AS r ON r.ID = a.ID
	SET IsResolved = 1;
    
END$$
DELIMITER ;