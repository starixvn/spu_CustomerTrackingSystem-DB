USE `CTS_DataCenter`;
DROP procedure IF EXISTS `CTS_DC_Subscriber_GetAll`;

DELIMITER $$
USE `CTS_DataCenter`$$
CREATE DEFINER=`ctsWeb`@`%` PROCEDURE `CTS_DC_Subscriber_GetAll`()
BEGIN
	/*
		Created:	20200911@Roger.Le
		Task :		Function add new subscriber
		DB:			CTS_DataCenter && CTS_Admin
		Original: 
		Revisions:
            - [20200911@Roger.Le][138102]: Created
            - [20200924@Lex.Khuat][138102]: Support return sub with multi sites
            
		Param's Explanation:
	*/ 
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    
	SELECT	sub.SubscriberID
		,	sub.SubscriberName
        ,	sub.SubscriberPrefix
        ,	MAX(sg.SubscriberGroupName) AS SubscriberGroupName
        ,	CASE WHEN COUNT(s.SiteID) > 1 THEN NULL ELSE MAX(s.RoleMapping) END AS RoleMapping
        ,	CASE WHEN COUNT(s.SiteID) > 1 THEN NULL ELSE MAX(s.SiteID) END AS SiteID
        ,	CASE WHEN COUNT(s.SiteID) > 1 THEN CONCAT(COUNT(s.SiteID), ' Sites') ELSE MAX(s.SiteName) END AS SiteName
        ,	CASE WHEN sub.SubscriberStatus = 1 THEN sub.SubscriberStatus ELSE 0 END AS isActive
        ,	DATE(sub.CreatedDate) AS CreatedDate
        ,	DATE(sub.TerminatedDate) AS TerminatedDate
        ,	sub.IsTest
        ,	CASE WHEN COUNT(s.SiteID) > 1 THEN 1 ELSE 0 END AS isMultiSite
    FROM  CTS_Admin.Subscriber AS sub
        INNER JOIN CTS_DataCenter.MappingSubscriberSite AS s
			ON s.SubscriberID = sub.SubscriberID
        INNER JOIN CTS_DataCenter.SubscriberGroup AS sg
			ON s.SubscriberGroupID = sg.SubscriberGroupID
	GROUP BY 	sub.SubscriberID
			,	sub.SubscriberName
            ,	sub.SubscriberPrefix
            ,	CASE WHEN sub.SubscriberStatus = 1 THEN sub.SubscriberStatus ELSE 0 END
            ,	sub.CreatedDate
            ,	sub.TerminatedDate
            ,	sub.IsTest
	ORDER BY	sub.TerminatedDate ASC
			,	sub.SubscriberID ASC;
    
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;  

END$$

DELIMITER ;

