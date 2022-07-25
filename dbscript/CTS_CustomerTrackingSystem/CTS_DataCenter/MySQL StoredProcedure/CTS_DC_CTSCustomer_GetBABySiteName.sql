/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_CTSCustomer_GetBABySiteName`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_CTSCustomer_GetBABySiteName`(
	IN ip_SiteName 		VARCHAR(50) 
)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220707@Long.Luu
		Task:		Get Customer by SiteName [Redmine ID: 174219]
		DB:			CTS_DataCenter
		Original:

		Revisions: 
			- 20220707@Long.Luu: Created [Redmine ID: 174219]
            
		Param's Explanation (filtered by):

		Example:
			- CALL CTS_DC_CTSCustomer_GetBABySiteName('BEST-ODDS');
	*/
		DECLARE lv_SiteID 		INT;
        
        SELECT SiteID
		INTO lv_SiteID
        FROM CTS_DataCenter.CTSCustomer
		WHERE Site = ip_SiteName
        LIMIT 1;
	
		SELECT c.CustID, c.CTSCustID, c.UserName, c.RoleID, c.SiteID, c.IsLicensee, c.IsLicenseeVIP, c.IsLicenseeBA
		FROM CTS_DataCenter.CTSCustomer AS c
		WHERE c.SiteID = lv_SiteID
			AND IsLicenseeBA = 1;
    
END$$
DELIMITER ;