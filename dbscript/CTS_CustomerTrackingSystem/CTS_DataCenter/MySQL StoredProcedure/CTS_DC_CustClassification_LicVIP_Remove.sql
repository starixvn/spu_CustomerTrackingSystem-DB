/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWebAdmin,ctsServiceAdmin" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_CustClassification_LicVIP_Remove`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CustClassification_LicVIP_Remove`(
		IN ip_CustIDList TEXT
)
    SQL SECURITY INVOKER
sp: BEGIN
		/*
		Created:	20200705@Casey.Huynh
		Task :		New Category Licensee VIP 
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200705@Casey.Huynh [Redmine ID: #174219]: Created
            
		Param's Explanation:
            
		Example:
			CALL CTS_DC_CustClassification_LicVIP_Remove('1,2,3,4');
	*/
    
   	SELECT 1 AS CustID;
    
END$$
DELIMITER ;