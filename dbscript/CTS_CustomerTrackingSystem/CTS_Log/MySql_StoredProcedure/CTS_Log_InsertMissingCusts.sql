/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Log_InsertMissingCusts`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_InsertMissingCusts`(
		IN 	ip_CustomerList 	JSON
    ,	IN	ip_ScannedDate		DATETIME
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
	DROP TEMPORARY TABLE IF EXISTS Temp_MissingCust;    
	CREATE TEMPORARY TABLE Temp_MissingCust(
		`CTSCustID`	BIGINT UNSIGNED NOT NULL
	);

    INSERT INTO Temp_MissingCust(CTSCustID)
	SELECT		CTSCustID	
	FROM JSON_TABLE(ip_CustomerList,
		 "$[*]" COLUMNS(
				CTSCustID		INT			UNSIGNED		PATH "$.CTSCustID"
			)
	) AS js;
    
    INSERT INTO CTS_Log.Monitor_Neo4j_CTSCustomer_Missing(CTSCustID, ScannedDate, IsResolved)
    SELECT 		CTSCustID	
            ,	ip_ScannedDate
            ,	0
    FROM Temp_MissingCust;

END$$
DELIMITER ;