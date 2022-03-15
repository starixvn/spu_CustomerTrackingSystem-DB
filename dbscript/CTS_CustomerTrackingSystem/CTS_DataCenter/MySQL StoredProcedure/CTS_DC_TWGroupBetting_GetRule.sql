/*<info serverAlias="CTSMain-CTS_DataCenter" databaseType="2" executers="ctsWeb,ctsAPI,ctsService" isFunction="0" isNested="0"></info>*/
DROP PROCEDURE IF EXISTS `CTS_DataCenter`.`CTS_DC_TWGroupBetting_GetRule`;

DELIMITER $$
CREATE DEFINER=`ctsOwner`@`%` PROCEDURE `CTS_DataCenter`.`CTS_DC_TWGroupBetting_GetRule`(
		IN ip_CustIDs 	TEXT
    ,	IN ip_TypeID 	SMALLINT
)
    SQL SECURITY INVOKER
BEGIN
	/*
		Created:	20220315@Harvey.Nguyen
		Task:		Get all rule
		DB:			CTS_DataCenter 
		Original:
		Revisions:
			- 20220315@Harvey.Nguyen: Initial 	-	[Redmine ID: 169334]
		Param's Explanation (filtered by):
            
		Example:
			- CALL CTS_DataCenter.CTS_DC_CustClassification_GetDangerLevel('36266996,27852979,2324948',1);
	*/
    
	SELECT RuleId
		,RuleName
		,LimitSecond
	FROM TWGroupBettingRule;
END$$
DELIMITER ;