/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Common_GetSites`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Common_GetSites`()
    SQL SECURITY INVOKER
BEGIN
/* 
		Created:	20220831@Aries.Nguyen
		Task :		[CTS] Associated Group Enhancement
		DB:			CTS_DataCenter
		Original: 
		Revisions: 
			- 20220831@Aries.Nguyen: Created [Redmine ID: #176991] 
		
        Param's Explanation: 

		Example:

*/
   SELECT 	SiteID
		,	SiteName
		,	CASE WHEN MAX(SubscriberGroupID) = 2 THEN 1 
			ELSE 0 END AS IsLicensee
	FROM CTS_DataCenter.MappingSubscriberSite
	GROUP BY SiteID
		,	 SiteName;
END$$
DELIMITER ;
