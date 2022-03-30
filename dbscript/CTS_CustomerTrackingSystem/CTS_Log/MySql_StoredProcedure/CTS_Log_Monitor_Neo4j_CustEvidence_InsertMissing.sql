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
		Task:		Insert missing customer evidence [Redmine ID: 170381]
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