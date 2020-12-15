/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_Subscriber_GetByGroup`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_Subscriber_GetByGroup`(IN ip_IsTest BIT)
	SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20201215@Lex.Khuat
		Task :		Listing subscriber by group [Redmine ID: #146844]
		DB:			CTS_DataCenter

		Revisions:
				- 20201215@Lex.Khuat: Created [Redmine ID: #146844]

		Param's Explanation (filtered by):  
				- ip_IsTest: filter isTest subs

		Example:  
				- CALL CTS_DC_Subscriber_GetByGroup (1);
	*/

	SELECT	sub.SubscriberID
		,	sub.SubscriberName
        ,	MAX(sg.SubscriberGroupID) AS SubscriberGroupID
        ,	MAX(sg.SubscriberGroupName) AS SubscriberGroupName
    FROM  CTS_Admin.Subscriber AS sub
        INNER JOIN CTS_DataCenter.MappingSubscriberSite AS s
			ON s.SubscriberID = sub.SubscriberID
        INNER JOIN CTS_DataCenter.SubscriberGroup AS sg
			ON s.SubscriberGroupID = sg.SubscriberGroupID
	WHERE	sub.SubscriberStatus = 1
		AND	(IFNULL(ip_IsTest, 0) = 1 OR sub.IsTest = 0)
	GROUP BY 	sub.SubscriberID
			,	sub.SubscriberName
	ORDER BY	SubscriberGroupName ASC
			,	SubscriberName ASC;

END$$

DELIMITER ;