/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
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
    
SELECT ID, FromCustID, ToCustID
FROM CTS_DataCenter.AssociationByIP
WHERE ID > ip_IDAssByIP 
ORDER BY ID
LIMIT ip_BatchSize;

END$$
DELIMITER ;