/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Add new table and system parameter for AssociationByIP		[Redmine ID: 168091]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('72', 'MonitorNeo4jAssociation_LastScannedAssByIP', 'MonitorNeo4jAssociation_LastScannedAssByIP', 'BIGINT', '0');

USE CTS_Log;
CREATE TABLE `CTS_Log`.`Monitor_Neo4j_AssByIP_Missing` (
	`ID`	BIGINT UNSIGNED NOT NULL,
	`FromCustID` 	BIGINT UNSIGNED NOT NULL,
	`ToCustID`	BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`ID`));
  
####     CTS_Log_Monitor_Neo4j_AssByIP_Get     ########
USE CTS_Log;
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByIP_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByIP_Get`(
	IN ip_IDAssByIP		 	BIGINT,
    IN ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220223@Harvey
		Task:		Get Ass by IP for monitor replication MySql -> Neo4j [Redmine ID: 168091]
		DB:			CTS_Log
		Original:

		Revisions:
			- 20220128@Harvey: Init
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_Log_CTSCustomer_Get ()
	*/
    
SELECT ID 'AssByIpID', FromCustID, ToCustID
FROM CTS_DataCenter.AssociationByIP
WHERE ID > ip_IDAssByIP 
ORDER BY ID
LIMIT ip_BatchSize;

END$$
DELIMITER ;


######### CTS_Log_Monitor_Neo4j_AssByIP_InsertMissing #########
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByIP_InsertMissing`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByIP_InsertMissing`(
		IN 	ip_AssByIPList 	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201213@Harvey
		Task:		Insert missing association by IP [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220128@Harvey: Initial
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_Log.CTS_Log_Monitor_Neo4j_AssByIP_InsertMissing ('');

	*/

    INSERT INTO CTS_Log.Monitor_Neo4j_AssByIP_Missing(ID, FromCustID, ToCustID)
	SELECT		ID
				, FromCustID
                , ToCustID	
	FROM JSON_TABLE(ip_AssByIPList,
		 "$[*]" COLUMNS(
				ID				BIGINT			UNSIGNED		PATH "$.AssByIpID",
                FromCustID		BIGINT			UNSIGNED		PATH "$.FromCustID",
                ToCustID		BIGINT			UNSIGNED		PATH "$.ToCustID"
			)
	) AS js;
    

END$$
DELIMITER ;

############################ CTS_Log_Monitor_Neo4j_AssByDevice_InsertMissing #####################
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByIP_InsertMissing`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByIP_InsertMissing`(
		IN 	ip_AssByIPList 	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201213@Harvey
		Task:		Insert missing association by IP [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220128@Harvey: Initial
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_Log.CTS_Log_Monitor_Neo4j_AssByIP_InsertMissing ('');

	*/

    DROP TEMPORARY TABLE IF EXISTS Temp_MissingAssByIP;    
	CREATE TEMPORARY TABLE Temp_MissingAssByIP(
		`ID`			BIGINT UNSIGNED NOT NULL,
        `FromCustID`	BIGINT UNSIGNED NOT NULL,
        `ToCustID`		BIGINT UNSIGNED NOT NULL
	);

    INSERT INTO Temp_MissingAssByIP(ID, FromCustID, ToCustID)
	SELECT		ID
				, FromCustID
                , ToCustID	
	FROM JSON_TABLE(ip_AssByIPList,
		 "$[*]" COLUMNS(
				ID				BIGINT			UNSIGNED		PATH "$.AssByIpID",
                FromCustID		BIGINT			UNSIGNED		PATH "$.FromCustID",
                ToCustID		BIGINT			UNSIGNED		PATH "$.ToCustID"
			)
	) AS js;
    
    INSERT INTO CTS_Log.Monitor_Neo4j_AssByIP_Missing(ID, FromCustID, ToCustID)
    SELECT 		ID	
            ,	FromCustID
            ,	ToCustID
    FROM Temp_MissingAssByIP;
    

END$$
DELIMITER ;