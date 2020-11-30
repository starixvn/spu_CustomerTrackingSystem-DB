/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_GetMaxCustIdCTSCustomer`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_GetMaxCustIdCTSCustomer` (IN ip_IsCustSub BOOLEAN)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20191107@Harvey
		Task:		Insert Customer [Redmine ID: 116528]
		DB:			CTS_DataCenter
		Original:

		Revisions: 
			- 20201130@Aries.Nguyen: Remove transaction isolation level UNCOMMITTED, REPEATABLE READ [Redmine ID: 145361]
        
		Param's Explanation (filtered by):
        
        CALL CTS_DataCenter.CTS_DC_GetMaxCustIdCTSCustomer (0)
	*/
IF ip_IsCustSub = 0 THEN
	SELECT 
		CASE
			WHEN MAX(custid) IS NULL THEN 0
			ELSE MAX(custid)
		END AS 'MaxCustId'
	FROM CTS_DataCenter.CTSCustomer;
ELSE
	SELECT 
		CASE
			WHEN MAX(CustSubID) IS NULL THEN 0
			ELSE MAX(CustSubID)
		END AS 'MaxCustId'
	FROM CTS_DataCenter.CTSCustomer;
END IF;
    
END$$
DELIMITER ;