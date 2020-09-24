USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_Subscriber_GetDetails`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_Subscriber_GetDetails`(
		IN ip_SubscriberID		INT
)
BEGIN
	/*
		Created:	20200924@Lex.Khuat
		Task :		Get Subcriber site details
		DB:			CTS_DataCenter
		Original: 
		Revisions:
            - [20200924@Lex.Khuat][138102]: Created
            
		Param's Explanation:
	*/
    
    SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    SELECT	RoleMapping
		,	SiteID
        ,	SiteName
	FROM CTS_DataCenter.MappingSubscriberSite
    WHERE SubscriberID = IFNULL(ip_SubscriberID, 0)
    ORDER BY	RoleMapping ASC
			,	SiteID ASC;

    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

END$$

DELIMITER ;

