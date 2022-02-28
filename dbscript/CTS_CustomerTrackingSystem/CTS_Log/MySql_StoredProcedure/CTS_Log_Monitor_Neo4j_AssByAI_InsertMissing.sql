/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByAI_InsertMissing`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByAI_InsertMissing`(
		IN 	ip_AssByAIList 	JSON
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201213@Harvey
		Task:		Insert missing association by IP [Redmine AssID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 20220128@Harvey: Initial
		Param's Explanation (filtered by):
		Example:
			- CALL CTS_Log.CTS_Log_Monitor_Neo4j_AssByAI_InsertMissing ('');

	*/

    DROP TEMPORARY TABLE IF EXISTS Temp_MissingAssByAI;    
	CREATE TEMPORARY TABLE Temp_MissingAssByAI(
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
    FROM Temp_MissingAssByAI;
    

END$$
DELIMITER ;