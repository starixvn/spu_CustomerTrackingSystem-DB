/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Add new table and system parameter for AssociationByAI		[Redmine ID: 168091]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('73', 'MonitorNeo4jAssociation_LastScannedAssByAI', 'MonitorNeo4jAssociation_LastScannedAssByAI', 'BIGINT', '0');

ALTER TABLE `CTS_DataCenter`.`AssociationByAI` 
DROP PRIMARY KEY,
ADD COLUMN `AssID` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT FIRST,
ADD PRIMARY KEY (`AssID`),
DROP INDEX IX_AssociationByAI_ToCustID,
ADD UNIQUE INDEX `UN_AssociationByAI_FromCustID_ToCustID` (`FromCustID`,`ToCustID`) VISIBLE,
ADD INDEX `IX_AssociationByAI_ToCustID_FromCustID` (`ToCustID`,`FromCustID`) VISIBLE;


USE CTS_Log;
CREATE TABLE `CTS_Log`.`Monitor_Neo4j_AssByAI_Missing` (
	`AssID`			BIGINT UNSIGNED NOT NULL,
	`FromCustID` 	BIGINT UNSIGNED NOT NULL,
	`ToCustID`		BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`AssID`));
  
################################### CTS_Log_Monitor_Neo4j_AssByAI_InsertMissing ###########################
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByAI_InsertMissing`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByAI_InsertMissing`(
		IN 	ip_AssByAIList 	JSON
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
		`AssID`			BIGINT UNSIGNED NOT NULL,
        `FromCustID`	BIGINT UNSIGNED NOT NULL,
        `ToCustID`		BIGINT UNSIGNED NOT NULL
	);

    INSERT INTO Temp_MissingAssByIP(AssID, FromCustID, ToCustID)
	SELECT		AssID
				, FromCustID
                , ToCustID	
	FROM JSON_TABLE(ip_AssByAIList,
		 "$[*]" COLUMNS(
				AssID			BIGINT			UNSIGNED		PATH "$.AssID",
                FromCustID		BIGINT			UNSIGNED		PATH "$.FromCustID",
                ToCustID		BIGINT			UNSIGNED		PATH "$.ToCustID"
			)
	) AS js;
    
    INSERT INTO CTS_Log.Monitor_Neo4j_AssByAI_Missing(AssID, FromCustID, ToCustID)
    SELECT 		AssID	
            ,	FromCustID
            ,	ToCustID
    FROM Temp_MissingAssByIP;

END$$
DELIMITER ;

################################### CTS_Log_Monitor_Neo4j_AssByAI_Get ###########################
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByAI_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByAI_Get`(
	IN ip_AssID		BIGINT,
    IN ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220223@Harvey
		Task:		Get Ass by AI for monitor replication MySql -> Neo4j [Redmine ID: 168091]
		DB:			CTS_Log
		Original:

		Revisions:
			- 20220128@Harvey: Init
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_Log_Monitor_Neo4j_AssByAI_Get ()
	*/
    
SELECT AssID, FromCustID, ToCustID
FROM CTS_DataCenter.AssociationByAI
WHERE AssID > ip_AssID 
ORDER BY AssID
LIMIT ip_BatchSize;

END$$