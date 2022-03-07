/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
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