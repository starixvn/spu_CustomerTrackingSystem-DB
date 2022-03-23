/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2"></info>*/
/*
    Creator: 	20220207@Harvey.Nguyen
    Task:	 	Add new table and system parameter for monitor CustEvidence		[Redmine ID: 168091]
    DBName:		CTS_DataCenter
*/

/*Run on Master*/
USE CTS_DataCenter;
INSERT INTO `CTS_DataCenter`.`SystemParameter` (`ParameterID`, `ParameterName`, `ParameterDesc`, `ParameterDataType`, `ParameterValue`) VALUES ('83', 'MonitorNeo4jCustEvidence_LastScannedCustEvidID', 'MonitorNeo4jCustEvidence_LastScannedCustEvidID', 'BIGINT', '0');

USE CTS_Log;
CREATE TABLE `CTS_Log`.`Monitor_Neo4j_CustEvidence_Missing` (
	CustEvidID		BIGINT UNSIGNED PRIMARY KEY,
	CTSCustID		BIGINT UNSIGNED NOT NULL,
	EvidenceID	 	SMALLINT UNSIGNED NOT NULL);
    

/*SP CTS_Log_Monitor_Neo4j_CustEvidence_Get*/
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_CustEvidence_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_CustEvidence_Get`(
	IN ip_CustEvidID		BIGINT,
    IN ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220223@Harvey
		Task:		Get cust evidence for monitor replication MySql -> Neo4j [Redmine ID: 168091]
		DB:			CTS_Log
		Original:

		Revisions:
			- 20220128@Harvey: Init
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_Log_Monitor_Neo4j_CustEvidence_Get ()
	*/

SELECT CustEvidID
	, CTSCustID
	, EvidenceID
FROM CTS_DataCenter.CustEvidence
WHERE CustEvidID > ip_CustEvidID
	AND LEVEL = 0
ORDER BY CustEvidID
LIMIT ip_BatchSize;

END$$
DELIMITER ;


/* SP CTS_Log_Monitor_Neo4j_CustEvidence_InsertMissing */
/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_CustEvidence_InsertMissing`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_CustEvidence_InsertMissing`(
		IN 	ip_CustEvidence 	JSON
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

    DROP TEMPORARY TABLE IF EXISTS Temp_MissingCustEvidence;    
	CREATE TEMPORARY TABLE Temp_MissingCustEvidence(
		CustEvidID		BIGINT UNSIGNED NOT NULL,
        CTSCustID		BIGINT UNSIGNED NOT NULL,
        EvidenceID		SMALLINT
	);

    INSERT INTO Temp_MissingCustEvidence(CustEvidID, CTSCustID, EvidenceID)
	SELECT		CustEvidID
				, CTSCustID
				, EvidenceID
	FROM JSON_TABLE(ip_CustEvidence,
		 "$[*]" COLUMNS(
				CustEvidID			BIGINT			UNSIGNED		PATH "$.CustEvidID",
                CTSCustID			BIGINT			UNSIGNED		PATH "$.CTSCustID",
                EvidenceID			SMALLINT		UNSIGNED		PATH "$.EvidenceID"
			)
	) AS js;
    
    INSERT INTO CTS_Log.Monitor_Neo4j_CustEvidence_Missing(CustEvidID, CTSCustID, EvidenceID)
    SELECT 		CustEvidID
			, CTSCustID
			, EvidenceID
    FROM Temp_MissingCustEvidence;

END$$
DELIMITER ;