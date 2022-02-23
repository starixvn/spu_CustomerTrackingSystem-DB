/*<info serverAlias="CTSMain-CTS_Log" databaseType="2" executers="ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_Log_Monitor_Neo4j_AssByDevice_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_Log_Monitor_Neo4j_AssByDevice_Get`(
	IN ip_CTSAssDevID 	BIGINT,
    IN ip_BatchSize 	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220221@Harvey
		Task:		Get Ass by device for monitor replication MySql -> Neo4j [Redmine ID: 168091]
		DB:			CTS_Log
		Original:

		Revisions:
			- 20220128@Harvey: Init
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_Log_CTSCustomer_Get ()
	*/
    
SELECT CTSAssDevID
	, CTSCustID
    , DCSDeviceID AS 'DeviceID'
FROM CTS_DataCenter.AssociationByDevice
WHERE CTSAssDevID > ip_CTSAssDevID 
ORDER BY CTSAssDevID
LIMIT ip_BatchSize;

END$$
DELIMITER ;