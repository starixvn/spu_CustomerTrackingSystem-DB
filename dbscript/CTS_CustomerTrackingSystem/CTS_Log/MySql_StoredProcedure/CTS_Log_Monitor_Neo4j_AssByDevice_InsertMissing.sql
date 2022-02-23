/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByDevice_InsertMissing`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByDevice_InsertMissing`(
		IN 	ip_AssByDeviceList 	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201213@Harvey
		Task:		Insert missing customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220128@Harvey: Initial
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_Log.CTS_Log_InsertMissingCusts ('');

	*/
	DROP TEMPORARY TABLE IF EXISTS Temp_MissingAssByDevice;    
	CREATE TEMPORARY TABLE Temp_MissingAssByDevice(
		`CTSAssDevID`	BIGINT UNSIGNED NOT NULL,
        `CTSCustID`		BIGINT UNSIGNED NOT NULL,
        `DCSDeviceID`	BIGINT UNSIGNED NOT NULL
	);

    INSERT INTO Temp_MissingAssByDevice(CTSAssDevID, CTSCustID, DCSDeviceID)
	SELECT		CTSAssDevID
				, CTSCustID
                , DCSDeviceID	
	FROM JSON_TABLE(ip_AssByDeviceList,
		 "$[*]" COLUMNS(
				CTSAssDevID		BIGINT			UNSIGNED		PATH "$.CTSAssDevID",
                CTSCustID		BIGINT			UNSIGNED		PATH "$.CTSCustID",
                DCSDeviceID		BIGINT			UNSIGNED		PATH "$.DeviceID"
			)
	) AS js;
    
    INSERT INTO CTS_Log.Monitor_Neo4j_CTSCustomer_Missing(CTSAssDevID, CTSCustID, DCSDeviceID)
    SELECT 		CTSAssDevID	
            ,	CTSCustID
            ,	DCSDeviceID
    FROM Temp_MissingAssByDevice;

END$$
DELIMITER ;