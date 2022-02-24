/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
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