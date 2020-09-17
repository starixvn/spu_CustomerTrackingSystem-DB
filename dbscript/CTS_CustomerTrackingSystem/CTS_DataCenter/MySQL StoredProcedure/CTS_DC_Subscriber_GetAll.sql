DELIMITER $$
USE `CTS_DataCenter` $$
DROP PROCEDURE IF EXISTS CTS_DC_Subscriber_GetAll $$

CREATE  PROCEDURE `CTS_DC_Subscriber_GetAll`()
BEGIN
	/*
		Created:	20200911@Roger.Le
		Task :		Function add new subscriber
		DB:			CTS_DataCenter && CTS_Admin
		Original: 
		Revisions:
			- 20200911@Roger.Le: Created [Redmine ID: #138102]
            
		Param's Explanation:
	*/ 

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
	SELECT DISTINCT sub.SubscriberID
		, sub.SubscriberName
        , sub.SubscriberPrefix
        , sg.SubscriberGroupName
        , s.RoleMapping
        , s.SiteID
        , s.SiteName
        , CASE WHEN sub.SubscriberStatus = 1 THEN sub.SubscriberStatus ELSE 0 END AS isActive
        , sub.CreatedDate
        , sub.TerminatedDate
    FROM  CTS_Admin.Subscriber AS sub
        INNER JOIN CTS_DataCenter.MappingSubscriberSite AS s ON s.SubscriberID = sub.SubscriberID
        INNER JOIN CTS_DataCenter.SubscriberGroup AS sg ON s.SubscriberGroupID = sg.SubscriberGroupID
	ORDER BY sub.TerminatedDate ASC, sub.SubscriberID ASC;

    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

END$$
DELIMITER ;