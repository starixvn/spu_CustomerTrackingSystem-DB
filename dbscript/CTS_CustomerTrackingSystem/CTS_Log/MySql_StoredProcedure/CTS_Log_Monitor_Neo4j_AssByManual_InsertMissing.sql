/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
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

    INSERT INTO Temp_MissingAssByIP(AssID, FromCTSCustID, ToCTSCustID)
	SELECT		AssID
				, FromCTSCustID
                , ToCTSCustID	
	FROM JSON_TABLE(ip_AssByAIList,
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