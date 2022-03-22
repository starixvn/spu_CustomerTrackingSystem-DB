/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Add new table and system parameter for monitor Classification		[Redmine ID: 168091]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('75', 'MonitorNeo4jClassification_LastScannedCustID', 'MonitorNeo4jClassification_LastScannedCustID', 'BIGINT', '0');

USE CTS_Log;
CREATE TABLE `CTS_Log`.`Monitor_Neo4j_CustClassification_Missing` (
	`CustID`		BIGINT UNSIGNED NOT NULL,
	`CategoryID` 	SMALLINT UNSIGNED NOT NULL,
PRIMARY KEY (`CustID`, `CategoryID`));


/* SP CTS_Log_Monitor_Neo4j_CustClassification_Get*/
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_CustClassification_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_CustClassification_Get`(
	IN ip_CustID		BIGINT,
    IN ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220223@Harvey
		Task:		Get cust classification by manual for monitor replication MySql -> Neo4j [Redmine ID: 168091]
		DB:			CTS_Log
		Original:

		Revisions:
			- 20220128@Harvey: Init
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_Log_Monitor_Neo4j_AssByManual_Get ()
	*/
    
SELECT CustID, CategoryID
FROM CTS_DataCenter.CTSCustomerClassification
WHERE CustID > ip_CustID 
ORDER BY CustID
LIMIT ip_BatchSize;

END$$
DELIMITER ;

/*SP CTS_Log_Monitor_Neo4j_CustClassification_InsertMissing*/
/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_CustClassification_InsertMissing`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_CustClassification_InsertMissing`(
		IN 	ip_CustClassification 	JSON
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
			- CALL CTS_Log.CTS_Log_Monitor_Neo4j_CustClassification_InsertMissing ('');

	*/

    DROP TEMPORARY TABLE IF EXISTS Temp_MissingCustClassification;    
	CREATE TEMPORARY TABLE Temp_MissingCustClassification(
		`CustID`		BIGINT UNSIGNED NOT NULL,
        `CategoryID`	SMALLINT UNSIGNED NOT NULL
	);

    INSERT INTO Temp_MissingCustClassification(CustID, CategoryID)
	SELECT		CustID
				, CategoryID
	FROM JSON_TABLE(ip_CustClassification,
		 "$[*]" COLUMNS(
				CustID			BIGINT			UNSIGNED		PATH "$.CustID",
                CategoryID		SMALLINT		UNSIGNED		PATH "$.CategoryID"
			)
	) AS js;
    
    INSERT INTO CTS_Log.Monitor_Neo4j_CustClassification_Missing(CustID, CategoryID)
    SELECT 		CustID
				, CategoryID
    FROM Temp_MissingCustClassification;

END$$
DELIMITER ;