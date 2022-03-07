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
    
    INSERT INTO CTS_Log.Monitor_Neo4j_AssByManual_Missing(CustID, CategoryID)
    SELECT 		CustID
				, CategoryID
    FROM Temp_MissingCustClassification;

END$$
DELIMITER ;