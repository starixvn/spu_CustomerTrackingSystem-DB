/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Add new table and system parameter for AssociationByManual		[Redmine ID: 168091]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('74', 'MonitorNeo4jAssociation_LastScannedAssByManual', 'MonitorNeo4jAssociation_LastScannedAssByManual', 'BIGINT', '0');

ALTER TABLE `CTS_DataCenter`.`AssociationByManual` 
ADD COLUMN `AssID` BIGINT NOT NULL AUTO_INCREMENT FIRST,
DROP PRIMARY KEY,
ADD PRIMARY KEY (`AssID`),
ADD INDEX `IX_AssociationByManual_FromCTSCustID` (`FromCTSCustID` ASC) VISIBLE;
;


USE CTS_Log;
CREATE TABLE `CTS_Log`.`Monitor_Neo4j_AssByManual_Missing` (
	`AssID`				BIGINT UNSIGNED NOT NULL,
	`FromCTSCustID` 	BIGINT UNSIGNED NOT NULL,
	`ToCTSCustID`		BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (`AssID`));
  
################################ CTS_Log_Monitor_Neo4j_AssByManual_Get #####################

DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByManual_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByManual_Get`(
	IN ip_AssID		BIGINT,
    IN ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220223@Harvey
		Task:		Get Ass by manual for monitor replication MySql -> Neo4j [Redmine ID: 168091]
		DB:			CTS_Log
		Original:

		Revisions:
			- 20220128@Harvey: Init
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_Log_Monitor_Neo4j_AssByManual_Get ()
	*/
    
SELECT AssID, FromCTSCustID, ToCTSCustID
FROM CTS_DataCenter.AssociationByManual
WHERE AssID > ip_AssID 
ORDER BY AssID
LIMIT ip_BatchSize;

END$$
DELIMITER ;

################################ CTS_Log_Monitor_Neo4j_AssByManual_InsertMissing #####################

DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByManual_InsertMissing`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByManual_InsertMissing`(
		IN 	ip_AssByManualList 	JSON
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

    DROP TEMPORARY TABLE IF EXISTS Temp_MissingAssByManual;    
	CREATE TEMPORARY TABLE Temp_MissingAssByManual(
		`AssID`			BIGINT UNSIGNED NOT NULL,
        `FromCTSCustID`	BIGINT UNSIGNED NOT NULL,
        `ToCTSCustID`		BIGINT UNSIGNED NOT NULL
	);

    INSERT INTO Temp_MissingAssByManual(AssID, FromCTSCustID, ToCTSCustID)
	SELECT		AssID
				, FromCTSCustID
                , ToCTSCustID	
	FROM JSON_TABLE(ip_AssByManualList,
		 "$[*]" COLUMNS(
				AssID			BIGINT			UNSIGNED		PATH "$.AssID",
                FromCTSCustID	BIGINT			UNSIGNED		PATH "$.FromCTSCustID",
                ToCTSCustID		BIGINT			UNSIGNED		PATH "$.ToCTSCustID"
			)
	) AS js;
    
    INSERT INTO CTS_Log.Monitor_Neo4j_AssByManual_Missing(AssID, FromCTSCustID, ToCTSCustID)
    SELECT 		AssID	
            ,	FromCTSCustID
            ,	ToCTSCustID
    FROM Temp_MissingAssByManual;

END$$
DELIMITER ;