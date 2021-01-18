/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_GetLastUpdateTime`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_GetLastUpdateTime`()
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20191107@Harvey
		Task:		Insert Customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions: 
			- 20201130@Aries.Nguyen: Remove transaction isolation level UNCOMMITTED, REPEATABLE READ [Redmine ID: 145361]
			- 20200111@Casey.Huynh: Enhance CTSCustomer Flow [145271]
		Param's Explanation (filtered by):

		Example:
			- CALL CTS_DataCenter.CTS_DC_GetMaxCustIdCTSCustomer (0)

	*/    
		SELECT	s.ParamaterValue AS LastUpdateTime
		FROM	CTS_DataCenter.SystemParameter AS s
		WHERE	s.ParameterID = 9 AND s.ParameterName = 'CTSCustomer_LastUpdateTime';

		SELECT	s.ParamaterValue AS LastUpdateCustID
		FROM	CTS_DataCenter.SystemParameter AS s
		WHERE	s.ParameterID = 10 AND s.ParameterName = 'CTSCustomer_LastUpdateCustID';
    
END$$
DELIMITER ;