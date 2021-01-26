/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Common_GetAllSubscriberGroups`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Common_GetAllSubscriberGroups`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20200622@Lex.Khuat
		Task :		Get all subscribers/sites with grouped
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200622@Lex.Khuat: Created [Redmine ID: #133934]
            - 20210121@John.Ngo: Enhance CTS SPs by removing ISSOLATION [Redmine ID: 148723]
			
		Param's Explanation:
	*/
    
    SELECT DISTINCT s.SiteID
		, 	s.SiteName
        , 	s.SubscriberGroupID
        , 	sg.SubscriberGroupName
        , 	sg.ParentID
        , 	sg.DisplayOrder
        , 	sg.IsActive
    FROM CTS_DataCenter.MappingSubscriberSite AS s
		INNER JOIN CTS_DataCenter.SubscriberGroup AS sg ON s.SubscriberGroupID = sg.SubscriberGroupID
        LEFT JOIN CTS_Admin.Subscriber AS sub ON s.SubscriberID = sub.SubscriberID
    WHERE sg.IsActive = 1
		AND sub.IsTest = 0
        AND sub.SubscriberStatus = 1
    ORDER BY sg.DisplayOrder ASC, s.SiteName ASC;
    
END$$

DELIMITER ;

