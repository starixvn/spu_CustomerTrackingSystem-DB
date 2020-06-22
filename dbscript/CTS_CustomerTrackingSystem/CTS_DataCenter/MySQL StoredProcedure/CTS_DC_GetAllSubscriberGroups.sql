USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_GetAllSubscriberGroups`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`fps`@`%` PROCEDURE `CTS_DC_GetAllSubscriberGroups`()
BEGIN
	/*
		Created:	20200622@Lex.Khuat
		Task :		Get all subscribers/sites with grouped
		DB:			CTS_DataCenter
		Original: 
		Revisions:
			- 20200622@Lex.Khuat: Created [Redmine ID: #133934]
            
		Param's Explanation:
	*/ 

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
    SELECT DISTINCT s.SiteID, s.SiteName, s.SubscriberGroupID, sg.SubscriberGroupName, sg.ParentID, sg.DisplayOrder, sg.IsActive
    FROM CTS_DataCenter.MappingSubscriberSite AS s
		INNER JOIN CTS_DataCenter.SubscriberGroup AS sg ON s.SubscriberGroupID = sg.SubscriberGroupID
        LEFT JOIN CTS_Admin.Subscriber AS sub ON s.SubscriberID = sub.SubscriberID
    WHERE sg.IsActive = 1
		AND sub.IsTest = 0
        AND sub.SubscriberStatus = 1
    ORDER BY sg.DisplayOrder ASC, s.SiteName ASC;
    
    SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;  

END$$

DELIMITER ;

