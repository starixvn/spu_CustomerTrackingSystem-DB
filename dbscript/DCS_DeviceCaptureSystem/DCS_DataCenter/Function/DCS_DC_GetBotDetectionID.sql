/*<info serverAlias="CTSMain-DCS_DataCenter" databaseType="2" executers="ctsServiceAdmin,ctsService" isFunction="1" isNested="0"></info>*/
DELIMITER $$

USE DCS_DataCenter$$
DROP FUNCTION IF EXISTS DCS_DC_GetBotDetectionID$$
CREATE DEFINER=`ctsOwner`@`%` FUNCTION DCS_DC_GetBotDetectionID(
	ip_BotDetectionJson LONGTEXT
)

RETURNS BIT(20)

DETERMINISTIC

BEGIN 
/*
	Created: 20230425@Jonathan.Doan
	Task : Return ID of BotDetection
	DB: DCS_DataCenter
	Original:

	Revisions:
	Param's Explanation (filtered by):
		SELECT DCS_DataCenter.DCS_DC_GetBotDetectionID('{"detectAppVersion":{"bot":true},"detectDocumentAttributes":{"bot":true},"detectDocumentProperties":{"bot":false}}')
*/

	DECLARE ip_BotDetectionValue BIT(20) DEFAULT 0;
    
	DROP TEMPORARY TABLE IF EXISTS Temp_Input;
	CREATE TEMPORARY TABLE Temp_Input(
        	Name				VARCHAR(100)			NULL		COMMENT 'BotKind.Name | None'
        ,	Value				BIT(20)					NULL		
    );     
    
    INSERT INTO Temp_Input(Name, Value)
    SELECT 	bd.Name
		,	bd.Value
	FROM (
		SELECT 	'detectAppVersion' AS Name, JSON_EXTRACT(ip_BotDetectionJson,'$.detectAppVersion.bot') AS Bot
		UNION ALL SELECT 'detectDocumentAttributes', JSON_EXTRACT(ip_BotDetectionJson,'$.detectDocumentAttributes.bot')
		UNION ALL SELECT 'detectDocumentProperties', JSON_EXTRACT(ip_BotDetectionJson,'$.detectDocumentProperties.bot')
		UNION ALL SELECT 'detectErrorTrace', JSON_EXTRACT(ip_BotDetectionJson,'$.detectErrorTrace.bot')
		UNION ALL SELECT 'detectEvalLengthInconsistency', JSON_EXTRACT(ip_BotDetectionJson,'$.detectEvalLengthInconsistency.bot')
		UNION ALL SELECT 'detectFunctionBind', JSON_EXTRACT(ip_BotDetectionJson,'$.detectFunctionBind.bot')
		UNION ALL SELECT 'detectLanguagesLengthInconsistency', JSON_EXTRACT(ip_BotDetectionJson,'$.detectLanguagesLengthInconsistency.bot')
		UNION ALL SELECT 'detectNotificationPermissions', JSON_EXTRACT(ip_BotDetectionJson,'$.detectNotificationPermissions.bot')
		UNION ALL SELECT 'detectPluginsArray', JSON_EXTRACT(ip_BotDetectionJson,'$.detectPluginsArray.bot')
		UNION ALL SELECT 'detectPluginsLengthInconsistency', JSON_EXTRACT(ip_BotDetectionJson,'$.detectPluginsLengthInconsistency.bot')
		UNION ALL SELECT 'detectProcess', JSON_EXTRACT(ip_BotDetectionJson,'$.detectProcess.bot')
		UNION ALL SELECT 'detectUserAgent', JSON_EXTRACT(ip_BotDetectionJson,'$.detectUserAgent.bot')
		UNION ALL SELECT 'detectWebDriver', JSON_EXTRACT(ip_BotDetectionJson,'$.detectWebDriver.bot')
		UNION ALL SELECT 'detectWebGL', JSON_EXTRACT(ip_BotDetectionJson,'$.detectWebGL.bot')
		UNION ALL SELECT 'detectWindowExternal', JSON_EXTRACT(ip_BotDetectionJson,'$.detectWindowExternal.bot')
		UNION ALL SELECT 'detectWindowProperties', JSON_EXTRACT(ip_BotDetectionJson,'$.detectWindowProperties.bot')
		UNION ALL SELECT 'detectWindowSize', JSON_EXTRACT(ip_BotDetectionJson,'$.detectWindowSize.bot')
		UNION ALL SELECT 'detectMimeTypesConsistent', JSON_EXTRACT(ip_BotDetectionJson,'$.detectMimeTypesConsistent.bot')
		UNION ALL SELECT 'detectProductSub', JSON_EXTRACT(ip_BotDetectionJson,'$.detectProductSub.bot')
		UNION ALL SELECT 'detectProductSub1', JSON_EXTRACT(ip_BotDetectionJson,'$.detectProductSub1.bot')
	) AS tmp
		INNER JOIN DCS_DataCenter.BotDetection AS bd ON bd.Name = tmp.Name
	WHERE tmp.Bot = true;
    
    SELECT IFNULL(SUM(tmp.Value), 0)
    INTO ip_BotDetectionValue
    FROM Temp_Input AS tmp;
    
	RETURN ip_BotDetectionValue;
END$$

DELIMITER ;

