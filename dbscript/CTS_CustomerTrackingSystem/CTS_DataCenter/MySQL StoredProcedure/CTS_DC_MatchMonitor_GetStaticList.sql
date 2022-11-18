/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DC_MatchMonitor_GetStaticList`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DC_MatchMonitor_GetStaticList`()
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20221118@Aries.Nguyen
		Task :		Support suspicious Irrigation in Match Monitor
		DB:			CTS_DataCenter
		Original:

		Revisions:
			- 	20221118@Aries.Nguyen: Created [Redmine ID: #179499]
            
		Param's Explanation (filtered by):
        
		Example:
        
	*/
    DECLARE	CONST_LIST_REASON				INT DEFAULT 16;
	DECLARE	CONST_LIST_SPORT 				INT DEFAULT 17;
    DECLARE	CONST_LIST_BETTYPE 				INT DEFAULT 18;
    
	SELECT 	ListNameDisplay
		,	CAST(ItemValue AS SIGNED) AS ReasonID
		,	ItemNameDisplay AS ReasonName
		,	CASE WHEN ItemDefaultValue = '1' THEN 1 ELSE 0 END IsSelected
	FROM  CTS_DataCenter.StaticList
	WHERE ListID = CONST_LIST_REASON
	ORDER BY PriorityOrder ASC;

	SELECT 	ListNameDisplay
		,	CAST(ItemValue AS SIGNED) AS SportID
		,	ItemNameDisplay AS SportName
		,	CASE WHEN ItemDefaultValue = '1' THEN 1 ELSE 0 END IsSelected
	FROM  CTS_DataCenter.StaticList
	WHERE ListID = CONST_LIST_SPORT
	ORDER BY PriorityOrder ASC;

	SELECT 	ListNameDisplay
		,	JSON_VALUE(ItemValue, '$.BetTypeID') AS BetTypeID
		,	JSON_VALUE(ItemValue, '$.BetID') AS BetID
		,	ItemNameDisplay AS BetTypeName
		,	ItemParentItemID AS SportID
		,	CASE WHEN ItemDefaultValue = '1' THEN 1 ELSE 0 END IsSelected
	FROM  CTS_DataCenter.StaticList AS sta
	WHERE ListID = CONST_LIST_BETTYPE
	ORDER BY PriorityOrder ASC;
END$$
DELIMITER ;


