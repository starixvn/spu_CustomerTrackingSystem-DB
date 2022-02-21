/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Log_CTSCustomer_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_CTSCustomer_Get`(
	IN ip_CTSCustID 	BIGINT,
    IN ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220128@Harvey
		Task:		Get Customer for monitor replication MySql -> Neo4j [Redmine ID: 168091]
		DB:			CTS_Log
		Original:

		Revisions:
			- 20220128@Harvey: Init
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_Log_CTSCustomer_Get ()
	*/
    
SELECT CTSCustID
FROM CTS_DataCenter.CTSCustomer
WHERE CTSCustID > ip_CTSCustID 
ORDER BY CTSCustID
LIMIT ip_BatchSize;

END$$
DELIMITER ;