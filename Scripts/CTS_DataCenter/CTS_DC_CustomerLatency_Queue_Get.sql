/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustomerLatency_Queue_Get`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_CustomerLatency_Queue_Get`(
	IN	ip_BatchSize	INT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Creator:	20250416@Thomas.Nguyen
		Task:	 	
		Server:  	CTSMain
		DBName:		CTS_DataCenter

		Revisions: 
				- 20250416@Thomas.Nguyen: 	Created [Redmine ID: #223443]

		Example:
			CALL CTS_DC_CustomerLatency_Queue_Get (1000);
	*/ 
   
	SELECT clq.CustID
	FROM CTS_DataCenter.CTSCustomerLatencyQueue AS clq
	ORDER BY clq.ID ASC
	LIMIT ip_BatchSize;

END$$
DELIMITER ;