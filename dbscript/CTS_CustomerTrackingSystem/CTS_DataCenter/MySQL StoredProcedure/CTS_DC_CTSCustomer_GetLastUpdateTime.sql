/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_GetLastUpdateTime`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_GetLastUpdateTime`()
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20210115@Casey.Huynh
		Task:		GET SystemParameter 
		DB:			CTS_DataCenter
		Original:

		Revisions: 
			-	20210115@Casey.Huynh: Created [Redmine ID: 148849]
		Param's Explanation (filtered by):

		Example:
			- CALL `CTS_DC_CTSCustomer_GetLastUpdateTime`()

	*/    
		SELECT	s.ParameterValue AS LastUpdateTime
		FROM	CTS_DataCenter.SystemParameter AS s
		WHERE	s.ParameterID = 9 AND s.ParameterName = 'CTSCustomer_LastUpdateTime';

		SELECT	s.ParameterValue AS LastUpdateCustID
		FROM	CTS_DataCenter.SystemParameter AS s
		WHERE	s.ParameterID = 10 AND s.ParameterName = 'CTSCustomer_LastUpdateCustID';
    
END$$
DELIMITER ;